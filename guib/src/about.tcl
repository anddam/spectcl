# about.tcl --
#
#	This file implements the about box
#
# Copyright (c) 2006 ActiveState Software Inc.
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::about {}

proc circle {delay w heart feather x1 y1 x2 y2 steps count dir} {
    if {![winfo exists $w] || ![winfo ismapped $w]} {
	return
    }
    if {$count == $steps} {
	set dir -1
	$w raise $feather $heart
    } elseif {$count == 0} {
	set dir 1
	$w raise $heart $feather
    }
    set x [expr {$x1 + ($count * ($x2-$x1)/$steps)}]
    set y [expr {$y1 + ($count * ($y2-$y1)/$steps)}]
    $w coords $heart $x $y
    update idle
    incr count $dir
    after $delay [lreplace [info level 0] end-1 end $count $dir]
}

proc about {{w .about}} {
    # Show the heart on Valentine's day
    if {[llength [info commands heart.gif]] &&
	[llength [info commands splash_feather.gif]] &&
	[clock format [clock seconds] -format "%m %d"] eq "02 14"} {
	set useheart 1
    } else {
	set useheart 0
    }
    if {![winfo exists $w]} {
	global tk_patchLevel tcl_patchLevel tcl_version
	toplevel $w
	wm withdraw $w
	wm title $w "About $::gui::APPNAME"
	wm overrideredirect $w 1

	set img splash.gif
	set height [image height $img]
	set width  [image width $img]
	canvas $w.c -width $width -height $height -highlightthickness 0
	pack $w.c
	$w.c create image 0 0 -anchor nw -image $img
	if {$useheart} {
	    $w.c create image 0 0 -anchor nw -tags feather \
		-image splash_feather.gif
	    # 150x30 -> 240x80 and back
	    $w.c create image 140 170 -anchor nw -tags heart -image heart.gif
	}
	# XXX: These coords may need to be adjusted if the splash changes
	$w.c create text 5 290 -anchor nw -font defaultFont -text $::gui::BUILD
	set x [expr {([winfo screenwidth  $w] - $width)/2}]
	set y [expr {([winfo screenheight $w] - $height)/2}]
	wm geometry $w +${x}+${y}
	wm resizable $w 0 0
	if {$::tcl_platform(platform) eq "windows"} {
	    wm attributes $w -topmost 1
	}

	if {$::AQUA} {
	    event add <<AboutDismiss>> <1> <2> <3>
	} else {
	    event add <<AboutDismiss>> <1> <2> <3> <FocusOut>
	}
	bind $w <<AboutDismiss>> [list about::dismiss $w %x %y]
    }
    wm deiconify $w
    raise $w
    focus $w
    if {$useheart} {
	tkwait visibility $w
	after 100 [list circle 50 $w.c heart feather 140 170 220 225 30 0 1]
    }
    return $w
}

proc about::dismiss {w x y} {
    if {$x > 25 && $x < 125 && $y > 25 && $y < 75} {
	::UItris::Init .__uitris
    }
    wm withdraw $w
}
