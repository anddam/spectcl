# toolbar.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# toolbar management routines

# create the toolbar.  Its hardwired for now, but should be user programmable
# Each toolbar has 3 procedures:
#  sync_<tool> win [options...] - to make tool value current with "win"
#  set_<tool>  win		- to make the tool take affect

namespace eval ::tbar {
    # this will contain the list of toolbar windows to sync
    variable TOOLS
    variable DEFS

    catch {font create smallfont -family Helvetica -size -9}
}; # create tbar (toolbar) namespace

proc ::tbar::show {type {bool 0}} {
    variable show
    if {[llength [info level 0]] == 3} {
	set show($type) [string is true -strict $bool]
    }
    return [expr {[info exists show($type)] && $show($type)}]
}

proc ::tbar::create {win} {
    global P
    variable TOOLS
    variable DEFS
    variable ENTRY

    # All toolbar widgets start in a disabled state
    # ::tbar::sync_* will enable them, when applicable

    set column 0	;# which column

    ## SAVE icon
    set w [set TOOLS(save) $win.save]
    if {$::TILE} {
	ttk::button $w -style Slim.Toolbutton -image save.gif -takefocus 0 \
	    -state disabled -command [list ::tbar::invoke save]
	grid $w -in $win -row 0 -column [incr column] -pady 2 -padx 1
    } else {
	button $w -image save.gif -takefocus 0 -state disabled -bd 1 \
	    -command [list ::tbar::invoke save] -width 16 -height 16 \
	    -relief flat -overrelief raised
	grid $w -in $win -row 0 -column [incr column] -sticky s -pady 2 -padx 1
    }
    help::balloon $w "Save the current dialog"

    ## separator frame
    if {$::TILE} {
	set w [ttk::separator $win.sep$column -orient vertical]
    } else {
	set w [frame $win.sep$column -width 2 -relief sunken -bd 2]
    }
    grid $w -in $win -row 0 -column [incr column] -sticky ns -pady 1 -padx 1

    ## TEXT / LABEL field
    set w [set TOOLS(entry) $win.entry]
    set l [set ENTRY(label) $win.text_label]
    ttk::label $l -text "Text:" -state disabled
    ttk::entry $w -textvariable ::tbar::ENTRY(text) -width 14 \
	-validatecommand {::tbar::EntryChange %W %P %V} -validate all \
	-state disabled
    grid $l -in $win -row 0 -column [incr column] -pady 2 -sticky ns
    grid $w -in $win -row 0 -column [incr column] -pady 2 -sticky nsew
    help::balloon $w "Set the text of the widget"

    # set up bindings for immediate action on text entry

    bind $w <Return>    [list ::tbar::EntryConfirm $w]
    bind $w <Escape>    [list ::tbar::EntryEscape $w]
    bind $w <Tab>       { break }

    ## FONT style (name, size & style)
    set w [set TOOLS(font) $win.font]
    set DEFS(fontsize) 8
    set DEFS(style)    Bold
    SelectFont $w -type toolbar -styles {bold italic} \
	    -command [list ::tbar::selectfont set]
    selectfont disable
    # we remove the font name for now - to save space on the toolbar
    catch {pack forget $w.font}
    if {!$::AQUA} {
	catch {$w.size configure -bd 1; pack configure $w.size -fill y}
	catch {$w.bold configure -bd 1; pack configure $w.bold -fill y}
	catch {$w.italic configure -bd 1; pack configure $w.italic -fill y}
    }
    grid $w -in $win -row 0 -column [incr column] -padx 2 -pady 2 -sticky ns
    help::balloon $w "Set the font style of the widget"

    ## JUSTIFICATION
    set DEFS(justify) center
    set w [set TOOLS(justify) $win.justify]
    ttk::menubutton $w -menu $w.justify -image justify_$DEFS(justify).gif \
	    -state disabled
    menu $w.justify -tearoff 0
    foreach item {left center right} {
	if {$::AQUA} {
	    # Aqua doesn't handle images in menus yet
	    $w.justify add command -label [string totitle $item] \
		-command [list ::tbar::set_justify $w $item]
	} else {
	    $w.justify add command -image justify_$item.gif \
		-command [list ::tbar::set_justify $w $item]
	}
    }
    grid $w -in $win -row 0 -column [incr column]
    help::balloon $w "Multiline text justification: left, center or right"

    ## FOREGROUND and BACKGROUND color
    set w [set TOOLS(fgcolor) $win.fgcolor]
    if {$::TILE} {
	label $w -text "FG" -font smallfont -bd 1 -relief raised \
	    -highlightthickness 0 \
	    -state disabled \
	    -pady [pad toolbar] -padx [pad toolbar]
	bind $w <ButtonRelease-1> [list ::tbar::color_menu $w foreground]
	grid $w -in $win -row 0 -column [incr column] \
	    -padx {2 0} -pady 2
    } else {
	button $w -text "FG" -font smallfont -bd 1 -highlightthickness 0 \
	    -command [list ::tbar::color_menu $w foreground] -takefocus 0 \
	    -state disabled -pady 0 -padx 2
	grid $w -in $win -row 0 -column [incr column] \
	    -padx {2 0} -pady 2 -sticky ns
    }
    help::balloon $w "Set the foreground color of the widget"

    set w [set TOOLS(bgcolor) $win.bgcolor]
    if {$::TILE} {
	label $w -text "BG" -font smallfont -bd 1 -relief raised \
	    -highlightthickness 0 \
	    -state disabled \
	    -pady [pad toolbar] -padx [pad toolbar]
	bind $w <ButtonRelease-1> [list ::tbar::color_menu $w background]
	grid $w -in $win -row 0 -column [incr column] \
	    -padx {0 2} -pady 2
    } else {
	button $w -text "BG" -font smallfont -bd 1 -highlightthickness 0 \
	    -command [list ::tbar::color_menu $w background] -takefocus 0 \
	    -state disabled -pady 0 -padx 2
	grid $w -in $win -row 0 -column [incr column] \
	    -padx {0 2} -pady 2 -sticky ns
    }
    help::balloon $w "Set the background color of the widget"

    ## STICKY-ness
    # The size of the buttons on the bar
    if {$::AQUA} {
	set size 24
    } else {
	set size 18
    }
    set w [set TOOLS(sticky) $win.sticky]
    set DEFS(sticky) {}
    frame $w -width $size -height $size -relief raised -bd 1
    frame $w.b -width $size -height $size
    frame $w.stickyf -height [expr {$size*0.4}] -width [expr {$size*0.4}] \
	    -bg grey
    foreach s {nw ne sw se n s e w} {
	frame $w.s$s -width 2 -height 2 -bg gray -relief raised -bd 1
	grid $w.s$s -row 0 -column 0 -sticky $s
    }
    bind $w <ButtonRelease-1> \
	[list ::tbar::sticky_menu $w ::Current(widget) ::tbar::set_sticky]
    bindtags $w.stickyf [linsert [bindtags $w.stickyf] 0 $w]
    bindtags $w.b [linsert [bindtags $w.b] 0 $w]
    grid $w.b -row 0 -column 0 -sticky news
    grid $w.stickyf -row 0 -column 0
    if {$::TILE} {
	grid $w -in $win -row 0 -column [incr column] -pady 2 -padx 2
    } else {
	grid $w -in $win -row 0 -column [incr column] -sticky s -pady 2 -padx 2
    }
    help::balloon $w "Which side(s) of the cell to attach widget (-sticky)"

    ## RELIEF and BORDERWIDTH settings
    set w [set TOOLS(relief)      $win.relief]
    set w [set TOOLS(borderwidth) $win.relief]
    set DEFS(relief)      flat
    set DEFS(borderwidth) 0
    frame $w -width $size -height $size -relief raised -bd 1
    frame $w.b -width $size -height $size
    frame $w.rbf -height [expr {int($size*0.75)}] -bd 0 -relief flat \
	    -width [expr {int($size*0.75)}] -bg grey -bd 4
    bind $w <ButtonRelease-1> [list ::tbar::relief_menu $w]
    bindtags $w.rbf [linsert [bindtags $w.rbf] 0 $w]
    bindtags $w.b [linsert [bindtags $w.b] 0 $w]
    grid $w.b -row 0 -column 0 -sticky news
    grid $w.rbf -row 0 -column 0
    if {$::TILE} {
	grid $w -in $win -row 0 -column [incr column] -pady 2 -padx 2
    } else {
	grid $w -in $win -row 0 -column [incr column] -sticky s -pady 2 -padx 2
    }
    help::balloon $w "Set the borderwidth and relief of the widget"

    ## ORIENTATION (horizontal or vertical)
    set ::tbar::orient [set DEFS(orient) vertical]
    set w [set TOOLS(orient) $win.orient]
    if {$::TILE} {
	ttk::checkbutton $w -style Slim.Toolbutton -takefocus 0 \
	    -variable ::tbar::orient \
	    -offvalue vertical -onvalue horizontal \
	    -image {orient_v.gif selected orient_h.gif} \
	    -command "::tbar::set_orient [list $w] \$::tbar::orient" \
	    -state disabled
	grid $w -in $win -row 0 -column [incr column] -pady 2 -padx 2
    } else {
	checkbutton $w -indicatoron 0 -takefocus 0 -bd 1 -width 16 -height 16 \
	    -variable ::tbar::orient \
	    -offvalue vertical -image orient_v.gif \
	    -onvalue  horizontal -selectimage orient_h.gif \
	    -command "::tbar::set_orient [list $w] \$::tbar::orient" \
	    -state disabled \
	    -selectcolor [$w cget -bg] \
	    -relief flat -overrelief raised -highlightthickness 0
	grid $w -in $win -row 0 -column [incr column] -sticky s -pady 2 -padx 2
    }
    help::balloon $w "Set the orientation of a widget"

    ## separator frame
    if {$::TILE} {
	set w [ttk::separator $win.sep$column -orient vertical]
    } else {
	set w [frame $win.sep$column -width 2 -relief sunken -bd 2]
    }
    grid $w -in $win -row 0 -column [incr column] -sticky ns -pady 1 -padx 4

    # setup the "divider", the blank space between the property tools, and
    # the command tools that may take user-defined buttons.
    if {$::TILE} {
	set w [ttk::frame $win.hold]
    } else {
	set w [frame $win.hold]
    }
    variable HOLD $w
    grid $w -in $win -row 0 -column [incr column] -sticky w

    ## DELETE RUN STOP buttons
    foreach {name help} {
	delete "Delete the currently selected item"
	run    "Click to test the interface"
	stop   "Click to stop the tested interface"
    } {
	# add button to command toolbar
	set w $win.$name
	set TOOLS($name) $w
	if {$::TILE} {
	    ttk::button $w -style Slim.Toolbutton -image $name.gif \
		-takefocus 0 -state disabled \
		-command [list ::tbar::invoke $name]
	    grid $w -in $win -row 0 -column [incr column] -pady 2 -padx 0
	} else {
	    button $w -image $name.gif \
		-takefocus 0 -state disabled \
		-bd 1 -relief flat -overrelief raised -width 16 -height 16 \
		-command [list ::tbar::invoke $name]
	    grid $w -in $win -row 0 -column [incr column] -sticky s \
		-pady 2 -padx 0
	}
	help::balloon $w $help
    }

    # Configure one final column to take up additional space when enlarged
    grid columnconfigure $win [incr column] -weight 10

    return $win
}

