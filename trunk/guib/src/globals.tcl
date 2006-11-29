# globals.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# Initializes various information about the global state of the application.
#

#
# Code to provide for a sharper default look and feel
#

proc defopts_init {{prio widgetDefault}} {
    option add *Listbox.activeStyle dotbox $prio
    if {[lsearch -exact [font names] defaultFont] == -1} {
	set cmd create
    } else {
	set cmd configure
    }
    if {[tk windowingsystem] eq "x11"} {
	font $cmd defaultFont      -size 9 -family Helvetica
	font $cmd defaultBoldFont  -size 9 -family Helvetica -weight bold
	font $cmd defaultFixedFont -size 9 -family Courier

	option add *Text.font defaultFixedFont $prio

	option add *Button.font      defaultFont $prio
	option add *Canvas.font      defaultFont $prio
	option add *Checkbutton.font defaultFont $prio
	option add *Entry.font       defaultFont $prio
	option add *Label.font       defaultFont $prio
	option add *Labelframe.font  defaultFont $prio
	option add *Listbox.font     defaultFont $prio
	option add *Menu.font        defaultFont $prio
	option add *Menubutton.font  defaultFont $prio
	option add *Message.font     defaultFont $prio
	option add *Radiobutton.font defaultFont $prio

	option add *Menu.borderWidth 1 $prio
    } elseif {[tk windowingsystem] eq "win32"} {
	# Use Win2K/XP defaults
	font $cmd defaultFont      -size 8 -family {Tahoma}
	font $cmd defaultBoldFont  -size 8 -family {Tahoma} -weight bold
	font $cmd defaultFixedFont -size 8 -family Courier
    } elseif {[tk windowingsystem] eq "aqua"} {
	# Use Aqua defaults
	set def [font actual system]
	eval [list font $cmd defaultFont] $def
	eval [list font $cmd defaultBoldFont] $def [list -weight bold]
	font $cmd defaultFixedFont -size 13 -family Courier
    }
    option add *Menubutton*padX 4 $prio
    option add *Menubutton*padY 2 $prio
}
defopts_init

proc globals_init {} {
    catch {unset ::Current}
    set ::Current(after)	  0  ;# after id for current auto-repeat event
    set ::Current(row)		  "" ;# the currently selected row tag
    set ::Current(column)	  "" ;# the currently selected column tag
    set ::Current(repeat)	  "" ;# toolbar repeat command for ^.
    set ::Current(gridline)	  "" ;# currently selected gridline
    set ::Current(widget)	  "" ;# name of "current widget(s)?"
    set ::Current(palette_widget) "" ;# palette widget type that's selected.
    set ::Arrow_move		  0  ;# currently sweeping row/col arrows
    set ::Down			  0  ;# true if button is down
    set ::X0			  0  ;# cached mouse position on B-down
    set ::Y0			  0  ;# cached mouse position on B-down
}
globals_init
