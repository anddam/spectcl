# scroll.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# figure out how to attach scroll bars

namespace eval ::scroll {}


proc ::scroll::get_x_tree {{node ""}} {
    # Create the tree struct for the droptree.  If we had one before, then
    # destroy that and start again.
    variable XTREE
    if {![info exists XTREE]} {
	set XTREE [::struct::tree::tree ::config::XTREE]
    }
    if {$node != ""} {
	return [$XTREE get $node]
    } else {
	return $XTREE
    }
}

proc ::scroll::get_y_tree {{node ""}} {
    # Create the tree struct for the droptree.  If we had one before, then
    # destroy that and start again.
    variable YTREE
    if {![info exists YTREE]} {
	set YTREE [::struct::tree::tree ::config::YTREE]
    }
    if {$node != ""} {
	return [$YTREE get $node]
    } else {
	return $YTREE
    }
}


proc ::scroll::update_trees {args} {
    set xtree [get_x_tree]
    set ytree [get_y_tree]

    # clear whatever may be in the trees
    foreach child [$xtree children root] { $xtree delete $child }
    foreach child [$ytree children root] { $ytree delete $child }

    # Allow users to empty out the attachment
    $xtree insert root end ""
    $xtree set "" "(NONE)"
    $xtree set "" -key image frame.gif
    $ytree insert root end ""
    $ytree set "" "(NONE)"
    $ytree set "" -key image frame.gif

    # find scrollbars and scrollable items by row (y) and column (x)
    foreach w [lsort -dictionary [::widget::widgets "Tk scrollbar"]] {
	if {[string match v* [::widget::data $w -orient]]} {
	    # vertical / row / y type scrollbar
	    set tree $ytree
	} else {
	    # horizontal / column / x type scrollbar
	    set tree $xtree
	}
	$tree insert root end $w
	$tree set $w [::widget::data $w ID]
	$tree set $w -key image scrollbar.gif
    }

    return [list [expr {[$xtree size]-1}] [expr {[$ytree size]-1}]]
}

# scroll_attach --
#
# Attach a single scrollbar to the nearest appropriate widget.
#
proc ::scroll::attach {w} {
    variable W

    set scrollok(x) [::widget::exists $w -xscrollcommand]
    set scrollok(y) [::widget::exists $w -yscrollcommand]

    set id [::widget::data $w ID]
    if {!$scrollok(x) && !$scrollok(y)} {
	tk_messageBox -title "Unable to Attach Scrollbars" -icon error \
	    -type ok -message "$id is not a scrollable widget"
	return
    }

    foreach {scrollable(x) scrollable(y)} [::scroll::update_trees] break
    if {!$scrollable(x) && !$scrollable(y)} {
	tk_messageBox -title "Unable to Attach Scrollbars" -icon error \
	    -type ok -message "There are either no scrollbars to attach"
	return
    }

    set W(root) [set top .__top_scroll_attach]
    if {![winfo exists $top]} {
	toplevel $top
	wm withdraw $top
	wm protocol $top WM_DELETE_WINDOW [list wm withdraw $top]
	wm transient $top $::W(ROOT)
	wm title $top "Attach Scrollbars"

	set btns [ttk::frame $top.b]
	ttk::button $btns.ok  -width 8 -text "OK" -default active \
	    -command [subst { ::scroll::apply; wm withdraw $top }]
	ttk::button $btns.can -width 8 -text "Cancel" \
	    -command [subst { wm withdraw $top }]

	grid x $btns.ok $btns.can -padx 4 -pady {6 4}
	grid configure $btns.can -padx [list 4 [pad corner]]
	grid columnconfigure $btns 0 -weight 1

	bind $top <Return> [list $btns.ok invoke]
	bind $top <Escape> [list $btns.can invoke]

	# This will id the widget we are attaching to.
	set W(FRAME) [set lf [ttk::labelframe $top.lf \
				  -padding [pad labelframe]]]

	# Use droptrees to display available scrollbars
	ttk::label $lf.lxscroll -anchor w \
	    -text "Horizontal (X) scrollbar to attach:"
	set W(SCROLLx) [Droptree $lf.dxscroll -tree [get_x_tree] -editable no]
	ttk::label $lf.lyscroll -anchor w \
	    -text "Vertical (Y) scrollbar to attach:"
	set W(SCROLLy) [Droptree $lf.dyscroll -tree [get_y_tree] -editable no]

	grid $lf   -row 0 -sticky nsew -padx 5 -pady 5
	grid $btns -row 1 -sticky ew
	grid rowconfigure    $top 0 -weight 1
	grid columnconfigure $top 0 -weight 1

	grid $lf.lxscroll -row 0 -column 0 -sticky ew -padx {5 0} -pady 4
	grid $lf.dxscroll -row 0 -column 1 -sticky ew -padx {0 5} -pady 4
	grid $lf.lyscroll -row 1 -column 0 -sticky ew -padx {5 0} -pady 4
	grid $lf.dyscroll -row 1 -column 1 -sticky ew -padx {0 5} -pady 4
	grid rowconfigure    $lf 2 -weight 1
	grid columnconfigure $lf 1 -weight 1

	::gui::PlaceWindow $top widget $::W(ROOT)
    }

    $W(FRAME) configure -text "Attach to [::widget::type $w] $id: "
    set W(widget) [winfo name $w]
    set W(lastx) ""
    set W(lasty) ""

    foreach dim {x y} {
	set ds $W(SCROLL$dim)
	$ds refresh

	if {!$scrollok($dim) || !$scrollable($dim)} {
	    $ds configure -state disabled
	} else {
	    # update to show what might already be associated
	    $ds configure -state normal
	    if {[regexp {^< scroll (\S+) set >$} \
		     [::widget::data $w -${dim}scrollcommand] -> win]} {
		set W(last$dim) $win
	    }
	}
	$ds setvalue $W(last$dim)
    }

    wm deiconify $top
    raise $top
}