####################################################################

proc ::tbar::getcurwidget {{sampleOK 1}} {
    global Current
    set current $Current(widget)
    if {$current == "" && $sampleOK} {
	# FIX: This window never exists - do this sync'ing right
	set palette .sample_$Current(palette_widget)
	if {[winfo exists $palette]} {
	    set current $palette
	}
    }
    return $current
}

# now sync all of the toolbars

proc sync_all {{ptn *}} {
    variable ::tbar::TOOLS
    foreach i [array names TOOLS $ptn] {
	::tbar::sync_$i $TOOLS($i)
    }
}

proc ::tbar::invoke {what} {
    variable TOOLS
    switch -exact $what {
	save   {
	    ::project::save [::project::get ui]
	    ::tbar::sync_save $TOOLS(save)
	}
	insert { mainmenu_insert }
	delete { mainmenu_delete }
	run {
	    if {[::compile::build_test]} {
		$TOOLS(stop) configure -state normal
	    }
	}
	stop {
	    ::compile::kill_test
	    $TOOLS(stop) configure -state disabled
	}
	default { return -code error "should not invoke: '[info level 0]'" }
    }
}

proc ::tbar::sync_save {w} {
    $w configure -state [expr {[dirty] ? "normal" : "disabled"}]
}

proc ::tbar::sync_insert {w} {
    global Current
    set arg "$Current(row)$Current(column)$Current(gridline)"
    if {$arg != ""} {
	$w configure -state normal
    } else {
	$w configure -state disabled
    }
}
proc ::tbar::sync_delete {w} {
    global Current
    set arg "$Current(row)$Current(column)$Current(widget)$Current(gridline)"
    if {$arg != ""} {
	$w configure -state normal
    } else {
	$w configure -state disabled
    }
}
proc ::tbar::sync_run {w} {
    # The container is always there
    if {[llength [::widget::widgets]] > 1} {
	$w configure -state normal
    } else {
	$w configure -state disabled
    }
}
proc ::tbar::sync_stop {w} {
    # do nothing
}

