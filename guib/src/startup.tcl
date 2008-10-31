#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec wish "$0" ${1+"$@"}

# startup.tcl
#
#	Starts up application, reporting any start-up errors.
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# We require Tk 8.4 for compound buttons, labelframes, spinboxes and
# a few other of the cool new features to make things look nicer.
# BWidgets is for the extra megawidgets like tabnotebook and combobox.
package require Tcl 8.4
package require BWidget
package require tile
package require widget::dialog 1.2
package require widget::scrolledwindow

# Use BWidget's theme set
Widget::theme 1

# Set this to one when we are in beta
set ::BETA 0

# We are using tile in general, but add a var that allows us to switch
# for some questionable transition areas.  The AQUA variable is to allow
# for widget elements that need different L&F on Aqua.
set ::TILE 1
set ::AQUA [expr {[tk windowingsystem] eq "aqua"}]

ttk::style configure Slim.TButton -padding 1
ttk::style configure Slim.Toolbutton -padding 1

ttk::style map TEntry -fieldbackground {invalid \#FFFFE0} \
    -foreground {invalid \#FF0000}
ttk::style map TLabel -foreground {invalid \#FF0000}

if {$::AQUA} {
    set ::tk::mac::useThemedToplevel 1
}

# Initialize some namespaces
namespace eval ::main {}
namespace eval ::gui {
    # We need to cache our startup directory
    variable BASEDIR [file normalize [file dirname [info script]]]

    variable APPNAME	"GUI Builder"	;# external name of app
    variable APPSHORT	"GUI_Builder"
    # We have deprecated use of VERSION in favor of just the build number
    # while it was a Komodo component.
    variable VERSION	3.0		;# version of app
    # This is what we display/expose to users, Rev gets set by svn
    variable BUILD	"Build [regexp -inline {\d+} {$Rev$}]"
    variable FULLVER	$VERSION.$BUILD

    variable COMPANY	"GUIB"

    # "Magic cookie" for ui files, an RE to match the first line
    variable FILEID	"# GUIBUILDER FILE"
    variable DATEFMT	"%Y-%m-%d %T"	;# date format for output files

    variable FILE_TYPES [list \
	    [list "$APPNAME UI files" {.ui} {TEXT GBui}] \
	    [list "All files"		*] \
	    ]

    # The separator character for enumeration in the auto-naming of widgets
    # This used to be '#'.  This should not be a regexp sensitive char.
    variable SEP	"_"

    # Supported languages - also update wbuilder.tcl:widget::get
    variable LANGS
    array set LANGS {
	tcl     {Tcl/Tk         {8.5 8.4 8.3}}
	perl    {Perl/Tk        {8.4 8.0}}
	perltkx {Perl/Tkx       {8.5 8.4}}
	tkinter {Python/Tkinter {8.5 8.4 8.3}}
	ruby    {Ruby/Tk        {8.5 8.4 8.3}}
    }
    # Current language info
    variable LANG
    set LANG(CUR)  tcl
    set LANG(NAME) Tcl/Tk
    set LANG(VER)  8.5
    set LANG(INIT) ""
    set LANG(INTERP) ""
}

proc ::gui::timestamp {} {
    return [clock format [clock seconds] -format $::gui::DATEFMT]
}


# Source --
#
#	Loads the given source file from the installation directory.
#
# Arguments:
#	name:	name of file to source
# Result:
#	None.
#
proc ::Source {name} {
    set file [file join $::gui::BASEDIR $name]
    uplevel #0 [list source $file]
}

# Toplevel --
#
#	A variation of toplevel to set certain attributes (unix only).
#
# Arguments:
#	name:	name of file to source
# Result:
#	None.
#
if {[tk windowingsystem] eq "x11"
    && ![catch {rename ::toplevel ::tk::toplevel}]} {
    proc ::toplevel {w args} {
	uplevel 1 [linsert $args 0 ::tk::toplevel $w]
	# Do this after idle to not cause the toplevel to blink onto
	# the screen.
	after idle [list ::port::seticon $w]
	return $w
    }
}

# ::gui::PlaceWindow --
#   place a toplevel at a particular position.
#   Same as tk::PlaceWindow, except it doesn't withdraw or deiconify
# Arguments:
#   toplevel	name of toplevel window
#   ?placement?	pointer ?center? ; places $w centered on the pointer
#		widget widgetPath ; centers $w over widget_name
#		defaults to placing toplevel in the middle of the screen
#   ?anchor?	center or widgetPath
# Results:
#   Returns nothing
#
proc ::gui::PlaceWindow {w {place ""} {anchor ""} {dir ""}} {
    update idletasks
    set checkBounds 1
    set wreqw [winfo reqwidth $w]
    set wreqh [winfo reqheight $w]
    if {$place eq "pointer"} {
	## place at POINTER (centered if $anchor == center)
	if {$anchor eq "center"} {
	    set x [expr {[winfo pointerx $w] - $wreqw/2}]
	    set y [expr {[winfo pointery $w] - $wreqh/2}]
	} else {
	    set x [winfo pointerx $w]
	    set y [winfo pointery $w]
	}
    } elseif {$place eq "widget" &&
	      [winfo exists $anchor] && [winfo ismapped $anchor]} {
	set rootx [winfo rootx $anchor]
	set rooty [winfo rooty $anchor]
	set aw    [winfo width $anchor]
	set ah    [winfo height $anchor]
	if {$dir eq "left"} {
	    set x [expr {$rootx - $wreqw}]
	    set y $rooty
	} elseif {$dir eq "right"} {
	    set x [expr {$rootx + $aw}]
	    set y $rooty
	} elseif {$dir eq "bottom"} {
	    set x $rootx
	    set y [expr {$rooty + $ah}]
	} elseif {$dir eq "top"} {
	    set x $rootx
	    set y [expr {$rooty - $wreqh}]
	} else {
	    ## center about WIDGET $anchor, widget must be mapped
	    set x [expr {$rootx + ($aw - $wreqw)/2}]
	    set y [expr {$rooty + ($ah - $wreqh)/2}]
	}
    } else {
	set x [expr {([winfo screenwidth $w]-[winfo reqwidth $w])/2}]
	set y [expr {([winfo screenheight $w]-[winfo reqheight $w])/2}]
	set checkBounds 0
    }
    if {[tk windowingsystem] eq "win32"} {
        # Bug 533519: win32 multiple desktops may produce negative geometry.
	# -1 indicates negative values are allowed when the entire geometry
	# (left and right or top and bottom) is negative.
        set checkBounds -1
    }
    if {$checkBounds} {
	if {$x < 0} {
	    # If checkBounds indicates negative allowed and both ends are
	    # negative, do not reset the x coord
	    if {($checkBounds != -1) || (($x + [winfo reqwidth $w]) > 0)} {
		set x 0
	    }
	} elseif {$x > ([winfo screenwidth $w]-[winfo reqwidth $w])} {
	    set x [expr {[winfo screenwidth $w]-[winfo reqwidth $w]}]
	}
	if {$y < 0} {
	    # If checkBounds indicates negative allowed and both ends are
	    # negative, do not reset the x coord
	    if {($checkBounds != -1) || (($y + [winfo reqheight $w]) > 0)} {
		set y 0
	    }
	} elseif {$y > ([winfo screenheight $w]-[winfo reqheight $w])} {
	    set y [expr {[winfo screenheight $w]-[winfo reqheight $w]}]
	}
	if {[tk windowingsystem] eq "aqua"} {
	    # Avoid the native menu bar which sits on top of everything.
	    if {$y < 20} { set y 20 }
	}
    }
    wm geometry $w +$x+$y
}

proc ::main::version {} {
    puts stdout "$::gui::COMPANY $::gui::APPNAME $::gui::BUILD"
    exit 0
}

proc ::main::usage {{chan stderr}} {
    puts $chan "$::gui::COMPANY $::gui::APPNAME $::gui::BUILD\
	    \nUsage: [file tail $::argv0] ?options? ?project?\
	    \n\t--help           print help info to stdout and exit\
	    \n\t--directory dir  specify current working directory to start in\
	    \n\t--interactive    run in interactive control mode\
	    \n\t--language 'lang ?ver?'  specify target language\
	    \n\t--languages      specify available target languages and exit\
	    \n\t--project name   specify project to load\
	    \n\t--version        print version to stdout and exit\
	    "
    if {$chan == "stderr"} { exit 1 } else { exit 0 }
}

proc ::main::handle_args {argc argv} {
    global P env
    variable ARGS
    catch {unset ARGS}
    if {[info exists env(GUIBUILDER_DEBUG)]} {
	set ARGS(debug) [string is true -strict $env(GUIBUILDER_DEBUG)]
    }
    set ARGS(gm) grid
    if {$::AQUA && [string match "-psn*" [lindex $argv 0]]} {
	# Handle OS X's app bundle arg
	incr argc -1
	set argv [lrange $argv 1 end]
    }
    for {set i 0} {$i < $argc} {incr i} {
	set arg [lindex $argv $i]
	if {![string match {-*} $arg]} { break }
	set val [lindex $argv [incr i]]
	## Handle arg based options
	switch -glob -- $arg {
	    --			{ incr i -1; break }
	    --debug		{
		# no val arg, decr i
		incr i -1
		# this will cause tkcon to be used
		set ARGS(debug) 1
	    }
	    --interactive	{
		set chan [file channels std*]
		if {[lsearch -exact $chan stdin] == -1 \
			|| [lsearch -exact $chan stdout] == -1} {
		    puts stderr "no std channels to work interactively"
		    usage stderr; # this will not return
		}
		if {![info exists ARGS(interactive)]} {
		    # Only allow this to be called once, but call it here
		    # so that it is as early as can be called once we know
		    # interactivity is desired.
		    set ARGS(interactive) 1
		    if {[string is integer -strict $val]} {
			# we've been passed a port to listen on
			set sock [::api::_connect 127.0.0.1 $val]
			if {$sock eq ""} {
			    puts stderr "unable to open socket to port $val"
			    exit 1
			}
			::api::_Interactive $sock $sock
		    } else {
			# no val arg, decr i, listed on stdin/stdout
			incr i -1
			::api::_Interactive stdin stdout
		    }
		}
	    }
	    --languages		{
		variable ::gui::LANGS
		set out ""
		foreach lang [lsort [array names LANGS]] {
		    set desc [lindex $LANGS($lang) 0]
		    foreach ver [lindex $LANGS($lang) 1] {
			lappend out $lang\ $ver:$desc\ $ver
		    }
		}
		puts stdout [join $out "\t"]
		exit 0
	    }
	    --language		{
		variable ::gui::LANGS
		if {[llength $val] > 1} {
		    set lang [string tolower [lindex $val 0]]
		} else {
		    set lang [string tolower $val]
		}
		if {$lang eq "default"} {
		    set ::gui::LANG(INIT) "default"
		    continue
		}
		if {![info exists LANGS($lang)]} {
		    puts stderr "unrecognized target language \"$val\",\
			    must be one of: [array names LANGS]"
		    usage stderr; # this will not return
		}
		set vers [lindex $LANGS($lang) 1]
		if {[llength $val] > 1} {
		    set ver [lindex $val 1]
		    set idx [lsearch -exact $vers $ver]
		    if {$idx == -1} {
			puts stderr "unrecognized target version \"$ver\"\
				for $lang, must be one of: $vers"
			usage stderr; # this will not return
		    }
		} else {
		    # default to first known version
		    set ver [lindex $vers 0]
		}
		# this will call targetLanguage after all sources are loaded
		set ARGS(lang) [list $lang $ver]
		set ::gui::LANG(INIT) "language"
	    }
	    --directory		{
		if {[catch {cd $val} msg]} {
		    puts stderr "could not cd to \"$val\":\n$msg"
		    usage stderr; # this will not return
		}
	    }
	    --tetris		{
		# just start uitris and nothing else
		set ARGS(tetris) 1
	    }
	    --gm		{
		if {[lsearch -exact {grid place} $val] == -1} {
		    puts stderr "invalid gm \"$val\": must be grid or place"
		    usage stderr; # this will not return
		}
		set ARGS(gm) $val
	    }
	    --project		{ set ARGS(project) $val }
	    --version		{ version;      # this will not return }
	    --help		{ usage stdout; # this will not return }
	    default		{ usage stderr; # this will not return }
	}
    }
    if {$i < $argc} {
	# If --project was explicitly used, then another project is not valid
	if {$argc - $i > 1 || [info exists ARGS(project)]} {
	    usage
	} else {
	    set ARGS(project) [lindex $argv $i]
	}
    }
    # Do sanity checking on the args here
    if {[info exists ARGS(project)]} {
	# A project can be specified as:
	# 1) exact location of project.ui file
	# 2) exact location of project file without .ui
	# 3) location of project file relative to $P(project_dir) with .ui
	# 4) location of project file relative to $P(project_dir) w/o  .ui
	set found ""
	foreach location [list $ARGS(project) \
		[file join $P(project_dir) $ARGS(project)]] {
	    if {[file exists $location]} {
		set found $location
		break
	    } elseif {[file exist $location$P(file_suffix)]} {
		set found $location$P(file_suffix)
		break
	    }
	}
	if {$found != ""} {
	    set ARGS(project) $found
	    set ::gui::LANG(INIT) "project"
	} else {
	    puts stderr "Could not find project file \"$ARGS(project)\""
	    usage stderr; # this will not return
	}
    }
}

# queryLanguage --
#
#	Language to target output for
#
proc queryLanguage {} {
    variable ::gui::LANGS
    variable ::gui::LANG

    # set defaults
    if {$LANG(CUR) eq ""} {
	error "How did this happen?"
    }
    set w .__ask
    destroy $w
    toplevel $w
    wm withdraw $w
    wm protocol $w WM_DELETE_WINDOW [list destroy $w]
    wm title $w "Specify Target Language"
    if {[winfo ismapped $::W(ROOT)]} {
	wm transient $w $::W(ROOT)
	if {$::AQUA} {
	    ::tk::unsupported::MacWindowStyle style $w moveableModal none
	}
    } else {
	if {[winfo exists .__startup] && [tk windowingsystem] eq "x11"} {
	    # Make the splash screen go away because it will otherwise
	    # obscure this dialog
	    ::main::progress -1
	}
	if {$::AQUA} {
	    ::tk::unsupported::MacWindowStyle style $w document none
	}
    }
    catch {wm attributes $w -topmost 1}
    set wf $w

    set f [ttk::labelframe $wf.title -text "Target Language:"]

    ttk::label $f.msg -anchor w -justify left -text \
	"Specify the target language for code generation.\
	\nThe version number is the target Tk version for that language."
    grid $f.msg -row 0 -columnspan 3 -padx 4 -pady 2 -sticky w

    set i 1
    foreach lang [lsort [array names LANGS]] {
	set desc [lindex $LANGS($lang) 0]
	set vers [lindex $LANGS($lang) 1]
	ttk::radiobutton $f.$lang -text $desc \
	    -variable ::gui::LANG(CUR) -value $lang
	if {$::AQUA} {
	    set ::gui::LANG($lang,sel) [lindex $vers 0]
	    set m [ttk::menubutton $f.c$lang -menu $f.c$lang.menu -width 4 \
		      -textvariable ::gui::LANG($lang,sel)]
	    menu $m.menu -tearoff 0
	    foreach item $vers {
		$m.menu add radiobutton -label $item \
		    -variable ::gui::LANG($lang,sel) -value $item
	    }
	    if {$lang eq $LANG(CUR)} {
		set ::gui::LANG($lang,sel) $LANG(VER)
	    }
	} else {
	    spinbox $f.c$lang -values $vers -state readonly -wrap 1 -width 4 \
		-readonlybackground white -bd 1
	    if {$lang eq $LANG(CUR)} {
		$f.c$lang set $LANG(VER)
	    }
	}
	grid $f.$lang  -row $i -column 0 -sticky w -padx {10 0}
	grid $f.c$lang -row $i -column 1 -sticky w
	incr i
    }
    grid columnconfigure $f 2 -weight 1
    grid rowconfigure    $f $i -weight 1

    grid $f -sticky news -padx [pad labelframe]

    grid rowconfigure    $wf 0 -weight 1
    grid columnconfigure $wf 0 -weight 1

    # FIX: Needs spacing on OS X
    if {$::AQUA} {
	set ok [ttk::button $wf.ok -text "OK" -default active \
		    -command "set ::gui::LANG(VER) \$::gui::LANG(\$::gui::LANG(CUR),sel); [list destroy $w]"]
    } else {
	set ok [ttk::button $wf.ok -text "OK" -width 8 -default active \
		    -command "set ::gui::LANG(VER) \[$f.c\$::gui::LANG(CUR) get\]; [list destroy $w]"]
    }
    grid $ok -sticky e -padx [pad corner] -pady [pad y]
    bind $w <Return> [list $ok invoke]

    ::gui::PlaceWindow $w center
    wm deiconify $w
    tkwait visibility $w
    focus -force $ok
    tkwait window $w
    # make sure window really disappears visually
    update
    return [list $LANG(CUR) $LANG(VER)]
}

# targetVersion --
#
#	Version of Tk to target for
#
proc targetVersion {{ver ""}} {
    if {[llength [info level 0]] > 1} {
	set ::gui::LANG(VER) $ver
	# refresh widget palette
	palette::refresh lang
    }
    return $::gui::LANG(VER)
}

# targetLanguage --
#
#	Language to target output for
#
proc targetLanguage {{lang ""} {ver ""} {interp ""}} {
    variable ::gui::LANG
    # lang and/or interp given
    set newlang [expr {[llength [info level 0]] > 1}]
    if {!$newlang && $LANG(INIT) ne "init"} {
	# language never specified and not being set now - query for it now
	if {$LANG(INIT) eq ""} {
	    set lang [queryLanguage]
	} else {
	    set lang $LANG(CUR)
	    set ver  $LANG(VER)
	}
	set newlang 1
    }
    if {$newlang} {
	if {[llength $lang] > 1} {
	    set ver  [lindex $lang 1]
	    set lang [lindex $lang 0]
	} elseif {$lang eq "tcl84"} {
	    # handle old case
	    set ver  8.4
	    set lang tcl
	} elseif {$ver eq ""} {
	    # pick default version
	    set ver [lindex $::gui::LANGS($lang) 1 0]
	}
	if {[catch {::${lang}::init $ver $interp} msg]} {
	    return -code error \
		"Cannot initialize target language \"$lang\":\n$msg"
	}
	set LANG(CUR)  $lang
	set LANG(NAME) [lindex $::gui::LANGS($lang) 0]
	set LANG(VER)  $ver
	set LANG(INIT) "init"
	# Notify that we are using a different target language, which
	# will have a different startup file.
	if {[info exists ::Current(project)]} {
	    set proj [file join $::P(project_dir) $::Current(project)]
	    set file [::api::normalize $proj$::P(include_suffix)]
	    ::api::Notify startup $file
	}
	::api::Notify language [list $LANG(CUR) $LANG(VER)]
	# This will request the interpreter setting from the controlling app
	::api::Notify interpreter
	# destroy the properties dialog as some attributes will change.
	::config::reset
	# refresh widget palette
	palette::refresh lang
    }
    return $LANG(CUR)
}

# ::main::progress --
#
#	Show a dialog for the user to be updated of startup progress
#
proc ::main::progress {length {msg {}}} {
    set w .__startup
    if {$length < 0} {
	destroy $w
	return
    } elseif {![winfo exists $w]} {
	toplevel $w
	wm withdraw $w
	wm overrideredirect $w 1
	wm resizable $w 0 0

	set img splash.gif
	set width  [image width $img]
	set height [image height $img]
	set c [canvas $w.can -width $width -height $height \
		-highlightthickness 0 -bd 0]
	$c create image 0 0 -anchor nw -image $img -tags img
	$c create text 200 297 -anchor e -tags text -text $msg
	if {[tk windowingsystem] ne "x11"} {
	    ttk::progressbar $c.bar -variable ::gui::PROGRESS -length 190
	} else {
	    ProgressBar $c.bar -variable ::gui::PROGRESS \
		-width 190 -height 15 -borderwidth 1
	}
	$c create window 207 297 -anchor w -tags window -window $c.bar
	pack $c -fill both -expand 1

	::gui::PlaceWindow $w center
	catch {wm attributes $w -topmost 1}
	wm deiconify $w
    }
    set ::gui::PROGRESS $length
    $w.can itemconfigure text -text $msg
    update idle
}

# ::main::dofirst --
#
#	These are the first things to be executed in this file
#
proc ::main::do_first {argc argv} {
    foreach {file comment} {
	port.tcl	"OS portability routines"
	globals.tcl	"global variable initialization"
	preferences.tcl	"preferences handling"
	script_api.tcl	"public script API"
    } {
	Source $file
    }
    ::port::loadsplash

    # This fills the global P (prefs) array with defaults
    ::prefs::init

    # Handle command line arguments
    handle_args $argc $argv
}

# ::main::create_visual --
#
#	Some visual settings, such as icon, background, etc
#
proc ::main::create_visual {{w .}} {
    wm protocol $w WM_DELETE_WINDOW mainmenu_quit
    wm geometry $w {}
    wm minsize $w 50 50
    tk appname $::gui::APPNAME
    ::port::loadimages
    ::port::seticon $w

    if {$::tcl_platform(platform) eq "unix"} {
	wm group $w $w
	wm command $w [concat [list [info nameofexecutable] $::argv0] $::argv]
    }
}

# ::main::load_sources --
#
#	Read source files
#
proc ::main::load_sources {} {
    foreach {file comment} {
	about.tcl	"About box code"
	arrow.tcl	"manage the row and col indicators 'arrows'"
	bindings.tcl	"global bindings and binding routines"
	btnbind.tcl	"specific binding behavior"
	compile.tcl	"code generation routines"
	compile_tcl.tcl	"tcl code gen routines"
	compile_tkinter.tcl "Python/Tkinter code gen routines"
	compile_perl.tcl "perl code gen routines"
	compile_perltkx.tcl "perl/tkx code gen routines"
	compile_ruby.tcl "ruby code gen routines"
	ctext.tcl	"highlighting text widget"
	droptree.tcl	"droptree extended bwidgets widget for properties"
	edit_api.tcl	"A default external editor."
	filters.tcl	"data filters for option values"
	grid.tcl	"The grid manipulation stuff"
	help.tcl	"preliminary help stuff"
	helpballoon.tcl	"ballon help management"
	highlight.tcl	"handle highlighting"
	menucmds.tcl	"The code that the menus call upon invocation"
	menued.tcl	"menu editor code"
	menus.tcl	"definition of menus and menu interaction routines"
	outline.tcl	"manage wxjed menu.tcl"
	properties.tcl	"Properties (widget configuration) dialog"
	project.tcl	"Project management routines"
	resize.tcl	"row and column resize behavior"
	save.tcl	"save/load project from disk"
	scroll.tcl	"auto scrollbar attachment code"
	subs.tcl	"misc stuff that will end up elsewhere"
	toolbar.tcl	"toobar management routines"
	tree.tcl	"tree struct from tcllib - here for convenience"
	uitris.tcl	"you do not see this"
	undo.tcl	"undo routines - in development"
	utils.tcl	"utility procedures (dump, lremove, ...)"
	wbuilder.tcl    "widget creation / configuration"
	widgets.tcl	"Widget palette / configuration routines"

	pref_appearance_ui.tcl	"Appearance prefs tab"
	pref_editor_ui.tcl	"Editor prefs tab"
	pref_general_ui.tcl	"General prefs tab"

	edit_ui.tcl	"'edit code' widget"
	rowcol_ui.tcl	"Dialog for row & column configuration"
	main_ui.tcl	"main ui"
    } {
	Source $file
    }
}

# ::main::init --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::main::init {root argc argv} {
    global P Current
    variable ARGS

    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]
    set ::W(ROOT) $root

    wm withdraw $root

    #
    # This asks the target language, depending on prefs, and must be called
    # before the progress dialog is created
    #
    do_first $argc $argv

    # set a minimum splash view time of 2 secs
    set ::NOSPLASH 0
    after 2000 [list set ::NOSPLASH 1]
    progress 0 "Initializing $::gui::APPNAME ..."
    update

    #
    # load all constituent source files
    #
    progress 10 "Loading ..."
    load_sources

    if {[info exists ARGS(debug)] && $ARGS(debug)} {
	# Source in tkcon as our command console.
	# Do this before menu::init to make sure "tkcon" cmd exists.
	progress 15 "Loading debugging console ..."
	namespace eval ::tkcon {}
	# we want to have only the main interpreter
	set ::tkcon::OPT(exec) ""
	# we don't want tkcon to override gets or exit
	set ::tkcon::OPT(gets) ""
	set ::tkcon::OPT(overrideexit) 0
	# use the specified window as root
	set ::tkcon::PRIV(root) .tkcon
	set ::tkcon::PRIV(protocol) "tkcon hide"
	Source tkcon.tcl

	# use the comm package to ease debugging
	catch {package require comm}
    }

    if {[info exists ARGS(tetris)]} {
	set uiroot $root
	::UItris::Init $uiroot
	wm protocol $uiroot WM_DELETE_WINDOW [list exit]
	progress -1
	return
    }

    #
    # create visual
    #
    create_visual

    progress 25 "Creating Interface ..."

    #
    # create the top-level interface
    #
    ui $root

    # These were created in ui and will be used later in the init.
    set ::W(TBAR)   $base.toolbar
    set ::W(PREFS)  $base.prefs
    set ::W(CONFIG) $base.widget
    set ::W(LOG)    $base.logwin

    set ::W(MENU) [::menu::init $root]

    set ::W(USERMENU) $base.__usermenu

    ::tbar::create $::W(TBAR)

    #
    # Perform widget initialization.
    # This will load from a cache if we've run before.
    #
    progress 35 "Initializing Widgets ..."
    ::widget::init

    #
    # Perform initializations specific to the current target language
    # The self-reference here makes sure that there is a default language.
    #
    progress 50 "Initializing Target Language ..."
    if {[info exists ARGS(lang)]} {
	targetLanguage $ARGS(lang)
    }

    #
    # Make the preference dialog.
    #
    progress 65 "Setting Up Preferences ..."
    ::prefs::dialog $::W(PREFS)

    # Initialize what help should be displayed
    #
    ::help::status   $P(show-statushelp)
    ::help::tooltips $P(show-tooltips)

    #
    # Build the workspace
    #
    progress 75 "Creating Workspace ..."

    # all user widgets are children of this one
    # create it and place it in the canvas
    set ::W(FRAME) [set parent $::W(CANVAS).f]
    frame $parent -bg $P(frame_bg) ; # NOTILE
    $::W(CANVAS) create window 0 0 -anchor nw -window $parent

    # this is the basic initialization that is also good at startup
    clear_all

    # setup the generic and widget option forms
    #
    ::config::dialog $::W(CONFIG)

    # initialize the button binding dispatcher
    #
    ::bind::setup palette palette {[winfo parent %W] %X %Y}
    ::bind::setup widget  widget  {[::widget::root %W] %X %Y}
    ::bind::setup resize  resize

    progress 85 "Building Widget Tree ..."

    # build the widget palette and sample widgets
    #
    ::palette::build $::W(PALETTE)

    # associate data filters with widget items
    #
    install_filters

    # Initialize the bindings
    #
    ::bind::init $root $::W(CANVAS) $::W(FRAME)

    # set default geometry for the future...
    #
    ::prefs::set_default_geometry $root

    progress 95 "Saving Options ..."

    ::prefs::save

    # Signal to the API that we are ready for in/out
    ::api::_Ready

    # Act on whatever args were passed in.

    # see if project was specified on the command line
    if {[info exists ARGS(project)]} {
	progress 99 "Loading project ..."
	load_project $ARGS(project)
    }
    progress 100 "Finished"

    busy_off

    wm deiconify $root
    raise $root

    if {!$::NOSPLASH} {
	vwait ::NOSPLASH
    }
    progress -1
}


#
# ::main::init does all the initialization and gui creation
#
if {[catch {::main::init . $::argc $::argv} errMsg]} {
    set msg "Initialization error:\n$errMsg"

    if {[catch {bgerror $msg ; exit 2}]} {
	catch {tk_messageBox -icon error -type ok -message $msg}
    }

    exit 1
}