proc ::scroll::apply {} {
    variable W

    foreach dim {x y} {
	set ds $W(SCROLL$dim)
	if {[$ds cget -state] eq "normal"} {
	    # this is the ID.  We need the real name.
	    # return the real name of a widget given the ID
	    set name [$ds getvalue]
	    foreach w [::widget::widgets] {
		if {[::widget::data $w ID] eq $name} { break }
	    }
	    # the value for a scrollbar may be "", which means set command
	    # to empty.
	    associate $W(widget) $w $W(last$dim) $dim
	}
    }
}

# associate --
#
# configure the scroll bar and its associated widget to make the attachment
#
# widget  - widget to bind to scrollbar
# newsbar - scrollbar to attach
# oldsbar - scrollbar to which widget was attached
# which   - x|y
proc ::scroll::associate {widget newsbar oldsbar which} {
    if {$newsbar eq $oldsbar} return
    if {$newsbar == ""} {
	# this means we should empty out the command
	::widget::data $widget -${which}scrollcommand ""
    } else {
	::widget::data $newsbar -command \
	    [list < scroll $widget ${which}view >]
	::widget::data $widget -${which}scrollcommand \
	    [list < scroll $newsbar set >]
    }
    if {$oldsbar != ""} {
	::widget::data $oldsbar -command ""
    }
}

# scroll_attach_magic --
#
# The original Attach Scrollbars proc that attached all scrollbars
# based on the nearest scrollbar to an appropriately scrollable widget
# in the same row/column.
#
proc scroll_attach_magic {} {
    # find scrollbars and scrollable items
    set scrollbars ""
    array set scrollable {row "" column ""}
    foreach w [::widget::widgets] {
	if {[::widget::exists $w -yscrollcommand]} {
            lappend scrollable(row) $w
        }
	if {[::widget::exists $w -xscrollcommand]} {
            lappend scrollable(column) $w
        } elseif {[::widget::type $w] eq "scrollbar"} {
            lappend scrollbars $w
        }
    }

    # FIX: XXX narrow candidates for each scrollbar based on row/column

    # start assigning scrollbars
    # do the easy ones first (1 candidate), then remove candidate from lists

    set assign 1
    while {$assign && [set list [array names candidate]] != ""} {
	set assign 0

	# process all scrollbars with 1 possible entry

	foreach i $list {
	    if {[llength $candidate($i)] == 1} {
		# bind $i to $candidate($i)
		scroll_associate $i $candidate($i) $orient($i)
		set assign 1
		lappend done($candidate($i)) $orient($i)
		unset candidate($i)
	    }
	}
	# puts "new candidate list"
	# parray candidate
	# puts "assigned widgets"
	# parray done

	# remove assigned widgets (slow for now)

	foreach i [array names candidate] {
	    set list $candidate($i)
	    foreach j [array names done] {
		if {[lsearch -exact $done($j) $orient($i)] == -1} continue
		if {[set found [lsearch -exact $list $j]] != -1} {
		    set candidate($i) [lreplace $list $found $found]
		}
	    }
	}
	catch {unset done}
    }
    return "$num_scrolls scrollbar(s) found"
}

# configure the scroll bar and its associated widget to make the attachment

proc scroll_associate {scroll widget orient} {
    if {$orient eq "column"} {
	::widget::data $scroll -command [list < scroll $widget xview >]
	::widget::data $widget -xscrollcommand [list < scroll $scroll set >]
    } else {
	::widget::data $scroll -command [list < scroll $widget yview >]
	::widget::data $widget -yscrollcommand [list < scroll $scroll set >]
    }
}