####################################################################

# ::tbar::EntryChange --
#
#	Reflects the changes in the toolbar entry in the current widget.
#
# Arguments:
#	w	the entry widget
#
# Result:
#	None.

proc ::tbar::EntryChange {w txt vtype} {
    variable ENTRY

    if {![info exists ENTRY(option)]} { return 1 }
    set widget $::Current(widget)
    if {[string match "focus*" $vtype]} {
	if {$vtype eq "focusin" && [$w cget -state] eq "normal" \
		&& [::widget::exists $widget $ENTRY(option)]} {
	    set ENTRY(oldtext) [::widget::data $widget $ENTRY(option)]
	    focus $w
	    $w selection range 0 end
	    $w icursor end
	    set ENTRY(curwidget) $widget
	} else {
	    EntryConfirm $w
	}
    } elseif {[::widget::exists $widget $ENTRY(option)]} {
	# allow \ subs in text
	set txt [subst -nocommand -novariable $txt]
	#if {[info exists ENTRY(textvariable)]} {
	#    upvar #0 $ENTRY(textvariable) var
	#    set var $txt
	#}
	::widget::data $widget $ENTRY(option) $txt
    }
    # This is called by validatecommand, so return 1 at all times
    return 1
}

# ::tbar::EntryEscape --
#
#	User cancels the edit changes in the toolbar entry -- restores
#	the original text setting.
#
# Arguments:
#	w	the entry widget
#
# Result:
#	None.

