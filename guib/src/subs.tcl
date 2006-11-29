# subs.tcl --
#
#	This file contains misc. routines that probably belong
#	somewhere else.
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# update the scroll region of a frame's containing canvas
# This should be called every time the frame changes size
# there should be a separate one of these for forms

proc scrollregion_update {frame} {
    set canvas [winfo parent $frame]
    set fw [winfo reqwidth $frame ]
    set fh [winfo reqheight $frame]
    set reg [concat 0 0 [lrange [$canvas bbox all] 2 3]]
    foreach i [list $canvas ${canvas}_row ${canvas}_column] {
	# the row/column may not exist from where this is called
	catch {$i configure -scrollregion $reg}
    }
}

# update table geometry
# This should be call anytime the geometry of the table changes
# Its slow, so try not to do this too often
# parent: The "master" of the widgets

# Schedule an update to happen later

proc update_table {master {why "?"}} {
    if {![info exists ::Update_Scheduled]} {
	after idle do_update_table
    }
    set ::Update_Scheduled 1
}

# do all scheduled updates

proc do_update_table {} {
    set f $::Current(frame)
    if {[winfo exists $f]} {
	arrow_update $::W(CANVAS) $f
	outline::refresh $f
    }
    scrollregion_update $::W(FRAME)
    catch {unset ::Update_Scheduled}
}

proc leave_subgrid {} {
    # Move from subframe to master
    if {[set widget $::Current(widget)] != ""} {
	set master [::widget::data $widget master]
	if {![::gui::isContainer $master] && $master ne ""} {
	    ::palette::select widget $master
	    sync_all
	}
    }
}

proc enter_subgrid {} {
    # Move from frame to first subwidget
    set current $::Current(widget)
    if {[info exists ::Frames($current)]} {
	current_frame $current
	status_message "Entering sub frame"

	set widgets {}
	foreach w [grid slaves $current] {
	    if {[::widget::exists $w]} {
		lappend widgets $w
	    }
	}

	if {[llength $widgets]} {
	    ::palette::select widget \
		[lindex [lsort -command sort_widgets $widgets] 0]
	    sync_all
	}
    }
}

# Automatically select a different widget
# - If no widget is selected, select 1st widget in current frame
# - If a widget is selected, select next widget in current frame

proc move_to_widget {leftOrRight} {
    set widget $::Current(widget)
    set widgets {}
    foreach slave [grid slaves $::Current(frame)] {
	if {[::widget::exists $slave]} {
	    lappend widgets $slave
	}
    }
    if {[llength $widgets] < 2 && $widget != ""} {
	return
    }

    set dir [expr {($leftOrRight eq "right") ? "-increasing" : "-decreasing"}]
    set sorted [lsort $dir -command sort_widgets $widgets]

    # loop through list to next widget which isn't me

    lappend sorted [lindex $sorted 0]
    set me 0
    foreach i $sorted {
	if {$widget ne $i} {
	    if {$me} { break } else { continue }
	} else {
	    incr me
	}
    }
    ::palette::select widget $i
}

# sort some widgets either by increasing rows or columns
# we should cache this information

proc sort_widgets {win1 win2} {
    array set w1 [grid info $win1]
    array set w2 [grid info $win2]
    return [expr {($w1(-row)*1000 + $w1(-column)) \
	    - ($w2(-row)*1000 + $w2(-column))}]
}

# Delete whatever is currently selected

proc delete_selected {{arrows 1}} {
    ::undo::mark
    if {$::Current(widget) != ""} {
	if {$::P(confirm-delete-item)} {
	    set ans [tk_messageBox \
			 -title "Delete Selected Widget" -type yesno \
			 -message "Delete Selected Widget?" -icon question]
	    if {$ans == "no"} { return }
	}
	delete_selected_widget $::Current(widget)
    } elseif {$arrows} {
	# try to delete selected row or column
	delete_selected_arrow
    }
    update_table $::W(FRAME) delete_widget
}

# delete the currently selected widget

proc delete_selected_widget {die {force 0}} {
    # The check to prevent reentrancy causes problems because this
    # code is recursive.  So, if called from outside, we set 'force' to
    # zero.  If called from within, we set force to 1 so that all the
    # child widgets get deleted when a frame is deleted.  Ugh.

    if {[info exists ::P(delete_pending)] && !$force} { return }

    set ::P(delete_pending) 1
    ::palette::unselect widget
    ::outline::remove $die

    # destroy all widgets packed inside

    if {[info exists ::Frames($die)]} {
	grid_destroy $die	;# only needed if we don't destroy the widget
	foreach i [grid slaves $die] {
	    if {![::widget::exists $i]} {
		delete_selected_widget $i 1
	    }
	}
	unset ::Frames($die)
    } else {
	::undo::log delete_widget $die
    }
    ::widget::delete $die
    # reset grid spacing if row/col becomes empty
    grid_spacing $::Current(frame) 	;# lazy!
    set ::Current(widget) ""
    unset ::P(delete_pending)

    if {!$force} {
	# Refresh the application palette
	::palette::refresh app
    }
}

