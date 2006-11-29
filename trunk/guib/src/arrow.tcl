# arrow.tcl --
#
# Based on SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# manage "arrows", the row/column indicators
# Each grid has a set of corrosponding row and column arrows that
# track the row and column sizes for that grid.  The arrow for each grid
# share the same "skinny" canvas-es and use canvas tags to identify
# each arrow group. Each arrow has 2 tags: the identifier for the arrow's
# group, and the group with a _nn suffix, where "nn" is the row or col #

namespace eval ::arrow {
    variable center 4
    variable SHAPE1 [list $center 8 3]
    variable SHAPE2 [list $center 0 3]
    variable WIDTH  3
    variable NOHIT  0 ;# hit -vs- sweep for row/col indicators
}

proc ::arrow::parsetag {tag} {
    regexp {tag:(.+):(\d+)$} $tag -> master index
    return [list $master $index]
}

proc ::arrow::maketag {master {index 0}} {
    if {[llength [info level 0]] == 2} {
	# no index was specified
	return tag:$master
    } else {
	return tag:${master}:$index
    }
}

# Update the arrow positions
# Each arrow is updated to match the length of its
# corrosponding row/col
# This gets called often, so it should be fast
#  base:	 The base name for the arrow canvases, as in ${base}_row...
#  master:	 The name of the table, which is also the tag name

proc arrow_update {base master} {
    global Current
    variable ::arrow::center

    if {$Current(frame) != "" && $Current(frame) ne $master} {
	#move existing arrows out of view
	set tag [::arrow::maketag $Current(frame)]
	${base}_row    move $tag -50 0
	${base}_column move $tag 0 -50
    }
    foreach {maxcolumn maxrow} [grid size $master] break
    for {set x1 2} {$x1 < $maxcolumn} {incr x1 2} {
	foreach {col row colh rowh} [grid bbox $master $x1 0] break
	${base}_column coords [::arrow::maketag $master $x1] $col $center \
		[expr {$col+$colh}] $center
    }
    for {set x1 2} {$x1 < $maxrow} {incr x1 2} {
	foreach {col row colh rowh} [grid bbox $master 0 $x1] break
	${base}_row coords [::arrow::maketag $master $x1] $center $row \
		$center [expr {$row+$rowh}]
    }
    ::arrow::updateOffsets $base $master
}

# Update an arrow position, move the rest for speed's sake.
# Each arrow is updated to match the length of its
# corrosponding row/col
# This gets called often, so it should be fast
#  base:	 The base name for the arrow canvases, as in ${base}_row...
#  master:	 The name of the table, which is also the tag name

proc arrow_update_one {base master what index} {
    global Current
    variable ::arrow::center

    if {$Current(frame) != "" && $Current(frame) ne $master} {
	#move existing arrows out of view
	set tag [::arrow::maketag $Current(frame)]
	${base}_row    move $tag -50 0
	${base}_column move $tag 0 -50
    }
    foreach {maxcolumn maxrow} [grid size $master] break
    if {$what eq "column"} {
	for {set x1 0} {$x1 < $maxcolumn} {incr x1 2} {
	    foreach {col row colh rowh} [grid bbox $master $x1 0] break
	    ${base}_column coords [::arrow::maketag $master $x1] $col $center \
		    [expr {$col+$colh}] $center
	}
    } else {
	for {set x1 0} {$x1 < $maxrow} {incr x1 2} {
	    foreach {col row colh rowh} [grid bbox $master 0 $x1] break
	    ${base}_row coords [::arrow::maketag $master $x1] $center $row \
		    $center [expr {$row+$rowh}]
	}
    }
    ::arrow::updateOffsets $base $master
}

proc ::arrow::updateOffsets {base master} {
    # now update the offsets, if any
    set mainw $::W(FRAME)
    if {$master ne $mainw} {
	set gsize [expr {2*[grid_line_size]}]
	arrow_offset $base column $master \
		[expr {[winfo rootx $master.@0]-[winfo rootx $mainw]+$gsize}]
	arrow_offset $base row    $master \
		[expr {[winfo rooty $master.@0]-[winfo rooty $mainw]+$gsize}]
    }
}


# activate a set of arrows.This affects the arrows visibility and bindings
#  base:  The base of the canvas name (e.g. $::W(CANVAS))
#  win:   Which set of arrows to activate

proc arrow_activate {base master} {
    arrow_update $base $master	;# this is overkill: find the bug!
    if {$::Current(frame) != ""} {
	#move existing arrows out of view
	set tag [::arrow::maketag $::Current(frame)]
	${base}_row    move $tag -50 0
	${base}_column move $tag 0 -50
    }
    #move new arrows into view.
    set tag [::arrow::maketag $master]
    set btn 1
    foreach i {row column} {
	set c ${base}_$i
	$c bind all  <$btn> {}
	$c bind $tag <$btn> [list arrow_begin_sweep $master %X %Y]
	$c bind $tag <ButtonRelease-$btn> [list ::arrow::unhit %W $i %X %Y]
	$c bind $tag <B$btn-Motion>       [list arrow_move %W $i %X %Y]
	$c itemconfigure $tag -fill $::P(grid_color)
	$c raise $tag
    }
    update idletasks
}

