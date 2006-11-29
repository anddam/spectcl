#!/bin/sh
# the next line starts with wish, don't remove the slash --> \
exec wish "$0" ${1+"$@"}

##----------------------------------------------------------------------
## uitris.tcl
##
## Stripped down version of full TkTetris.
## Copyright (c) 1995-2002 Jeffrey Hobbs jeff (at) hobbs.org
##----------------------------------------------------------------------

package require Tk 8.3
namespace eval UItris {;

variable tetris
variable block
variable players
variable stats
variable pmap
variable piece
variable widget

## VERSION:
set tetris(version) 3.4.0

set tetris(WWW) [info exists embed_args]
set tetris(DIR) [file dirname [info script]]
wm withdraw .

proc About {} {
    variable tetris
    tk_messageBox -title "About UItris v$tetris(version)" \
	    -icon info -type ok -message $tetris(info)
}

proc Init {{base {}}} {
    variable tetris
    variable widget
    variable keys
    variable color

    set tetris(name) [namespace current]::
    array set tetris {
	blocksize	16
	maxInterval	500
	initLevel	0
	autoPause	0
	showNext	1
	shadow		1
	growing		0
	growLevel	0
	growMax		26
	startRows	0

	maxbrick 0 growRows 0 growInterval idle

	info	"(c) Jeffrey Hobbs 1995-2002\njeff@hobbs.org"
    }
    array set color {
	0		\#FF0000
	1		\#00FF00
	2		\#0000FF
	3		\#FFFF00
	4		\#FF00FF
	5		\#00FFFF
	6		\#FFFFFF
    }
    array set keys {
	Left		<Key-Left>
	Right		<Key-Right>
	"Rotate Left"	<Key-Up>
	"Rotate Right"	<Key-Down>
	Slide		<Key-Return>
	Drop		<Key-space>
	Options		<Key-o>
	Quit		<Control-q>
	Start		<Key-s>
	Reset		<Key-r>
	AddRow		<Key-a>
	Faster		<Key-f>
	Stats		<Control-s>
	About		<Control-a>
	Keys		<Control-k>
    }

    option add *Button.takeFocus	0 startup
    option add *Button*highlightThickness 1 startup
    option add *Canvas*highlightThickness 0 startup
    option add *Canvas.borderWidth	1 startup
    option add *Canvas.relief		ridge startup

    foreach i [array names keys] {
	event add <<[string map {{ } {}} $i]>> $keys($i)
    }

    set bs $tetris(blocksize)
    array set tetris [list root $base base $base \
	    width	[expr {10*$bs}] height	[expr {30*$bs}]]
    if {[string equal {} $base]} {
	set tetris(root) .
    } elseif {![winfo exists $base]} {
	toplevel $base
	wm withdraw $base
    }

    set left [frame $base.l]
    set right [frame $base.r]
    array set widget [list \
	    board	$right.board \
	    stats	$base.stats	shadow	$right.shade \
	    next	$left.next	keys	$base.keys \
	    ]

    grid $left $right -sticky new

    canvas $widget(board) -width $tetris(width) -height $tetris(height) \
	    -bg gray
    canvas $widget(shadow) -width $tetris(width) -height $bs -bg gray

    # Oh my gosh, a cheat!
    $widget(board) bind piece <<Cheater>> [namespace code {Cheat %W}]
    $widget(board) bind struc <<Cheater>> [namespace code {Cheat %W}]
    event add <<Cheater>> <Triple-1>

    label $left.title -text "UItris v$tetris(version)" -relief ridge -bd 2
    label $left.lnext -text "Next Object" -anchor c
    canvas $widget(next) -width [expr {$bs*4+10}] -height [expr {$bs*2+10}]
    button $left.start -textvariable $tetris(name)tetris(start) \
	    -command [namespace code ToggleState]
    button $left.reset -text "Reset" -un 0 -command [namespace code Reset]
    button $left.addrow -text "Add Random Row" -underline 0 \
	    -command [namespace code {AddRows 1}]

    if {!$tetris(WWW)} {
	# This works when we are being "hosted" as well as being the main app
	button $left.quit  -text "Quit" -underline 0 \
		-command "[namespace code Reset]; destroy [list $tetris(root)]"
	button $left.stats -text "Stats" -command [namespace code Stats]
	button $left.keys -text "Keys Bindings" -command [namespace code Keys]
	button $left.about -text "About" -command [namespace code About]
	checkbutton $left.pause -text "Auto Pause" -anchor w \
		-variable $tetris(name)tetris(autoPause) \
		-command [namespace code AutoPause]

	foreach i {Stats About Keys} {
	    bind $tetris(root) <<$i>>	[namespace code $i]
	}
	bind $tetris(root) <<Quit>>	[list $left.quit invoke]
	wm protocol $tetris(root) WM_DELETE_WINDOW [list $left.quit invoke]
	wm title $tetris(root) "UItris v$tetris(version)"
    }

    checkbutton $left.show -text "Show Next" -anchor w \
	    -variable $tetris(name)tetris(showNext) \
	    -command [namespace code ShowNext]
    checkbutton $left.shadow -text "Shadow Piece" -anchor w \
	    -variable $tetris(name)tetris(shadow) \
	    -command [namespace code Shadow]
    checkbutton $left.grow -text "Growing Rows" -anchor w \
	    -variable $tetris(name)tetris(growing) \
	    -command [namespace code GrowRows]
    label $left.glbl -text "Grow Speed:" -anchor w
    button $left.gup -text "+" -padx 0 -pady 0 -command [namespace code \
	    {set tetris(growLevel) [expr {($tetris(growLevel)+1)%16}]}]
    label $left.gval -textvariable $tetris(name)tetris(growLevel) -anchor e
    label $left.mlbl -text "Grow To Max:" -anchor w
    button $left.mup -text "+" -padx 0 -pady 0 -command [namespace code \
	    {set tetris(growMax) [expr {($tetris(growMax)+1)%27}]}]
    label $left.mval -textvariable $tetris(name)tetris(growMax) -anchor e

    label $left.lscore -text Score: -anchor w
    label $left.llvl -text Level: -anchor w
    label $left.lrows -text Rows:   -anchor w
    label $left.vscore -textvariable $tetris(name)tetris(score) -anchor e
    label $left.vlvl -textvariable $tetris(name)tetris(level) -anchor e
    label $left.vrows -textvariable $tetris(name)tetris(rows) -anchor e
    button $left.ilvl -text "+" -padx 0 -pady 0 -command [namespace code \
	    {SetIntervalLevel [incr tetris(level)]}]

    bind $tetris(root) <<Start>> [list $left.start invoke]
    bind $tetris(root) <<Reset>> [list $left.reset invoke]
    bind $tetris(root) <<AddRow>> [list $left.addrow invoke]
    bind $tetris(root) <<Faster>> [list $left.ilvl invoke]

    grid $left.title	- - -sticky new
    grid $left.lnext	- - -sticky new
    grid $widget(next)	- - -sticky n
    grid $left.lscore $left.vscore - -sticky new
    grid $left.llvl   $left.ilvl $left.vlvl -sticky new
    grid $left.lrows  $left.vrows - -sticky new
    grid $left.start	- - -sticky new -padx 4
    grid $left.reset	- - -sticky new -padx 4 -pady 4

    if {!$tetris(WWW)} {
	grid $left.stats	- - -sticky new -padx 4
	grid $left.keys		- - -sticky new -padx 4
	grid $left.about	- - -sticky new -padx 4
	grid $left.quit		- - -sticky new -padx 4 -pady 4
	grid $left.pause	- - -sticky new
    }
    grid $left.show	- - -sticky new
    grid $left.shadow	- - -sticky new
    grid $left.grow	- - -sticky new
    grid $left.glbl $left.gup $left.gval -sticky new
    grid $left.mlbl $left.mup $left.mval -sticky new
    grid $left.addrow	- - -sticky new -padx 4

    grid configure $left.llvl $left.ilvl $left.gup $left.mup \
	    $left.lrows $left.lscore -sticky nw

    grid $widget(board) -sticky news
    grid $widget(shadow) -sticky news

    ## Don't touch this - the returned canvas id numbers are important
    for {set j 0} {$j < 30} {incr j} {
	for {set i 0} {$i < 10} {incr i} {
	    set x [expr {int(($i+.5)*$bs)}]
	    set y [expr {int(($j+.5)*$bs-1)}]
	    $widget(board) create line $x $y $x [incr y 2] \
		    -tags back -fill $color(0)
	    if {$j == 0} {
		$widget(shadow) create rect [expr {$i*$bs}] 0 \
			[expr {($i+1)*$bs}] $bs -outline {}
	    }
	}
    }
    focus $widget(board)

    Reset
    InitPieces $bs
    if {$tetris(WWW)} {
	Stats
	Keys
    } else {
	wm resizable $tetris(root) 0 0
	wm deiconify $tetris(root)
    }
    AutoPause
}

proc SetIntervalLevel {n} {
    variable tetris

    set i [expr {round($tetris(maxInterval)-($tetris(maxInterval)/20*$n))}]
    if {$i<8} { set i 8 }
    set tetris(interval) $i
    set tetris(growInterval) [expr {$tetris(maxInterval) * \
	    (25-$tetris(growLevel))}]
}

proc ToggleState {} {
    variable tetris

    if {$tetris(start) == "Pause"} {
	Pause
    } elseif {$tetris(start) == "Game Over"} {
	Reset
    } else {
	Resume
    }
}

proc AutoPause {} {
    variable tetris

    if {$tetris(autoPause) && !$tetris(WWW)} {
	## Not available for WWW play
	bind $tetris(root) <Unmap> [namespace code {
	    if {$tetris(start) == "Pause"} { Pause }
	}]
	bind $tetris(root) <Map>   [namespace code {
	    if {$tetris(start) == "Resume"} { Resume }
	}]
	## These are not available for during multiplayer mode
	## (would potentially require way too much communication)
	bind $tetris(root) <FocusOut> [namespace code {
	    if {"%d" == "NotifyAncestor" && $tetris(start) == "Pause"} {
		Pause
	    }
	}]
	bind $tetris(root) <FocusIn>  [namespace code {
	    if {"%d" == "NotifyAncestor" && $tetris(start) == "Resume"} {
		Resume
	    }
	}]
    } else {
	foreach i {Unmap Map FocusOut FocusIn} { bind $tetris(root) <$i> {} }
    }
}

proc Pause {} {
    variable tetris
    variable keys

    set tetris(break) 1
    foreach i [after info] { after cancel $i }
    set tetris(start) "Resume"
    bind $tetris(root) <<Left>>		{}
    bind $tetris(root) <<Right>>	{}
    bind $tetris(root) <<RotateLeft>>	{}
    bind $tetris(root) <<RotateRight>>	{}
    bind $tetris(root) <<Slide>>	{}
    bind $tetris(root) <<Drop>>		{}
}

proc Resume {} {
    variable tetris
    variable keys

    set tetris(break) 0
    set tetris(start) "Pause"
    bind $tetris(root) <<Left>>		[namespace code Left]
    bind $tetris(root) <<Right>>	[namespace code Right]
    bind $tetris(root) <<RotateLeft>>	[namespace code {Rotate Left}]
    bind $tetris(root) <<RotateRight>>	[namespace code {Rotate Right}]
    bind $tetris(root) <<Slide>>	[namespace code Slide]
    bind $tetris(root) <<Drop>>		[namespace code Drop]
    GrowRows
    Fall
}

proc GameOver {} {
    variable tetris
    variable widget

    foreach i [after info] { after cancel $i }
    set tetris(break) 1
    set tetris(start) "Game Over"
    $widget(board) delete piece
}

proc Reset {} {
    variable tetris
    variable block
    variable stats
    variable widget
    variable color

    Pause
    array set tetris [list start "Start" level $tetris(initLevel) \
	    rows 0 next [random 7] maxbrick 0]
    SetIntervalLevel $tetris(level)
    $widget(board) delete piece struc
    $widget(board) itemconfig back -fill $color([expr {$tetris(level)%7}])
    $widget(next) delete all
    $widget(shadow) dtag shadow
    $widget(shadow) itemconfig all -fill gray
    for {set i -30} {$i < 300} {incr i} { set block($i) 0 }
    for {}          {$i < 310} {incr i} { set block($i) 1 }
    for {set i 0}   {$i < 7}   {incr i} { set stats($i) 0 }
    if {$tetris(startRows)} {
	set i $tetris(startRows)
	while {$i > 4} {
	    AddRows 4
	    # a little anim effect
	    update idletasks
	    incr i -4
	}
	AddRows $i
    }
    set tetris(score) 0
}

proc SetKey {key var} {
    variable keys
    variable tetris

    regsub { } $var {} event
    set newevent <Key-$key>

    if {[catch {event add <<$event>> $newevent} err]} {
	bgerror $err
    } else {
	event delete <<$event>> $keys($var)
	set keys($var) $newevent
    }
    if {$tetris(WWW)} {
	focus $tetris(root)
    }
}

proc Keys {} {
    variable tetris
    variable widget
    variable keys

    set w $widget(keys)
    if {![winfo exists $w]} {
	if {$tetris(WWW)} {
	    grid [frame $w] - - - - -sticky new
	} else {
	    toplevel $w
	    wm withdraw $w
	    wm title $w "UItris v$tetris(version) Keys"
	}
	label $w.l -justify center \
		-text "Key Bindings: Click in widget and hit a key to change"

	foreach {name key} {
	    ml Left mr Right rl "Rotate Left" rr "Rotate Right"
	    sl Slide dr Drop
	} {
	    label $w.$name -text $key: -anchor e
	    entry $w.e$name -textvariable $tetris(name)keys($key)
	    bind $w.e$name <Any-Key> \
		    [namespace code "SetKey %K [list $key]; break"]
	}

	grid $w.l - - - -sticky ew
	grid $w.ml $w.eml $w.rl $w.erl -sticky ew
	grid $w.mr $w.emr $w.rr $w.err -sticky ew
	grid $w.sl $w.esl $w.dr $w.edr -sticky ew

	if {!$tetris(WWW)} {
	    foreach i {AddRow Faster Start Reset Quit} {
		set n [string tolower [string index $i 0]]
		label $w.$n -text "$i:" -anchor e
		entry $w.e$n -textvariable $tetris(name)keys($i)
		bind $w.e$n <Any-Key> [namespace code "SetKey %K $i; break"]
	    }

	    grid $w.a $w.ea $w.f $w.ef -sticky ew
	    grid $w.s $w.es $w.r $w.er -sticky ew
	    grid x    x     $w.q $w.eq -sticky ew

	    frame $w.sep -height 2 -bd 2 -relief ridge
	    button $w.dis -text "Dismiss" -command [list wm withdraw $w]
	    grid $w.sep - - - -sticky ew
	    grid $w.dis - - - -sticky ew -padx 4 -pady 4
	    wm resizable $w 0 0
	    update idletasks
	    set a $tetris(root)
	    wm transient $w $a
	    wm group $w $a
	    wm geometry $w +[expr {[winfo rootx $a]+([winfo width $a]\
		    -[winfo reqwidth $w])/2}]+[expr {[winfo rooty $a]\
		    +([winfo height $a]-[winfo reqheight $w])/2}]
	}
    }
    if {!$tetris(WWW)} {
	if {[wm state $w] != "normal"} {
	    wm deiconify $w
	} else {
	    wm withdraw $w
	}
    }
}

proc Stats {} {
    variable tetris
    variable widget
    variable pmap
    variable stats
    variable color

    set w $widget(stats)
    if {![winfo exists $w]} {
	if {$tetris(WWW)} {
	    grid [frame $w] -sticky new -row 0 \
		    -column [lindex [grid size [winfo parent $w]] 0]
	} else {
	    toplevel $w
	    wm withdraw $w
	    wm title $w "UItris v$tetris(version) Stats"
	}
	set bs $tetris(blocksize)
	grid [label $w.l -text "Piece Statistics"] -sticky ew
	grid [canvas $w.c -bd 2 -width [expr {$bs*9.5}] \
		-height [expr {$bs*22.5}]] -sticky news
	label $w.c.s -text "Session"
	label $w.c.g -text "Game"
	$w.c create window 5 5 -window $w.c.s -anchor nw
	$w.c create window [expr {7*$bs}] 5 \
		-window $w.c.g -anchor nw
	for {set i 0} {$i < 7} {incr i} {
	    foreach p $pmap($i) {
		$w.c create rectangle [lindex $p 0] [lindex $p 1] \
			[lindex $p 2] [lindex $p 3] -tags "p$i piece"
	    }
	    # Oh my gosh, a cheat!
	    $w.c bind piece <<Cheater>> [namespace code {Cheat %W}]
	    foreach {x0 y0 x y} [$w.c bbox p$i] {set x [expr {int($x-$x0)}]}
	    set y [expr {(3*$i+2)*$bs}]
	    $w.c move p$i [expr {int(($bs*9.5-$x)/2-$x0)}] $y
	    $w.c itemconfig p$i -fill $color($i)
	    label $w.c.g$i -textvariable $tetris(name)stats(g$i) -anchor w
	    $w.c create window [expr {.75*$bs}] $y \
		    -window $w.c.g$i -anchor nw
	    label $w.c.$i -textvariable $tetris(name)stats($i) -anchor w
	    $w.c create window [expr {7.5*$bs}] $y \
		    -window $w.c.$i -anchor nw
	}
	if {$tetris(WWW)} {
	    grid [label $w.about -font fixed -text $tetris(info)] -sticky news
	} else {
	    button $w.b -text "Dismiss" -command [list wm withdraw $w]
	    grid $w.b -sticky ew -padx 4 -pady 4
	    wm resizable $w 0 0
	    update idletasks
	    set a $tetris(root)
	    wm transient $w $a
	    wm group $w $a
	    wm geometry $w +[expr {[winfo rootx $a]+([winfo width $a]\
		    -[winfo reqwidth $w])/2}]+[expr {[winfo rooty $a]\
		    +([winfo height $a]-[winfo reqheight $w])/2}]
	}
    }
    if {!$tetris(WWW)} {
	if {[wm state $w] != "normal"} {
	    wm deiconify $w
	} else {
	    wm withdraw $w
	}
    }
}

proc LoadImages {} {
    variable thumbs
    variable faces
    variable tetris

    if {[llength [array names thumbs]]} { return }

    set dir [file join $tetris(DIR) images]
    # We have seven pieces - we need at least 7 images
    foreach i {
	button.gif      canvas.gif    checkbutton.gif    entry.gif
	label.gif       listbox.gif   menubutton.gif     message.gif
	radiobutton.gif scale.gif     scrollbar.gif      text.gif
	shantel.gif
    } {
	if {[lsearch -exact [image names] $i] > -1} {
	    set thumbs($i) $i
	} else {
	    set thumbs($i) [image create photo $i -file [file join $dir $i]]
	}
    }
    foreach i {jeff.gif} {
	if {[lsearch -exact [image names] $i] > -1} {
	    set faces($i) $i
	} else {
	    set faces($i) [image create photo $i -file [file join $dir $i]]
	}
    }
}

proc InitPieces size {
    variable stats
    variable pmap

    LoadImages
    ## Block
    set pmap(0) [list \
	    [list [expr {4*$size}] 0 [expr {5*$size}] $size 4] \
	    [list [expr {5*$size}] 0 [expr {6*$size}] $size 5] \
	    [list [expr {4*$size}] $size [expr {5*$size}] [expr {2*$size}] 14]\
	    [list [expr {5*$size}] $size [expr {6*$size}] [expr {2*$size}] 15]]
    ## L
    set pmap(1) [list \
	    [list [expr {3*$size}] 0 [expr {4*$size}] $size 3] \
	    [list [expr {4*$size}] 0 [expr {5*$size}] $size 4] \
	    [list [expr {5*$size}] 0 [expr {6*$size}] $size 5] \
	    [list [expr {5*$size}] $size [expr {6*$size}] [expr {2*$size}] 15]]
    ## Mirror L
    set pmap(2) [list \
	    [list [expr {3*$size}] 0 [expr {4*$size}] $size 3] \
	    [list [expr {4*$size}] 0 [expr {5*$size}] $size 4] \
	    [list [expr {5*$size}] 0 [expr {6*$size}] $size 5] \
	    [list [expr {3*$size}] $size [expr {4*$size}] [expr {2*$size}] 13]]
    ## Shift One
    set pmap(3) [list \
	    [list [expr {4*$size}] 0 [expr {5*$size}] $size 4] \
	    [list [expr {5*$size}] 0 [expr {6*$size}] $size 5] \
	    [list [expr {5*$size}] $size [expr {6*$size}] [expr {2*$size}] 15]\
	    [list [expr {6*$size}] $size [expr {7*$size}] [expr {2*$size}] 16]]
    ## Shift Two
    set pmap(4) [list \
	    [list [expr {5*$size}] 0 [expr {6*$size}] $size 5] \
	    [list [expr {6*$size}] 0 [expr {7*$size}] $size 6] \
	    [list [expr {4*$size}] $size [expr {5*$size}] [expr {2*$size}] 14]\
	    [list [expr {5*$size}] $size [expr {6*$size}] [expr {2*$size}] 15]]
    ## Bar
    set pmap(5) [list \
	    [list [expr {3*$size}] 0 [expr {4*$size}] $size 3] \
	    [list [expr {4*$size}] 0 [expr {5*$size}] $size 4] \
	    [list [expr {5*$size}] 0 [expr {6*$size}] $size 5] \
	    [list [expr {6*$size}] 0 [expr {7*$size}] $size 6]]
    ## T
    set pmap(6) [list \
	    [list [expr {4*$size}] 0 [expr {5*$size}] $size 4] \
	    [list [expr {5*$size}] 0 [expr {6*$size}] $size 5] \
	    [list [expr {6*$size}] 0 [expr {7*$size}] $size 6] \
	    [list [expr {5*$size}] $size [expr {6*$size}] [expr {2*$size}] 15]]

    for {set i 0} {$i < 7} {incr i} { set stats($i) 0; set stats(g$i) 0 }
}

proc ShowNext {} {
    variable tetris
    variable widget
    variable color

    $widget(next) delete all
    if {$tetris(showNext) && [string compare $tetris(start) "Start"]} {
	variable pmap
	foreach i $pmap($tetris(next)) {
	    $widget(next) create rectangle [lindex $i 0] [lindex $i 1] \
		    [lindex $i 2] [lindex $i 3]
	}
	# make sure it is centered
	foreach {x0 y0 x y} [$widget(next) bbox all] {
	    set x [expr {$x-$x0}]
	    set y [expr {$y-$y0}]
	}
	$widget(next) move all \
		[expr {int(([winfo width $widget(next)]-$x)/2-$x0)}] \
		[expr {int(([winfo height $widget(next)]-$y)/2-$y0)}]
	$widget(next) itemconfig all -fill $color($tetris(next))
    }
}

proc CreatePiece {} {
    variable tetris
    variable widget
    variable piece
    variable pmap
    variable stats
    variable block
    variable color
    variable thumbs
    variable faces

    if {$tetris(growRows)} {
	AddRows $tetris(growRows)
	set tetris(growRows) 0
    }
    set p $tetris(next)
    set j 0
    #set IMG 1; # test image piece number
    if {$p == 0} {
	#  the block piece gets a face image
	set imgs [array names faces]
    } else {
	set imgs [array names thumbs]
    }
    set img  [lindex $imgs [random [llength $imgs]]]
    foreach i $pmap($p) {
	if {$block([set piece($j) [lindex $i 4]])} {
	    GameOver
	    return
	}
	if {$p == 0} {
	    if {![info exists nomore]} {
		set piece(_img$j) [$widget(board) create image \
			[expr {[lindex $i 0]+1}] [lindex $i 1] \
			-anchor nw -image $img \
			-tags "img_$img image piece piece_$j"]
		set nomore 1
	    }
	} else {
	    set piece(_img$j) [$widget(board) create image \
		    [expr {[lindex $i 0]+1}] [lindex $i 1] \
		    -anchor nw -image $img \
		    -tags "img_$img image piece piece_$j"]
	}
	set piece(_$j) [$widget(board) create rectangle \
		[lindex $i 0] [lindex $i 1] [lindex $i 2] [lindex $i 3] \
		-tags "p$p piece piece_$j rect"]
	incr j
    }
    set piece(current) $p
    incr stats($p)
    incr stats(g$p)
    #$widget(board) itemconfig p$p -fill $color($p)
    set tetris(next) [random 7]

    ShowNext
    Shadow
}

proc Cheat {w} {
    if {[regexp {p([0-9])} [$w gettags current] junk i]} {
	variable tetris
	set tetris(next) $i
	ShowNext
    }
}

proc Fall {{a {}}} {
    variable tetris

    if {!$tetris(break)} {
	after $tetris(interval) [namespace code Fall]
	Slide
    }
}

proc Shadow {} {
    variable tetris
    variable widget
    variable piece

    $widget(shadow) dtag shadow
    $widget(shadow) itemconfig all -fill gray
    if {$tetris(shadow) && [string compare {} [$widget(board) bbox piece]]} {
	foreach i {0 1 2 3} {
	    $widget(shadow) addtag shadow with [expr {$piece($i)%10+1}]
	}
	$widget(shadow) itemconfig shadow -fill black
    }
}

proc GrowRows {{now 0}} {
    variable tetris

    if {$tetris(growing) && !$tetris(break)} {
	if {$now && ($tetris(maxbrick) < $tetris(growMax))} {
	    incr tetris(growRows)
	}
	after $tetris(growInterval) [namespace code {GrowRows 1}]
    }
}

proc CementPiece {} {
    variable tetris
    variable widget
    variable piece
    variable block

    foreach i {0 1 2 3} {
	set block($piece($i)) 1
	set row [expr {$piece($i)/10}]
	$widget(board) addtag row$row with piece_$i
	if {(30-$row)>$tetris(maxbrick)} {
	    set tetris(maxbrick) [expr {30-$row}]
	}
	$widget(board) dtag piece_$i
    }
    $widget(board) addtag strucimg with image
    $widget(board) dtag image piece
    $widget(board) addtag struc with piece
    $widget(board) itemconfig struc -stipple gray50
    $widget(board) dtag piece
    array unset piece _*
    incr tetris(score) 5
    DropRows
}

proc Slide {} {
    variable tetris
    variable piece
    variable block
    variable widget

    if {![llength [set ix [$widget(board) bbox piece]]]} {
	CreatePiece
    } else {
	if {
	    $block([expr {$piece(0)+10}]) || $block([expr {$piece(1)+10}]) ||
	    $block([expr {$piece(2)+10}]) || $block([expr {$piece(3)+10}])
	} {
	    CementPiece
	    update idletasks
	} else {
	    incr piece(0) 10
	    incr piece(1) 10
	    incr piece(2) 10
	    incr piece(3) 10
	    $widget(board) move piece 0 $tetris(blocksize)
	}
    }
}

proc Drop {} {
    variable tetris
    variable piece
    variable block
    variable widget

    set tetris(sync) 1
    if {![llength [set ix [$widget(board) bbox piece]]]} return
    set move 0
    while {1} {
	if {
	    $block([expr {$piece(0)+10}]) || $block([expr {$piece(1)+10}]) ||
	    $block([expr {$piece(2)+10}]) || $block([expr {$piece(3)+10}])
	} {
	    break
	} else {
	    incr piece(0) 10
	    incr piece(1) 10
	    incr piece(2) 10
	    incr piece(3) 10
	    incr move $tetris(blocksize)
	}
    }
    $widget(board) move piece 0 $move
    CementPiece
    set tetris(sync) 0
}

proc Left {} {
    variable tetris
    variable piece
    variable block
    variable widget

    if {[string match {} [set ix [$widget(board) bbox piece]]] || \
	    [lindex $ix 0] <= 0} return
    if {
	$block([expr {$piece(0)-1}]) || $block([expr {$piece(1)-1}]) ||
	$block([expr {$piece(2)-1}]) || $block([expr {$piece(3)-1}])
    } {
	return
    } else {
	incr piece(0) -1
	incr piece(1) -1
	incr piece(2) -1
	incr piece(3) -1
	$widget(board) move piece -$tetris(blocksize) 0
	Shadow
	update idletasks
    }
}

proc Right {} {
    variable tetris
    variable piece
    variable block
    variable widget

    if {[string match {} [set ix [$widget(board) bbox piece]]] || \
	    [lindex $ix 2] >= $tetris(width)} return
    if {
	$block([expr {$piece(0)+1}]) || $block([expr {$piece(1)+1}]) ||
	$block([expr {$piece(2)+1}]) || $block([expr {$piece(3)+1}])
    } {
	return
    } else {
	incr piece(0)
	incr piece(1)
	incr piece(2)
	incr piece(3)
	$widget(board) move piece $tetris(blocksize) 0
	Shadow
	update idletasks
    }
}

proc Rotate dir {
    variable tetris
    variable piece
    variable block
    variable widget

    if {$piece(current) == 0} {
	# This is the block piece, which does not need rotation
	return
    }
    set ix [$widget(board) find withtag "piece && rect"]
    if {![llength $ix]} { return }
    foreach {x0 y0 xn yn} [$widget(board) bbox piece] {
	set x [$widget(board) canvasx [expr {($xn+$x0)/2}] $tetris(blocksize)]
	set y [$widget(board) canvasy [expr {($yn+$y0)/2}] $tetris(blocksize)]
    }
    set flag 1
    foreach i $ix {
	set p [$widget(board) coords $i]
	if {[string equal Left $dir]} {
	    set cd [list [expr { [lindex $p 1]+$x-$y}] \
		    [expr {-[lindex $p 0]+$x+$y}] \
		    [expr { [lindex $p 3]+$x-$y}] \
		    [expr {-[lindex $p 2]+$x+$y}]]
	} else {
	    set cd [list [expr {-[lindex $p 1]+$x+$y}] \
		    [expr { [lindex $p 0]-$x+$y}] \
		    [expr {-[lindex $p 3]+$x+$y}] \
		    [expr { [lindex $p 2]-$x+$y}]]
	}
	set n [lindex [eval [list $widget(board) find enclosed] $cd] 0]
	if {$n == "" || $block([incr n -1])} {
	    set flag 0
	    break
	}
	set m [lindex [eval [list $widget(board) find enclosed] $p] 0]
	incr m -1
	set coords($m)  [concat $i $cd]
	set coords(_$m) $n
    }
    if {$flag} {
	foreach i {0 1 2 3} {
	    foreach {p x1 y1 x2 y2} $coords($piece($i)) {
		$widget(board) coords $p $x1 $y1 $x2 $y2
		if {[info exists piece(_img$i)]} {
		    if {$x1 > $x2} { set x1 $x2 }
		    if {$y1 > $y2} { set y1 $y2 }
		    $widget(board) coords $piece(_img$i) $x1 $y1
		}
	    }
	    set piece($i) $coords(_$piece($i))
	}
	Shadow
	update idletasks
    }
}

proc DropRows {} {
    variable tetris
    variable block
    variable piece
    variable widget
    variable color

    set full {}
    foreach {i j} [array get piece {[0-3]}] {
	if {[set j [expr {$j/10}]]} { set tmp($j) {} }
    }
    foreach i [array names tmp] {
	if {
	    $block(${i}0) && $block(${i}1) && $block(${i}2) && $block(${i}3) &&
	    $block(${i}4) && $block(${i}5) && $block(${i}6) && $block(${i}7) &&
	    $block(${i}8) && $block(${i}9)
	} {
	    lappend full $i
	    array set block [list ${i}0 0 ${i}1 0 ${i}2 0 ${i}3 0 \
		    ${i}4 0 ${i}5 0 ${i}6 0 ${i}7 0 ${i}8 0 ${i}9 0]
	}
    }
    if {[set i [llength $full]]} {
	incr tetris(score) [expr {round(pow($i,2))*($tetris(level)+1)}]
	incr tetris(rows)  $i
	incr tetris(maxbrick) -$i
	if {($tetris(rows)/10) > $tetris(level)} {
	    ## Move to the next level
	    incr tetris(level)
	    $widget(board) itemconfig back \
		    -fill $color([expr {$tetris(level)%7}])
	    bell
	    SetIntervalLevel $tetris(level)
	}

	foreach row [lsort -integer $full] {
	    $widget(board) delete row$row
	    for {set i $row; incr i -1} {$i > 0} {incr i -1} {
		$widget(board) move row$i 0 $tetris(blocksize)
		$widget(board) addtag row[expr {$i+1}] with row$i
		$widget(board) dtag row$i
	    }
	    update idletasks
	    for {set i ${row}0} {$i > 0} {incr i -1} {
		if {$block($i)} {
		    set block([expr {$i+10}]) 1
		    set block($i) 0
		}
	    }
	}
	update
    }
}

proc AddRows {num} {
    variable tetris
    variable block
    variable widget
    variable piece

    if {$num>4 || $num<1} return
    set w $widget(board)

    ## Move pieces
    set bs $tetris(blocksize)

    ## Check if the piece will be moved off the board, if so, we delete it
    set shift [expr {$num*-$bs}]
    $w move piece 0 $shift
    set y [lindex [$w bbox piece] 1]
    if {![string compare {} $y]} {
	# no piece
    } elseif {$y < -2} {
	$w delete piece
    } else {
	set i [expr {$num*-10}]
	incr piece(0) $i
	incr piece(1) $i
	incr piece(2) $i
	incr piece(3) $i
    }

    $w move struc 0 $shift
    $w move strucimg 0 $shift
    for {set i 0} {$i < 31} {incr i} {
	$w addtag row[expr {$i-$num}] with row$i
	$w dtag row$i
    }
    if {$tetris(maxbrick)>29} {
	GameOver
	return
    }
    ## Reassign block vars
    set move ${num}0
    for {set i 0} {$i<300} {incr i} {
	if {$block($i)} {
	    set block([expr {$i-$move}]) 1
	    set block($i) 0
	}
    }
    ## Add random black structure blocks
    set numblocks 0
    for {set i [expr {300-$move}]} {$i < 300} {incr i} {
	if {[random]} {
	    set block($i) 1
	    set row [expr {$i/10}]
	    $w create rectangle [expr {($i%10)*$bs}] [expr {$row*$bs}] \
		    [expr {($i%10+1)*$bs}] [expr {($row+1)*$bs}] \
		    -tags "row$row struc" -fill black
	    incr numblocks
	}
	if {$numblocks == 9} {
	    ## jump one block for every nine that we add.
	    ## this ensures that we don't make a whole row of new blocks
	    set numblocks 0
	    incr i
	}
    }
    $w itemconfig struc -stipple gray50
}

expr {srand([clock clicks]%65536)}
proc random {{range 2}} {
    return [expr {int(rand()*$range)}]
}

if {$::argv0 == [info script]} {
    Init
}

}; # end namespace
