# SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
#
# See the file "license.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
proc recipe_box {canvas args} {
    global tcl_platform

    frame $canvas -bd 0 -relief flat
    frame $canvas.holder -bd 2 -relief raised
    if {$tcl_platform(platform) == "macintosh"} {
	$canvas config -bg #a0a0a0
	$canvas.holder config -bg #a0a0a0
    }
    grid $canvas.holder -row 1 -column 0 -sticky nsew
    grid rowconfigure $canvas.holder 0 -minsize 5
    grid rowconfigure $canvas.holder 1 -weight 1
    grid columnconfigure $canvas.holder 0 -weight 1
    upvar \#0 [winfo name $canvas]combobox c
    grid rowconfigure $canvas 0 -minsize 20
    grid rowconfigure $canvas 1 -weight 1
    grid columnconfigure $canvas 0 -weight 1
    grid propagate $canvas 1
    frame $canvas.hide -bd 0 -relief flat
    grid $canvas.hide -in $canvas.holder -row 0 -column 0 -sticky nsew \
	-rowspan 2
    set c(currenttab) 0
    set c(totaltabs) 0
    set c(next) 15
    set c(xpadding) 5
    set c(ypadding) 5
    set c(top) 5
    set c(contentheight) 0
    foreach {t f} $args {
	if {$t != "" && $f != ""} {
	    eval "recipe_tab $canvas [list $t] [list $f]"
	}
    }
    return $canvas
}

proc recipe_tab {canvas text win} {
    upvar \#0 [winfo name $canvas]combobox c
    global tcl_platform

    set i [incr c(totaltabs)]

    frame $canvas.$i -bd 2 -relief raised
    if {$tcl_platform(platform) == "macintosh"} {
	$canvas.$i config -bg #a0a0a0
    }
    set font "Helvetica,12,Bold"
    OutFilter_font dummy font font
    label $canvas.$i.l -text $text -padx $c(xpadding) -pady $c(ypadding) \
	-font $font -anchor n
    set wideness [expr [winfo reqwidth $canvas.$i.l]+14]
    pack $canvas.$i.l -side top -expand yes -fill both
    bind $canvas.$i.l <1> "recipe_raise_tab $canvas $i"
    bind $canvas.$i <1> "recipe_raise_tab $canvas $i"
    set c($i) $win
    recipe_raise_tab $canvas $i
    update idletasks
    if {$i > 1} {
	set idx 1
	set x 0
	while {$idx < $i} {
	    set x [expr $x + [winfo reqwidth $canvas.$idx] + 8]
	    incr idx
	}
	set h [winfo reqheight $canvas.[expr $i-1].l]
    } else {
	set x 0
	set y 0
	set h 0
    }
    set height [grid rowconfigure $canvas 0 -minsize]
    if {$h > $height} {
	grid rowconfigure $canvas 0 -minsize [expr $h + 5]
    }
    place $canvas.$i -x [expr $x] -y 0 -height 100 -width $wideness
    grid $win -in $canvas.holder -row 1 -column 0 -sticky nsew
}

proc recipe_raise_tab {canvas tab} {
    upvar \#0 [winfo name $canvas]combobox c
    if {[info exist c(last)]} {
	set f [$canvas.$c(last).l cget -font]
	InFilter_font f
	set base {}
	set style {}
	if {[regexp {([^,]*,[^,]*)(.*)} $f dummy base style]} {
	    regsub -- {Bold} $style {} style
	    set f $base,$style
	    OutFilter_font dummy f f
	    catch {$canvas.$c(last).l config -font $f}
	}
    }
    
    set c(last) $tab
    set f [$canvas.$tab.l cget -font]
    InFilter_font f
    set base {}
    set style {}
    if {[regexp {([^,]*,[^,]*)(.*)} $f dummy base style]} {
	regsub -- {Bold} $style {} style
	set f "$base,${style}Bold"
	OutFilter_font dummy f f
	catch {$canvas.$tab.l config -font $f}
    }
    raise $canvas.holder
    raise $canvas.$tab
    raise $c($tab)
    raise $canvas.hide
}
