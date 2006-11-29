# pref_appearance_ui.tcl --
#
#	This file implements the preferences Appearance tab.
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
namespace eval ::prefs {}

proc ::prefs::select_color {type cacheVar {color ""}} {
    variable W
    set w $W(color,$type)
    if {$color == ""} {
	# If a color wasn't specified, then query the user
	set color [tk_chooseColor -parent $w \
		-initialcolor [set ${cacheVar}($type)]]
    }
    if {$color != ""} {
	set ${cacheVar}($type) $color
	$w configure -bg $color -activebackground $color
    }
}

#   root     is the parent window for this user interface
proc ::prefs::ui_appearance {root cacheVar args} {
    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]
    variable W

    ##
    set cframe [ttk::labelframe $base.colors -text "Colors:" \
		    -padding [pad labelframe]]

    set i 0
    set j 0
    foreach {color label comment}  {
	grid_highlight		"Selection Color:"
	"The color of the selected widget or grid line"
	generic_over_color	"Active Over Color:"
	"The color for hovering over grid lines or empty cells"
	grid_color		"Grid Background:"
	"The background for the grid line elements"
	frame_bg		"Frame Background:"
	"The background for the empty space in grid elements"
    } {
	set W(color,$color) $cframe.$color
	ttk::label $cframe.l$color -text $label -anchor e
	if {$::AQUA} {
	    label $cframe.$color -text " " -bd 1 -relief raised -width 2 \
		-highlightthickness 0
	    bind $cframe.$color <ButtonRelease-1> \
		[namespace code [list select_color $color $cacheVar]]
	} else {
	    button $cframe.$color -padx 0 -pady 0 -bd 1 -width 3 \
		-command [namespace code [list select_color $color $cacheVar]]
	}
	grid $cframe.l$color -row $i -column $j -sticky e
	grid $cframe.$color  -row $i -column [incr j] -sticky news \
	    -pady 2 -padx 2
	help::balloon $cframe.$color $comment
	incr j
	if {$j > 3} {
	    incr i
	    set j 0
	}
    }

    grid $base.colors -row 0 -column 0 -columnspan 4 -sticky ew

    ##
    set gframe [ttk::labelframe $base.grid -text "Workspace Grid:" \
		    -padding [pad labelframe]]

    grid $base.grid -row 2 -column 0 -columnspan 4 -sticky ew
    grid columnconfigure $gframe 2 -weight 1

    ##
    ttk::checkbutton $gframe.showgrid -text "Show Grid Lines" \
	    -variable ${cacheVar}(show-grid)
    help::balloon $gframe.showgrid \
	    "Whether to display the workspace grid lines normally\
	    \nor minimize them to reduce visual interference"

    grid $gframe.showgrid -row 0 -column 0 -columnspan 2 -sticky w

    ##
    ttk::label $gframe.glabel -text "Grid Line Thickness: " -anchor e
    if {$::AQUA} {
	set m $gframe.gsize.menu
	ttk::menubutton $gframe.gsize -menu $m -width 2 -direction flush \
	    -textvariable ${cacheVar}(grid_size)
	menu $m
	for {set i 1} {$i <= 8} {incr i} {
	    $m add radiobutton -label $i -value $i \
		-variable ${cacheVar}(grid_size)
	}
    } else {
	spinbox $gframe.gsize -width 3 -from 1 -to 8 -increment 1 \
	    -validate key -validatecommand {string is integer %P} \
	    -textvariable ${cacheVar}(grid_size) \
	    -state readonly -readonlybackground white
    }
    set help "The thickness of the workspace grid line elements"
    help::balloon $gframe.glabel $help
    help::balloon $gframe.gsize $help

    grid $gframe.glabel -row 1 -column 0 -sticky ew
    grid $gframe.gsize  -row 1 -column 1 -sticky ew

    ##
    ttk::label $gframe.dlabel -text "Default Grid Spacing:"
    if {$::AQUA} {
	set m $gframe.dsize.menu
	ttk::menubutton $gframe.dsize -menu $m -width 2 -direction flush \
	    -textvariable ${cacheVar}(grid_spacing)
	menu $m
	for {set i 15} {$i <= 60} {incr i 5} {
	    $m add radiobutton -label $i -value $i \
		-variable ${cacheVar}(grid_spacing)
	}
    } else {
	spinbox $gframe.dsize -width 3 -from 15 -to 60 -increment 15 \
	    -validate key -validatecommand {string is integer %P} \
	    -textvariable ${cacheVar}(grid_spacing)
    }
    set help "Default minimum grid element spacing"
    help::balloon $gframe.dlabel $help
    help::balloon $gframe.dsize $help

    grid $gframe.dlabel -row 0 -column 2 -sticky e
    grid $gframe.dsize  -row 0 -column 3 -sticky w

    ##
    ttk::label $gframe.rlabel -text "Widget Handle Size:"
    if {$::AQUA} {
	set m $gframe.rsize.menu
	ttk::menubutton $gframe.rsize -menu $m -width 2 -direction flush \
	    -textvariable ${cacheVar}(resize_handles)
	menu $m
	for {set i 0} {$i <= 4} {incr i} {
	    $m add radiobutton -label $i -value $i \
		-variable ${cacheVar}(resize_handles)
	}
    } else {
	spinbox $gframe.rsize -width 3 -from 0 -to 4 -increment 1 \
	    -validate key -validatecommand {string is integer %P} \
	    -textvariable ${cacheVar}(resize_handles) \
	    -state readonly -readonlybackground white
    }
    set help "Size of control points for row/column spanning\
	    \nthat are displayed on the selected widget"
    help::balloon $gframe.rlabel $help
    help::balloon $gframe.rsize $help

    grid $gframe.rlabel -row 1 -column 2 -sticky e
    grid $gframe.rsize  -row 1 -column 3 -sticky w

    # Geometry management

    grid rowconfigure    $root 6 -weight 1
    grid columnconfigure $root 0 -weight 1
    grid columnconfigure $root 2 -weight 1
}
