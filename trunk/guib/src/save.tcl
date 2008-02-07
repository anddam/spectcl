# save.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# manage saving and loading project files

namespace eval ::gui {}

proc ::gui::container {} {
    return [winfo name $::W(FRAME)]
}

proc ::gui::isContainer {w} {
    return [expr {$w eq $::W(FRAME) || $w eq [container]}]
}


proc get_children {w} {
    if {$w != "" && [::widget::exists $w]} {
	set result {}
	foreach child [grid slaves $w] {
	    if {[::widget::exists $child]} {
		lappend result $child
		set result [concat $result [get_children $child]]
	    }
	}
	return $result
    }
}

# ::gui::get_file_data --
#
#	Returns the content of the project as it would appear inside
#	a project file. This procedure is normally from these places:
#	- save_project: to format the content of a project file
#	- to_clipboard: puts info of the selected widgets in the clipboard
#
# Arguments:
#	start_widget: The name of the starting widget
#
# Result:
#	The language independent GUI file

proc ::gui::get_file_data {} {
    set result ""

    append result "$::gui::FILEID $::gui::BUILD\n"
    append result "# Created: [::gui::timestamp]\
	    by $::gui::APPNAME $::gui::BUILD\n"

    append result "language [list [targetLanguage] [targetVersion]]\n"

    append result [get_widget_data]
    append result [get_menu_data]

    return $result
}

proc ::gui::get_menu_data {} {
    set result ""

    set menus [::widget::menus]
    if {![llength $menus]} { return }

    foreach w [concat [list MENU] $menus] {
	set name $w
	if {$w eq "MENU"} {
	    set type "Menu menu"
	} else {
	    set type [::widget::menutype $w]
	}

	array set defOpts [::widget::configure $type]
	array set data [::widget::data $w]
	append result "menu [list $type] [list $name] \{\n"
	foreach key [lsort [array names data]] {
	    set map $key
	    if {[info exists defOpts($key)]} {
		# menu item option
		if {$data($key) eq $defOpts($key)} {
		    # skip setting to default value
		    continue
		}
		set what "configure"
	    } else {
		# special keys: GROUP ID MASTER TYPE data level
		if {$key eq "data" || $key eq "GROUP"
		    || $key eq "ID" || $key eq "TYPE"} {
		    continue
		}
		set what "data"
	    }

	    # run the input conversion filters
	    set value [filter input $key $data($key)]

	    append result "\t[list $what $map $value]\n"
	}
	append result "\}\n"
	unset data
    }
    return $result
}

proc ::gui::get_widget_data {{start_widget ""}} {
    set result ""
    # geometry options that we don't save defaults for
    #-columnspan 1	-rowspan    1	-sticky     ""
    array set geomDefs {
	-ipadx      0	-ipady      0	-padx       0	-pady       0
    }

    set_frame_level $::W(FRAME)
    if {$start_widget eq ""} {
	set widgets [lsort -command frameLevelSort [::widget::widgets]]
    } else {
	set widgets [concat [list $start_widget] [get_children $start_widget]]
    }
    foreach w $widgets {
	set name [winfo name $w]
	set type [::widget::type $w]

	array set defOpts [::widget::configure $type]
	array set data [::widget::data $w]
	append result "widget [list $type] [list $name] \{\n"
	foreach key [lsort [array names data]] {
	    # skip configuration values that are defaulted!
	    set map $key
	    if {[info exists defOpts($key)]} {
		# widget option
		if {$data($key) eq $defOpts($key)} {
		    # skip setting to default value
		    continue
		}
		set what "configure"
	    } elseif {[string match "GM:*" $key]} {
		# geometry option
		set map [string range $key 3 end]
		if {[info exists geomDefs($map)] \
			 && $data($key) eq $geomDefs($map)} {
		    continue
		}
		set what "geometry"
	    } else {
		# special keys: GROUP ID MASTER TYPE data level
		if {$key eq "data"} { continue }
		if {$key eq "MASTER"} {
		    # process outbound master info
		    if {$data($key) eq $::W(FRAME) || $data($key) eq ""} {
			set data($key) ""
		    } else {
			set data($key) [winfo name $data($key)]
		    }
		}
		set what "data"
	    }

	    # run the input conversion filters
	    set value [filter input $key $data($key)]

	    append result "\t[list $what $map $value]\n"
	}
	append result "\}\n"
	unset data
	unset defOpts
    }
    return $result
}

