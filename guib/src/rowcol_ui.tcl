# rowcol.ui.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

#   root     is the parent window for this user interface

package require BWidget

namespace eval ::rowcol {
    variable W

    #
    # Determine default values for -minsize, -weight and -pad
    #
    variable DEFAULTS
    variable w .____testf
    destroy $w
    frame $w ; # NOTILE
    foreach type {row column} {
	set DEFAULTS($type) [grid ${type}configure $w 0]
    }
    destroy $w
}

# DESCRIPTION
#   Opens the Row & Column editing window
# SOURCE
#
proc ::rowcol::OpenWindow {} {
    set w .rowColProps
    if {![winfo exists $w]} {
	toplevel $w
	wm withdraw $w
	wm title $w "Row / Column Properties"
	wm transient $w $::W(ROOT)
	# only resize width
	wm resizable $w 1 0
	::rowcol::ui $w
	::gui::PlaceWindow $w widget $::W(ROOT)
    }
    ::rowcol::init $w
    wm deiconify $w
    tkwait visibility $w
    grab $w
}

# DESCRIPTION
#    Initialises the RowCol window
# SOURCE
#
proc ::rowcol::init {root} {
    variable W
    variable VAL
    variable DEFAULTS
    # Create the variables $root, $base and $mbase
    set base [expr {($root == ".") ? "" : $root}]

    # Put in widgets for row & column properties
    set title ""
    foreach dim {row column} {
	set w $W($dim,frame)
	if {$::Current($dim) == ""} {
	    # remove this frame for now, and unweight the column this was in
	    # to allow better resize behavior
	    array set ginfo [grid info $w]
	    if {[info exists ginfo(-in)]} {
		grid columnconfigure $ginfo(-in) $ginfo(-column) -weight 0
	    }
	    grid remove $w
	    continue
	}
	foreach {master i} [::arrow::parsetag $::Current($dim)] break
	# master can be $::W(FRAME)
	set master [winfo name $master]
	set pos [expr {$i/2-1}]
	foreach {opt val} $DEFAULTS($dim) {
	    set opt [string range $opt 1 end] ; # remove '-'
	    # Get initial values
	    switch -exact -- $opt {
		minsize	{ set val [::widget::geometry $master min_$dim] }
		weight	{ set val [::widget::geometry $master weight_$dim] }
		pad	{ set val [::widget::geometry $master pad_$dim] }
		default	{
		    # only -minsize -weight and -pad currently supported
		    continue
		}
	    }

	    # This is the tied textvariable
	    set VAL($dim,$opt) [lindex $val $pos]
	}

	grid $w
	array set ginfo [grid info $w]
	grid columnconfigure $ginfo(-in) $ginfo(-column) -weight 1
	$w configure -text "[string totitle $dim] [incr pos] Properties"
    }

    bind $root <Destroy> [subst {grab release [list $root]; focus [focus]}]
}

#
# DESCRIPTION
#   Saves the data from the entry widgets in global arrays
# SOURCE
#
proc ::rowcol::apply {} {
    variable VAL
    foreach {dim} {row column} {
	if {$::Current($dim) == ""} {continue}
	foreach {master i} [::arrow::parsetag $::Current($dim)] break
	# master can be $::W(FRAME)
	set pos [expr {$i/2-1}]
	foreach {key wpart} \
	    [list min_$dim minsize weight_$dim weight pad_$dim pad] {
	    if {![string is integer -strict $VAL($dim,$wpart)]} {
		set VAL($dim,$wpart) 0
	    }
	    ::widget::geometry $master $key \
		[lreplace [::widget::geometry $master $key] \
		     $pos $pos $VAL($dim,$wpart)]
	}
	grid ${dim}configure $master $i \
	    -pad     [lindex [::widget::geometry $master pad_$dim] $pos] \
	    -minsize [lindex [::widget::geometry $master min_$dim] $pos]
	set weight [lindex [::widget::geometry $master weight_$dim] $pos]
	resize_set $master $dim $i [expr {$weight ? 3: 1}]
	# can be modified by resize_set
	set weight [lindex [::widget::geometry $master weight_$dim] $pos]
	arrow_shape $::W(CANVAS) $master $dim $i [expr {$weight > 0}]
    }
    update idletasks
    arrow_update $::W(CANVAS) $master
}

