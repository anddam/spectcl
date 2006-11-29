# edit_ui.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::edit {
    variable W
    set W(lang) ""

    set W(command)	"#893793"; # purple
    set W(comment)	"#A03030"; # maroon
    set W(syntax)	"#1F2FAA"; # dark blue
    set W(var)		"#507850"; # dark green

    # class type pattern color
    set W(tcl) [list \
	    [list comment ClassForRegexp {\#\[^\n\]*} $W(comment)] \
	    [list var     ClassWithOnlyCharStart "\$" $W(var)] \
	    [list syntax  ClassForSpecialChars "\[\]{}\"" $W(syntax)] \
	    [list command Class [info commands] $W(command)] \
	    ]
    set W(tcl84) $W(tcl)
    set W(perl) [list \
	    [list comment ClassForRegexp {\#\[^\n\]*} $W(comment)] \
	    [list var     ClassWithOnlyCharStart "\$" $W(var)] \
	    [list syntax  ClassForSpecialChars "\[\]{}()\"'" $W(syntax)] \
	    [list command Class {
	if else return continue break next for sub use require
    } $W(command)] \
	    ]
    set W(tkinter) [list \
	    [list comment ClassForRegexp {\#\[^\n\]*} $W(comment)] \
	    [list syntax  ClassForSpecialChars "\[\]{}()\"'" $W(syntax)] \
	    [list command Class {
	if else return continue break for def import class from
    } $W(command)] \
	    ]
}


proc ::edit::dismiss {{apply 1}} {
    variable W
    if {$apply} { apply }
    destroy $W(root)
}

proc ::edit::apply {} {
}

proc ::edit::highlight {} {
    variable W

    set w $W(text)
    if {$W(lang) != [targetLanguage]} {
	# The language changed
	set W(lang) [targetLanguage]

	# Remove all highlight classes from a widget:
	ctext::clearHighlightClasses $w

	if {[info exists W($W(lang))]} {
	    foreach class $W($W(lang)) {
		foreach {cname ctype cptn ccol} $class break
		ctext::addHighlight$ctype $w $cname $ccol $cptn
	    }
	}
    }

    $w configure -state normal
    $w highlight 1.0 end
    $w configure -state disabled
}

proc ::edit::revert {} {
    variable W
}

#   root     is the parent window for this user interface
proc edit_ui {root data args} {
    variable ::edit::W
    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]

    set sw [widget::scrolledwindow $base.sw]
    set t  [ctext $sw.text -font defaultFixedFont \
		-height 20 -width 70 -wrap none]
    $sw setwidget $t

    set W(root) $root
    set W(text) $t

    set btns [ttk::frame $base.btns]
    ttk::button $btns.ok  -width 8 -text "OK" -default active \
	-command {::edit::dismiss 1}
    ttk::button $btns.app -width 8 -text "Apply" -state disabled \
	-command ::edit::apply
    ttk::button $btns.can -width 8 -text "Cancel" \
	-command {::edit::dismiss 0}

    grid x $btns.ok $btns.can $btns.app -padx 4 -pady {6 4}
    grid configure $btns.app -padx [list 4 [pad corner]]
    grid columnconfigure $btns 0 -weight 1

    bind [winfo toplevel $root] <Return> [list $btns.ok invoke]
    bind [winfo toplevel $root] <Escape> [list $btns.can invoke]

    grid $base.sw   -row 0 -sticky nesw
    grid $base.btns -row 1 -sticky ew

    # Resize behavior management
    grid rowconfigure    $root 0 -weight 1
    grid columnconfigure $root 0 -weight 1

    # additional interface code
    $t insert 1.0 $data

    tkwait visibility $root
    focus $t

    after idle [list ::edit::highlight]
}