proc ::tbar::EntryEscape {w} {
    variable ENTRY

    if {[info exists ENTRY(oldtext)] \
	    && [::widget::exists $::Current(widget) $ENTRY(option)]} {
	# setting ENTRY(text) will trigger the EntryChange validation call
	::widget::data $::Current(widget) $ENTRY(option) $ENTRY(oldtext)
	set ENTRY(text) $ENTRY(oldtext)
    }
    focus .
}

# ::tbar::EntryConfirm --
#
#	User confirms the edit changes in the toolbar entry.
#
# Arguments:
#	w	the entry widget
#
# Result:
#	None.

proc ::tbar::EntryConfirm {w} {
    variable ENTRY
    focus .
    catch {unset ENTRY(curwidget)}
    catch {unset ENTRY(oldtext)}
}

# ::tbar::sync_entry --
#
#	Reflect text/label of current widget into the "label editor"
#	box. Enable/disable the "Edit Text Property" menu command
#	according to the class of the widget.
#
# Arguments:
#	w:	The entry widget that implements the "label editor" box.
#
# Result:
#	None.

proc ::tbar::sync_entry {w} {
    variable ENTRY
    global Current

    if {[info exists ENTRY(curwidget)] \
	    && (![info exists Current(widget)] \
		    || $ENTRY(curwidget) ne $Current(widget))} {
	# The user has selected another widget.
	# Apply the text changes for the widget previously being edited.
	EntryConfirm $w
    }

    set state "disabled"
    unset -nocomplain ENTRY(curwidget)
    unset -nocomplain ENTRY(oldtext)
    unset -nocomplain ENTRY(option)
    set ENTRY(text) ""
    if {[set widget $Current(widget)] != ""} {
	foreach opt {-text -label} {
	    if {[::widget::exists $widget $opt]} {
		set ENTRY(text)   [::widget::data $widget $opt]
		set ENTRY(option) $opt
		set state "normal"
		break
	    }
	}
    }

    set l $ENTRY(label)
    $l configure -state $state
    $w configure -state $state
    if {$state eq "disabled"} {
	# We're done here. If the entry is still holding the focus, give it up
	catch {if {[focus -displayof $w] eq $w} { focus . }}
    }

    ::menu::setstate "Edit Text Property" $state
}