proc load_build_project {master clean widgets} {
    set do {}
    # sets the levels for widgets that don't have them set so that
    # we can do the sort below.  This happens when loading a project
    # into a sub-frame.
    set_frame_level $::W(FRAME) 0

    # create and manage the widgets
    # Sort first, so frames get made first
    foreach w $widgets {
        # The row & column padding & weight in frames if it doesn't exist
	if {[::widget::isFrame $w]} {
	    foreach dim {row column} {
		# This works because geometry/data returns "" for
		# non-existent values
		set pad [::widget::geometry $w pad_$dim]
		set min [::widget::geometry $w min_$dim]
		if {[llength $pad] != [llength $min]} {
		    set pad ""
		    foreach val $min {
			lappend pad 0
		    }
		    ::widget::geometry $w pad_$dim $pad
		}
		set weight [::widget::geometry $w weight_$dim]
		set resize [::widget::geometry $w resize_$dim]
		if {[llength $weight] != [llength $resize]} {
		    set weight ""
		    foreach val $resize {
			lappend weight [expr {$val > 1}]
		    }
		    ::widget::geometry $w weight_$dim $weight
		}
	    }
	}

	if {[::gui::isContainer $w]} {
	    if {$clean} {
		make_decorations $master
	    }
	    continue
	}

	# Input filters for row / column data
	foreach key {-row -column} {
	    set val [::widget::geometry $w $key]
	    ::widget::geometry $w $key [expr {$val * 2}]
	}
	foreach key {-rowspan -columnspan} {
	    set val [::widget::geometry $w $key]
	    ::widget::geometry $w $key [expr {($val * 2) - 1}]
	}

	# Get geometry info and make any necessary adjustments
	array set geom [::widget::geometry $w]
	# Validate master
	set geom(-in)  [::widget::data $w MASTER]
	if {$geom(-in) eq ""} {
	    set geom(-in) $master
	}

	# create gm command for $w
	lappend do [linsert [array get geom -*] 0 grid $w]
	#lappend do [list outline::outline $w]
	# set the widget bindtags so that we essentially control it.
	# widgets with a resize_row parameter are containing frames
	set isframe [::widget::isFrame $w]
	::palette::setbind $w $isframe
	if {$isframe} {
	    make_decorations $w
	}
	# Now reset all the other geom attributes to get synchronization
	array unset geom -*
	eval [list ::widget::geometry $w] [array get geom]
    }
    foreach i $do {
	if {[catch $i err]} {
	    append oops "ERROR '$i':\n\t$err\n"
	}
    }
    if {[info exists oops]} {
	set msg "The following errors occured loading widgets:\n$oops"
	tk_messageBox -title "Open Error" -type ok -icon error -message $msg
    }
}

proc load_project_string_menu {w master cmd clean} {
    foreach {op tag value} $cmd break
    if {$op eq "data"} {
	# GROUP ID MASTER TYPE level
	::widget::data $w $tag $value
    } elseif {$op eq "configure"} {
	::widget::data $w $tag $value
    } else {
	return -code error "unknown widget operation '$op'"
    }
}

