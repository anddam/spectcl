# widgets.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# Create and manage the widget palette and configuration information
#

namespace eval ::palette {
    variable LAST ""; # last type of tree shown in palette
}

namespace eval ::gui {}

namespace eval ::config {
    variable TYPES
    foreach {type value} {
	activestyle	{dotbox none underline}
	anchor	{n ne e se s sw w nw center}
	bitmap	{"" error gray75 gray50 gray25 gray12 \
		hourglass info questhead question warning}
	cursor	{
	    "" X_cursor arrow based_arrow_down based_arrow_up boat bogosity
	    bottom_left_corner bottom_right_corner bottom_side bottom_tee
	    box_spiral center_ptr circle clock coffee_mug cross cross_reverse
	    crosshair diamond_cross dot dotbox double_arrow draft_large
	    draft_small draped_box exchange fleur gobbler gumby hand1 hand2
	    heart icon iron_cross left_ptr left_side left_tee leftbutton
	    ll_angle lr_angle man middlebutton mouse pencil pirate plus
	    question_arrow right_ptr right_side right_tee rightbutton rtl_logo
	    sailboat sb_down_arrow sb_h_double_arrow sb_left_arrow
	    sb_right_arrow sb_up_arrow sb_v_double_arrow shuttle sizing spider
	    spraycan star target tcross top_left_arrow top_left_corner
	    top_right_corner top_side top_tee trek ul_angle umbrella ur_angle
	    watch xterm
	}
	compound {bottom center left none right top}
	default {active disabled normal}
	direction {above below flush left right}
	justify	{left right center}
	orient	{horizontal vertical}
	relief	{flat groove raised ridge solid sunken}
	state	{disabled normal}
	buttonstate	{active disabled normal}
	entrystate	{disabled normal readonly}
	selectmode {browse single multiple extended}
	validate {none focus focusin focusout key all}
	wrap	{none char word}
    } {
	set TYPES($type) [lsort -dictionary $value]
    }
    #sticky	{"" nw n ne new w e ew sw s se sew nsw ns nse nsew}