# delete the currently selected row and/or column
# don't delete the last row or column though

proc delete_selected_arrow {} {
    global Current
    if {$Current(gridline) == ""} {
	foreach i {row column} {
	    set tag [::arrow::maketag $Current(frame)]
	    if {[llength [$::W(CAN_$i) find withtag $tag]] == 1} {
		continue
	    }
	    if {[set tag $Current($i)] != ""} {
		foreach {master index} [::arrow::parsetag $tag] break
		# creating arrow $master $i $index
		if {![table_delete $master $i $index]} {
		    status_message "can't delete non-empty $i"
		} elseif {[grid_remove $master $i]} {
		    grid_update $master
		    set tag [arrow_delete $::W(CANVAS) $i $master]
		    if {$Current($i) == $tag || "current" == $tag} {
			# Unselecting dead $i arrow $tag
			set Current($i) ""
		    }
		}
	    }
	}
    } else {
	regexp {(.*)\.([^\.]*)@([0-9]*)} $Current(gridline) - master what index
	set numdivs 0
	foreach w [grid slaves [winfo parent $Current(gridline)]] {
	    if {[string match "*${what}@*" $w]} { incr numdivs }
	}
	unselect_grid
	# Make sure the user isn't deleting right or bottom-most index line, or
	# the last one left.
	if {$numdivs > 2 && $numdivs*2 > ($index+1)} {
	    if {![table_delete $master $what [expr {$index+1}]]} {
		status_message "can't delete non-empty $what"
	    } elseif {[grid_remove $master $what]} {
		grid_update $master
		set tag [arrow_delete $::W(CANVAS) $what $master]
	    }
	}
	select_grid $master.$what@$index
    }
}

# insert something in the currently selected whatever

proc insert_selected {} {
    ::undo::mark
    if {[set die $::Current(widget)] != ""} {
	insert_selected_widget $die
    } else {				;# try to delete selected row or column
	insert_selected_arrow
    }
}

# insert something into a widget

proc insert_selected_widget {die} {}

# insert a row/column, depending on what's highlighted

proc insert_selected_arrow {} {
    global Current

    if {$Current(gridline) == ""} {
	set evals {}
	foreach i {row column} {
	    if {[set tag $Current($i)] != ""} {
		foreach {master index} [::arrow::parsetag $tag] break

		set win $Current(frame).$i@[expr {$index-1}]
		if {[winfo exists $win]} {
		    grid_insert $win
		    lappend evals [list ::arrow::highlight $i $Current(frame) \
				       $index $::P(grid_highlight)]
		}
	    }
	}
	eval [join $evals ";"]
    } else {
	grid_insert $Current(gridline)
    }
}

proc dirty {{val 0}} {
    variable ::main::DIRTY
    if {![info exists DIRTY]} { set DIRTY 0 }
    if {[llength [info level 0]] > 1} {
	# val was specified
	set val [string is true -strict $val]
	if {$val != $DIRTY} {
	    set DIRTY $val
	    sync_all save; # just sync the save button
	    ::api::Notify dirty $DIRTY
	}
    }
    return $DIRTY
}

proc current_frame {frame} {
    if {$frame eq ""} { set frame $::W(FRAME) }

    if {$frame eq $::Current(frame)} return
    ::arrow::unhighlight
    arrow_activate $::W(CANVAS) $frame	;# temporary?

    set ::Current(frame) $frame

    # fix up the grid colors

    foreach i [array names ::Frames] {
	set current [$i cget -bg]
	if {$i eq $frame} {
	    grid_color $i [complement $current]
	} else {
	    grid_color $i $current
	}
    }
}

# compute the nesting depth of frames, so their stacking order is
# generated correctly.  Store result in the "level" entry of the widget
# structure

proc set_frame_level {master {level 0}} {
    ::widget::data $master level $level
    incr level
    foreach i [grid slaves $master] {
	if {[::widget::isFrame $i]} {
	    set_frame_level $i $level
	}
    }
}

# compute a widgets nominal position, which is the top left corner
# of its enclosing cell

proc get_tabbing_coords {w} {
    array set ginfo [grid info $w]
    foreach {sizecolumn sizerow sizewidth sizeheight} \
	    [grid bbox $ginfo(-in) $ginfo(-column) $ginfo(-row)] break
    set master [::widget::data $w master]
    set x [expr {[winfo x $master] + $sizecolumn}]
    set y [expr {[winfo y $master] + $sizerow}]

    return [list $y $x]
}

