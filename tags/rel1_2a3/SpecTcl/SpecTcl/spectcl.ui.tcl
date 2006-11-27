# interface generated by SpecTcl version 1.0 from /home/kcorey/hack/SpecTcl/SpecTcl/spectcl.ui
#   root     is the parent window for this user interface

proc spectcl_ui {root args} {

	# this treats "." as a special case

	if {$root == "."} {
	    set base ""
	} else {
	    set base $root
	}
    
	frame $base.toolbar \
		-background #c0c0c0

	frame $base.palette \
		-background #c0c0c0 \
		-borderwidth 2 \
		-highlightbackground #c0c0c0 \
		-relief ridge

	frame $base.buttons \
		-background #c0c0c0

	frame $base.frame#7 \
		-background #c0c0c0 \
		-borderwidth 2 \
		-relief sunken

	frame $base.frame#8 \
		-background #c0c0c0 \
		-borderwidth 2 \
		-relief raised

	frame $base.menu \
		-background #c0c0c0 \
		-borderwidth 2 \
		-relief raised

	canvas $base.can_column \
		-background white \
		-borderwidth 2 \
		-height 0 \
		-highlightthickness 0 \
		-relief ridge \
		-width 0 \
		-xscrollincrement 10

	scrollbar $base.can_yscroll \
		-background #c0c0c0 \
		-command {can_view {.can .can_row} y} \
		-highlightthickness 0 \
		-orient v

	canvas $base.can_row \
		-background white \
		-borderwidth 2 \
		-height 0 \
		-highlightthickness 0 \
		-relief ridge \
		-width 5 \
		-yscrollincrement 10

	canvas $base.can \
		-background #c0c0c0 \
		-height 0 \
		-highlightbackground #c0c0c0 \
		-width 0 \
		-xscrollcommand {scroll_set .can_xscroll} \
		-xscrollincrement 10 \
		-yscrollcommand {scroll_set .can_yscroll} \
		-yscrollincrement 10

	scrollbar $base.can_xscroll \
		-background #c0c0c0 \
		-command {can_view {.can .can_column} x} \
		-orient h

	entry $base.helpbox \
		-background #c0c0c0 \
		-highlightbackground #c0c0c0
	catch {
		$base.helpbox configure \
			-font -*-Helvetica-Bold-R-Normal-*-*-120-*-*-*-*-*-*
	}

	label $base.message \
		-anchor w \
		-background #c0c0c0 \
		-relief sunken \
		-text {saving label#4} \
		-textvariable _Message \
		-width 25


	# Geometry management

	grid $base.toolbar -in $root	-row 2 -column 1  \
		-columnspan 4 \
		-sticky ew
	grid $base.palette -in $root	-row 3 -column 1  \
		-padx 2 \
		-pady 2 \
		-rowspan 2 \
		-sticky ns
	grid $base.buttons -in $root	-row 6 -column 1  \
		-columnspan 4 \
		-sticky ew
	grid $base.frame#7 -in $root	-row 4 -column 4  \
		-sticky nesw
	grid $base.frame#8 -in $root	-row 7 -column 1  \
		-columnspan 4 \
		-sticky ew
	grid $base.menu -in $root	-row 1 -column 1  \
		-columnspan 4 \
		-sticky ew
	grid $base.can_column -in $root	-row 3 -column 4  \
		-sticky nesw
	grid $base.can_yscroll -in $root	-row 4 -column 2  \
		-sticky ns
	grid $base.can_row -in $root	-row 4 -column 3  \
		-sticky nesw
	grid $base.can -in $base.frame#7	-row 1 -column 1  \
		-sticky nesw
	grid $base.can_xscroll -in $root	-row 5 -column 4  \
		-sticky ew
	grid $base.helpbox -in $base.frame#8	-row 1 -column 2  \
		-sticky ew
	grid $base.message -in $base.frame#8	-row 1 -column 4  \
		-sticky ew

	# Resize behavior management

	grid rowconfigure $base.frame#7 1 -weight 1 -minsize 30
	grid columnconfigure $base.frame#7 1 -weight 1 -minsize 1

	grid rowconfigure $base.frame#8 1 -weight 0 -minsize 30
	grid columnconfigure $base.frame#8 1 -weight 0 -minsize 3
	grid columnconfigure $base.frame#8 2 -weight 2 -minsize 197
	grid columnconfigure $base.frame#8 3 -weight 0 -minsize 3
	grid columnconfigure $base.frame#8 4 -weight 1 -minsize 187
	grid columnconfigure $base.frame#8 5 -weight 0 -minsize 2

	grid rowconfigure $root 1 -weight 0 -minsize 2
	grid rowconfigure $root 2 -weight 0 -minsize 5
	grid rowconfigure $root 3 -weight 0 -minsize 12
	grid rowconfigure $root 4 -weight 1 -minsize 2
	grid rowconfigure $root 5 -weight 0 -minsize 9
	grid rowconfigure $root 6 -weight 0 -minsize 8
	grid rowconfigure $root 7 -weight 0 -minsize 30
	grid columnconfigure $root 1 -weight 0 -minsize 30
	grid columnconfigure $root 2 -weight 0 -minsize 6
	grid columnconfigure $root 3 -weight 0 -minsize 12
	grid columnconfigure $root 4 -weight 1 -minsize 364
# additional interface code
$root config -background #c0c0c0 -highlightbackground #c0c0c0




# end additional interface code

}


# Allow interface to be run "stand-alone" for testing

catch {
    if {$argv0 == [info script]} {
	wm title . "Testing spectcl"
	spectcl_ui .
    }
}