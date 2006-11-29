# menucmds.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# mainmenu_quit --
#
#	This procedure is invoked by the following actions:
#	- File->Quit command
#	- "Quit" keyboard accelerator
#	- WM_DELETE_WINDOW
#
#	Cleans up and exits the application.  This can also override "exit".
#
# Arguments:
#	Whatever might be passed to the real exit command.
#
# Results:
#	Never returns.
#
proc mainmenu_quit {} {
    set askUser [expr {!$::P(confirm-autosave-on-quit) || $::P(file_untitled)}]

    if {![save_if_dirty $askUser]} {
	return 0
    }
    catch {::compile::kill_test}

    ::api::Notify exit; # tell everyone we are exiting

    # Save the use prefs
    #
    ::prefs::save

    # Remove temporary files

    foreach file [array names ::edit::TEMPFILES] {
	catch {file delete -force $file}
    }

    exit
}

proc mainmenu_view_code {} {
    # Currently in GUI builder this only views the code, unless
    # we are interactive, in which case it tells the controlling
    # app to edit the include file.
    edit_code $::Current(project)
}

# mainmenu_edit_label --
#
#	Handles the "Edit Widget Text" command in the Edit menu.

proc mainmenu_edit_label {} {
    set w $::tbar::TOOLS(entry)
    if {[$w cget -state] == "normal"} { focus $w }
}

proc mainmenu_delete {} {
    delete_selected
    sync_all
}
proc mainmenu_insert {} {
    insert_selected
    sync_all
}
proc mainmenu_cut {} {
    to_clipboard
    delete_selected 0
}
proc mainmenu_copy {} {
    to_clipboard
}
proc mainmenu_paste {} {
    from_clipboard
}

proc mainmenu_load_project_into_frame {} {
    if {[::widget::isFrame $::Current(widget)]} {
	# XXX: This should not be necessary, but on Win2K only the
	# guibuilder can hang when not getting data down the stdin
	# pipe - so this exists to ping/pong.
	# See also script_api pong response and koGuiBuilderService.py
	::api::Notify ping
	set filename [tk_getOpenFile -filetypes $::gui::FILE_TYPES]
	if {$filename != ""} {
	    load_project $filename $::Current(widget)
	}
    }
}
proc mainmenu_attach_scrollbars {} {
    ::scroll::attach $::Current(widget)
}
proc mainmenu_reapply_toolbar {} {
    status_message "repeating: $::Current(repeat)"
    eval $::Current(repeat)
}

# Copy the selected widget to the clipboard
#
proc to_clipboard {} {
    if {$::Current(widget) != ""} {
	# 'save' the widget and contents into a string.
	set data [::gui::get_widget_data $::Current(widget)]
	clipboard clear
	clipboard append $data
    }
}

# paste the clipboard item into the current canvas (gulp)
# This is still broken
#
proc from_clipboard {{test 0}} {
    global Current

    if {[catch {clipboard get} code]} {
	if {!$test} { status_message "No data on clipboard" }
	return 0
    }
    if {![string match "widget *" $code]} {
	if {!$test} { status_message "Invalid data on clipboard" }
	return 0
    }

    if {$test} {return 1}

    # figure out where to put it
    # 1) if a widget is selected, delete it and put new one there
    # 2) if a row and column are selected, put it there
    # 3) if a row or column is selected, put in first empty cell (later)
    # 4) punt

    if {$Current(widget) != ""} {
	regexp -- {-column (\d+) -row (\d+)} \
	    [grid info $Current(widget)] -> col row
	delete_selected 0
    } elseif {$Current(row) != "" && $Current(column) != ""} {
	set row [lindex [::arrow::parsetag $Current(row)] 1]
	set col [lindex [::arrow::parsetag $Current(column)] 1]
	if {[grid slaves $Current(frame) -row $row -column $col] != ""} {
	    status_message "Selected position is already occupied"
	    return 0
	}
    } else {
	status_message "No where to put widget!"
	return 0
    }

    # Watch for frame + components copy - that would be multiple commands
    set cmds [::compile::CmdSplit $code]
    set w [lindex $cmds 0]
    set subs [lindex $w 3]

    # The current frame is our master
    set master [winfo name $Current(frame)]
    if {$Current(frame) eq "" || [::gui::isContainer $Current(frame)]} {
	set master ""
    } else {
	set master [winfo name $Current(frame)]
    }

    set newsubs {}
    foreach cmd [::compile::CmdSplit $subs] {
	foreach {op tag value} $cmd { break }
	if {$op eq "data"} {
	    if {$tag eq "MASTER"} {
		set value $master
	    }
	} elseif {$op eq "geometry"} {
	    # Adjust the widget so that it gets put into the right spot.
	    # Note that we only want to change the very first widget, as
	    # if there's more, the first one is the container.
	    if {$tag eq "-row"} {
		set value [expr {$row/2}]
	    } elseif {$tag eq "-column"} {
		set value [expr {$col/2}]
	    } elseif {$tag eq "-rowspan"} {
		# Constrain cell spanning
		set value 1
	    } elseif {$tag eq "-columnspan"} {
		# Constrain cell spanning
		set value 1
	    }
	}
	lappend newsubs [list $op $tag $value]
    }
    set w [lreplace $w 3 3 [join $newsubs \n]]

    if {[llength $cmds] > 1} {
	set cmds [lreplace $cmds 0 0 $w]
	set w [join $cmds \n]
    }

    # FIX : XXX Should FRAME be used or $master ??
    # This will return the name of the first widget pasted in, which
    # may be the containing frame, and may have changed due to name
    # collisions.
    set sel [load_project_string $w $::W(FRAME) 0]
    # FIX: XXX Guard against "CONTAINER" ?
    ::palette::select widget $sel
    sync_all
}