#################################
## FONT STYLE
##

proc ::tbar::selectfont {what} {
    set w $::tbar::TOOLS(font)
    switch -exact $what {
	set {
	    set font [$w cget -font]
	    set current [::tbar::getcurwidget]
	    if {[::tbar::sync_font $current $font]} {
		::widget::data $current -font $font
		set ::Current(repeat) [list ::tbar::sync_font bogus $font]
	    }
	}
	enable {
	    foreach c [winfo children $w] {
		catch {$c configure -state normal}
	    }
	}
	disable {
	    foreach c [winfo children $w] {
		catch {$c configure -state disabled}
	    }
	}
	default {
	    error "Not Implemented: '[info level 0]'"
	}
    }
}

proc ::tbar::sync_font {win {setfont {}}} {
    set current [::tbar::getcurwidget]
    set w $::tbar::TOOLS(font)
    if {![::widget::exists $current -font]} {
	$w configure -font {Helvetica 8}
	::tbar::selectfont disable
	# If we want to enable setting the font without a specific widget,
	# we could consider it the default and set that here.
	return 0
    } else {
	::tbar::selectfont enable
	if {[llength [info level 0]] == 3} {
	    # we called ourselves with a font to set
	    set font $setfont
	    ::widget::data $current -font $font
	} else {
	    set font [::widget::data $current -font]
	}
	$w configure -font $font
	return 1
    }
}

#################################
## JUSTIFY
##

proc ::tbar::sync_justify {w} {
    variable DEFS
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -justify]} {
	$w configure -image justify_$DEFS(justify).gif -state disabled
    } else {
	set style [::widget::data $current -justify]
	$w configure -image justify_$style.gif -state normal
    }
}

# set the justify value - need to update the form too

proc ::tbar::set_justify {w style} {
    variable DEFS
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -justify]} {
	$w configure -image justify_$DEFS(justify).gif -state disabled
	status_message "This item has no \"justify\" option"
	# If we want to enable setting this style without a specific widget,
	# we could consider it the default and set that here.
    } else {
	# this will set widget::data appropriately
	::widget::data $current -justify $style
	$w configure -image justify_$style.gif -state normal
    }
    set ::Current(repeat) [info level 0]
}

#################################
## COLOR
##

proc ::tbar::sync_fgcolor {w} {
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -foreground]} {
	$w configure -fg black -bg white -state disabled
    } else {
	set color [::widget::data $current -foreground]
	$w configure -fg [complement $color] -bg $color -state normal
    }
}

proc ::tbar::sync_bgcolor {w} {
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -background]} {
	$w configure -fg white -bg black -state disabled
    } else {
	set color [::widget::data $current -background]
	$w configure -fg [complement $color] -bg $color -state normal
    }
}

# set the color value - need to update the form too

proc ::tbar::set_color {w what color} {
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -$what]} {
	set c [expr {$what == "foreground" ? "white" : "black"}]
	$w configure -bg $c -fg [complement $c] -state disabled
	status_message "This item has no \"$what\" color option"
	# If we want to enable setting this style without a specific widget,
	# we could consider it the default and set that here.
    } else {
	$w configure -bg $color -fg [complement $color] -state normal
	# this will set widget::data appropriately
	::widget::data $current -$what $color
	# heuristic - set the active color to the same
	if {[::widget::exists $current -active$what]} {
	    ::widget::data $current -active$what $color
	}
    }
    set ::Current(repeat) [info level 0]
}

proc ::tbar::color_menu {w type} {
    set color [SelectColor::menu $w.color [list below $w]]
    if {$color != ""} {
	::tbar::set_color $w $type $color
    }
}

#################################
## STICKY
##

