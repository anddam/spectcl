# preferences.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# set some initial preferences
#

namespace eval ::prefs {
    variable C_P      ; # cached P prefs data
    variable W        ; # used to store prefs widget info
}

proc ::prefs::init {{restore 1}} {
    global P
    foreach {key default comment} {
	show-grid	1	"whether to show the grid lines"
	grid_size	4	"size of grid lines (between widgets)"
	grid_color	gray	"grid color"
	grid_spacing	40	"size of the empty rows/cols lines"
	grid_highlight	blue	"color of grid line when highlighted"
	arrow_highlight	red	"color to highlight the arrow on selection"
	generic_over_color green "color to use to indicate the cursor \
		is over something"
	maxrows		6	"# of rows in the table * 2"
	maxcols		6	"# of cols in the table * 2"
	gravity		5	"how many pixels of mouse motion \"counts\""
	scroll_delay	75	"ms to wait for scrolling canvas/w widget"
	project		untitled "name of untitled projects"
	frame_bg	#e9e9e9	"color of frame background"
	insert_on_gridline 1	"flag to allow insertion if a widget\
		dropped on gridline"
	show-statushelp	1	"whether to display field specific help"
	show-tooltips	1	"whether to display tooltips"
	file_suffix	".ui"	"user interface file suffix"
	target_suffix	"_ui.tcl"	"generated code file suffix"
	include_suffix	".tcl"	"source'd code file suffix"
	resize_handles	2	"size of the resize handles (control points)"
	highlight_border_width 3	"size of the widget highlight border"
	sticky-palette	1	"Whether a button on palette stays selected\
		after clicking"
	confirm-delete-item	0	"confirm deletion of items"
	confirm-save-layout	1	"confirm saving of layouts"
	confirm-autosave-on-quit 0	"automatically save on quitting."
	confirm-quit-without-save 1	"confirm quit with a dirty layout"
	confirm-auto-extend	1	"confirm auto-extend on canvas"
	auto-extend-canvas	0	"automatically extend the canvas\
		when clicking outside the defined canvas area"
	use-external-editor	0	"flag to use an external editor"
	external-editor-command {}	"string to use to invoke editor"
	project_dir		[pwd]	""
	MRU		""	"most recently used files"
	rootGeometry	""	"root geometry - empty by default"
    } {
	if {$restore || ![info exists P($key)]} {
	    set P($key) [subst $default]
	}
    }

    set P(file_untitled) 1

    if {$restore} {
	# Load the "rc" file, if any
	::prefs::load_rc_file
    }

    trace variable ::P w ::prefs::tracevar
}

# tracevar --
#
#    Called when ::P is modified.  Elements that require updates to
#    something onscreen should trigger that here.
#
proc ::prefs::tracevar {name elem op} {
    if {[namespace tail $name] ne "P" || $op ne "w"} { return }
    switch -exact $elem {
	"frame_bg" {
	    # Update the main frame's bg
	    if {[info exists ::W(FRAME)] && [winfo exists $::W(FRAME)]} {
		$::W(FRAME) configure -bg $::P($elem)
	    }
	}
    }
}

# load_rc_file --
#
#    Read in the "rc" file, if any, during startup
#
proc ::prefs::load_rc_file {} {
    set rc [::port::rc_file]
    if {[file readable $rc]} {
	interp create -safe rcloader
	interp expose rcloader source
	rcloader eval [list source $rc]

	# only reload values in P that exist for us
	array set RC_P [rcloader eval [list array get DATA]]
	foreach key [array names ::P] {
	    if {[info exists RC_P($key)]} { set ::P($key) $RC_P($key) }
	}

	interp delete rcloader
    }

    set ::P(file_untitled) 1
}

# set_default_geometry --
#
# set default geometry for the future...
#
proc ::prefs::set_default_geometry {w} {
    global P
    update idle
    set width  [winfo reqwidth $w]
    set height [winfo reqheight $w]
    # Arbitrary minsize is 20% smaller than the requested size
    wm minsize $w [expr {int($width*0.8)}] [expr {int($height*0.8)}]
    if {![info exists P(rootGeometry)]} {
	# Arbitrarily chosen default size is 20% larger than default
	#set P(rootGeometry) 600x400
	set P(rootGeometry) [expr {int($width*1.2)}]x[expr {int($height*1.2)}]
    }
    wm geometry $w $P(rootGeometry)
}

