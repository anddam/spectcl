# highlight.tcl --
#
# Based on SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# Procedures to manage highlighting.  Highlighting comes in two flavors
# (which are sufficiently unrelated as to belong in different files).
# The window highlights are red borders around the active widget.  The
# border is a rectagular "frame" managed (with the placer) by the widget, 
# but stacked below it.

# The resize handles are little squares at the corners and sides of the active
# widget that are used for interactive resizing.  The "handles" are managed
# by the widgets outline(see outline.tk), so they stick to the edges of
# the widgets cavity.

# draw a highlight frame around a window
# arguments
#  win: the window to highlight
#  border: the size of the border around the window
#  name: - don't change.  Used to name highlight windows
# return value
#  The name of the highlight window
# side affects
#  add a binding tag to the window to pick up configure events
# notes
#  This version uses the new placer stuff

proc window_highlight {win {border 2}} {
    set new ${win}_highlight
    if {![winfo exists $new]} {
	frame $new -bg $::P(grid_highlight) -relief raised -bd 1
    }
    place $new -in $win -bordermode outside -relx 0 -rely 0 \
	-relwidth 1 -relheight 1 \
	-x -$border -y -$border \
	-width [expr {2 * $border}] \
	-height [expr {2 * $border}]
    lower $new $win
    return $new
}

# unhighlight a window (or all windows)
# arguments
#  win: window to "un-highlight" (or all highlighted object)
# returns
#  window that was un-highlighted

proc window_unhighlight {{win ""}} {
    if {$win == ""} {
	set result ""
	foreach i [info commands .*.*_highlight] {
	    regsub "(.+)_highlight" $i {\1} win
	    lappend result [window_unhighlight $win]
	}
	return $result
    }
    if {![winfo exists [set del ${win}_highlight]]} {
	return ""
    }
    destroy $del
    return $win
}


# Add resize handles to a widget.  The resize handles consist of 8 (or 9)
# squares placed around the edges and sides of a widget's cavity.

#  size:	the size of the highlight frame border (see highlight_window)
#  extra:	the amount the resize handles protrude into the window
# arguments
#  master:	The window to add resize handles around (usually the outline)
#             <masterframe>.<widget name>_outline
#  color:	the color of the resize handles
# return value
#  the name of the resize frame

proc add_resize_handles {w {color gray35}} {
    set master ${w}_outline
    set size  $::P(highlight_border_width)
    set extra $::P(resize_handles)
    set z [expr {$size + $extra}]
    foreach i {0 1 2 3 4 5 6 7 8} {
	set x [expr {($i%3)}]
	set y [expr {($i/3)}]
	set anchor [lindex {"n" "" "s"} $y][lindex {"w" "" "e"} $x]
	# If a "center" handle is desired, swap comment the following 2 lines
	# if {$i == 4} {set anchor c}
	if {$i == 4} {continue}
	# resize handles should be siblings of their widgets, so they
	# are always visible floating "above" the widget.
	# pick a name that can be parsed to retrieve the outline, widget,
	#   anchor, and widget master, that is a sibling of the widget
	set name $master:$anchor
	destroy $name
	frame $name -relief raised -bd 1
	$name configure -width $z -height $z \
	    -bg $color -cursor [cursor handle_$i]
	place $name -in $master -relx [expr {$x/2.0}] -rely [expr {$y/2.0}] \
	    -anchor $anchor -bordermode outside
	bindtags $name [list resize [winfo toplevel $name] all]
    }
}

# destroy all resize handles managed in master. (if any)
# Resize handles should be the only slaves of the outline, so destroying
# all of its slaves should be adaquate

proc del_resize_handles {master} {
    eval destroy [info commands .*_outline:*]
}

# parameters for moving resize handles.  For each resize handle, we only
# change either x or y of the managing frame, which we keep track of here.
# The coordinate names (-x, -y) are chosen to match the "place" option names
# The coords +x and +y are easier to use than -width and -height

# map from  a resize handle name to the coordinate that needs to be adjusted
array set Adjust "
    n.y  -y	s.y  +y		w.x  -x		e.x  +x
    nw.x -x 	nw.y -y		ne.x +x 	ne.y -y
    sw.x -x 	sw.y +y		se.x +x 	se.y +y
    numrows $P(maxrows)   numcolumns $P(maxcols)
"

# We started a sweep.  Compute relevent information
# win:  resize handle widget
proc resize_start_sweep {win x y} {
    global Adjust

    regexp "(\\..+)_outline:(.*)\$" $win -> owner Adjust(how)
    set Adjust(owner)  $owner	;# The widget owning the outline
    set Adjust(parent) [::widget::data $owner master] ;# The parent frame
    set Adjust(master) $Adjust(owner)_outline
    set Adjust(row)    ""
    set Adjust(column) ""
    foreach {Adjust(numcolumns) Adjust(numrows)} [grid size $Adjust(parent)] {}
    incr Adjust(numcolumns) -1
    incr Adjust(numrows)    -1
    array set info [grid info $owner]
    set Adjust(start_row)    $info(-row)
    set Adjust(start_column) $info(-column)
    set Adjust(end_row)      [expr {$info(-row) + $info(-rowspan) - 1}]
    set Adjust(end_column)   [expr {$info(-column) + $info(-columnspan) - 1}]
    set Adjust(r1)           $Adjust(start_row)
    set Adjust(c1)           $Adjust(start_column)
    set Adjust(r2)           $Adjust(end_row)
    set Adjust(c2)           $Adjust(end_column)

    # kludge to get around serious implicit-grab bug in TK
    # That causes an implicit grab to be released when "%W" is moved
    grab $win
}

