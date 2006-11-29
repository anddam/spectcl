# bindings.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::bind {
    # These are used for the button bindings
    variable LOST 1	;# true if we lost a button push
    variable NEWHIT 0	;# true if this is a new hit
}

# bind::init --
#
#	Initializes the bindings for the gui builder to function.
#	These are the system wide bindings.
#
proc ::bind::init {root canvas master args} {
    # set binding to propagate geometry changes
    bind widget <Configure> { ::bind::widget_Configure %W }

    # double click on a widget to bring up
    bind widget <Double-1> {::bind::widget_Double1 [::widget::root %W]; break}

    bind $root <Configure> [list ::bind::root_Configure $root %W]

    # If no palette type is on, then
    # "deselect" when button press outside active region,
    # else extend the palette and drop the widget in there.
    bind $canvas <1> { ::bind::can_button %x %y }

    # select row&col when clicking in an empty grid
    bind $master <1> { grid_single_click %W %x %y }

    # highlight a grid line, for easier identification
    bind grid <Enter>    { ::bind::GridEnter %W }
    bind grid <Leave>    { ::bind::GridLeave %W }
    bind grid <Double-1> { ::bind::GridDouble1 }
}

proc ::bind::widget_Double1 {w} {
    # double-click on a widget brings it the properties dialog
    ::palette::activate app 1 $w
}

proc ::bind::root_Configure {root w} {
    if {$root eq $w} {
	# Only store WxH as +X+Y may not still be valid [Bug #30826]
	regexp {^\d+x\d+} [wm geometry $root] ::P(rootGeometry)
    }
}

proc ::bind::widget_Configure {w} {
    # see if a configuration change to a widget requires a table update
    # name:	The name of the window that got a configure event
    # This still forces updates even when none are needed
    if {!$::Arrow_move && !$::Down && [::widget::exists $w]} {
	set master [::widget::data $w master]
	if {$master ne ""} {
	    update_table $master "configure $w"
	}
    }
}

proc ::bind::can_button {x y} {
    if {$::Current(palette_widget) != "" && [set code [extend_canvas]] == 1} {
	grid_single_click $::W(FRAME) $x $y
    } elseif {![info exists code] || $code == 0} {
	::palette::unselect *
	current_frame $::W(FRAME)
	sync_all
    }
}

proc ::bind::extend_canvas_ok {w ok} {
    variable _ok $ok
    grab release $w
    wm withdraw $w
}

# extend_canvas returns 1 == Extend Canvas; 0 == Unselect All; -1 == Cancel
#
proc ::bind::extend_canvas {} {
    global P W
    variable _ok 1
    if {$P(confirm-auto-extend)} {
	set w .__askAutoExtend
	set root $::W(ROOT)
	if {![winfo exists $w]} {
	    toplevel $w
	    wm withdraw $w
	    wm title $w "Auto Extend Canvas?"

	    radiobutton $w.auto  -text "Automatically Extend Canvas" \
		    -variable ::P(auto-extend-canvas) -value 1
	    radiobutton $w.unsel -text "Unselect All" \
		    -variable ::P(auto-extend-canvas) -value 0
	    checkbutton $w.dont -variable ::P(confirm-auto-extend) \
		    -text "Do not ask me again." -onvalue 0 -offvalue 1
	    frame $w.div -height 2 -bd 1 -relief raised
	    frame $w.btns
	    button $w.ok     -width 8 -default active -text "OK" \
		    -command [list ::bind::extend_canvas_ok $w 1]
	    button $w.cancel -width 8 -default normal -text "Cancel" \
		    -command [list ::bind::extend_canvas_ok $w 0]
	    grid $w.auto  -padx 14 -sticky w
	    grid $w.unsel -padx 14 -sticky w
	    grid $w.dont -padx 4 -sticky w
	    grid $w.div -sticky ew

	    grid $w.btns -sticky e
	    grid $w.ok $w.cancel -in $w.btns -pady 4 -padx 4 -sticky e
	    wm resizable $w 0 0
	    wm transient $w $root
	}
	::tk::PlaceWindow $w widget $root
	tkwait visibility $w
	grab $w
	focus $w.ok
	vwait ::bind::_ok
    }
    if {$::bind::_ok} {
	return $P(auto-extend-canvas)
    } else {
	return -1
    }
}