proc arrow_begin_sweep {master x y} {
    set ::Arrow_move 1
    set ::Y0 $y
    set ::X0 $x
    set w [set ::Current(resize_widget) $::Current(widget)]
    if {$w != "" && [winfo exists ${w}_outline]} {
	array set ginfo [grid info $w]
	grid ${w}_outline -sticky nsew \
		-row    $ginfo(-row)    -rowspan    $ginfo(-rowspan) \
		-column $ginfo(-column) -columnspan $ginfo(-columnspan)
    }
}

# This gets called from the button-release binding of an arrow as:
# ::arrow::unhit %W [row|column] %x %y

proc ::arrow::unhit {win what x y} {
    variable ::arrow::NOHIT
    set ::Arrow_move 0

    # re-sized a row/column - we had all this info, then lost it.  Oh well.
    # 'tis all broken

    if {$NOHIT} {
	set tag [lindex [$win gettags [$win find withtag current]] 1]
	foreach {master index} [::arrow::parsetag $tag] break
	set index [expr {$index / 2 - 1}]
	set min [::widget::geometry $master min_$what]
	::widget::geometry $master min_$what \
	    [lreplace $min $index $index $NOHIT]
	set NOHIT 0
	if {[winfo exists $::Current(resize_widget)]} {
	    ::palette::select_widget $::Current(resize_widget)
	    sync_all
	}
	foreach frame [array names ::Frames] {
	    update_table $frame arrow_move
	}
	# toggled row/column state
    } else {
	::arrow::hit $win $what $x $y
    }
}

# Process a button hit on an arrow.  This is invoked via bind
# If the arrow is "current", toggle its resize mode, otherwise make it
# the current arrow
#   win:	the window receiving the event (%W)
#   what:	"row" or "column"

proc ::arrow::hit {win what x y} {
    set ::X0 $x
    set ::Y0 $y
    set master none
    set tag [lindex [$win gettags [$win find withtag current]] 1]
    foreach {master index} [::arrow::parsetag $tag] break
    if {$master eq "none"} return
    ::palette::unselect widget
    unselect_grid
    if {$tag eq $::Current($what)} {
	arrow_shape $::W(CANVAS) $master $what $index \
		[expr {[resize_set $master $what $index] > 1}]
    } else {
	highlight $what $master $index $::P(arrow_highlight)
	sync_all
    }
    # Call this to update the message about resizability
    ::arrow::Enter $win $what $master $index
}

# change the offset of a set of arrow, for sub-frames
# this interface is temporary
#  base: $::W(CANVAS)
#  what: "row" or "column"
#  tag:  which table
#  offset:  Offset from the beginning (defaults to 0)

proc arrow_offset {base what master {offset 0}} {
    set tag [::arrow::maketag $master]
    set coords [${base}_$what coords $tag]
    if {$what eq "row"} {
	${base}_row    move $tag 0 [expr {$offset - [lindex $coords 1]}]
    } else {
	${base}_column move $tag [expr {$offset - [lindex $coords 0]}] 0
    }
}


# delete an arrow from the end of the table
# it should suffice to delete the last tag, but only if we're careful
# to maintain the relative stacking order of all arrows with "tag"
#  base: The base of the canvas name (e.g. $::W(CANVAS))
#  what: Row or Column
#  master:  Which frame
#  all:  delete the last arrow, or all of them
# return value:  The name of the tag deleted, or ""

# This should return the tag of the arrow deleted, so the caller can
# unset "Current", if any

proc arrow_delete {base what master {all ""}} {
    set can ${base}_$what
    set tag [::arrow::maketag $master]
    if {$all != ""} {
	$can delete $tag
	return ""
    } else {
	set alltags [lindex [$can find withtag $tag] end]
	set tag [lindex [$can gettag $alltags] end]
	$can delete $tag
	return $tag
    }
}

# set the shape of an arrow
#  can:  the root of the canvas (e.g. can_$what)
#  master:  Which table the arrow belongs to
#  what:  "row" or "column"
#  index: which arrow
#  value:	true if <->, otherwise |-|

proc arrow_shape {can master what index value} {
    dirty 1
    set tag [::arrow::maketag $master $index]
    if {$value} {
	set shape $::arrow::SHAPE1
	grid ${what}configure $master $index -weight 1000
    } else {
	set shape $::arrow::SHAPE2
	grid ${what}configure $master $index -weight 1
    }
    ${can}_$what itemconfigure $tag -arrowshape $shape
}

# reshape all the arrows, based on the table's resize property

proc arrow_shapeall {can master what} {
    set list [::widget::geometry $master resize_$what]
    set index 0
    foreach arrow $list {
	if {$arrow > 1} {
	    set shape $::arrow::SHAPE1
	    set resize 1000
	} else {
	    set shape $::arrow::SHAPE2
	    set resize 1
	}
	set tag [::arrow::maketag $master [incr index 2]]
	${can}_$what itemconfigure $tag -arrowshape $shape
	grid ${what}configure $master $index -weight $resize
    }
}

