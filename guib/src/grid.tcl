# grid.tcl --
#
# SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
# Copyright (c) 2002-2006 ActiveState Software Inc.  All Rights Reserved.
#
# do grid related stuff (take 2)
# all of the information is derived from querying the table layout
# Grid lines are placed in "odd" rows and columns

# create the grid - for starting
#  master:			master of the table
#  max rows/cols:	how many grid lines to create
#  size:			The thickness of each grid line
#  spacing:			The grid spacing
#  color:			The color of each grid line

proc grid_create {master maxrows maxcols} {
    # These used to be params, but were never changed
    set size [grid_line_size]
    set color $::P(grid_color)
    set relief raised

    # should use existing grid lines instead
    catch {frame $master.@0 -bg $color -bd 1 -relief $relief}
    grid $master.@0 -row 1 -column 1 -sticky {nsew}
    for {set row 1} {$row <= $maxrows} {incr row 2} {
	grid_line $master row $color $size $relief $row
    }
    for {set col 1} {$col <= $maxcols} {incr col 2} {
	grid_line $master column $color $size $relief $col
    }
    grid_update $master
    resize_init $master [expr {$maxrows/2-1}] [expr {$maxcols/2-1}]
    grid_spacing $master
    grid rowconfigure    $master 0 -minsize 0 -weight 0
    grid columnconfigure $master 0 -minsize 0 -weight 0
}

# create a grid row or column separator frame
#  master:  master of the table
#  what:    "row" or "column"
#  color:   grid line color
#  thick:   Grid line thickness
#  index:   row or column number (must be odd). Defaults to end.

proc grid_line {master what color thick relief {index ""}} {
    global P
    if {$index == ""} {		;# find the next grid line
	set index -1
	foreach qq [grid slaves $master] {
	    if {[regexp "${what}@" $qq]} {
		incr index 2
	    }
	}
	incr index 2
    } elseif {[winfo exists $master.${what}@$index]} {
	return $index
    }
    #	array set option {row height column width}
    array set slot {row 0 column 1}
    set win $master.${what}@$index
    if {$what eq "row"} {
	set place [list -row $index -column 2]
    } else {
	set place [list -row 2 -column $index]
    }

    frame $win -bg $color -cursor [cursor $what] -bd 1 -relief $relief
    if {$what eq "row"} {
	raise $win $master.row@1
    } else {
	lower $win $master.row@1
    }
    eval [list grid $win -in $master -sticky nsew] $place
    grid ${what}configure $master $index -minsize $thick
    bindtags $win [list grid $what [winfo toplevel $win] all]
    ::bind::setup grid grid
    if {$what eq "row"} {
	$win config -cursor sb_v_double_arrow
    } else {
	$win config -cursor sb_h_double_arrow
    }
    # too late - we've lost the row/column number
    # resize_insert $master $what $index
    return $index
}

# remove the last grid line - but not the first

proc grid_remove {master what} {
    set slaves {}
    foreach qq [grid slaves $master] {
	if {[regexp "${what}@" $qq]} {
	    lappend slaves $qq
	}
    }
    # apply all the new weights and sizes to the grid:
    set curr 1
    foreach min [::widget::geometry $master min_$what] \
	wght [::widget::geometry $master resize_$what] {
	grid ${what}config $master [expr {$curr+1}] -minsize $min \
	    -weight [expr {$wght<2?1:1000}]
	incr curr 2
    }
    update idletasks
    arrow_update $::W(CANVAS) $master
    if {[llength $slaves] > 2} {
	set slave $master.$what@[expr {[llength $slaves]*2-1}]
	array set idx [grid info $slave]
	grid remove $slave
	catch {destroy $slave}
	foreach {cols rows} [grid size $master] {}
	grid ${what}configure $master $idx(-$what) -weight 0 -minsize 0
	grid ${what}configure $master [incr idx(-$what) -1] -weight 0 -minsize 0
	grid_update $master
	return 1
    } else {
	return 0
    }
}

# return current grid size

proc grid_size {master} {
    set slaves [grid slaves $master]
    set zz 0
    foreach qq $slaves {
	if {[string match "$master.row@*" $qq]} {
	    incr zz 2
	}
    }
    set maxrows $zz
    set zz 0
    set slaves [grid slaves $master]
    foreach qq $slaves {
	if {[string match "$master.column@*" $qq]} {
	    incr zz 2
	}
    }
    set maxcols $zz
    return [list $maxrows $maxcols]
}

