# button.tk --
#
#	This file handles the button events (selection, drag & drop)
#	inside the palette and the grid.
#
# Copyright (c) 1994-1997 The Regents of the University of California.
# Copyright (c) 2002-2006 ActiveState Software Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# arguments:
#   win:		The window the button was clicked on (%W)
#   x,y:		The absolute mouse coordinates (%X %Y)

########################################################

namespace eval ::palette {
    variable W
    set W(DRAG) .__dnd
}

proc ::palette::setbind {w {isFrame 0} {keep 0}} {
    # set the bindtags for the widget to work on the palette only
    if {$keep} {
	set cur [bindtags $w]
    }
    if {$isFrame} {
 	bindtags $w [list frame widget [winfo toplevel $w] all]
    } else {
 	bindtags $w [list widget [winfo toplevel $w] all]
    }
    if {$keep} {
	eval lappend bindtags $cur
    }
    foreach child [winfo children $w] {
	# we need to make sure children in megawidgets are ignored
	setbind $child 0 1
    }
}

# procedures for managing hits on widget palette

proc palette_down {w x y} {
    set sel [lindex [$w selection get] 0]
    if {[llength $sel]} {
	status_message "Drag to create a new $sel"
	::palette::select palette $sel
    }
}

proc palette_up {w x y} {
    variable ::palette::W

    set type $::Current(palette_widget)
    if {$type eq ""} { return }

    ::palette::select palette $type
    if {[winfo ismapped $::W(CONFIG)]} {
	# update the Properties dialog
	::palette::activate lang 0 $type
    }
}

proc make_dnd_label {w args} {
    destroy $w
    toplevel $w
    wm withdraw $w
    wm override $w 1
    wm transient $w $::W(ROOT)
    wm group $w $::W(ROOT)
    if {$::tcl_platform(platform) eq "windows"} {wm attributes $w -topmost 1}
    set lbl $w.label
    eval [list label $lbl] $args
    pack $lbl -fill both -expand 1
    return $lbl
}

# To autoscroll a canvas, we schedule scrolling using after.
# Current(after) contains the next scheduled auto-scroll command.
# to stop auto scrolling, cancel that id

proc palette_start_sweep {w x y} {
    global Current In_view Where Row Col

    set Where   ""
    set In_view 0
    set Row     ""
    set Col     ""
    current_frame $::W(FRAME)
    set drag $::palette::W(DRAG)
    destroy $drag
    if {$Current(palette_widget) == ""} { return }
    make_dnd_label $drag -text $Current(palette_widget) -relief solid -bd 1
}

# track the cursor over the canvas, keep track of its position
# The optional "repeat" argument is used for auto-scrolling

proc palette_sweep {win x y {repeat 0}} {
    global P Current Where Row Col

    # make sure the widget is in view

    if {$repeat == 0} {
	after cancel $Current(after)
    }
    set drag $::palette::W(DRAG)
    if {![winfo exists $drag]} { return }

    # let us keep showing the widget wherever it is...funny as
    # this looks.  this is important so that when the user
    # drops it over the palette,
    #wm geometry $drag +[expr {$x - 10}]+[expr {$y + 5}]
    wm geometry $drag +[expr {$x - ([winfo width $drag] / 2)}]+$y
    update idle
    wm deiconify $drag

    set viewresult [keep_in_view $::W(CANVAS) $x $y]
    if {$viewresult <= 0} {
	set Current(after) [after $P(scroll_delay) \
				[list palette_sweep $win $x $y 1]]
    }

    # where on the canvas are we?

    set before $Where
    set row $Row; set col $Col
    set Where [find_slot $Current(frame) $x $y Row Col]
    if {$Where == $before && $Row == $row && $Col == $col} {
	return
    }

    if {$viewresult < 2} {
	$::W(ROOT) configure -cursor [cursor $Where]
    } else {
	# this indicates that we shouldn't drop the widget
	$::W(ROOT) configure -cursor [cursor occupied]
    }

    switch  -glob $Where {
	Cr	{
	    # on a row grid line
	    ::arrow::unhighlight row
	}
	Cc	{
	    # on a column grid line
	    ::arrow::unhighlight column
	}
	Crc	{
	    # on both row and column grid line
	    ::arrow::unhighlight
	}
	C* {
	    # in a slot
	    set on [grid slaves $Current(frame) -row $Row -column $Col]
	    set status ""
	    if {$on != ""} {
		foreach qq $on {
		    if {[info exists ::Frames($qq)]} {
			$::W(ROOT) configure -cursor [cursor occupied]
			current_frame [find_grid $x $y "" $qq]
		    }
		    set status "Occupied"
		    set color $P(grid_highlight)
		}
	    } else {
		set color $P(generic_over_color)
	    }
	    if {$status eq "Occupied"} {
		$::W(ROOT) configure -cursor [cursor occupied]
	    }
	    ::arrow::highlight row    $Current(frame) $Row $color
	    ::arrow::highlight column $Current(frame) $Col $color
	    status_message "row [expr {$Row/2}], col [expr {$Col/2}] $status"
	}
	default {				# outside the grid
	    current_frame [find_grid $x $y]
	}
    }
}