# change the widget position by adjusting the span and/or row/col

proc resize_end_sweep {win x y} {
    # undo grab kludge
    grab release $win

    global Adjust
    set column $Adjust(c1); set row $Adjust(r1)
    set rowspan    [expr {$Adjust(r2) - $row + 1}]
    set columnspan [expr {$Adjust(c2) - $column + 1}]
    set widget $Adjust(owner)
    grid $widget -in [::widget::data $widget master]
    widget::geometry $widget -row $row -column $column \
	-rowspan $rowspan -columnspan $columnspan

    arrow_update $::W(CANVAS) $Adjust(parent)
    return 1
}

# adjust the resize frame, called from bind with %W %X %Y
# %W is the resize handle, named:
#	$::W(FRAME).<name of outline's widget>:<anchor code>
# The outline is named: <frame managing widget>.<widget name>_outline

proc resize_sweep {win x y} {
    global Current Adjust
    # make coords relative to parent

    incr x [expr {0 - [winfo rootx $Adjust(parent)]}]
    incr y [expr {0 - [winfo rooty $Adjust(parent)]}]

    # make modulo row/col (is this better?)

    foreach {col row} [grid location $Current(frame) $x $y] {}
    set row [expr {$row & ~1}]
    set col [expr {$col & ~1}]
    if {$row < 2 || $col < 2} return
    if {($row == $Adjust(row)) && ($col == $Adjust(column))} return
    set Adjust(row) $row; set Adjust(column) $col
    if {![get_position r1 c1 r2 c2]} return
    if {![position_ok $Adjust(owner) $r1 $c1 $r2 $c2]} return
    if {$row >= $Adjust(numrows) || $col >= $Adjust(numcolumns)} return
    foreach i {r1 c1 r2 c2} {set Adjust($i) [set $i]}	;# last good position
    if {[llength [array names Adjust $Adjust(how).x]] \
	    && [regexp {^\+} $Adjust($Adjust(how).x)] \
	    && ($col > $Adjust(start_column))} {
	incr col +1
    }
    if {[llength [array names Adjust $Adjust(how).y]] \
	    && [regexp {^\+} $Adjust($Adjust(how).y)] \
	    && ($row > $Adjust(start_row))} {
	incr row +1
    }

    # do the replacement
    foreach coord {x y} {
	set index $Adjust(how).$coord
	if {[info exists Adjust($index)]} {
	    set Adjust([set Adjust($index)]) [set $coord]
	}
    }

    # move the "box"

    if {![winfo exists $Adjust(master)]} {
	# create outline?
    } else {
	grid $Adjust(master) -row $r1 -column $c1 \
		-columnspan [expr {($c2-$c1)+1}] -rowspan [expr {($r2-$r1)+1}]
    }
    grid $Adjust(owner) -row $r1 -column $c1 \
	    -columnspan [expr {($c2-$c1)+1}] -rowspan [expr {($r2-$r1)+1}]
    update idletasks
    arrow_update $::W(CANVAS) $Adjust(parent)
}

# temporary binding stuff
#    <prefix>_down:  The button went down
#    <prefix>_start_sweep	We started a sweep
#    <prefix>_sweep			We are sweeping
#	 <prefix>_end_sweep		We ended the sweep (button up)
#	 <prefix>_up			button up - no sweep

proc resize_down {win x y} {
    after cancel $::Current(after)
    status_message "Drag past grid-line to change span"
}

# We could use this as a short cut for setting the edge stickyness

proc resize_up {win x y} {
}

# check to make sure widget can occupy slot(s)
# This is brute force for now, it should be made faster,
# Since it needs to be run at mouse-motion time
# All of the info needed for this is already packaged in the Adjust
# array, so don't bother passing in all of the parameters

# convert Adjustment position into starting and ending rows and columns

proc get_position {R1 C1 R2 C2} {
    global Adjust
    upvar $R1 r1  $C1 c1  $R2 r2  $C2 c2

    foreach element {
	row column owner how start_row start_column end_row end_column
    } {
	set $element $Adjust($element)
    }
    switch -glob $how {
	n*  {
	    if {$row > $end_row} {return 0}
	    set r1 $row; set r2 $end_row
	}
	s* {
	    if {$row < $start_row} {return 0}
	    set r1 $start_row; set r2 $row
	}
	* {
	    set r1 $start_row; set r2 $end_row
	}
    }

    switch -glob $how {
	*w  {
	    if {$column > $end_column} {return 0}
	    set c1 $column; set c2 $end_column
	}
	*e {
	    if {$column < $start_column} {return 0}
	    set c1 $start_column; set c2 $column
	}
	* {
	    set c1 $start_column; set c2 $end_column
	}
    }
    return 1
}

# See if rows and column range is empty

proc position_ok {widget r1 c1 r2 c2 {result _Message}} {
    global Current Adjust
    upvar 1 $result _Message

    if {$r1 < 2 || $c1 < 2 \
	    || $r2 >= $Adjust(numrows) || $c2 >= $Adjust(numcolumns)} {
	set _Message "Location is past the edge of the table"
	return 0
    }
    for {} {$r1 <= $r2} {incr r1 2} {
	for {set c $c1} {$c <= $c2} {incr c 2} {
	    set win [grid slaves $Current(frame) -row $r1 -column $c]
	    if {$win == ""} continue
	    if {[lsearch $win $widget] == -1} {
		set _Message \
		    "Location is occupied (by [winfo name [lindex $win 0]])"
		return 0
	    }
	}
    }
    set _Message ""
    return 1
}