proc load_project_string_widget {w master cmd clean} {
    foreach {op tag value} $cmd break
    if {$op eq "data"} {
	# GROUP ID MASTER TYPE level
	if {!$clean} {
	    # !clean means we are being loaded into an existing workspace
	    # This can happen when pasting widgets, or loading into subframes
	    if {$tag eq "level"} {
		# level should be a number, but if it isn't, default to 1
		if {[catch {incr value}]} {
		    set value 1
		}
	    } elseif {$tag eq "ID"} {
		set value [winfo name $w]
	    } elseif {$tag eq "MASTER"} {
		if {$w eq $master} {
		    # set this widget's master to the -in value of the known
		    # master
		    array set ginfo [grid info $master]
		    set value $ginfo(-in)
		} elseif {$value eq ""} {
		    # If empty, use $master as that will represent the
		    # frame we are loading into
		    set value $master
		} else {
		    # If !empty, it's master will be a sibling created
		    # in $::W(FRAME)
		    set value $::W(FRAME).$value
		}
	    }
	} else {
	    # On a clean container, only MASTER needs checking
	    if {$tag eq "MASTER"} {
		if {$value eq ""} {
		    set value $::W(FRAME)
		} else {
		    # If !empty, it's master will be a sibling created
		    # in $::W(FRAME)
		    set value $::W(FRAME).$value
		}
	    }
	}
	::widget::data $w $tag $value
    } elseif {$op eq "geometry"} {
	::widget::geometry $w $tag $value
    } elseif {$op eq "configure"} {
	# We need to do filtering on input widget options
	# This handles things like -image creation, but use the original
	# input value.
	set newval [filter input $tag $value]
	::widget::data $w $tag $value
    } else {
	return -code error "unknown widget operation '$op'"
    }
}

# This is where we can pass a string to be loaded.
# We are !clean when loading data from the clipboard.
proc load_project_string {lines master clean} {
    # We will cache the widgets we create.  If this isn't a clean load,
    # then we will only rebuild these created widgets.
    set widgets {}
    # Now onto loading in the new data
    set cmds [::compile::CmdSplit $lines]
    set first_widget ""
    array set renamed_widgets {}
    foreach cmd $cmds {
	# Can be one of:
	#	language lang ?ver?
	#	widget|menu type name subs
	foreach {wcmd type name subs} $cmd { break }
	if {$wcmd eq "widget"} {
	    set neednewname 0
	    if {!$clean} {
		# This will handle reworking the MASTER for subwidgets
		foreach {old new} [array get renamed_widgets] {
		    regsub "data MASTER $old\n" $subs \
			"data MASTER $new\n" subs
		}
		# FIX: we could ignore name collisions, assume all could
		# be, and pass "" to ::widget::new
		if {[::widget::exists $::W(FRAME).$name] \
			&& ![::gui::isContainer $name]} {
		    set neednewname 1
		}
	    }
	    if {[::gui::isContainer $name]} {
		if {!$clean} {
		    # the geometry needs to be set for the containing frame,
		    # not the master canvas.
		    set w $master
		    # HACK ALERT FIX XXX: When loading data into a project that
		    # has widgets already, we need to adjust the
		    # -(row|column)(span)? info, because load_build_project
		    # will set it back.  This should be fixed by better control
		    # over user/program view of geometry data at some point.
		    foreach key {-row -column} {
			set val [::widget::geometry $w $key]
			::widget::geometry $w $key [expr {$val / 2}]
		    }
		    foreach key {-rowspan -columnspan} {
			set val [::widget::geometry $w $key]
			::widget::geometry $w $key [expr {($val / 2) + 1}]
		    }
		} else {
		    set w "CONTAINER" ; # $::W(FRAME) ?
		}
	    } else {
		if {$neednewname} {
		    set w [::widget::new $type]
		    set renamed_widgets($name) [winfo name $w]
		} else {
		    set w [::widget::new $type $::W(FRAME).$name]
		}
		# default to specified master
		::widget::data $w MASTER $master
		# Set the default grid geometry manager attributes
		array set geomDefs {
		    -row	1	-column	    1
		    -columnspan 1	-rowspan    1	-sticky     ""
		    -ipadx      0	-ipady      0
		    -padx       0	-pady       0
		}
		eval [list ::widget::geometry $w] [array get geomDefs]
	    }
	    if {$first_widget eq ""} { set first_widget $w }
	    set redo_subs {}
	    foreach sub [::compile::CmdSplit $subs] {
		# process the widget foo {... subcmds ...} data
		set res [catch {
		    load_project_string_widget $w $master $sub $clean
		} err]
		if {$res} {
		    # Allow some items to be retried if they are order
		    # dependent.  [Bug #1847667]
		    lappend redo_subs $sub
		}
	    }
	    foreach sub $redo_subs {
		load_project_string_widget $w $master $sub $clean
	    }
	    lappend widgets $w
	} elseif {$wcmd eq "menu"} {
	    if {!$clean} {
		# At this time, loading dialogs with menus into subframes
		# just drops the menus
		continue
	    }
	    if {$name eq "MENU"} { ; # && $type eq "Menu menu"
		set w $name
	    } else {
		set w [::widget::new_menuitem $type]
	    }
	    foreach sub [::compile::CmdSplit $subs] {
		# process the widget foo {... subcmds ...} data
		load_project_string_menu $w $master $sub $clean
	    }
	} elseif {$wcmd eq "language"} {
	    # only process the language command if we are "clean"
	    # otherwise check and see if these components are compatible
	    set lang $type
	    set ver  $name
	    if {$clean} {
		targetLanguage $lang $ver
	    } elseif {$lang ne [targetLanguage]} {
		# FIX: should also check changing targetVersion
		return -code error \
		    "Language $lang incompatible with [targetLanguage]"
	    }
	} else {
	    # Do we want to error on modified files?
	}
    }

    if {$clean} {
	# When clean, rebuild all widgets
	set widgets [lsort -command frameLevelSort [::widget::widgets]]
    }
    # Do the work of loading whatever widgets were created
    load_build_project $master $clean $widgets

    # FIX: should we sync_all here?
    ::palette::refresh app
    ::palette::refresh menu

    return $first_widget
}

