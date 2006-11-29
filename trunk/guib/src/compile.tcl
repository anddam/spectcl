# compile.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# compile a ui file into tk code

# Each project file has the following format:
# 1: title-> # WIDGET FILE, created:  <date>

# 2: widget_data ...
#
# widget data consists of:
#   widget {<group> <command>} <name> {
#	<type> <name> <value>
#	...
#   }

namespace eval ::compile {}

proc ::compile::CmdSplit {cmd} {
    set inc {}
    set cmds {}
    foreach cmd [split [string trimleft $cmd] \n] {
	if {$inc ne ""} {
	    append inc \n$cmd
	} else {
	    append inc [string trimleft $cmd]
	}
	if {[info complete $inc] && ![regexp {[^\\]\\$} $inc]} {
	    #set inc [string trimright $inc]
	    if {[string trim $inc] ne "" && \
		    ![string match "#*" $inc]} {lappend cmds $inc}
	    set inc {}
	}
    }
    if {[string trim $inc] ne "" && \
	    ![string match "#*" [string trimleft $inc]]} {lappend cmds $inc}
    return $cmds
}

# ::compile::project --
#
#	Compiles the project (.ui) into an application (.tcl, .java, .. etc)
#
# Arguments:
#	None.
#
# Result:
#	None.
# SOURCE

proc ::compile::project {} {
    set project  $::Current(project)
    # we create a prefix that has no whitespace chars in it.
    # this prevents goofy problems in code generation
    regsub -all {\s} $project {_} prefix
    set fui      [::project::get ui]
    set ftarget  [::project::get target]
    set finclude [::project::get include]

    if {$fui eq ""} {
	tk_messageBox -title "Error compiling $project" \
		-type ok -icon error -message "Cannot compile untitled project"
	return 0
    }

    status_message "Generating $ftarget"
    if {[catch {::compile::compileTarget \
	    $prefix $fui $ftarget $finclude} autocmds]} {
	tk_messageBox -title "Error Generating Target File" \
		-type ok -icon error -message $autocmds
	return 0
    }
    status_message "Generating $finclude"
    if {[catch {::compile::compileInclude \
	    $prefix $autocmds $fui $ftarget $finclude} err]} {
	tk_messageBox -title "Error Generating Include File" \
		-type ok -icon error -message $err
	return 0
    }
    status_message "Generated [targetLanguage] code"

    # Notify that we compiled the code generated file, and also specify
    # that this is the startup file.
    ::api::Notify save    $ftarget
    ::api::Notify save    $finclude
    ::api::Notify startup $finclude

    return 1
}

