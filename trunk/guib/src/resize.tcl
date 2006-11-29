# resize.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# manage resize behavior of rows and columns
# Each row or column is either resizable, or not.  The data associated
# with the resize behavior is kept in a list, one element per row/col, 
# kept in the frame's widget array in the options resize_row and
# resize_column.
# Since weight_row & weight_column were introduced this is really double
# work. Preserved for backward compatibility. (MSJ July 2001)

namespace eval ::resize {}

# Each element may have the following values:
#	0  don't resize (the default)
#	1  don't resize (Specified by the user)
#	2  resize - picked by the ui builder
#	3  resize - picked by the user

# In addition, min_row and min_column is a list of minimum row and
# column sizes, which track along with the resize behavior

# insert a new row/column onto the resize list
#   table:  Which frame the grid belongs to
#   what:   row/column
#   index:  Which row or column #

proc resize_insert {table what index {resize 0} {min 0} {pad 0}} {
    set weight [expr {$resize>1}]
    set index [expr {$index/2 -1}]
    if {$index < 0} return

    if {!$min} { set min $::P(grid_spacing) }

    if {[::widget::exists $table GM:resize_$what]} {
	foreach {item val} [list resize_$what $resize weight_$what $weight \
				min_$what $min pad_$what $pad] {
	    ::widget::geometry $table $item \
		[linsert [::widget::geometry $table $item] $index $val]
	}
	set i 2
	foreach qq [::widget::geometry $table resize_$what] {
	    if {$qq < 2} {
		set wt 1
	    } else {
		set wt 1000
	    }
	    grid ${what}configure $table $i -weight $wt
	    incr i 2
	}
	arrow_shapeall $::W(CANVAS) $table $what
    } else {
	::widget::geometry $table resize_$what $resize \
	    weight_$what $weight min_$what $min pad_$what $pad
    }

    ::resize::configure $table $what
}

# delete a row or column from the resize list

proc resize_delete {table what index} {
    set index [expr {$index/2 -1}]
    catch {
	foreach {item} [list resize_$what weight_$what min_$what pad_$what] {
	    ::widget::geometry $table $item \
		[lreplace [::widget::geometry $table $item] $index $index]
	}
	arrow_shapeall $::W(CANVAS) $table $what
    }
    # set shown row/column padding
    ::resize::configure $table $what
}

# initialize a resize list
# Args are subject to change
# This routine will probably go away

proc resize_init {table rows cols} {
    if {![::widget::exists $table GM:resize_column]} {
	while {[incr cols -1] >= 0} {
	    lappend col 0
	    lappend col2 $::P(grid_spacing)
	}
	::widget::geometry $table resize_column $col \
	    weight_column $col min_column $col2 pad_column $col
    }
    if {![::widget::exists $table GM:resize_row]} {
	while {[incr rows -1] >= 0} {
	    lappend row 0
	    lappend row2 $::P(grid_spacing)
	}
	::widget::geometry $table resize_row $row \
	    weight_row $row min_row $row2 pad_row $row
    }
    # Visualise row/column -pad & -minsize
    foreach what {row column} {
	::resize::configure $table $what
    }
}

proc ::resize::configure {table what} {
    set i 2
    foreach pad [::widget::geometry $table pad_$what] \
	min [::widget::geometry $table min_$what] {
	grid ${what}configure $table $i -pad $pad -minsize $min
	incr i 2
    }
}

# set/clear/or toggle the resize behavior

proc resize_set {table what idx {value ""}} {
    set idx [expr {$idx/2 -1}]

    set current [lindex [::widget::geometry $table resize_$what] $idx]
    if {$value == ""} {
	set value [expr {$current<2 ? 3 : 1}]
    }
    if {$value < 2} {
	set weight 0
    } elseif {[set val [lindex [::widget::geometry $table weight_$what] $idx]] > 0} {
	set weight $val
    } else {
	set weight 1
    }
    ::widget::geometry $table resize_$what \
	[lreplace [::widget::geometry $table resize_$what] $idx $idx $value]
    ::widget::geometry $table weight_$what \
	[lreplace [::widget::geometry $table weight_$what] $idx $idx $weight]
    return $value
}

# set the min size value

proc ::resize::min_set {table what idx value} {
    if {$idx > 1} {
	set idx [expr {$idx/2 -1}]
	set min [::widget::geometry $table min_$what]
	::widget::geometry $table min_$what [lreplace $min $idx $idx $value]
	return $value
    }
}