# destroy a grid entirely

proc grid_destroy {master} {
    foreach qq [grid slaves $master] {
	if {[string match "$master.*@*" $qq]} {
	    destroy $qq
	}
    }
    foreach {col row} [grid size $master] {}
    while {$col >= 0} {
	grid columnconfig $master $col -weight 0 -minsize 0
	incr col -1
    }
    while {$row >= 0} {
	grid rowconfig $master $row -weight 0 -minsize 0
	incr row -1
    }
}

# see if we need to add a new grid row or column
#  what:    row or column
#  return:  # of grid lines we need to add

proc grid_check {master what} {
    set offset [string equal $what "row"]
    set slots [lindex [grid size $master] $offset]

    set grids 0
    foreach qq [grid slaves $master] {
	if {[string match "$master.${what}@*" $qq]} {
	    set mygrids($qq) 1
	}
    }
    set grids [llength [array names mygrids]]
    return [expr {$slots/2 - $grids}]  ;# CHECK
}

# update the row/col grid lengths after adding new grid lines to the table
# look at the actual grid lines, as the table dimension isn't always reliable
#   master: The master of the table

proc grid_update {master} {
    array set other {row column column row}
    set span 1
    set zz {}
    foreach what {row column} {
	foreach qq [grid slaves $master] {
	    if {[string match "$master.$other($what)@*" $qq]} {
		set zz [concat $qq $zz]
	    }
	}
	set slaves $zz
	# we can't rely on [grid size], because if a column is
	# supposed to be deleted it doesn't go away until row/column
        # spans have been shortened as well.
	set span [expr {[llength $zz]*2 - 1}]
	set zz {}
	foreach qq [grid slaves $master] {
	    if {[string match "$master.$what@*" $qq]} {
		grid configure $qq -$other($what)span [expr {$span-1}]
	    }
	}
    }
}

# set the grid spacing to match the configuration info
#   master:  Which table

proc grid_spacing {master} {
    foreach what {row column} {
	set $what 0
	foreach width [::widget::geometry $master min_${what}] \
	    resize [::widget::geometry $master resize_${what}] {
	    grid ${what}configure $master [incr $what 2] -minsize $width \
		-weight [expr {$resize<2?1:1000}]
	}
    }
}

# turn a grid on/off - specify its size

proc grid_resize {win {size 3}} {
    if {$size == "on"} {set size 3}
    if {$size == "off"} {set size 0}
    foreach {cols rows} [grid size $win] {}
    for {set row 1} {$row < $rows} {incr row 2} {
	append row_list " $row"
    }
    for {set col 1} {$col < $cols} {incr col 2} {
	append col_list " $col"
    }
    foreach qq $col_list {
	grid columnconfigure $win $qq -minsize $size
    }
    foreach qq $row_list {
	grid rowconfigure $win $qq -minsize $size
    }
}

# insert a row or column into a grid - invoked from a grid-window binding
# Then update the grid as needed

proc grid_insert {win} {
    set what [split [winfo name $win] @]
    set master [winfo parent $win]
    set index [lindex $what 1]
    set what [lindex $what 0]
    table_insert $master $what [incr index]

    grid_process $master $what 1
    update_table $master "insert $what $index"
}

# return the current size that a grid line show be.
# takes into account whether the user wants to see grid lines.
proc grid_line_size {} {
    return [expr {$::P(show-grid) ? $::P(grid_size) : 0}]
}

# check the grid to see if it needs to be bigger
#
proc grid_process {master what {always 0}} {
    if {$always || [grid_check $master $what]} {
	if {$what == "row"} {
	    set color [$master.column@1 cget -bg]
	} else {
	    set color [$master.row@1 cget -bg]
	}
	set relief [$master.row@1 cget -relief]
	set index [grid_line $master $what $color [grid_line_size] $relief]
	grid_update $master
	grid_spacing $master
	# need to have the new shape by here (we don't)
	arrow_create $::W(CAN_$what) $what $master

	# this is overkill!
	arrow_activate $::W(CANVAS) $::Current(frame)	;# temporary?

	return 1
    }
    return 0
}