# ::compile::compileTarget --
#
#	compile a ui into a tk program
#
# Arguments:
#
#  prefix	The procedure prefix (project name)
#  uiFile	the unix file containing the ui description
#  targetFile	The language-specific file to write
#  includeFile	Optional include file
#
proc ::compile::compileTarget {prefix uiFile targetFile includeFile} {
    if {[catch {::port::writable $targetFile; open $targetFile w} fd]} {
	return -code error "Cannot write to file \"$targetFile\": $fd"
    }

    # This will contain the end script
    set script ""

    # This will hold the set of commands that we need to provide hooks for
    set autocmds ""

    set lang [targetLanguage]
    set ver  [targetVersion] ; # FIX : XXX USE THIS

    # Allow for language specific code generation initialization
    append script [::compile::${lang}::init $ver]

    # Follow the logic in get_file_data
    set widgets [lsort -command frameLevelSort [::widget::widgets]]

    set menus [::widget::menus]
    if {[llength $menus]} {
	# Add the menu widget if we have menu items
	lappend widgets "MENU"
	# We will cache menu options for creation of any cascaded menus
	set menuOptions ""
    }

    # Preprocess data to allow language to process option info
    foreach w $widgets {
	set type [::widget::type $w]
	::compile::${lang}::require $type $w

	array set defOpts [::widget::get $type options -default]
	array set data [::widget::data $w]
	foreach key [lsort [array names data]] {
	    # skip configuration values that are defaulted!
	    if {[info exists defOpts($key)]} {
		# widget option
		# skip setting to default value
		if {$data($key) eq $defOpts($key)} { continue }
		# Allow each language to process the options
		::compile::${lang}::option $type $data(ID) $key $data($key)
	    } elseif {[string match "GM:*" $key]} {
		# geometry option
	    } else {
		# special keys: GROUP ID MASTER TYPE data level
	    }
	}
	if {$w ne "MENU"} {
	    if {$data(MASTER) eq ""} {
		set Masters($::W(FRAME)) 1
	    } else {
		set Masters($data(MASTER)) 1
	    }
	}
	unset data
	unset defOpts
    }

    # Script header
    append script [::compile::${lang}::targetHeader $targetFile $uiFile $prefix]

    # Add include file if one was specified
    #append script [::compile::${lang}::include $includeFile $prefix]

    # Create main proc
    append script [::compile::${lang}::uiProcBegin $prefix]

    # now create the widgets (and the tags)
    append script [::compile::${lang}::comment "Widget Initialization"]

    foreach w $widgets {
	if {[::gui::isContainer $w]} continue

	set type [::widget::type $w]

	array set defOpts [::widget::get $type options -default]
	array set data [::widget::data $w]

	set options [list]
	foreach key [lsort [array names data]] {
	    # skip configuration values that are defaulted!
	    if {[info exists defOpts($key)]} {
		# widget option
		# run the input conversion filters
		set value [filter input $key $data($key)]
		if {[string match "*command*" $key]} {
		    if {$value == ""} {
			lappend autocmds [list $data(ID) $key]
		    } elseif {[string match "< command* >" $value]} {
			lappend autocmds [list $data(ID) $key $value]
		    }
		} elseif {$data($key) eq $defOpts($key)} {
		    # skip setting to default value
		    continue
		}
		lappend options $key $value
	    }
	}
	append script [::compile::${lang}::widget $data(TYPE) $data(ID) \
			   [id_master $w $lang] $options]
	if {$w eq "MENU"} {
	    set menuOptions $options
	    # We don't allow users to create tearoff menus at this point
	    lappend menuOptions -tearoff 0
	}
	unset data
	unset defOpts
    }

    # do whatever post-widgets creation processing is necessary,
    # like outputting bindtags and such.
    append script [::compile::${lang}::postWidgets]

    # Add menus
    # Menu will have been create.  Populate it now.
    foreach w $menus {
	set type   [::widget::menutype $w]
	set master [::widget::parent $w]
	if {$master eq "MENU"} {
	    set master "menu"
	}

	array set defOpts [::widget::configure $type]
	array set data [::widget::data $w]

	set options [list]
	foreach key [lsort [array names data]] {
	    # skip configuration values that are defaulted!
	    if {[info exists defOpts($key)]} {
		# option
		# skip setting to default value, except for label
		# which some langs (perl) require in making items
		if {$key ne "-label" && $data($key) eq $defOpts($key)} {
		    continue
		}
		# run the input conversion filters
		set value [filter input $key $data($key)]
		if {[string match "*command*" $key]} {
		    # We could add menuitem autocmds, but we would have
		    # to configure them specially
		}
		lappend options $key $value
	    }
	}
	if {$type eq "Menu cascade"} {
	    append script [::compile::${lang}::widget "Menu menu" $w \
			       [id_master $w $lang] $menuOptions]
	    lappend options -menu $w
	}
	append script [::compile::${lang}::menu $master \
			   [lindex $type 1] $options]
	unset data
	unset defOpts
    }

    # now create the geometry management commands
    # this has to wait until all of the widgets are created to
    # avoid forward references
    append script [::compile::${lang}::comment "Geometry Management"]
    foreach w $widgets {
	if {[::gui::isContainer $w] || $w eq "MENU"} continue
	# FIX: Should widgets with master eq $::W(FRAME) do this?
	set master [id_master $w $lang]
	array set data [::widget::data $w]

	set options [list]
	foreach key [lsort [array names data]] {
	    if {[string match "GM:-*" $key]} {
		# geometry option
		set map [string range $key 3 end]
		if {$map eq "-row" || $map eq "-column"} { continue }
		# run the input conversion filters
		set value [filter input $key $data($key)]
		lappend options $map $value
	    }
	}
	append script [::compile::${lang}::geometry $data(ID) $master \
			   [filter input GM:-row $data(GM:-row)] \
			   [filter input GM:-column $data(GM:-column)] $options]
	unset data
    }

    # now for the resize behavior, this is only run for geometry masters
    #
    append script [::compile::${lang}::comment "Resize Behavior"]
    foreach w [lsort [array names Masters]] {
	array set data [::widget::data $w]
	set master [namespace inscope ::compile::${lang} \
			[list translate $data(ID)]]
	foreach dim {row column} {
	    set weights [get_resize $data(GM:resize_$dim) \
			     $data(GM:weight_$dim)]
	    if {[llength $weights]} {
		append script [::compile::${lang}::resizing \
				   $master $dim $weights \
				   $data(GM:min_$dim) $data(GM:pad_$dim)]
	    }
	}
    }

    if {[llength $menus]} {
	append script [::compile::${lang}::attachmenu menu]
    }

    # We have now reached the end of the <dialog>_ui procedure.
    append script [::compile::${lang}::uiProcEnd $prefix]

    append script [::compile::${lang}::targetFooter $prefix]

    # Ruby requires this, and the other files shouldn't care if we
    # did our unicode quoting right.
    fconfigure $fd -encoding utf-8

    puts -nonewline $fd $script
    close $fd
    ::port::ownFile $targetFile 1; # readonly

    foreach i [info vars ::compile::*] {
	unset $i
    }

    return $autocmds
}