# ::rowcol::dismiss --
#
#   Dismiss the window
#
# Arguments:
#   root	toplevel widget
#   apply	whether to apply changes first
# Results:
#   Returns ...
#
proc ::rowcol::dismiss {root apply} {
    if {$apply} { apply }
    grab release $root
    wm withdraw $root
}


proc ::rowcol::ui {root args} {
    variable W
    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]

    foreach dim {row column} {
	ttk::labelframe $base.f$dim -padding [pad labelframe]
	set W($dim,frame) [set f $base.f$dim]

	ttk::label $f.lminsize -text "Minimum Size:" -anchor e
	spinbox $f.minsize -width 3 -highlightthickness 1 \
	    -textvariable ::rowcol::VAL($dim,minsize) \
	    -from 0 -to 100 -increment 5 -readonlybackground white \
	    -validate key -validatecommand {string is integer %P} \
	    -invalidcommand bell

	ttk::label $f.lweight -text "[string totitle $dim] Weight:" -anchor e
	if {$::AQUA} {
	    set m $f.weight.menu
	    ttk::menubutton $f.weight -menu $m -width 2 -direction flush \
		-textvariable ::rowcol::VAL($dim,weight)
	    menu $m
	    for {set i 0} {$i <= 10} {incr i} {
		$m add radiobutton -label $i -value $i \
		    -variable ::rowcol::VAL($dim,weight)
	    }
	} else {
	    spinbox $f.weight -width 3 -highlightthickness 1 \
		-textvariable ::rowcol::VAL($dim,weight) \
		-from 0 -to 10 -increment 1 -readonlybackground white \
		-validate key -validatecommand {string is integer %P} \
		-invalidcommand bell
	}

	ttk::label $f.lpad -text "Widget Pad:" -anchor e
	if {$::AQUA} {
	    set m $f.pad.menu
	    ttk::menubutton $f.pad -menu $m -width 2 -direction flush \
		-textvariable ::rowcol::VAL($dim,pad)
	    menu $m
	    for {set i 0} {$i <= 10} {incr i} {
		$m add radiobutton -label $i -value $i \
		    -variable ::rowcol::VAL($dim,pad)
	    }
	} else {
	    spinbox $f.pad -width 3 -highlightthickness 1 \
		-textvariable ::rowcol::VAL($dim,pad) \
		-from 0 -to 10 -increment 1 -readonlybackground white \
		-validate key -validatecommand {string is integer %P} \
		-invalidcommand bell
	}

	grid $f.lminsize $f.minsize -sticky ew
	grid $f.lweight  $f.weight  -sticky ew
	grid $f.lpad     $f.pad     -sticky ew
	grid columnconfigure $f 1 -weight 1
	grid rowconfigure    $f 4 -weight 1
    }

    # [OK] [Cancel] [Apply]
    set btns [ttk::frame $base.btns]
    ttk::button $btns.ok  -width 8 -text "OK" -default active \
	-command [list ::rowcol::dismiss $root 1]
    ttk::button $btns.app -width 8 -text "Apply" -state normal \
	-command [list ::rowcol::apply]
    ttk::button $btns.can -width 8 -text "Cancel" \
	-command [list ::rowcol::dismiss $root 0]

    grid x $btns.ok $btns.can $btns.app -padx 4 -pady {6 4}
    grid configure $btns.app -padx [list 4 [pad corner]]
    grid columnconfigure $btns 0 -weight 1

    bind $root <Return> [list $btns.ok invoke]
    bind $root <Escape> [list $btns.can invoke]

    # Geometry management

    grid $base.frow    -in $root -row 1 -column 1 -sticky news -padx 4 -pady 2
    grid $base.fcolumn -in $root -row 1 -column 3 -sticky news -padx 4 -pady 2

    grid $base.btns    -in $root -row 3 -column 1 -columnspan 3 -sticky ew

    # Resize behavior management

    grid rowconfigure    $root 1 -weight 1
    grid columnconfigure $root 1 -weight 1
    grid columnconfigure $root 3 -weight 1

    # Return focus to . when window is destroyed
    bind $root <Unmap> [list grab release $root]

    # end additional interface code
}