proc grid_single_click {w x y} {
    global Current

    if {$Current(palette_widget) != ""} {
	# translate to global coords
	set gx $x
	set gy $y

	#Translate to global coords
	incr x [winfo rootx $w]
	incr y [winfo rooty $w]
	if {[::gui::isContainer $w] || [::widget::isFrame $w]} {
	    # This is the container or a frame
	    set enclosinggrid [find_grid $x $y]
	    if {$enclosinggrid ne $Current(frame)} {
		current_frame $w
	    }
	    set ::In_view 1
	    set ::Where [find_slot $Current(frame) $x $y ::Row ::Col]
	    set tempframe $Current(frame)
	    set result [palette_end_sweep $Current(palette_widget) $x $y]
	    if {$result eq "occupied"} {
		::palette::select widget $w 1
	    } elseif {$result eq "offtable"} {
		::palette::unselect *
		current_frame $w
		select_rowcol $gx $gy
		grid_single_click $w $gx $gy
	    } else {
		current_frame $tempframe
	    }
	} elseif {$w ne $Current(widget)} {
	    ::palette::select widget $w 1
	}
	if {!$::P(sticky-palette) ||
		[string match -nocase *frame* $Current(palette_widget)]} {
	    ::palette::unselect palette
	}
    } elseif {[::gui::isContainer $w] || [::widget::isFrame $w]} {
	if {[::gui::isContainer $w] || $w eq $Current(widget)} {
	    current_frame $w
	    select_rowcol $x $y
	} else {
	    ::palette::select widget $w 1
	}
    } elseif {$w ne $Current(widget)} {
	::palette::select widget $w 1
    }
}

# given an x,y position on the current grid, select the row/column

proc select_rowcol {x y} {
    ::palette::unselect *
    set frame $::Current(frame)
    foreach {col row} [grid location $frame $x $y] {}
    ::arrow::highlight row    $frame $row $::P(grid_highlight)
    ::arrow::highlight column $frame $col $::P(grid_highlight)
}

proc ::bind::GridEnter {w} {
    variable cache_grid_color [$w cget -bg]
    $w configure -bg $::P(generic_over_color)
}

proc ::bind::GridLeave {w} {
    variable cache_grid_color
    if {[info exists cache_grid_color]} {
	$w configure -bg $cache_grid_color
    }
}

proc ::bind::GridDouble1 {} {
    mainmenu_insert
    set ::Current(startw) {}
}

#
# Here are the procs for handling just the button sweeping
# (palette to canvas, widgets around canvas, subwidgets ...)
#
proc ::bind::btnPress {prefix btn state X Y args} {
    variable LOST	0
    variable NEWHIT	$btn

    # Used to know which button is down, if any
    set ::Down		$btn

    # Used to know if we want copy vs. move in the canvas
    set ::Shift		[expr {$state & 1}]
    set ::Alt		[expr {($state & 64) > 0}]
    set ::Control	[expr {($state & 4) > 0}]

    # Used for checking mouse gravity
    set ::X0		$X
    set ::Y0		$Y

    eval [list ${prefix}_down] $args
    update idletasks
}
proc ::bind::btnMotion {prefix btn tag W X Y args} {
    variable LOST
    if {$LOST} {
	# somehow we got here without a matching btnPress
	return
    }
    variable NEWHIT
    if {$NEWHIT} {
	if {[button_gravity $X $Y]} { return }
	set NEWHIT 0
	# user just started moving the mouse
	eval [list ${prefix}_start_sweep] $args
    } else {
	# user has been moving the mouse
	eval [list ${prefix}_sweep] $args
    }
    update idletasks
}
proc ::bind::btnRelease {prefix args} {
    variable LOST
    variable NEWHIT
    set ::Down 0
    if {$LOST} {
	# somehow we got here without a matching btnPress
	return
    }
    set LOST 1
    # grab release [grab current %W]
    if {$NEWHIT} {
	# user released without moving the mouse
	eval [list ${prefix}_up] $args
    } else {
	# user released after moving the mouse
	eval [list ${prefix}_end_sweep] $args
    }
    update idletasks
}

# setup the bindings for widgets of a class
#  tag		The window or tag to bind to this button
#  btn		The button number to bind to
#  prefix	The function prefix for the binding procedures
#    <prefix>_down:  The button went down
#    <prefix>_start_sweep	We started a sweep
#    <prefix>_sweep			We are sweeping
#	 <prefix>_end_sweep		We ended the sweep (button up)
#	 <prefix>_up			button up - no sweep
#    each proc gets "%W %X %Y" by default
#  gravity	The amount of sweeping needed to cause a "sweep"
#  args		The arguments passed to the button functions
#
#  Calling sequences:
#	 down -> up
#    down -> start_sweep -> [sweep] -> end_sweep

proc ::bind::setup {tag prefix {params {%W %X %Y}}} {
    # set the bindings
    set btn	1

    bind $tag <Button-$btn> \
	    "[list ::bind::btnPress $prefix $btn %s %X %Y] $params; break"

    bind $tag <B${btn}-Motion> \
	    "[list ::bind::btnMotion $prefix $btn $tag \
	    %W %X %Y] $params; break"

    bind $tag <ButtonRelease-${btn}> \
	    "[list ::bind::btnRelease $prefix] $params; break"
}

# return true if gravity is still on (we haven't moved enough pixels)
# X0 and Y0 (globals) containing the gravitational center

proc button_gravity {x y} {
    return [expr {(abs($x-$::X0) + abs($y-$::Y0)) < $::P(gravity)}]
}