proc translate {name} {
    if {$name == "" || [::gui::isContainer $name]} {
	return \$root
    } else {
	return \$base.$name
    }
}

# find the master's ID of this window, as the user may have changed its name.
#
proc ::compile::id_master {w lang} {
    if {[::gui::isContainer $w]} { return "" }

    set master [::widget::data $w master]
    if {$master != ""} {
	# the name of the master may have been changed!
	set master [::widget::data $master ID]
    }
    # Allow the language to translate it to native style code
    return [namespace inscope ::compile::${lang} [list translate $master]]
}

# figure out the resize behavior

proc get_resize {list1 {list2 ""}} {
    set index 0
    set result ""
    if {[llength $list2]==0} {
	foreach i $list1 {lappend list2 1}
    }
    foreach i $list1 {
	if {$i > 1} {
	    lappend result [lindex $list2 $index]
	} else {
	    lappend result 0
	}
	incr index
    }
    return $result
}

# build_test --
#
#	Implements the 'Command->Start Test' menu command.
#
# Arguments:
#	None.
#
# Result:
#	0 if the user has aborted the action. 1 otherwise

proc ::compile::build_test {} {
    if {![build]} {
	return 0
    }

    set code [::compile::test $::Current(project)]
    if {$code} { enable_kill_test } else { disable_kill_test }
    return $code
}

# build --
#
#	Implements the 'Command->Build' menu command.
#
# Arguments:
#	None.
#
# Result:
#	0 if the user has aborted the action. 1 otherwise

proc ::compile::build {} {
    global Current P

    check_project_file_exist
    set projectFile [::project::get ui]
    set targetFile  [::project::get target]

    set rebuild 0

    if {![file exists $targetFile]} {
	set rebuild 1
    }

    catch {
	if {[file mtime $targetFile] < [file mtime $projectFile]} {
	    set rebuild 1
	}
    }

    if {[dirty] || $P(file_untitled)} {
	set rebuild 1
	set askUser [expr {$P(file_untitled) || $P(confirm-save-layout)}]
	set message "\"$Current(project)\" has not been saved. \
		You must save it before building the application. Continue?"

	if {![save_if_dirty $askUser $message yesno] || [dirty]} {
	    return 0
	}
    }

    if {$rebuild} {
	::compile::project
    } else {
	status_message "No need to rebuild"
    }

    return 1
}