# Create a new widget and plunk it down

proc palette_end_sweep {win x y} {
    global Current Row Col In_view Where

    # create the widget
    destroy $::palette::W(DRAG)
    $::W(ROOT) configure -cursor [cursor reset]

    # Do not drop a widget if we haven't entered the grid yet,
    # or if we are below the 0,0 point of the canvas frame.
    if {$In_view == 0 || ($x < [winfo rootx $::W(FRAME)]) \
	    || ($y < [winfo rooty $::W(FRAME)])} {
	return
    }
    check_table $Current(frame) $Where Row Col
    set on [grid slaves $Current(frame) -row $Row -column $Col]
    if {$on != ""} {
	if {$Current(palette_widget) != ""} {
	    ::palette::unselect palette
	    return "occupied"
	} else {
	    status_message \
		"row [expr {$Row/2}], col [expr {$Col/2}] is occupied"
	}
    } else {
	::undo::mark
	add_widget $Current(palette_widget) $Current(frame) $Row $Col
    }

    # clean up
    ::arrow::unhighlight
    after cancel $Current(after)
    sync_all
}

#######  AUX procedures used by bindings

# scroll canvas to keep in view
# x and y are root coords
# Make sure we don't scroll before the widget is in bounds
#
proc keep_in_view {win x y} {
    global In_view
    set in_bounds 0
    set rootx [winfo rootx $win]
    set rooty [winfo rooty $win]
    if {$x < $rootx} {
	set frootx [winfo rootx $::W(FRAME)]
	# check the relative roots to not scroll below 0
	if {$In_view && ($rootx > $frootx)} {
	    $win          xview scroll -1 units
	    ${win}_column xview scroll -1 units
	} else {
	    return 2
	}
    } elseif {$y < $rooty} {
	set frooty [winfo rooty $::W(FRAME)]
	# check the relative roots to not scroll below 0
	if {$In_view && ($rooty > $frooty)} {
	    $win       yview scroll -1 units
	    ${win}_row yview scroll -1 units
	} else {
	    return 2
	}
    } elseif {$x > $rootx + [winfo width $win]} {
	$win          xview scroll 1 units
	${win}_column xview scroll 1 units
    } elseif {$y > $rooty + [winfo height $win]} {
	$win       yview scroll 1 units
	${win}_row yview scroll 1 units
    } else {
	set In_view 1
	set in_bounds 1
    }
    return [expr {!$In_view || $in_bounds}]
}

# get the row and column position
# win: table master
# x,y: Root x and y coords
# row,col: get filled in if True
# result: code indicating where it is
#  position relative to grid:  nw n ne e se s sw w
#  where in grid: r c rc (row, column, row&column)
#  "" on a grid slot