    variable CONFIG
    variable CTYPE
    variable CVERSION
    foreach {opt ver prop type} {
	activebackground	8.0 advanced color
	activeborderwidth	8.0 advanced {pixels {0 4 1}}
	activeforeground	8.0 advanced color
	activerelief		8.0 advanced relief
	activestyle		8.4 advanced activestyle
	anchor			8.0 advanced anchor
	aspect			8.0 advanced {pixels {100 300 20}}
	autoseparators		8.4 advanced boolean
	background		8.0 basic    color
	bitmap			8.0 basic    bitmap
	borderwidth		8.0 advanced {pixels {0 4 1}}
	buttonbackground	8.4 advanced color
	buttoncursor		8.4 advanced cursor
	buttondownrelief	8.4 advanced relief
	buttonuprelief		8.4 advanced relief
	class			8.0 advanced string
	closeenough		8.0 advanced {double {0.0 4.0 1.0}}
	colormap		8.0 advanced custom
	command			8.0 basic    command
	compound		8.4 advanced compound
	confine			8.0 advanced boolean
	container		8.0 advanced boolean
	cursor			8.0 basic    cursor
	default			8.0 advanced default
	digits			8.0 basic    {integer {0 4 1}}
	direction		8.0 advanced direction
	disabledbackground	8.0 advanced color
	disabledforeground	8.0 advanced color
	exportselection		8.0 basic    boolean
	foreground		8.0 basic    color
	format			8.0 advanced string
	font			8.0 basic    font
	from			8.0 basic    double
	height			8.0 advanced integer
	highlightbackground	8.0 advanced color
	highlightcolor		8.0 advanced color
	highlightthickness	8.0 advanced {pixels {0 4 1}}

	image			8.0 advanced image

	increment		8.0 basic    double
	indicatoron		8.0 advanced boolean
	insertbackground	8.0 advanced color
	insertborderwidth	8.0 advanced {pixels {0 4 1}}
	insertofftime		8.0 advanced {integer {0 300 50}}
	insertontime		8.0 advanced {integer {0 300 50}}
	insertwidth		8.0 advanced {pixels {0 4 1}}
	invalidcommand		8.3 advanced command
	jump			8.0 advanced boolean
	justify			8.0 advanced justify
	label			8.0 basic    string
	length			8.0 advanced {pixels {0 400 20}}
	listvariable		8.3 basic    variable
	menu			8.0 advanced widget
	onvalue			8.0 advanced string
	offrelief		8.4 advanced relief
	offvalue		8.0 advanced string
	offset			8.0 advanced custom
	orient			8.0 advanced orient
	overrelief		8.4 advanced relief
	padx			8.0 advanced {pixels {0 6 1}}
	pady			8.0 advanced {pixels {0 6 1}}
	readonlybackground	8.3 advanced color
	relief			8.0 advanced relief
	repeatdelay		8.0 advanced {integer {100 1000 100}}
	repeatinterval		8.0 advanced {integer {100 1000 100}}
	resolution		8.0 advanced double
	scrollregion		8.0 advanced custom
	selectbackground	8.0 advanced color
	selectborderwidth	8.0 advanced {pixels {0 4 1}}
	selectcolor		8.0 advanced color
	selectforeground	8.0 advanced color
	selectimage		8.0 advanced image
	selectmode		8.0 basic    selectmode
	setgrid			8.0 advanced boolean
	show			8.0 advanced string
	showvalue		8.0 advanced boolean
	sliderlength		8.0 advanced {pixels {10 50 5}}
	sliderrelief		8.0 advanced relief
	spacing1		8.0 advanced pixels
	spacing2		8.0 advanced pixels
	spacing3		8.0 advanced pixels
	state			8.0 advanced state
	tabs			8.0 advanced string
	takefocus		8.0 basic    boolean
	text			8.0 basic    string
	textvariable		8.0 basic    variable
	tickinterval		8.0 basic    double
	to			8.0 basic    double
	troughcolor		8.0 advanced color
	underline		8.0 advanced {integer {-1 20 1}}
	undo			8.4 advanced boolean
	validate		8.3 advanced validate
	validatecommand		8.3 advanced command
	variable		8.0 basic    variable
	values			8.0 basic    string
	visual			8.0 advanced custom
	width			8.0 advanced integer
	wrap			8.0 advanced wrap
	wraplength		8.0 advanced pixels
	xscrollcommand		8.0 advanced command
	yscrollcommand		8.0 advanced command

	orientation		8.0 advanced orient
	comments		8.0 advanced string
	elementborderwidth	8.0 advanced {integer {0 4 1}}
	ipadx			8.0 advanced {pixels {0 6 1}}
	ipady			8.0 advanced {pixels {0 6 1}}
	postcommand		8.0 advanced command
	selector		8.0 advanced string
	tabbing			8.0 advanced string
	tags			8.0 advanced string

	labelbitmap		8.0 advanced bitmap
	labelfont		8.0 advanced font
	labelimage		8.0 advanced image
	labelmargin		8.0 advanced pixels
	labelpos		8.0 advanced {list {nw n ne sw s se en e es wn w ws}}
	labeltext		8.0 advanced string
	labelvariable		8.0 advanced variable

	textfont		8.0 advanced font

	barcolor		8.0 advanced color
	barheight		8.0 advanced pixels
	steps			8.0 advanced {integer {0 100 10}}

	type			8.0 advanced string

	tearoff			8.0 advanced boolean
	tearoffcommand		8.0 advanced command
	title			8.0 advanced string

	hidemargin		8.0 advanced boolean
	accelerator		8.0 basic    string
	columnbreak		8.0 advanced boolean
	menu			8.0 ignore   ignore

	sticky			8.0 ignore sticky
    } {
	set CONFIG($opt)   $type
	set CTYPE($opt)    $prop
	set CVERSION($opt) $ver
    }
}

# return the type of an option
# the only *guaranteed* way to do this is by creating a new widget for
# each test, as some invalid options leave the widgets in an undefined state
# Thats too slow, so We'll keep a list of "bad" options and deal with them
# separately