# ::compile::test --
#
#   Execute the application generated by the compile_project command.
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::test {project} {
    # we create a prefix that has no whitespace chars in it.
    # this prevents goofy problems in code generation
    regsub -all {\s} $project {_} prefix
    # do this before each test in case the attached controlling app
    # has changed the interpreter
    api::Notify interpreter
    return [::compile::[targetLanguage]::test $prefix]
}

# ::compile::runlog --
#
#   Keep a running log of results from test runs
#
# Arguments:
#   msg		message string to add to log
# Results:
#   Returns nothing
#
proc ::compile::runlog {msg} {
    if {![winfo exists $::W(LOG)]} {
	# Don't make it transient on Aqua because Aqua hides the transient
	# windows when you switch apps - and this shows the running log
	# for the test app running in another process
	set dlg [widget::dialog $::W(LOG) -title "Test Run Log" \
		     -transient [expr {!$::AQUA}] -parent $::W(ROOT) \
		     -separator 1 -synchronous 0 -padding 4]

	set frame [$dlg getframe]
	set sw [widget::scrolledwindow $frame.sw -scrollbar vertical]
	set text [ctext $sw.text -font defaultFixedFont -state disabled -bd 1 \
		     -background white -width 60 -height 10]
	$sw setwidget $text
	pack $sw -fill both -expand 1

	$dlg add button -text "Clear" -command [list ::compile::clearlog $text]
	set btn [$dlg add button -text "Dismiss" -default active \
		     -command [list $dlg withdraw]]
	bind $dlg <Return> [list $btn invoke]
	$dlg display
    } else {
	set text [$::W(LOG) getframe].sw.text
    }
    $text configure -state normal
    $text insert end $msg
    $text configure -state disabled

    wm deiconify $::W(LOG)
    raise $::W(LOG)
}

proc ::compile::clearlog {text} {
    $text configure -state normal
    $text delete 1.0 end
    $text configure -state disabled
}

# isTestRunning --
#
#	Tells you if a test is currently being run
#
# Arguments:
#	None.
#
# Result:
#	0 if no test is running, 1 otherwise.

proc ::compile::isTestRunning {} {
    return [::compile::[targetLanguage]::isTestRunning]
}

# read_test --
#
#   read_test catches output from running code and puts it in a log
#
# Arguments:
#   fid		file id
# Results:
#   Returns nothing
#
proc ::compile::read_test {fid} {
    if {[eof $fid] || [catch {read $fid} msg]} {
	kill_test
	::compile::runlog "Test run finished.\n"
    } elseif {[info exists msg]} {
	# Add to the log, avoid recursive updates
	set evt [fileevent $fid readable]
	fileevent $fid readable {}
	::compile::runlog $msg
	fileevent $fid readable $evt
    }
}

proc ::compile::kill_test {} {
    ::compile::[targetLanguage]::kill_test
    disable_kill_test
}

proc enable_kill_test {} {
    $::tbar::TOOLS(stop) config -state normal
}

proc disable_kill_test {} {
    $::tbar::TOOLS(stop) config -state disabled
}

# ::compile::compileInclude --
#
#	generate the callbacks file.
#	this file may have user-defined code and must first be parsed
#	before we can write it out again.
#
# Arguments:
#
#  prefix	The procedure prefix (project name)
#  uiFile	the unix file containing the ui description
#  targetFile	The language-specific file to write
#  includeFile	Optional include file
#
proc ::compile::compileInclude {
    prefix autocmds uiFile targetFile includeFile
} {
    set lang [targetLanguage]

    set script [uplevel 1 [lreplace [info level 0] 0 0 \
			       ::compile::${lang}::compileInclude]]

    if {[catch {::port::writable $includeFile; open $includeFile w} fd]} {
	return -code error "Cannot write to file \"$targetFile\": $fd"
    }

    # Note that the include file is written in the default system encoding

    puts -nonewline $fd $script
    close $fd
    ::port::ownFile $includeFile

    return $script
}

proc ::compile::fileHeader {file uifile} {
    # Spit out unified header info for a file
    return "# [file tail $file] --\n#\n#\
	UI generated by $::gui::APPNAME $::gui::BUILD\
	on [::gui::timestamp] from:\n#    $uifile\n"
}
