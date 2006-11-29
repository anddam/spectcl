# outline.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# Outlines serve 2 purposes.
# 1) The function as a container to hold the resize handles
# 2) They "block out" the parts of grid lines for widgets that span
#    multiple rows or columns

# Outlines are expensive to maintain, so create
# them only if a widget has a row or column span > 1 *OR* the widget
# is currently selected - so the resize handles will show.
# This should be re-coded to avoid using variable traces, which tend to
# be hard to debug, and can have subtle side effects

# the outline is drawn as a child of the frame the widget is managed in, so
# it is easy to find all outlines for a given frame, in case we need to
# change their color.

namespace eval ::outline {}

# create or destroy an outline for a window
#
#   w:   The widget that needs an outline
#
proc ::outline::outline {w} {
    if {$::Current(widget) eq $w && [::widget::exists $w]} {
	activate $w
    }
}

# actually make the outline for a window
# outline names end in "_outline", and are children of the widget's master
#  name:  The name of the widget to make an outline for

proc ::outline::activate {w} {
    if {[::gui::isContainer $w]} { return }

    set outline ${w}_outline
    if {![winfo exists $outline]} {
	set bg [[::widget::data $w master] cget -bg]
	frame $outline -bg $bg
    }

    lower $outline $w
    refresh $w
}

# destroy the outline, and any resize handles
# The resize handles will be "placed" in the outline, but
# they are not children of the outline
#  called in delete_selected_widget
proc ::outline::remove {w} {
    set outline ${w}_outline
    if {[winfo exists $outline]} {
	eval destroy [place slaves $outline] [list $outline]
    }
}

# update the highlight regions for a frame
# This is called whenever the table geometry of a master changes, which
# causes the outline's size and location to change

# This finds too many outlines when the master is the toplevel frame

proc ::outline::refresh {w} {
    set outline ${w}_outline
    if {[winfo exists $outline]} {
	array set ginfo [grid info $w]
	grid $outline -in $ginfo(-in) -sticky nsew \
	    -row    $ginfo(-row)    -rowspan    $ginfo(-rowspan) \
	    -column $ginfo(-column) -columnspan $ginfo(-columnspan)
	if {[winfo exists ${w}_highlight]} {
	    lower $outline ${w}_highlight
	}
    }
}