proc find_slot {win x y set_row set_col} {
    upvar $set_row row $set_col col
    set result ""
    incr x [expr {0 - [winfo rootx $win.@0]}]
    incr y [expr {0 - [winfo rooty $win.@0]}]
    foreach {col row} [grid location $win $x $y] {}
    foreach {xwidth ywidth} [grid size $win] {}
    incr xwidth -1
    incr ywidth -1

    if {$y < 0} {
	append result n
    } elseif {$row > $ywidth} {
	append result s
    } elseif {($row == $ywidth) && ($row & 1)} {
	append result s
    }
    if {$x < 0} {
	append result w
    } elseif {$col > $xwidth} {
	append result e
    } elseif {($col == $xwidth) && ($col & 1)} {
	append result e
    }

    if {$result != ""} {
	return $result
    }
    set result C

    if {$row & 1} {
	append result r
    }
    if {$col & 1} {
	append result c
    }
    return $result
}

########################################################3
# procedures for managing hits on widgets
# these should be combined with the palette routines!!

proc widget_down {w x y} {
    if {$w eq $::Current(widget)} {
	status_message "Double click to activate properties dialog"
    } else {
	set id [::widget::data $w ID]
	if {$id ne ""} {
	    status_message "selecting $id"
	} else {
	    status_message "selecting [winfo name $w]"
	}
    }
}

# take 2 - sweep a label, not the entire widget

proc widget_start_sweep {w x y} {
    set ::Row     [::widget::geometry $w -row]
    set ::Col     [::widget::geometry $w -column]
    set ::Where   ""
    set ::In_view 0
    ::palette::unselect widget
    current_frame [::widget::data $w MASTER]
    destroy $::palette::W(DRAG)
    make_dnd_label $::palette::W(DRAG) \
	-bd 1 -relief raised -text [widget_describe $w]
}

proc widget_sweep {w x y {repeat 0}} {
    palette_sweep $w $x $y $repeat
}

proc widget_end_sweep {w x y} {
    global Row Col
    after cancel $::Current(after)

    # move or copy it!
    destroy $::palette::W(DRAG)
    $::W(ROOT) configure -cursor [cursor reset]

    set frame $::Current(frame)
    check_table $frame $::Where Row Col
    ::palette::unselect widget
    set on [grid slaves $frame -row $Row -column $Col]

    # Find all the frame parents to disallow moving a frame somewhere
    # within itself or a child
    set masters [list $frame]
    set master  [::widget::data $frame MASTER]
    while {![::gui::isContainer $master] && $master ne ""} {
	set master [::widget::data $frame MASTER]
	if {![::gui::isContainer $master] && $master ne ""} {
	    lappend masters $master
	}
    }
    if {[lsearch -exact $masters $w] != -1} {
	status_message "Can't move or copy widget to itself"
	return
    }
    if {$on == ""}  {
	if {$::Shift} {
	    ::undo::mark
	    set w [copy_widget $frame $w $Row $Col]
	} else {
	    set w [move_widget $frame $w $Row $Col]
	}
	::widget::data $w MASTER $frame
	::widget::geometry $w -rowspan 1 -columnspan 1 -row $Row -column $Col
	::palette::select widget $w
    }
    ::arrow::unhighlight
    sync_all
}

# make the proper widget selected
# 1 if frame and selected, de-select and select row/col instead
# 2 if "parent" is current frame, select widget
# 3 select parent who is a child of the current frame

proc widget_up {w x y} {
    # Clicked in frame, select row/col
    grid_single_click $w \
	[expr {$x - [winfo rootx $w]}] [expr {$y - [winfo rooty $w]}]
}

# add_widget --
#
#	Adds a new widget of the given type to row,column.
#
# Arguments:
#	type		The type of the widget.
# 	master		The frame to manage the copy in.
#  	row,column	where to put it.
#
# Result:
#	Returns the pathname of the new widget.