# change the color of a grid (to make it invisible?)

proc grid_color {master color} {
    if {![winfo exists $master.row@1] || [$master.row@1 cget -bg] eq $color} {
	return 0
    }
    set list [info commands $master.*@*]
    foreach line $list {
	$line configure -bg $color
    }
    return 1
}

# Allow the users to drag a line left or right with the cursor over
# the grid line.

proc grid_down {gridwin distcolumn distrow} {
    upvar \#0 X0 offcolumn Y0 offrow
    set parent [winfo parent $gridwin]

    regexp {.*\.([^@\.]*)@([0-9]*)$} $gridwin dummy what index
    incr distcolumn [expr {0 - [winfo rootx $parent]}]
    incr distrow    [expr {0 - [winfo rooty $parent]}]
    foreach {column row} [grid location $parent $distcolumn $distrow] {}
    incr $what -1
    foreach {ocolumn orow columnsize rowsize} [grid bbox $parent $column $row] {}
    set ::Current(startw) [expr {[set ${what}size] - [set off$what]}]
}

bind enterblocker <Enter> { _enterblocker }
bind enterblocker <Leave> { _enterblocker }
proc _enterblocker {} { set TCL_BREAK 3; return -code $TCL_BREAK }

proc grid_start_sweep {gridwin distcolumn distrow} {
    bindtags $gridwin [concat enterblocker [bindtags $gridwin]]
    regexp {.*\.([^@\.]*)@([0-9]*)$} $gridwin dummy what index
    set w [set ::Current(resize_widget) $::Current(widget)]
    if {$w ne "" && [winfo exists ${w}_outline]} {
	array set ginfo [grid info $w]
	grid ${w}_outline -sticky nsew \
	    -row $ginfo(-row) -column $ginfo(-column) \
	    -rowspan $ginfo(-rowspan) -columnspan $ginfo(-columnspan)
    }
}

proc grid_sweep {gridwin curcolumn currow} {
    regexp {.*\.([^@\.]*)@([0-9]*)$} $gridwin dummy what index
    if {$index < 2} return
    incr index -1
    set minsize [expr {$::Current(startw) + [set cur$what]}]
    if {$minsize < 0} { set minsize 0 }
    grid ${what}configure [winfo parent $gridwin] $index -minsize $minsize
    arrow_update_one $::W(CANVAS) $::Current(frame) $what $index
    status_message "$what [expr {$index/2}] size $minsize"
}

proc grid_end_sweep {gridwin curcolumn currow} {
    upvar #0 X0 offcolumn Y0 offrow
    set parent [winfo parent $gridwin]
    regexp {.*\.([^@\.]*)@([0-9]*)$} $gridwin dummy what index
    set idx [expr {($index/2-1)}]
    if {$idx < 0} { set idx 0 }
    set val [lindex [::widget::geometry $parent min_$what] $idx]
    set size [expr {$val + [set cur$what] - [set off$what]}]
    if {$size < 2} { set size 2 }
    ::resize::min_set $parent $what $index $size
    bindtags $gridwin [lrange [bindtags $gridwin] 1 end]
    update_table $parent arrow_move
}

proc grid_up {gridwin curx cury} {
    ::palette::unselect *
    select_grid $gridwin
    sync_all
}

proc select_grid {gridwin} {
    regexp {.*\.([^@\.]*)@([0-9]*)$} $gridwin dummy what index

    if {[winfo exists $gridwin]} {
	set ::Current(gridline) $gridwin
	$gridwin config -bg $::P(grid_highlight)
	bindtags $gridwin [concat enterblocker [bindtags $gridwin]]
    }
}

proc unselect_grid {} {
    if {![info exists ::Current(gridline)]} { return }
    set w $::Current(gridline)
    if {[winfo exists $w]} {
	$w config -bg $::P(grid_color)
	bindtags $w [lrange [bindtags $w] 1 end]
    }
    set ::Current(gridline) {}
}


# Refresh the grid lines with a new size
# We may want to check on ::main::gridsizeon whether the users wants
# to display grid lines right now
proc grid_update_size {{size -1}} {
    if {$size < 0} { set size [grid_line_size] }
    foreach i [array names ::Frames] {
	grid_resize $i $size
	update_table $i grid
    }
}