# figure out which sub-grid we're sitting on
#   x,y:   Where we're at (%X, %Y)
#   skip: never decend into this level
#   start: where in the grid to start (used internally to manage recursion)

proc find_grid {x y {skip ""} {start ""}} {
    if {$start eq ""} { set start $::W(FRAME) }

    # don't descend onto self
    if {$start eq $skip} {
	return $start
    }

    set myx [expr {$x - [winfo rootx $start]}]
    set myy [expr {$y - [winfo rooty $start]}]

    foreach {column row} [grid location $start $myx $myy] {}
    if {$column >= 0 && $row >= 0} {
	set owner [grid slaves $start -column $column -row $row]
    } else {
	return $start
    }
    foreach qq $owner {
	if {[info exists ::Frames($qq)]} {
	    set start [find_grid $x $y $skip $qq]
	}
    }
    return $start
}

# describe a widget briefly

proc widget_describe {win} {
    set text "?"
    set type [::widget::type $win]
    if {[::widget::exists $win -text]} {
	set text [::widget::data $win -text]
    } elseif {[::widget::exists $win -label]} {
	set text [::widget::data $win -label]
    } else {
	set text [::widget::data $win ID]
	# This grabs the widget uid from the end of the name
	set try [split $text $::gui::SEP]
	if {[llength $try] > 1} {
	    set text [lindex $try end]
	}
    }
    set text [string map [list "\n" /] $text]
    set text [string range $text 0 [string length $type]]
    if {$text eq $type} {
	return $type
    } else {
	return "$type\n$text"
    }
}

# insert a binding tag into a window

proc insert_tag {win tag} {
    set tags [bindtags $win]
    if {[lsearch -exact $tags $tag] != -1} {
	return 0		;# tag is already there
    }
    bindtags $win [linsert $tags 0 $tag]
    return 1
}

# delete a tag from a tag binding.

proc delete_tag {win tag} {
    set tags [bindtags $win]
    if {[set index [lsearch -exact $tags $tag]] == -1} {
	return 0		;# tag is not there
    } else {
	bindtags $win [lreplace $tags $index $index]
    }
    return 1
}

# clear_all --
#
#	Clear out everything and (re)initialize the the parent frame
#
proc clear_all {} {
    # all user widgets are children of this frame
    set container $::W(FRAME)

    ## Destroy stuff
    ##
    # delete all widgets
    eval [linsert [::widget::widgets] 0 ::widget::delete]
    ::widget::delete_menuall
    set ::argv ""
    catch {unset ::Frames}
    ::undo::reset
    eval [linsert [winfo children $container] 0 destroy]
    ::config::reset
    # FIX: do we really care to do this?
    ::widget::uid_reset
    ::arrow::zapall $::W(CANVAS)

    grid_destroy $container

    ## Reinit stuff
    ##
    globals_init

    ::project::setp $::P(project)

    # special case stuff for "top level" that is automatic for other frames
    # Create the 'f' container frame
    ::widget::new "CONTAINER"
    set ::Frames($container) 1
    set ::Current(frame) $container

    # create the default menu
    ::widget::new "MENU"

    # draw the grid lines, they go in ODD numbered rows and columns
    grid_create $container $::P(maxrows) $::P(maxcols)

    # make the row and column arrows
    arrow_create $::W(CAN_ROW) row $container all
    arrow_create $::W(CAN_COL) column $container all
    arrow_activate $::W(CANVAS) $container

    update idletasks
    arrow_update $::W(CANVAS) $container
    update_table $container clear_all

    # Refresh the application palette
    ::palette::refresh app
    ::palette::refresh menu

    # do this after because some of above will trigger dirty-ness
    dirty no
}

# set the window and icon title

proc set_title {name} {
    set name [file tail $name]
    wm iconname $::W(ROOT) $name
    wm title $::W(ROOT) "$name - $::gui::APPNAME"
}

######################################################################
# utility routines for extracting table structures

# insert a row or column into the table
#  Table: The parent table to do the inserting in
#  What is "row" or "column"
#  index must be even!
#  count must be even
#
proc table_insert {table what index {count 2}} {
    ::undo::log create_grid $table $what $index
    if {$index%2} {
	status_message "table_insert:Ack! index wasn't even!"
    }
    set elems {}
    foreach w [grid slaves $table] {
	if {[::widget::exists $w]} { lappend elems $w }
    }
    foreach w $elems {
	array set ginfo [grid info $w]
	set start $ginfo(-$what)
	set end   [expr {$start + $ginfo(-${what}span) -1}]
	if {$end < $index} {
	    continue	;# before insertion - skip
	}
	if {$start >= $index} {
	    # move entire widget
	    set opt -$what
	} else {
	    # shift span
	    set opt -${what}span
	}
	::widget::geometry $w $opt [expr {$ginfo($opt) + $count}]
    }

    resize_insert $table $what $index
    return 1
}