proc add_widget {type master row column} {
    set new [::widget::new $type]
    # set the overriding bindings
    set isFrame [::widget::isFrame $new]
    ::palette::setbind $new $isFrame
    ::widget::data $new MASTER $master
    grid $new -in $master -row $row -column $column
    # FIX : XXX should this be user or internal row/col vals?
    ::widget::geometry $new -row $row -column $column

    status_message "Created new $type at [expr {$row/2}],[expr {$column/2}]"

    # Each widget type potentially has its own special code
    # for creation in the workspace.  Run it here, as a filter
    filter widgettype $type $new

    # Refresh the application palette
    ::palette::refresh app

    ::palette::select widget $new

    return $new
}

# copy_widget --
#
#	Copy a widget to row,col. Assumes new widget is a sibling of
#	the old one
#
# Arguments:
# 	master	The frame to manage the copy in
#  	win	The widget to copy
#	args	optional {row col}: where to put it (if moved)
#
# Result:
#	Returns the pathname of the new widget.

proc copy_widget {master win args} {
    # name and clone the widget parameters
    set path [::widget::clone $win]

    # change the parameters, just append new values to the end, as
    # grid will parse all then act.

    array set ginfo [grid info $win]
    set ginfo(-in) $master
    if {[llength $args]} {
	array set ginfo [list -row [lindex $args 0] -column [lindex $args 1]]
    }
    eval [list grid $path] [array get ginfo]
    # FIX : XXX should this be user or internal row/col vals?
    ::widget::geometry $path -row $ginfo(-row) -column $ginfo(-column)
    ::widget::data $path MASTER $master
    set isframe [::widget::isFrame $path]
    ::palette::setbind $path $isframe

    # If this is a frame, copy all its children,
    # Then make the grid and arrows (broken, but close)

    if {$isframe} {
	foreach {maxrows maxcols} [grid_size $win] { break }
	::filter::create_frame $path $maxrows $maxcols
	foreach child [grid slaves $win] {
	    if {$child ne $path} {
		if {[::widget::exists $child]} {
		    set new [copy_widget $path $child]
		    ::widget::data $new MASTER $path
		    #after idle [list ::outline::outline $new]
		}
	    }
	}
	arrow_update $::W(CANVAS) $path
    }

    # Refresh the application palette
    ::palette::refresh app

    return $path
}

# move_widget --
#
#	Move a widget to row,col and update form entries.
#
# Arguments:
#	table		Where to move the widget to
# 	win		The name of the window to move
#	row,column	Where in the table to put it

proc move_widget {table w row col} {
    array set ginfo [grid info $w]
    array set ginfo [list -in $table -column $col -row $row]
    grid remove $w
    eval [list grid $w] [array get ginfo]
    # FIX : XXX should this be user or internal row/col vals?
    ::widget::geometry $w -row $ginfo(-row) -column $ginfo(-column)
    if {![::widget::isFrame $w]} {
	raise $w
    }

    # Refresh the application palette
    ::palette::refresh app

    return $w
}

# If we selected a spot that is "out of bounds", then extend the table,
# and make sure the spot IS in bounds

proc check_table {table where myrow mycol} {
    global P
    upvar $myrow row $mycol col
    set add 0

    if {!$P(insert_on_gridline)} {
	# Make sure we don't drop widgets on grid/row lines.
	if {$row&1} { incr row }
	if {$col&1} { incr col }
    }

    # check front of table

    if {$row <= 1} {
	table_insert $table row [set row 2]
	grid_process $table row 1
	incr add
    }
    if {$col <= 1} {
	table_insert $table column [set col 2]
	grid_process $table column 1
	incr add
    }

    if {$P(insert_on_gridline)} {
	# check on grid lines
	if {$row&1} {
	    table_insert $table row [incr row]
	    grid_process $table row 1
	    incr add
	}
	if {$col&1} {
	    table_insert $table column [incr col]
	    grid_process $table column 1
	    incr add
	}
    }

    # check ends of table
    if {[string match *e $where]} {
	resize_insert $table column 999
	grid_process $table column 1
	incr add
    }
    if {[string match s* $where]} {
	resize_insert $table row 999
	grid_process $table row 1
	incr add
    }
    return $add
}
