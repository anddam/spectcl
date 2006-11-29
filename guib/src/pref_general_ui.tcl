# pref_general_ui.tcl --
#
#	This file implements package p, which  ...
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

#   root     is the parent window for this user interface
proc ::prefs::ui_general {root cacheVar args} {
    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]

    set lframe [ttk::frame $base.left]
    set rframe [ttk::frame $base.right]

    set ehframe [ttk::labelframe $rframe.ehframe -text "Help:" \
		     -padding [pad labelframe]]

    grid $lframe -row 0 -column 0 -sticky nw
    grid $rframe -row 0 -column 1 -sticky new -ipadx 2 -ipady 2

    grid rowconfigure    $root 1 -weight 1
    grid columnconfigure $root 1 -weight 1

    # lframe
    ttk::checkbutton $lframe.gridline \
	    -text "Insert if widget dropped on gridline" \
	    -variable ${cacheVar}(insert_on_gridline)
    help::balloon $lframe.gridline "When a widget is dropped on a gridline,\
	    this\nwill cause a row or column to first be inserted"

    ttk::checkbutton $lframe.confirm \
	    -text "Confirm saves before Test" \
	    -variable ${cacheVar}(confirm-save-layout)
    help::balloon $lframe.confirm "If selected, you will be prompted before\
	    \nthe saving of generated files for testing"

    ttk::checkbutton $lframe.delete \
	    -text "Confirm widget delete" \
	    -variable ${cacheVar}(confirm-delete-item)
    help::balloon $lframe.delete "If selected, you will be prompted\
	    \nbefore a widget is deleted"

    ttk::checkbutton $lframe.autosave \
	    -text "Autosave on quit" \
	    -variable ${cacheVar}(confirm-autosave-on-quit)
    help::balloon $lframe.autosave "If selected, the current dialog will\
	    \nautomatically be saved on exit"

    grid $lframe.gridline -sticky w
    grid $lframe.confirm  -sticky w
    grid $lframe.delete   -sticky w
    grid $lframe.autosave -sticky w

    # rframe
    ttk::label $rframe.lmgrav -anchor e -text "Mouse Gravity:" -width 12
    if {$::AQUA} {
	set m $rframe.mgrav.menu
	ttk::menubutton $rframe.mgrav -menu $m -width 2 -direction flush \
	    -textvariable ${cacheVar}(gravity)
	menu $m
	for {set i 1} {$i <= 10} {incr i} {
	    $m add radiobutton -label $i -value $i \
		-variable ${cacheVar}(gravity)
	}
    } else {
	spinbox $rframe.mgrav -width 3 -from 1 -to 10 -increment 1 \
	    -validate key -validatecommand {string is integer %P} \
	    -textvariable ${cacheVar}(gravity) \
	    -state readonly -readonlybackground white
    }
    help::balloon $rframe.mgrav "how many pixels of mouse motion \"counts\""

    if 0 {
	label $rframe.lsdelay -anchor e -text "Scroll Delay:" -width 12
	spinbox $rframe.sdelay -width 3 -from 50 -to 150 -increment 25 \
		-validate key -validatecommand {string is integer %P} \
		-textvariable ${cacheVar}(scroll_delay)
	help::balloon $rframe.sdelay "ms to wait for scrolling canvas widget"
    }

    grid $rframe.lmgrav  $rframe.mgrav -sticky ew
    if 0 { grid $rframe.lsdelay $rframe.sdelay -sticky ew }
    grid $ehframe -columnspan 2 -sticky ew
    grid columnconfigure $rframe 0 -weight 1
    grid columnconfigure $rframe 1 -weight 1

    # ehframe
    ttk::checkbutton $ehframe.tooltips \
	    -text "Show Tooltips" \
	    -variable ${cacheVar}(show-tooltips)
    help::balloon $ehframe.tooltips \
	    "Whether to display tooltips balloon help"

    ttk::checkbutton $ehframe.sbhelp \
	    -text "Show Statusbar Help" \
	    -variable ${cacheVar}(show-statushelp)
    help::balloon $ehframe.sbhelp \
	    "Whether to display context-sensitive help displayed in status bar"

    grid $ehframe.tooltips -row 0 -column 0 -sticky w
    grid $ehframe.sbhelp -row 1 -column 0 -sticky w
    grid columnconfigure $ehframe 1 -weight 1

}
