# menued.tcl --
#
#	This file implements package menued, which  ...
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::menued {}
namespace eval ::widget {}

proc ::widget::menus {{type *}} {
    # return menus in inorder depth-first order
    set t [gettree app]
    if {![$t exists "MENU"]} {
	return ""
    }
    set all [$t children "MENU"]
    if {$type eq "*"} {
	return $all
    } else {
	set out [list]
	foreach w $all {
	    if {[string match $type [$t get $w -key TYPE]]} {
		lappend out $w
	    }
	}
	return $out
    }
}

proc ::widget::parent {node} {
    set t [gettree app]
    return [$t get $node -key MASTER]
}

proc ::widget::id {node {id {}}} {
    if {[llength [info level 0]] > 2} {
	::widget::data $node -label $id
    }
    return [::widget::data $node -label]
}

proc ::widget::menutype {node} {
    set t [gettree app]
    # return image based on type
    if {$node eq "MENU"} { return "Menu cascade" }
    return [$t get $node -key TYPE]
}

proc ::widget::getimage {node} {
    set t [gettree app]
    # return image based on type
    return [::widget::get [$t get $node -key TYPE] image]
}

proc ::widget::new_menuitem {type {node "MENU"} {refresh 0}} {
    if {$node eq ""} { set node "MENU" }

    set t [gettree app]
    # the actual type of menu item
    set wcmd [::widget::get $type command]

    set name menuitem[::widget::uid menuitem]
    $t insert "MENU" end $name
    $t set $name $name
    $t set $name -key TYPE   $type
    #$t set $name -key ID     $name
    $t set $name -key GROUP  Menu
    $t set $name -key MASTER $node

    set menu $::W(USERMENU)
    lappend config $menu add $wcmd

    array set opts    [::widget::get $type options -default]
    array set reflect [::widget::get $type options -reflect]
    foreach opt [array names opts] {
	# Apply a default value to the -text option of a widget
	if {$opt eq "-label" && $opts($opt) eq ""} {
	    set opts($opt) $name
	}
	$t set $name -key $opt $opts($opt)
	# Make sure that we know whether an option should be "reflected"
	if {!$reflect($opt)} { continue }
	lappend config $opt $opts($opt)
    }

    uplevel #0 $config
    dirty yes
    if {$refresh} {
	::palette::refresh menu
    }
    return $name
}

proc ::widget::delete_menuall {} {
    set t [gettree app]
    set menu $::W(USERMENU)
    destroy $menu
    if {[$t exists "MENU"]} {
	$t delete "MENU"
	dirty yes
    }
}

proc ::widget::delete_menu {args} {
    set t [gettree app]
    foreach w $args {
	if {$w eq "MENU"} {
	    delete_menuall
	    return
	}
	if {[$t exists $w]} {
	    # Make sure to remove children of a cascade
	    foreach m [$t children "MENU"] {
		# Extra recursion delete sanity check
		if {![$t exists $m]} { continue }
		if {[$t get $m -key MASTER] eq $w} {
		    delete_menu $m
		}
	    }
	    $t delete $w
	}
    }
    dirty yes
}

proc ::menued::show {{invert 1}} {
    variable W
    variable show

    if {$invert} { set show [expr {!$show}] }

    if {$show} {
	grid $W(root)
    } else {
	grid remove $W(root)
    }

    # Redisplay menu structure

}

proc ::menued::update_menubar {} {
    variable W
    variable M

    set root $W(root)
    eval [list destroy] [winfo children $root]

    foreach w [::widget::menus] {
	set type [lindex [::widget::menutype $w] end]
	set master [::widget::parent $w]
	set label [::widget::id $w]
	array set data [::widget::data $w]
	if {$master eq "MENU"} {
	    switch -exact $type {
		cascade {
		    menubutton $root.$w -text $data(-label) \
			-image $data(-image) -bitmap $data(-bitmap)
		    set M($w) [menu $root.$w.menu -tearoff 0]
		    $root.$w configure -menu $M($w)
		    if {[info exists data(-compound)]} {
			$root.$w configure -compound $data(-compound)
		    }
		    pack $root.$w -side left -fill both
		}
		command -
		checkbutton -
		radiobutton -
		separator -
		default {
		    error "how did a $type item get to be a child of MENU?"
		}
	    }
	} else {
	    # make sure to only use -* options
	    if {$type eq "cascade"} {
		set M($w) [menu $M($master).menu$w -tearoff 0]
		set data(-menu) $M($w)
	    }
	    if {[info exists data(-command)]} {
		set data(-command) [list ::palette::activate menu 1 $w]
	    }
	    eval [list $M($master) add $type] [array get data -*]
	}
	unset data
    }

    button $root.next -bg white -fg grey -relief solid -bd 1 \
	-padx 2 -pady 2 \
	-textvariable [namespace current]::nextvar \
	-command [list ::widget::new_menuitem "Menu cascade" "MENU" 1]

    pack $root.next -side left -fill both

    help::balloon $root "Menu Editor"
    help::balloon $root.next "Enter new cascade menu here"
}

proc ::menued::init {root args} {
    variable show 0
    variable W
    variable nextvar "New Cascade"
    set W(root) $root

    grid remove $root

    update_menubar
}