# dialog --
#
#	Create the initial Preferences dialog
#
proc ::prefs::dialog {root} {
    global P
    variable W

    # Loads in the preference panels needed by the current platform
    #
    set cmd ::prefs::$::tcl_platform(platform)_ui_output
    if {[info command $cmd] != ""} {
	rename $cmd ::prefs::ui_output
    }

    # Panels in the Preferences dialog
    #set panels "general appearance editor output"
    set panels "general appearance output"

    if {$::tcl_platform(platform) eq "windows"} {
	set panels [lremove $panels output]
    }
    if {[::api::IsInteractive]} {
	# It is automatically assumed that interactive controlling apps
	# have their own editors, so remove the editor tab.
	# Also, no external editor on the Mac
	set panels [lremove $panels editor]
    }

    set w [set W(root) $root]
    toplevel $w
    wm protocol $w WM_DELETE_WINDOW [list wm withdraw $w]
    wm withdraw $w
    wm title $w "$::gui::APPNAME Preferences"
    wm transient $w $::W(ROOT)

    # [OK] [Cancel] [Apply]
    set btns [ttk::frame $w.b]
    ttk::button $btns.ok  -width 8 -text "OK" -default active \
	-command [list ::prefs::dismiss $w 1]
    ttk::button $btns.app -width 8 -text "Apply" \
	-command {::prefs::apply}
    ttk::button $btns.can -width 8 -text "Cancel" \
	-command [list ::prefs::dismiss $w 0]

    grid x $btns.ok $btns.can $btns.app -padx 4 -pady {6 4}
    grid configure $btns.app -padx [list 4 [pad corner]]
    grid columnconfigure $btns 0 -weight 1

    bind $w <Return> [list $btns.ok invoke]
    bind $w <Escape> [list $btns.can invoke]

    if {$::TILE} {
	set nb [ttk::notebook $w.f -padding [pad notebook]]
    } else {
	# Use a BWidget notebook
	set nb [NoteBook $w.f -font defaultFont]
    }
    set W(nb) $nb

    grid $w.f -row 0 -column 0 -sticky nsew
    if {!$::TILE} {
	grid configure $w.f -padx 5 -pady 5
    }
    grid $w.b -row 1 -column 0 -sticky ew
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    foreach pref $panels {
	if {$::TILE} {
	    set f [ttk::frame $nb.$pref -padding [pad labelframe]]
	    $nb add $f -sticky news -text [string totitle $pref]
	    set W($pref) $f
	} else {
	    set W($pref) [$nb insert end $pref -text [string totitle $pref]]
	}
	# pass the root panel name and the name of the cached prefs var
	::prefs::ui_${pref} $W($pref) ::prefs::C_P
    }
    if {$::TILE} {
	$nb select $nb.[lindex $panels 0]
    } else {
	$nb compute_size
	$nb raise [lindex $panels 0]
    }

    ::gui::PlaceWindow $w center
}


proc ::prefs::popup {} {
    global P
    variable C_P      ; # cached P prefs data
    variable W

    # cache current data
    array set C_P      [array get P]

    # Set up the "output" box
    if {[string equal $::tcl_platform(platform) "unix"]} {
	set text $W(output,text)
	if {[winfo exists $text]} {
	    set_unix_stub_default $text ::prefs::C_P
	}
    }

    foreach color {
	grid_color grid_highlight generic_over_color frame_bg
    } {
	select_color $color ::prefs::C_P $P($color)
    }

    wm deiconify $W(root)
    raise $W(root)
}

proc ::prefs::apply {} {
    global P
    variable C_P      ; # cached P prefs data
    variable W

    if {$C_P(show-statushelp) != $P(show-statushelp)} {
	::help::status $C_P(show-statushelp)
    }
    if {$C_P(show-tooltips) != $P(show-tooltips)} {
	::help::tooltips $C_P(show-tooltips)
    }

    array set P [array get C_P]
    set P(maxcols) $P(maxrows)

    # force grid update in case show-grid or grid_size changed
    grid_update_size

    if {[string equal $::tcl_platform(platform) "unix"]} {
	set text $W(output,text)
	if {[winfo exists $text]} {
	    set P(unix-stub) [string trim [$text get 1.0 end-1c]]
	}
    }
}

proc ::prefs::dismiss {w save} {
    if {$save} {
	::prefs::apply
	::prefs::save
    }
    wm withdraw $w
}