# delete a row or column - only delete empty rows or columns
#  table: parent of the table to operate on
#  what:  "row" or "col"
#  index: table index - MUST be even
#  count: How many to delete - MUST be even
#  return value: TRUE if successful, false if widget would be deleted
#
proc table_delete {table what index {count 2}} {
    # check for widget that would be deleted, gather info for the rest
    dputs $table $what $index
    set elems {}
    foreach w [grid slaves $table] {
	if {[::widget::exists $w]} { lappend elems $w }
    }
    foreach w $elems {
	array set ginfo [grid info $w]
	set start $ginfo(-$what)
	set end [expr {$start + $ginfo(-${what}span) -1}]
	if {$start == $index && $end == $index} {
	    return 0
	}
	if {$end < $index} {
	    continue
	}
	if {$start > $index} {
	    # move entire widget
	    set opt -$what
	} else {
	    # shift span
	    set opt -${what}span
	}
	::widget::geometry $w $opt [expr {$ginfo($opt) - $count}]
    }

    update_table $table "deleting $what $index"
    resize_delete $table $what $index
    return 1
}

######################################################################
# manage busy state
#
# This should really create a label to grab to that does nothing
#
namespace eval ::busy {
    variable BUSY 0
}
proc busy_on {{msg {}} {delay 120000}} {
    variable ::busy::LAST
    set LAST(grab)   [grab current]
    set LAST(cursor) [$::W(ROOT) cget -cursor]
    $::W(ROOT) configure -cursor watch
    catch {grab $::W(MESSAGE)}
    if {$msg eq ""} {
	set msg "Working ..."
    }
    status_message $msg $delay
}

proc busy_off {{msg {}} {delay 1000}} {
    variable ::busy::LAST
    grab release $::W(MESSAGE)
    if {[info exists LAST(cursor)]} {
	$::W(ROOT) configure -cursor $LAST(cursor)
	if {[winfo exists $LAST(grab)]} {
	    catch {grab $LAST(grab)}
	}
	unset LAST
    }
    status_message $msg $delay
}
######################################################################


# this is the "scroll set" command that unmaps the scrollbar when
# its size would be 1
proc scroll_set {win min max} {
    $win set $min $max
    if {$min == 0 && $max == 1} {
	grid remove $win
    } else {
	grid $win
    }
}

######################################################################

namespace eval ::status { variable handle }
# status_message --
#
#	Shows a message on the status bar. The message will disappear in
#	$delay milliseconds.
#
# Arguments:
#	msg:	The message to display
#
# Result:
#	None.
#
# Side effects:
#	(1) update idletasks is called.
#	(2) an after handler is created to clear the message.

proc status_message {msg {delay 8000}} {
    if {[info exists ::status::handle]} {
	after cancel $::status::handle
    }
    set ::_Message $msg
    update idletasks
    if {$msg ne ""} {
	set ::status::handle [after $delay [list set ::_Message ""]]
    }
}

######################################################################

######################################################################
## CURSOR HANDLING
##

# return a cursor using symbolic cursor names
proc cursor {name} {
    return $::cursor::cursors($name)
}

namespace eval ::cursor {
    variable cursors

    # global cursor map

    set cursors(handle)	hand2		;# row or column handle
    set cursors(menu)	top_left_arrow	;# menu background
    set cursors(item)	hand2		;# menu items

    # grid position cursors
    array set cursors {
	C	circle			Crc	cross
        Cc	sb_h_double_arrow	Cr	sb_v_double_arrow
	s	sb_down_arrow		n	sb_up_arrow
	e	sb_right_arrow		w	sb_left_arrow
	nw	top_left_corner		ne	top_right_corner
	sw	bottom_left_corner	se	bottom_right_corner
	inside	dot			occupied X_cursor
	reset {}
    }

    # resize handle cursors
    array set cursors {
	handle_0 top_left_corner	handle_1 top_side
	handle_2 top_right_corner	handle_3 left_side
	handle_4 cross			handle_5 right_side
	handle_6 bottom_left_corner	handle_7 bottom_side
	handle_8 bottom_right_corner
    }

    # row and column lines
    array set cursors {
	row sb_v_double_arrow		column sb_h_double_arrow
    }
}

##
## END CURSOR HANDLING
######################################################################