#procedure to create sticky menu
# shared by ::config::_add
proc ::tbar::sticky_menu {w widgname cmd} {
    if {![::tbar::show sticky]} { return }

    # create the top level (if needed)
    set win $w.top
    destroy $win
    toplevel $win -cursor [cursor menu]
    wm withdraw $win
    if {!$::AQUA} {
	$win configure -bd 1 -relief solid
    }
    wm transient $win [winfo toplevel $w]
    wm overrideredirect $win 1
    catch { wm attributes $win -topmost 1 }
    set x [winfo rootx $w]
    set y [expr {[winfo rooty $w] + [winfo height $w]}]
    wm geometry $win +$x+$y

    # If the current item is a frame, and no row and/or column is resizable,
    # then alter the bindings so that things cannot be sticky so as to have
    # conflicting restraints.
    upvar 1 $widgname widget

    set resizecols 0
    set resizerows 0
    if {[::widget::isFrame $widget]} {
	# XXX This doesn't account for single-frame cells that are resizable,
	# XXX like you might use for a labelframe
	set curcol [::widget::geometry $widget resize_column]
	set currow [::widget::geometry $widget resize_row]
	regsub -all {[01]} $curcol {} resizec
	regsub -all {[01]} $currow {} resizer
	set resizecols [expr {[llength $resizec]>0?0:1}]
	set resizerows [expr {[llength $resizer]>0?0:2}]
    }

    # pack in existing alignments, set bindings
    set Stickies   {nw n ne new w "" e ew sw s se sew nsw ns nse nsew}
    set Stickymods {0  0 0  1   0 0  0 1  0  0 0  1   2   2  2   3}
    if {$::TILE} {
	set fsize 20
    } else {
	set fsize 16
    }
    set bsize [expr {$fsize/2}]
    set index 0
    foreach sticky $Stickies mod $Stickymods {
	set oksticky [expr {!(($resizecols & $mod) || ($resizerows & $mod))}]
	set f [frame $win.s$sticky -bd 1 -relief raised \
		-height $fsize -width $fsize]
	frame $f.f -height $fsize -width $fsize
	frame $f.b -height $bsize -width $bsize \
		-bg [expr {$oksticky ? "blue" : "#888"}]
	grid $f.f -row 0 -column 0
	grid $f.b -row 0 -column 0 -sticky $sticky
	grid $f -row [expr {$index/4}] -column [expr {$index%4}]
	incr index
	if {$oksticky} {
	    set fcmd [concat $cmd [list $sticky]]
	    bind $f   <ButtonRelease-1> $fcmd
	    bind $f.f <ButtonRelease-1> $fcmd
	    bind $f.b <ButtonRelease-1> $fcmd
	    bind $f   <Enter> { %W configure -relief sunken }
	    bind $f   <Leave> { %W configure -relief raised }
	}
    }
    bind $win <Key-Escape> [list destroy $win]
    bind $win <ButtonRelease-1> [list destroy $win]
    bind $win <FocusOut> [subst {if {"%W" == "$win"} {destroy "$win"}}]

    update idle
    wm deiconify $win
    raise $win
    #tkwait visibility $win
    tk::SetFocusGrab $win ""
    tkwait window $win
    tk::RestoreFocusGrab $win ""
}

proc ::tbar::sync_sticky {win} {
    set current $::Current(widget)
    set w $::tbar::TOOLS(sticky).stickyf
    if {![::widget::exists $current GM:-sticky]} {
	::tbar::show sticky no
	grid configure $w -sticky ""
	$w configure -bg grey
    } else {
	::tbar::show sticky yes
	grid configure $w -sticky [::widget::geometry $current -sticky]
	$w configure -bg blue
    }
}

# set the sticky value - need to update the form too

proc ::tbar::set_sticky {style} {
    set current $::Current(widget)
    set w $::tbar::TOOLS(sticky).stickyf
    if {![::widget::exists $current GM:-sticky]} {
	::tbar::show sticky no
	grid configure $w -sticky ""
	$w configure -bg grey
	status_message "Unable to apply sticky value to this item"
    } else {
	::widget::geometry $current -sticky $style
	grid configure $w -sticky $style
    }
    set ::Current(repeat) [info level 0]
}

#################################
## RELIEF && BORDERWIDTH
##