# Load a project.  This loads the data from the file
#
# master - if specified, it means load the project into this frame
#
# Result:
#	1: the file has been successfully loaded
#	0: the file doesn't exist or is not a UI file

proc load_project {file {master {}}} {
    status_message "loading project $file"

    if {$master eq ""} { set master $::W(FRAME) }

    if {![winfo exists $master]} {
	status_message "master $master does not exist!"
	return 0
    }

    if {[catch {::project::loadui $file} data]} {
	tk_messageBox -title "Unable to Load Project File" \
	    -type ok -icon error \
	    -message "Error loading project file:\n$data"
    }

    busy_on
    set code [catch {
	# We have a "clean" load if we loading into the container,
	# otherwise we are loading a project into a subframe
	set clean [::gui::isContainer $master]

	if {$clean} {
	    global P
	    # Set the current project information if are loading
	    ::project::setp $file
	    # Append to the MRU list in "time file" tuples
	    # then sort unique to remove multiple of the same file
	    # then resort unique by time to get the 10 most recent
	    lappend P(MRU) [list [clock seconds] [::project::get ui]]
	    set P(MRU) [lsort -unique -dictionary -index 1 $P(MRU)]
	    set P(MRU) [lrange [lsort -unique -integer -decreasing \
				    -index 0 $P(MRU)] 0 9]
	}

	# Now actually parse all the data into memory
	load_project_string $data $master $clean

	if {$clean} {
	    # after a clean load, reset dirty
	    dirty 0
	}

	::api::Notify load $file

	# Refresh the application palette
	::palette::refresh app
    } err]
    busy_off

    if {$code} { return -code $code $err }
    return 1
}

# sort a list of widgets so the "masters" always get made first
# this will be called from qsort
#  - Frames go in front of widgets
#  - Master frames go in front of their children
# SOURCE

proc frameLevelSort {w1 w2} {
    set aframe [::widget::isFrame $w1]
    set bframe [::widget::isFrame $w2]
    if {!$aframe && !$bframe} {
	return 0
    } elseif {!$aframe} {
	return 1
    } elseif {!$bframe} {
	return -1
    }

    # both frames look for child master relationship
    return [expr {[::widget::data $w1 level] - [::widget::data $w2 level]}]
}

# make the grid lines, arrows, etc

proc make_decorations {master} {
    grid_create $master \
	[expr {1 + 2 * [llength [::widget::geometry $master resize_row]]}] \
	[expr {1 + 2 * [llength [::widget::geometry $master resize_column]]}]
    set ::Frames($master) 1

    arrow_create $::W(CAN_ROW) row $master all
    arrow_create $::W(CAN_COL) column $master all
    arrow_shapeall $::W(CANVAS) $master row
    arrow_shapeall $::W(CANVAS) $master column
    arrow_activate $::W(CANVAS) $master
}