proc get_option_type {name widget option {font {Helvetica 8}}} {
    # try to set the option to these values.  Keep track of the values
    # that work.
    set option [string trimleft $option "-"]
    if {[info exists ::config::CONFIG($option)]} {
	return $::config::CONFIG($option)
    }

    set tests [list 2 1 1c \#123 ne raised warning arrow disabled vertical]
    array set bad_options {image 1 orient 1}
    set bad [info exists bad_options($option)]

    foreach test $tests {
	set code [catch {$name configure -$option $test}]
	append out $code
	if {$code && $bad} {
	    # If something went wrong, recreate widget
	    destroy $name
	    $widget $name
	}
    }
    if {$out eq "0000000000"} {
	# FIX: font detection is hard because font requests don't fail
	# so we need a special font check here ...
    }
    return [assign_option_type $out]
}

# assign a type to result pattern
# This depends on the types and order of tests performed in
# get_option_types
#   pat:  The list of successes/failures for each test

proc assign_option_type {pat} {
    switch -exact $pat {
	0000000000 {set result string}
	0001111111 {set result distance}
	0011111111 {set result integer}
	1011111111 {set result boolean}
	1110111111 {set result color}
	1111011111 {set result anchor}
	1111101111 {set result relief}
	1111110111 {set result bitmap}
	1111111011 {set result cursor}
	1111111101 {set result state}
	1111111110 {set result orientation}
	1111111111 {set result special}
	default    {set result unknown}
    }
    return $result
}

proc ::palette::_update_tree {w tree node} {
    if {$node eq "root"} { return }
    if {[$tree keyexists $node -key image]} {
	$w insert end [$tree parent $node] $node -open yes \
		-text [$tree get $node] -image [$tree get $node -key image]
    } else {
	$w insert end [$tree parent $node] $node -open yes \
		-text [$tree get $node]
    }
}

proc ::palette::refresh {what} {
    variable W

    # Check whether the trees exist first
    if {![info exists W($what)]} { return }

    # Ensure that we do not recursively enter here
    variable IN_REFRESH
    if {[info exists IN_REFRESH]} { return }
    set IN_REFRESH 1

    set t $W($what)
    $t delete [$t nodes root]

    if {$what eq "lang"} {
	# shared with ::config::update_tree
	# FIX: we should cache this
	set widgets [::widget::palette [targetLanguage] [targetVersion]]
	foreach {node children} $widgets {
	    $t insert end root $node -text $node -open yes -selectable no \
		-font defaultBoldFont -fill \#000099
	    foreach child $children {
		# Add widget to palette unless it is the menu widget
		set w [::widget::get $child wid]

		$t insert end $node $child -text $w \
		    -image [::widget::get $child image] \
		    -helptext "Create $child"
	    }
	}
    } elseif {$what eq "app"} {
	# Copied from properties.tcl:update_tree
	# should be shared code
	::config::update_tree
	set tree [::config::gettree]
	$tree walk $::W(FRAME) \
	    -command [list [namespace current]::_update_tree $t $tree %n]
    } elseif {$what eq "menu"} {
	::config::update_tree
	set tree [::config::gettree]
	$tree walk "MENU" \
	    -command [list [namespace current]::_update_tree $t $tree %n]
	::menued::update_menubar
	::palette::menuBtnState
    }

    unset IN_REFRESH
}

# activate a specific item in the display
#
# type: app menu lang
# show: whether to raise the properties sheet dialog
# w:    widget/item to show
#
proc ::palette::activate {type show w} {
    if {$type eq "app"} {
	# Dialog widget
	# [::widget::exists $w]
	set type [::widget::type $w]
	set id   [::widget::data $w ID]

	if {[::gui::isContainer $w]} {
	    status_message "Retrieving Dialog container properties ..."
	    ::config::show container $w $show
	} else {
	    status_message "Retrieving $type $id properties ..."
	    ::config::show widget $w $show
	}
    } elseif {$type eq "menu"} {
	# Menu item
	# [::menu::exists $w]
	set type [::widget::menutype $w]
	status_message "Retrieving $type properties ..."
	::config::show menu $w $show
    } elseif {$type eq "lang"} {
	# Language-specific palette widget

	# Prevent triggers on group items (should be [list $grp $w] form)
	if {[llength $w] > 1} {
	    status_message "Retrieving default $w properties ..."
	    ::config::show sample $w $show
	}
    }
}

proc ::palette::menuInsert {type} {
    variable W

    set sel [lindex [$W(menu) selection get] 0]
    if {$sel eq ""} {
	set sel "MENU"
    }
    set node [::widget::new_menuitem [list Menu $type] $sel 1]
    if {[::widget::menutype $sel] eq "Menu cascade"} {
	select menu $sel
    } else {
	# only select the new menu when we were not a cascade.
	# provides a better user experience.
	select menu $node
    }
}

proc ::palette::menuDelete {} {
    variable W

    set sel [lindex [$W(menu) selection get] 0]
    if {$sel eq ""} {
	return
    }
    if {$sel eq "MENU"} {
	# delete all
	::widget::delete_menuall
	::widget::new "MENU"
    } else {
	::widget::delete_menu $sel
    }
    # Refresh the tree
    ::palette::refresh menu
}

proc ::palette::menuDropCmd {args} {
    puts stderr $args
}

proc ::palette::menuBtnState {} {
    variable W
    set sel [lindex [$W(menu) selection get] 0]
    # We could default to assuming the toplevel menu
    #if {$sel eq ""} { set sel "MENU" }
    if {$sel eq ""} {
	set type ""
    } else {
	set type [lindex [::widget::menutype $sel] end]
    }
    # For "MENU" we only allow cascades.  Other cascades can have any
    # menu item type.  This is an artificial limitation for happy UI design.
    set state [expr {$type eq "cascade" ? "normal" : "disabled"}]
    $W(b.cascade) configure -state $state
    set state [expr {$sel eq "MENU" ? "disabled" : $state}]
    foreach type {command separator checkbutton radiobutton} {
	$W(b.$type) configure -state $state
    }
    set state "disabled"
    if {$sel ne ""} {
	set state "normal"
    }
    $W(b.delete) configure -state $state
}

proc ::palette::select_widget {w} {
    variable W
    # make the named widget "selected"
    # as a side effect, make its "master" current

    set ::Current(widget) $w
    $W(app) selection set $w
    $W(app) see $w

    if {![::gui::isContainer $w]} {
	window_highlight $w
	outline::activate $w
	add_resize_handles $w
    }
    current_frame [::widget::data $w MASTER]
}

proc ::palette::select_palette {w} {
    variable W
    # FIX: check for bad type?
    set node [::widget::get $w node]
    set ::Current(palette_widget) $node
    $W(lang) selection set $node
    $W(lang) see $node
}

proc ::palette::select_menu {w} {
    variable W
    set ::Current(menu_widget) $w
    $W(menu) selection set $w
    $W(menu) see $w
    menuBtnState
}

# Called by other code to specify what widget element we want selected
# Keep the trees in sync with properties and canvas
proc ::palette::select {what node {clear 0}} {
    variable W

    if {$what eq "palette"} { set what "lang" }
    if {$what eq "widget"}  { set what "app" }

    if {![info exists W($what)]} { return }

    # At this time we ignore the clear and always unselect before select
    unselect *

    if {$node eq ""} { return }

    if {$what eq "lang"} {
	# Ensure that we aren't selecting a group
	if {![$W($what) itemcget $node -selectable]} {
	    return
	}
	select_palette $node
    } elseif {$what eq "app"} {
	select_widget $node
    } elseif {$what eq "menu"} {
	select_menu $node
    }
    # update the Properties dialog
    ::palette::activate $what 0 $node
    # synchronize the toolbar
    sync_all
}

proc ::palette::unselect {{what *}} {
    variable W

    if {![info exists W(app)]} { return }

    if {[string match $what "lang"] || [string match $what "palette"]} {
	$W(lang) selection clear
	set ::Current(palette_widget) ""
    }
    if {[string match $what "app"] || [string match $what "widget"]} {
	set current $::Current(widget)
	$W(app) selection clear
	set ::Current(widget) ""
	if {$current ne "" && ![::gui::isContainer $current]} {
	    # undo the highlighting
	    window_unhighlight $current
	    # this will remove a superfluous outline
	    ::outline::remove $current
	    del_resize_handles $current
	}
    }
    if {[string match $what "menu"]} {
	$W(menu) selection clear
	set ::Current(menu_widget) ""
	menuBtnState
    }
    if {[string match $what "arrows"]} {
	::arrow::unhighlight
    }
    if {[string match $what "grid"]} {
	unselect_grid
    }
    sync_all
}

proc ::palette::bindtree {w type} {
    $w bindText  <ButtonRelease-1> [list ::palette::select $type]
    $w bindImage <ButtonRelease-1> [list ::palette::select $type]
    # Tree palette behaviour - open option sheet only on double click
    $w bindText  <Double-1> [list ::palette::activate $type 1]
    $w bindImage <Double-1> [list ::palette::activate $type 1]
    # disable the toggling behavior
    $w bindText  <Control-1> ""
    $w bindImage <Control-1> ""
}

# install the widgets in the palette
proc ::palette::build {palette} {
    variable W

    if {$::TILE} {
	set nb [ttk::notebook $palette.nb]
    } else {
	set nb [NoteBook $palette.nb -font defaultFont -internalborderwidth 0]
    }
    set W(nb) $nb
    if {$::TILE} {
	set f [frame .___f]
	set bg [$f cget -bg]
	destroy $f
    } else {
	set bg [$nb cget -bg]
    }

    # LANGUAGE-specific Widget Palette
    if {$::TILE} {
	set f [ttk::frame $nb.lang]
	$nb add $f -sticky news -text "Palette"
    } else {
	set f  [$nb insert end lang -text "Palette"]
    }
    set sw [widget::scrolledwindow $f.sw]
    set t  [Tree $sw.tree -showlines 0 -deltax 1 -deltay 18 -width 16 \
	       -relief flat -borderwidth 0 -highlightthickness 0 \
	       -background $bg -selectfill 1]
    set W(lang) $t
    bindtree $t lang
    $sw setwidget $t

    set can $t.c
    #bindtags $can [linsert [bindtags $can] 0 busy]
    bindtags $can [linsert [bindtags $can] end-1 palette]

    grid $sw -sticky news
    grid rowconfigure    $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1

    # APPLICATION Widgets
    if {$::TILE} {
	set f [ttk::frame $nb.app]
	$nb add $f -sticky news -text "Dialog"
    } else {
	set f  [$nb insert end app -text "Dialog"]
    }
    set sw [widget::scrolledwindow $f.sw]
    set t  [Tree $sw.tree -showlines 1 -deltax 8 -deltay 18 -width 16 \
		-relief flat -borderwidth 0 -highlightthickness 0 \
		-background $bg -selectfill 1 \
		-linestipple gray50]
    set W(app) $t
    bindtree $t app
    $sw setwidget $t

    grid $sw -sticky news
    grid rowconfigure    $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1

    # MENUS Structure
    if {$::TILE} {
	set f [ttk::frame $nb.menu]
	$nb add $f -sticky news -text "Menu"
    } else {
	set f  [$nb insert end menu -text "Menu"]
    }
    set sw [widget::scrolledwindow $f.sw]
    # FIX: XXX enable dragging around of menu items
    set t  [Tree $sw.tree -showlines 1 -deltax 8 -deltay 18 -width 16 \
		-relief flat -borderwidth 0 -highlightthickness 0 \
		-background $bg -selectfill 1 \
		-linestipple gray50 \
	        -dropenabled 0 -dragenabled 0 -dragevent 1 \
		-droptypes {TREE_NODE {move {}}} \
		-dropcmd ::palette::menuDropCmd \
	       ]
    set W(menu) $t
    bindtree $t menu
    $sw setwidget $t

    set div [frame $f.div -height 2 -relief sunken -bd 2]

    # create button controls for menu items
    set btns [frame $f.btns]
    set col 0
    foreach type {cascade command separator checkbutton radiobutton} {
	set b [set W(b.$type) $btns.$type]
	button $b -bd 1 -takefocus 0 -state disabled \
	    -relief flat -overrelief raised \
	    -image [::widget::get "Menu $type" image] \
	    -command [list ::palette::menuInsert $type]
	help::balloon $b "Create new $type menu item"
	grid $b -row 0 -column [incr col] -sticky ns
    }
    grid columnconfigure $btns [incr col] -weight 1

    set W(b.delete) $btns.del
    button $btns.del -bd 1 -takefocus 0 -state disabled \
	-relief flat -overrelief raised -image delete.gif \
	-command [list ::palette::menuDelete]
    grid $btns.del -row 0 -column [incr col] -sticky ns
    #button $btns.up   -bd 1 -image arrow_up.gif -state disabled
    #button $btns.down -bd 1 -image arrow_down.gif -state disabled
    #grid $btns.del $btns.up $btns.down -sticky ns
    #grid columnconfigure $btns [incr col] -weight 1

    grid $btns -sticky ew
    grid $div -sticky ew
    grid $sw -sticky news
    grid rowconfigure    $f 2 -weight 1
    grid columnconfigure $f 0 -weight 1

    refresh lang
    refresh app
    refresh menu

    if {$::TILE} {
	$nb select $nb.lang
    } else {
	$nb compute_size
	$nb raise lang
    }

    grid $nb -sticky news
    grid rowconfigure    $palette 0 -weight 1
    grid columnconfigure $palette 0 -weight 1
}