# create a new arrow
# This doesn't happen often (except, perhaps,  at startup)
#  can: name of the canvas
#  what: "row" or "column"
#  master: The table master
#  index:  MUST be even or "all" or ""
#  value:  what shape: <=1 -> no resize, >=2 -> resize

# the "value" option is never used

proc arrow_create {can what master {index ""} {value ""}} {
    set tag [::arrow::maketag $master]

    # create all of the arrows

    foreach {maxcolumns maxrows} [grid size $master] {}
    if {![winfo exists $can]} {return 0}
    if {$index == "all"} {
	set max [set max${what}s]
	incr max -1
	set shape 0
	$can delete $tag
	for {set indx 2} {$indx < $max} {incr indx 2; incr shape} {
	    arrow_create $can $what $master $indx [lindex $value $shape]
	}
	$can itemconfigure $tag -fill [$can cget -bg]
	return 1

	# create the "next" arrow, get the resize behavior right (or try to)

    } elseif {$index == ""} {
	set index [expr {[llength [$can find withtag $tag]] * 2 + 2}]
	set value [lindex [::widget::geometry $master resize_$what] end]
    }

    if {$what == "row"} {
	foreach {col row colH rowH} [grid bbox $master 0 $index] {
	    set coords [list -45 $row -45 $rowH]; break
	}
    } else {
	foreach {col row colH rowH} [grid bbox $master $index 0] {
	    set coords [list $col -45 $colH -45]; break
	}
    }
    if {$value != "" && $value > 1} {
	set shape $::arrow::SHAPE1
	set reshape 1000
    } else {
	set shape $::arrow::SHAPE2
	set reshape 1
    }

    set itag [::arrow::maketag $master $index]
    $can create line $coords -fill $::P(grid_color) \
	    -width $::arrow::WIDTH -arrow both -arrowshape $shape \
	    -tags [list $tag $itag]
    $can bind $itag <Enter> [list ::arrow::Enter $can $what $master $index]
    $can bind $itag <Leave> [list ::arrow::Leave $can]
    grid ${what}configure $master $index -weight $reshape
    return 1
}

proc ::arrow::Enter {can what master index} {
    set index [expr {$index/2 - 1}]
    if {[lindex [::widget::geometry $master resize_$what] $index] > 1} {
	set resize "resizable"
    } else {
	set resize "not resizable"
    }
    if {$master eq $::W(FRAME)} {
	set master master
    } else {
	set master [::widget::data $master ID]
    }
    set ::G(HELPMSG) "$master $what $index ($resize: click to change)"
    $can configure -cursor [cursor handle]
}

proc ::arrow::Leave {can} {
    set ::G(HELPMSG) ""
    $can configure -cursor {}
}

# sweep out a row or column, changing its size
# Only sweep if we're near the right edge of the arrow
# (I'm re-computing too much stuff here)

proc arrow_move {win what x y} {
    # check gravity slush before actually moving
    if {[button_gravity $x $y]} {return}

    variable ::arrow::NOHIT

    dirty 1
    if {!$NOHIT} {
	incr NOHIT
    }
    array set map2 {row y column x}
    set tag [lindex [$win gettags [$win find withtag current]] 1]
    foreach {master index} [::arrow::parsetag $tag] break
    if {$what == "row"} {
	foreach {dumcolumn dumrow dumwidth dumheight} \
		[grid bbox $master 0 $index] break
    } else {
	foreach {dumcolumn dumrow dumwidth dumheight} \
		[grid bbox $master $index 0] break
    }
    set width [expr {int(([set $map2($what)]-[winfo root$map2($what) $master])\
	    - [set dum${what}] - [grid_line_size])}]
    if {$width < 5} return
    set NOHIT $width
    status_message "$what [expr {$index/2}] size $width"
    grid ${what}configure $master $index -minsize $width
    arrow_update_one $::W(CANVAS) $master $what $index
}

# unselect the "current" row or column indicator
# what: "row" or "column".  default unhighlights both

proc ::arrow::unhighlight {{dims {row column}}} {
    foreach what $dims {
	if {$::Current($what) != ""} {
	    $::W(CAN_$what) itemconfigure $::Current($what) \
		-fill $::P(grid_color)
	    set ::Current($what) ""
	}
    }
}


# highlight an arrow
#  what: "row" or "column"
#  tag:  which set of arrows (the table master)
#  index: which arrow in the set
#  color: What color to make the arrow

proc ::arrow::highlight {what master index color} {
    unhighlight $what
    set tag [maketag $master $index]
    $::W(CAN_$what) itemconfigure $tag -fill $color
    set ::Current($what) $tag
}

# zap all arrows!

proc ::arrow::zapall {base} {
    ${base}_row delete all
    ${base}_column delete all
}
