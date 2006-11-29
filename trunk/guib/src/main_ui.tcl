# main_ui.tcl --
#
#	Main dialog creation procedure.
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
namespace eval ::main {}

######## Stuff added to support row/column indicators

# scroll multiple canvii with a single scroll bar
#   list:		The list of canvii to scroll
#   how:		"x" or "y"
#   args:		The rest

proc ::main::can_view {canvases cmd args} {
    foreach w $canvases {
	eval [linsert $args 0 $w $cmd]
    }
}

# ui --
#
#   Create the main dialog for the gui builder
#
#   root     is the parent window for this user interface
#
proc ::main::ui {root args} {
    global W
    # this treats "." as a special case
    set base [expr {($root eq ".") ? "" : $root}]
    set W(ROOT) $root
    set W(BASE) $base

    if {[tk windowingsystem] eq "win32"} {
	# divides menu from everything else on Windows, not needed on Unix
	ttk::separator $base.menudivider -orient horizontal
    }

    # Toolbar
    ttk::frame $base.toolbar; # Avoid -class Toolbar because of iwidgets

    # Centre Section (panedwindow)
    set pw [panedwindow $base.pw -orient horizontal -bd 0 -relief flat \
		-sashpad 0 -sashwidth 3 -sashrelief flat -showhandle 0]

    # Widget Palette (main left)
    set W(PALETTE) [ttk::frame $pw.palette -relief sunken]

    # Centre Right (menu editor, dialog canvas)
    set crf [ttk::frame $pw.crf -relief sunken]

    set W(MENUED) [ttk::frame $crf.menued]

    image create photo imggridsizeon -width 6 -height 6
    #image create photo imggridsizeoff -width 6 -height 6
    #-selectimage imggridsizeoff
    checkbutton $crf.gsize -indicatoron 0 -variable ::P(show-grid) \
	-image imggridsizeon -selectcolor $::P(grid_color) -bd 1 \
	-width 6 -height 6 -highlightthickness 0 -padx 0 -pady 0 \
	-command {grid_update_size [grid_line_size]}
    if {$::AQUA} {
	$crf.gsize configure -width 2 -height 2
    }
    help::balloon $crf.gsize "Click here to toggle the grid lines on/off"

    set W(CAN_COL) [canvas $crf.can_column \
			-background white \
			-height 8 \
			-width  0 \
			-highlightthickness 0 \
			-bd 0 -relief sunken \
			-xscrollincrement 10]
    $W(CAN_COL) xview moveto 0
    $W(CAN_COL) yview moveto 0

    set W(CAN_ROW) [canvas $crf.can_row \
			-background white \
			-height 0 \
			-width  8 \
			-highlightthickness 0 \
			-bd 0 -relief sunken \
			-yscrollincrement 10]
    $W(CAN_ROW) xview moveto 0
    $W(CAN_ROW) yview moveto 0

    # This is for arrow.tcl
    set W(CAN_row)    $W(CAN_ROW)
    set W(CAN_column) $W(CAN_COL)

    # We create an extra frame for the canvas with the sunken characteristics
    # in order to have it display correctly onscreen
    frame $crf.cframe -bd 1 -relief sunken
    set W(CANVAS) [canvas $crf.can \
		       -highlightthickness 0 \
		       -height 0 \
		       -width  0 \
		       -xscrollcommand [list scroll_set $crf.can_xscroll] \
		       -xscrollincrement 10 \
		       -yscrollcommand [list scroll_set $crf.can_yscroll] \
		       -yscrollincrement 10]
    $W(CANVAS) xview moveto 0
    $W(CANVAS) yview moveto 0
    grid $W(CANVAS) -in $crf.cframe -sticky news
    grid rowconfigure    $crf.cframe 0 -weight 1
    grid columnconfigure $crf.cframe 0 -weight 1

    scrollbar $crf.can_xscroll -orient horizontal \
	-command [list ::main::can_view [list $W(CANVAS) $W(CAN_COL)] xview]

    scrollbar $crf.can_yscroll -orient vertical \
	-command [list ::main::can_view [list $W(CANVAS) $W(CAN_ROW)] yview]

    # Centre right frame geom
    $pw add $W(PALETTE) -sticky news
    $pw add $pw.crf     -sticky news
    grid $crf.menued      -in $crf -row 1 -column 1 -columnspan 3 -sticky ew
    grid $crf.gsize       -in $crf -row 2 -column 1 -sticky news
    grid $crf.can_column  -in $crf -row 2 -column 2 -sticky nesw
    grid $crf.can_row     -in $crf -row 3 -column 1 -sticky nesw
    grid $crf.cframe      -in $crf -row 3 -column 2 -sticky nesw
    grid $crf.can_yscroll -in $crf -row 3 -column 3 -sticky ns
    grid $crf.can_xscroll -in $crf -row 4 -column 2 -sticky ew
    grid rowconfigure    $crf 3 -weight 1 ; # main canvas
    grid columnconfigure $crf 2 -weight 1 ; # main canvas

    # status window widgets
    set pw [panedwindow $base.statpane -bd 0 -relief flat -sashwidth 3 \
		-orient horizontal -showhandle 0 -sashpad 0 -sashrelief flat]
    set bg [$root cget -bg]
    if {0 && $::TILE} {
	set W(STATUSHELP) [ttk::entry $pw.statushelp -takefocus 0 \
			       -state readonly -cursor "" \
			       -textvariable ::G(HELPMSG)]
	set W(MESSAGE)    [ttk::entry $pw.message -takefocus 0 \
			       -state readonly -cursor "" \
			       -textvariable ::_Message]
    } else {
	set W(STATUSHELP) [entry $pw.statushelp -background $bg -takefocus 0 \
			       -relief sunken -bd 1 -state disabled \
			       -textvariable ::G(HELPMSG) -cursor "" \
			       -highlightthickness 0 \
			       -disabledbackground $bg -disabledforeground black]
	set W(MESSAGE)    [entry $pw.message -background $bg -takefocus 0 \
			       -relief sunken -bd 1 -state disabled \
			       -textvariable ::_Message -cursor "" \
			       -highlightthickness 0 \
			       -disabledbackground $bg -disabledforeground black]
    }
    $pw add $W(STATUSHELP) -sticky ew -width 250
    $pw add $W(MESSAGE)    -sticky ew -width 150

    # Geometry management

    if {[winfo exists $base.menudivider]} {
	grid $base.menudivider -in $root -row 1 -column 1 -sticky ew
    }
    grid $base.toolbar  -in $root -row 2 -column 1 -sticky ew
    grid $base.pw       -in $root -row 3 -column 1 -sticky news
    grid $base.statpane -in $root -row 4 -column 1 -sticky ew \
	-pady {4 2} -padx 2
    if {$::AQUA} {
	grid configure $base.statpane -padx {2 15} ; # resize control
    }

    # init the menu editor frame
    ::menued::init $W(MENUED)

    # Resize behavior management

    grid rowconfigure    $root 3 -weight 1 -minsize 150 ; # main canvas (pw)
    grid columnconfigure $root 1 -weight 1 -minsize 150 ; # main canvas (pw)

}