# ::prefs::save
#
proc ::prefs::save {} {
    global P

    set filename [::port::rc_file]

    if {[catch {open $filename w} fid]} {
	return -code error "Unable to write preferences file:\n$fid"
    }

    # move the stuff in P that we want to save into DATA
    foreach key [array names P] {
	switch -glob $key {
	    project_dir		-
	    file_suffix		-
	    target_suffix	-
	    include_suffix	-
	    title		{
		# do not save these keys
	    }
	    default		{ set DATA($key) $P($key) }
	}
    }
    set prefs    "##\n## AUTO-GENERATED FILE -- DO NOT EDIT\n"
    append prefs "## GENERATED [::gui::timestamp] \n##\n"
    if {[array size DATA]} {
	append prefs [dump var DATA]\n
    }
    puts $fid [string trim $prefs]
    close $fid
}

proc ::prefs::macintosh_ui_output {root cacheVar args} {
    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]

    label $base.help -justify left -text \
"Choose a stub file for creating a Tcl application.
By default, choose the file \"stub\" from the $::gui::APPNAME
installation directory.

Choose a four letter creator code for the Tcl application."

    label $base.lab1 -text "Application stub file:"
    entry $base.stub -textvariable ${cacheVar}(mac-stub)
    button $base.browse -text "Browse ..." \
	-command "set ${cacheVar}(mac-stub) \[tk_getOpenFile -parent $root\]"

    label $base.lab2 -text "Creator code:"
    # creator code cannot be more than 4 chars
    entry $base.code -textvariable ${cacheVar}(mac-creator) -width 6 \
	    -validate key -validatecommand {expr {[string length %P] <= 4}}

    grid $base.help    -column 1 -row 0 -sticky nw
    grid $base.lab1    -column 1 -row 1 -sticky nw
    grid $base.stub    -column 1 -row 2 -sticky ew -columnspan 3
    grid $base.browse  -column 4 -row 2 -sticky w -padx 4
    grid $base.lab2    -column 1 -row 3 -sticky nw
    grid $base.code    -column 1 -row 4 -sticky nw

    grid columnconfig $root 2 -weight 1
    grid rowconfigure $root 7 -weight 1
}

proc ::prefs::unix_ui_output {root cacheVar args} {
    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]
    variable W

    ttk::label $base.help -justify left -text \
"The startup stub appears at the beginning of the file
generated by $::gui::APPNAME. It specifies the
program needed to run the file as a stand-alone application.

Use the Permission entry to set the permission mode of the
file. Leave it empty if you don't want to change the permission
mode. See chmod(1) for a list of possible permission modes."

    set W(output,text) [text $base.text -width 50 -height 4 -wrap none \
			    -xscrollcommand [list $base.sbx set] \
			    -yscrollcommand [list $base.sby set] \
			    -highlightthickness 1]
    scrollbar $base.sbx -command [list $base.text xview] -orient horizontal
    scrollbar $base.sby -command [list $base.text yview] -orient vertical

    ttk::button $base.default -text Default \
	    -command [list ::prefs::set_unix_stub_default $base.text $cacheVar]
    ttk::label $base.lab  -text "Startup stub:"
    ttk::label $base.lab1 -text "Permission:"
    ttk::entry $base.perm -textvariable ${cacheVar}(unix-perm) -width 6

    grid $base.help -column 1 -row 0 -sticky nw -columnspan 3
    grid $base.lab  -column 1 -row 1 -sticky nw
    grid $base.text -column 1 -row 2 -sticky news -columnspan 4
    grid $base.sbx  -column 1 -row 3 -sticky news -columnspan 4
    grid $base.sby  -column 5 -row 2 -sticky nws
    grid $base.default -column 4 -row 7 -columnspan 2 -padx 4 -pady 5 -sticky e

    grid $base.lab1 -column 1 -row 4 -sticky w -pady 5
    grid $base.perm -column 2 -row 4 -sticky w -pady 5

    grid columnconfig $root 2 -weight 1
    grid rowconfigure $root 8 -weight 1
}

proc ::prefs::set_unix_stub_default {w cacheVar} {
    set state [$w cget -state]
    $w config -state normal
    $w delete 1.0 end
    $w insert 1.0 [unix_stub default]
    $w config -state $state

    set ${cacheVar}(unix-perm) "a+x"
}

proc unix_stub {{default ""}} {
    global P
    if {$default != "default" && [info exists P(unix-stub)]} {
	return "[string trimright $P(unix-stub)]\n"
    }
    # take the filename of the specified interpreter
    # (assume it will be on the path)
    set exe [file tail [[targetLanguage]::interpreter]]
    set stub "#!/usr/bin/env $exe"
    if {![info exists P(unix-stub)]} {
	set P(unix-stub) $stub
    }
    if {![info exists P(unix-perm)]} {
	set P(unix-perm) "a+x"
    }
    return $stub
}