proc ::tbar::relief_menu {w} {
    if {![::tbar::show relief]} { return }

    # create the top level (if needed)
    set win $w.top
    destroy $win
    toplevel $win -cursor [cursor menu]
    if {!$::AQUA} {
	$win configure -bd 1 -relief solid
    }
    wm overrideredirect $win 1
    set x [winfo rootx $w]
    set y [expr {[winfo rooty $w] + [winfo height $w]}]
    wm geometry $win +$x+$y

    # pack in existing reliefs, set bindings

    set reliefs {flat raised sunken ridge groove solid}
    set index 0
    label $win.lt -text "Type: " -anchor w
    grid $win.lt -row 0 -column 0 -sticky ew
    foreach i $reliefs {
	frame $win.$i -bd 1 -cursor [cursor item]
	frame $win.$i.l -width 15 -height 15 -bd 4 -relief $i -bg grey
	grid $win.$i   -row 0 -column [incr index]
	grid $win.$i.l -row 0 -column 0 -padx 2 -pady 2
	incr index
	foreach j {"" .l} {
	    bind $win.$i$j <ButtonRelease-1> \
		    [list ::tbar::set_relief $w.rbf $i]
	    bind $win.$i$j <Enter> [list $win.$i configure -relief raised]
	    bind $win.$i$j <Leave> [list $win.$i configure -relief flat]
	}
    }
    set widths {0 1 2 3 4 5}
    set index 0
    label $win.lw -text "Width: " -anchor w
    grid $win.lw -row 1 -column 0 -sticky ew
    foreach i $widths {
	frame $win.$i -bd 1 -cursor [cursor item]
	frame $win.$i.l -width 15 -height 15 -bd $i -relief raised -bg grey
	grid $win.$i   -row 1 -column [incr index]
	grid $win.$i.l -row 0 -column 0 -padx 2 -pady 2
	incr index
	foreach j {"" .l} {
	    bind $win.$i$j <ButtonRelease-1> \
		    [list ::tbar::set_borderwidth $w.rbf $i]
	    bind $win.$i$j <Enter> [list $win.$i configure -relief raised]
	    bind $win.$i$j <Leave> [list $win.$i configure -relief flat]
	}
    }
    bind $win <Key-Escape> [list destroy $win]
    bind $win <ButtonRelease-1> [list destroy $win]
    tkwait visibility $win
    grab $win
}

proc ::tbar::sync_relief {win} {
    variable DEFS
    set current [::tbar::getcurwidget]
    set w $::tbar::TOOLS(relief).rbf
    if {![::widget::exists $current -relief]} {
	::tbar::show relief no
	$w configure -relief $DEFS(relief)
    } else {
	::tbar::show relief yes
	$w configure -relief [::widget::data $current -relief]
    }
}

proc ::tbar::sync_borderwidth {win} {
    variable DEFS
    set current [::tbar::getcurwidget]
    set w $::tbar::TOOLS(borderwidth).rbf
    if {![::widget::exists $current -borderwidth]} {
	::tbar::show relief no
	$w configure -bd $DEFS(borderwidth)
    } else {
	::tbar::show relief yes
	set bd [::widget::data $current -borderwidth]
	$w configure -bd [expr {($bd>4) ? 4 : $bd}]
    }
}

# set the selected widget to the proper relief

proc ::tbar::set_relief {w relief} {
    variable DEFS
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -relief]} {
	::tbar::show relief no
	$w configure -relief $DEFS(relief)
	status_message "This item has no \"relief\" option"
    } else {
	::tbar::show relief yes
	$w configure -relief $relief
	::widget::data $current -relief $relief
    }
    set ::Current(repeat) [info level 0]
}

# set the border size - need to update the form too

proc ::tbar::set_borderwidth {w bd} {
    variable DEFS
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -borderwidth]} {
	::tbar::show relief no
	$w configure -borderwidth $DEFS(borderwidth)
	status_message "This item has no \"borderwidth\" option"
    } else {
	::tbar::show relief yes
	$w configure -borderwidth $bd
	::widget::data $current -borderwidth $bd
    }
    set ::Current(repeat) [info level 0]
}

#################################
## ORIENTATION (vertical|horizontal)
##
# select orientation (scrollbars and scales only) - placeholder

proc ::tbar::sync_orient {w} {
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -orient]} {
	$w configure -state disabled
    } else {
	$w configure -state normal
    }
}

proc ::tbar::set_orient {w style} {
    set current [::tbar::getcurwidget]
    if {![::widget::exists $current -orient]} {
	$w configure -state disabled
	status_message "This item has no \"orient\" option"
    } else {
	set ::tbar::orient $style
	$w configure -state normal
	::widget::data $current -orient $style
	# we call this to update the stickiness as well
	orient_create $current
    }
    set ::Current(repeat) [info level 0]
}

##########################################################

