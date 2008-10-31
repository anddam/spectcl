# wbuilder.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# Create and manage widget configuration information
#

namespace eval ::wbuilder {}

proc ::wbuilder::MouseWheel {w D} {
    variable W
    if {![string equal $w $W(frame)]} {
	$W(frame) yview scroll [expr {- ($D / 120) * 4}] units
    }
}

namespace eval ::widget {
    variable A_TYPES
    variable A_CATEGORIES
    array set A_TYPES {
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
	sticky	{"" nw n ne new w e ew sw s se sew nsw ns nse nsew}
	selectmode {browse single multiple extended}
	validate {none focus focusin focusout key all}
	wrap	{none char word}
    }
    set A_ITYPES {
	integer
	pixels
	double
	color
	boolean
	string
	command
	image
	variable
	widget
	font
    }
    array set A_CATEGORIES {
	basic    1
	advanced 1
	ignore   1
    }
    variable VAL .__validator
}

proc ::widget::uid_reset {{type {}}} {
    variable UIDS
    if {[llength [info level 0]] == 1} {
	# no args
	array unset UIDS
    } else {
	catch {unset UIDS($type)}
    }
}

proc ::widget::uid {type} {
    variable UIDS
    if {![info exists UIDS($type)]} { set UIDS($type) 0 }
    return [incr UIDS($type)]
}

proc ::widget::validate {type val} {
    variable VAL
    variable A_ITYPES
    variable A_TYPES

    # cache a button for some type validations
    if {![winfo exists $VAL]} { button $VAL }

    switch -exact -- $type {
	default {}
    }
    return 1
}

proc ::widget::type {w} {
    if {[::widget::exists $w type]} {
	return [::widget::data $w type]
    } elseif {[info exists ::W(FRAME)] && \
		  [::widget::exists "$::W(FRAME).$w" type]} {
	return [::widget::data "$::W(FRAME).$w" type]
    }

    return -code error "invalid widget '$w'"
}

proc ::widget::isFrame {w} {
    if {[catch {set type [type $w]}]} { return 0 }
    return [expr {$type eq "Tk frame" || $type eq "Tk labelframe"}]
}

proc ::widget::root {w} {
    # this returns the root of a possible megawidget
    while {![::widget::exists $w] && $w ne "."} {
	set w [winfo parent $w]
    }
    if {$w ne "."} {
	return $w
    }
    return ""
}

# in widget.tcl
interp alias {} ::widget::opt_type {} get_option_type
proc ::widget::opt_category {w cmd opt} {
    set opt [string trimleft $opt "-"]
    if {[info exists ::config::CTYPE($opt)]} {
	return $::config::CTYPE($opt)
    } else {
	return "advanced"
    }
}

proc ::widget::inherit {lang group cmd ns args} {
    switch -exact -- $group {
	"Menu"     { set ver 8.0 }
	"Tk"       { set ver 8.0 }
	"BWidget"  { set ver 8.2 }
	"Iwidgets" { set ver 8.2 }
	"Themed Tk" { set ver 8.4 }
	default {
	    return -code error "Cannot inherit from group '$group'"
	}
    }
    if {$lang eq ""} { set lang tcl }
    if {![string match tcl* $lang]} {
	return -code error "Cannot inherit from language '$lang' at this time"
    }
    variable VAL
    set w $VAL$cmd
    set options [list]
    if {$group eq "Menu"} {
	# Inheriting from Menu items
	menu $w -tearoff 0
	$w add $cmd
	set fullopts0 [$w entryconfigure 0]
	# We currently trim the options for menu items for sanity
	set fullopts ""
	foreach optlist $fullopts0 {
	    if {[llength $optlist] != 5} { continue }
	    foreach {opt dbname dbclass default value} $optlist { break }
	    array set ok {
		-activebackground	0
		-activeforeground	0
		-accelerator		1
		-background		0
		-bitmap			1
		-columnbreak		1
		-command		1
		-compound		1
		-font			0
		-foreground		0
		-hidemargin		0
		-image			1
		-indicatoron		0
		-label			1
		-menu			0
		-offvalue		1
		-onvalue		1
		-selectcolor		0
		-selectimage		0
		-state			1
		-underline		1
		-value			1
		-variable		1
	    }
	    if {[info exists ok($opt)] && $ok($opt)} {
		lappend fullopts $optlist
	    }
	}
    } else {
	# Inheriting from regular widgets
	# namespace can be ""
	set cmd ${ns}::$cmd
	# Avoid creation in this sub-namespace
	uplevel \#0 [list $cmd $w]
	set fullopts [$w configure]
    }
    foreach optlist $fullopts {
	if {[llength $optlist] != 5} { continue }
	foreach {opt dbname dbclass default value} $optlist { break }
	# don't reflect *command* options by default
	lappend options \
	    [list option $opt -version $ver -default $default \
		 -type [::widget::opt_type $w $cmd $opt] \
		 -category [::widget::opt_category $w $cmd $opt] \
		 -reflect [expr {![string match "*command*" $opt]}]]
    }
    destroy $w
    return $options
}

proc ::widget::widgets {{type *}} {
    set t [gettree app]
    if {![info exists ::W(FRAME)] || ![$t exists "CONTAINER"]} {
	return ""
    }
    set all [concat [list $::W(FRAME)] [$t children "CONTAINER"]]
    if {$type eq "*"} {
	return $all
    } else {
	set out [list]
	foreach w [lreplace $all 0 0 "CONTAINER"] {
	    if {[string match $type [$t get $w -key TYPE]]} {
		lappend out $w
	    }
	}
	return $out
    }
}

proc ::widget::gettree {which} {
    # Create the tree struct for the droptree.  If we had one before, then
    # destroy that and start again.
    variable TREE
    if {![info exists TREE]} {
	set TREE(widgets) [::struct::tree::tree [namespace current]::TREE_W]
	set TREE(app)     [::struct::tree::tree [namespace current]::TREE_A]
    }
    return $TREE($which)
}

proc ::widget::palette {lang ver {init 0}} {
    # return the widget palette for a particular language and version
    set wtree [gettree widgets]
    if {$init} {
	set atree [gettree app]
	foreach child [$atree children root] { $atree delete $child }
	::widget::new "CONTAINER"
    }

    set out [list]
    foreach node [$wtree children root] {
	set children [list]
	foreach child [$wtree children $node] {
	    set clang [$wtree get $child -key -language]
	    set cver  [$wtree get $child -key -version]
	    # Menu items are specially handled
	    if {$node eq "Menu"} { continue }
	    if {($clang eq "" || [lsearch -exact $clang $lang] != -1) \
		    && [package vsatisfies $ver $cver]} {
		lappend children $child
	    }
	}
	if {[llength $children]} {
	    # This node has children for this language
	    lappend out $node $children
	    if {!$init} { continue }

	    # add to app tree
	    $atree insert root end $node
	    $atree set $node $node
	    $atree set $node -key -image unknown.gif
	    foreach child $children {
		$atree insert $node end $child
		$atree set $child $child
		array set opts [$wtree get $child -key -options]
		foreach opt [array names opts] {
		    array set vals $opts($opt)
		    if {
			![package vsatisfies $ver $vals(-version)]
			|| ($vals(-category) eq "ignore")
		    } {
			continue
		    }
		    # FIX: We could use -value, if we get to it...
		    $atree set $child -key $opt $vals(-default)
		    $atree set $child -key GROUP [lindex $child 0]
		    $atree set $child -key TYPE  [lindex $child 1]
		}
	    }
	}
    }
    return $out
}

proc ::widget::delete {args} {
    set t [gettree app]
    # do a while loop so we can append to args
    while {[llength $args]} {
	set w [lindex $args 0]
	if {[$t exists $w]} {
	    if {[::widget::isFrame $w]} {
		# Make sure to remove any children
		foreach child [$t children "CONTAINER"] {
		    if {[$t get $child -key MASTER] eq $w} {
			lappend args $child
		    }
		}
	    }
	    if {![::gui::isContainer $w]} {
		destroy $w
	    }
	    $t delete $w
	}
	set args [lreplace $args 0 0]
    }
    dirty yes

    # Refresh the application palette
    ::palette::refresh app
}

proc ::widget::new {type {name {}}} {
    # FIX: Here we should check the default vs. user-request default
    # and create the widget with the appropriate default options
    #array set optDefs [::widget::get $type options -default]

    set t [gettree app]

    if {$type eq "CONTAINER" || $type eq "MENU"} {
	# When requesting a new container or menu, just set the default options
	if {[$t exists $type]} {
	    if {[$t numchildren $type] != 0} {
		return -code error "$type not empty on new request"
	    }
	    $t delete $type
	}
	if {$type eq "CONTAINER"} {
	    set GROUP Tk
	    set TYPE  {Tk frame}
	    set name  $::W(FRAME)
	    set ID    ""
	} else {
	    set GROUP Menu
	    set TYPE  {Menu menu}
	    set name  $::W(USERMENU)
	    set ID    "menu"
	    destroy $::W(USERMENU)
	    menu $::W(USERMENU) -tearoff 0
	}
	$t insert root end $type
	$t set $type $type
	$t set $type -key GROUP  $GROUP
	$t set $type -key TYPE   $TYPE
	$t set $type -key MASTER ""
	$t set $type -key ID     $ID
	$t set $type -key level  0
	array set opts    [::widget::get $TYPE options -default]
	array set reflect [::widget::get $TYPE options -reflect]
	foreach opt [array names opts] {
	    # Don't include non-reflected options
	    if {!$reflect($opt)} { continue }
	    $t set $type -key $opt $opts($opt)
	}
	# FIX: should we re-configure the widget?
	return $name
    }

    if {[::widget::get $type group] eq "Menu"} {
	return [::widget::new_menuitem $type "MENU"]
    }

    # We can configure things that may not reflect in the displayed widget.
    set wid  [::widget::get $type wid]
    set wcmd [::widget::get $type command]
    set sep $::gui::SEP
    if {$name eq ""} {
	# FIX: This is a hack because we aren't updating the uid on
	# project load correctly
	set pre "$::W(FRAME).$sep$wid$sep"
	set uid [::widget::uid $wid]
	while {[winfo exists $pre$uid]} {
	    set uid [::widget::uid $wid]
	}
	set name $pre$uid
    }
    if {![string match "$::W(FRAME).*" $name]} {
	return -code error "ERROR: What to do with '[info level 0]'"
    }
    destroy $name
    uplevel #0 [list ::$wcmd $name]
    lappend config $name configure

    $t insert CONTAINER end $name
    $t set $name $name
    # TYPE == {group command}
    $t set $name -key TYPE   $type
    # ID defaults to widget name, but can be user specified, ie myListbox
    $t set $name -key ID     [winfo name $name]
    # GROUP is just the group name
    $t set $name -key GROUP  [::widget::get $type group]
    # MASTER is the -in frame
    $t set $name -key MASTER ""
    array set geomDefs {
	-row        0	-column     0
	-columnspan 1	-rowspan    1	-sticky     ""
	-ipadx      0	-ipady      0	-padx       0	-pady       0
    }
    foreach def [array names geomDefs] {
	$t set $name -key GM:$def $geomDefs($def)
    }
    array set opts    [::widget::get $type options -default]
    array set reflect [::widget::get $type options -reflect]
    foreach opt [array names opts] {
	# Apply a default value to the -text option of a widget
	if {$opt eq "-text" && $opts($opt) eq ""} {
	    set opts($opt) [winfo name $name]
	}
	$t set $name -key $opt $opts($opt)
	# Make sure that we know whether an option should be "reflected"
	if {!$reflect($opt)} { continue }
	lappend config $opt $opts($opt)
    }

    uplevel #0 $config

    dirty yes

    return $name
}

proc ::widget::clone {old} {
    if {![llength [info command $old]]} {
	status_message "No such widget '$old'"
	return
    }
    set type [::widget::type $old]
    set new  [::widget::new $type]
    array set opts [::widget::data $old]
    eval [linsert [array get opts -*] 0 ::widget::data $new]

    return $new
}

proc ::widget::scrollable {{w ""}} {
    if {[winfo exists $w]} {
	# return whether this application widget is scrollable
	set t [gettree app]
	if {[$t exists $w]} {
	    if {[$t keyexists $w -key -xscrollcommand] \
		    || [$t keyexists $w -key -yscrollcommand]} {
		return 1
	    }
	}
	return 0
    } else {
	# return all widget types that are scrollable
	set t [gettree widgets]
	set out [list]
	foreach group [$t children root] {
	    foreach cmd [$t children $group] {
		if {[$t keyexists $cmd -key -xscrollcommand] \
			|| [$t keyexists $cmd -key -yscrollcommand]} {
		    # just return the command
		    lappend $out [lindex $cmd 1]
		}
	    }
	}
	return $out
    }
}

proc ::widget::isMenu {w} {
    set t [gettree app]
    if {$w eq "MENU"} { return 1 }
    return [expr {[$t exists $w] && [$t parent $w] eq "MENU"}]
}

proc ::widget::isWidget {w} {
    set t [gettree app]
    if {([info exists ::W(FRAME)] && $w eq $::W(FRAME)) || $w eq "f"} {
	set w "CONTAINER"
    }
    if {$w eq "CONTAINER"} { return 1 }
    return [expr {[$t exists $w] && [$t parent $w] eq "CONTAINER"}]
}

proc ::widget::exists {w args} {
    set t [gettree app]
    if {([info exists ::W(FRAME)] && $w eq $::W(FRAME)) || $w eq "f"} {
	set w "CONTAINER"
    }
    if {[llength $args] == 0} {
	return [$t exists $w]
    } else {
	set item [lindex $args 0]
	foreach {old new} {master MASTER type TYPE} {
	    if {$item eq $old} { set item $new; break }
	}
	return [expr {[$t exists $w] && [$t keyexists $w -key $item]}]
    }
}

proc ::widget::data {w args} {
    set t [gettree app]
    if {([info exists ::W(FRAME)] && $w eq $::W(FRAME)) || $w eq "f"} {
	set w "CONTAINER"
    }
    if {![$t exists $w]} {
	if {[info exists ::W(FRAME)] && [$t exists "$::W(FRAME).$w"]} {
	    variable ::main::ARGS
	    if {[info exists ARGS(debug)] && $ARGS(debug)} {
		puts stderr "called '[info level 0]'"
	    }
	    set w "$::W(FRAME).$w"
	} else {
	    return -code error "no known widget '$w'"
	}
    }
    set len [llength $args]
    if {$len == 0} {
	# return all items, vals
	return [$t getall $w]
    }
    set dirty   0
    set outline 0
    set config  ""
    set gconfig ""
    if {$len > 1} {
	array set reflect [::widget::get [::widget::type $w] options -reflect]
    }
    foreach {item val} $args {
	# Map old names to new ones
	foreach {old new} {master MASTER type TYPE} {
	    if {$item eq $old} { set item $new; break }
	}
	if {$len == 1} {
	    # return item val
	    if {[$t keyexists $w -key $item]} {
		return [$t get $w -key $item]
	    } elseif {[$t keyexists $w -key GM:$item]} {
		# save.tcl peeks into GM:*
		return [$t get $w -key GM:$item]
	    }
	    return ""
	}
	if {[$t keyexists $w -key $item]} {
	    set oldval [$t get $w -key $item]
	}
	if {![info exists oldval] || $oldval != $val} {
	    # set item to val
	    $t set $w -key $item $val
	    set dirty 1
	} else {
	    # we could just continue, but we let things get re-reflected
	}
	if {[string match -* $item]} {
	    # should we configure here? - check -reflect
	    if {!$reflect($item)} { continue }
	    lappend config $item $val
	} elseif {[string match GM:-* $item]} {
	    set item [string range $item 3 end]
	    if {[string match "-*" $item]} {
		lappend gconfig $item $val
		if {$item eq "-rowspan" || $item eq "-columnspan"} {
		    set outline 1
		}
	    }
	}
    }
    if {[winfo exists $w]} {
	if {[llength $config]} {
	    eval [list $w configure] $config
	    # Synchronize the properties sheet if this widget is showing
	    eval [linsert $config 0 ::config::synchronize $w data]
	}
	if {[llength $gconfig] && [winfo manager $w] eq "grid"} {
	    eval [list grid configure $w] $gconfig
	    # Synchronize the properties sheet if this widget is showing
	    eval [linsert $gconfig 0 ::config::synchronize $w geometry]
	    if {$outline && $dirty} {
		outline::outline $w
	    }
	}
    }
    if {$dirty} { dirty 1 }
}

proc ::widget::geometry {w args} {
    # like widget::data but only for geometry data, errors on unknown keys
    set t [gettree app]
    if {([info exists ::W(FRAME)] && $w eq $::W(FRAME)) || $w eq "f"} {
	set w "CONTAINER"
    }
    if {![$t exists $w]} {
	if {[info exists ::W(FRAME)] && [$t exists "$::W(FRAME).$w"]} {
	    puts stderr "called '[info level 0]'"
	    set w "$::W(FRAME).$w"
	} else {
	    return -code error "no known widget '$w'"
	}
    }
    set len [llength $args]
    if {$len == 0} {
	# return all items, vals
	set out ""
	foreach {key val} [$t getall $w] {
	    if {[string match "GM:*" $key]} {
		lappend out [string range $key 3 end] $val
	    }
	}
	return $out
    }
    set dirty   0
    set outline 0
    set config  ""
    foreach {item val} $args {
	set key GM:$item
	if {[string match "-*" $item] && ![$t keyexists $w -key $key]} {
	    return -code error "unknown geometry option '$item'"
	}
	if {$len == 1} {
	    # return item val
	    if {[$t keyexists $w -key $key]} {
		return [$t get $w -key $key]
	    }
	    return ""
	}
	if {[$t keyexists $w -key $key]} {
	    set oldval [$t get $w -key $key]
	}
	if {![info exists oldval] || $oldval != $val} {
	    # set item to val
	    $t set $w -key $key $val
	    set dirty 1
	} else {
	    # we could just continue, but we let things get re-reflected
	}
	if {[string match "-*" $item]} {
	    lappend config $item $val
	    if {$item eq "-rowspan" || $item eq "-columnspan"} {
		set outline 1
	    }
	}
    }
    if {[winfo exists $w]} {
	if {[llength $config] && [winfo manager $w] eq "grid"} {
	    eval [list grid configure $w] $config
	    # Synchronize the properties sheet if this widget is showing
	    eval [linsert $config 0 ::config::synchronize $w geometry]
	    if {$outline && $dirty} {
		outline::outline $w
	    }
	}
    }
    if {$dirty} { dirty 1 }
}

proc ::widget::_wnode {cmd} {
    # get a node name from the widget tree
    set tree [gettree widgets]
    if {[winfo exists $cmd]} {
	# determine type
	set cmd [type $cmd]
    }

    if {[llength $cmd] == 1} {
	# given a command without a group?  Ensure Tk is checked first
	foreach group [concat [list Tk] [$tree children root]] {
	    if {[$tree exists [list $group $cmd]]} {
		set node [list $group $cmd]
		break
	    }
	}
	if {![info exists node]} {
	    return -code error "unable to find widget group for '$cmd'"
	}
    } else {
	set node $cmd
    }
    return $node
}

proc ::widget::get {cmd what args} {
    set tree [gettree widgets]
    set node [_wnode $cmd]

    switch -exact -- $what {
	node     { return $node }
	group    { return [lindex $node 0] }
	command  {
	    # return a command to create this or an equivalent widget in
	    # the gui builder
	    set equiv [$tree get $node -key -equivalent]
	    if {$equiv eq ""} {
		set ns [$tree get $node -key -namespace]
		if {$ns eq ""} {
		    return [lindex $node 1]
		} else {
		    return ${ns}::[lindex $node 1]
		}
	    } else {
		return [::widget::get $equiv command]
	    }
	}
	instance {
	    # return a command to create this widget for
	    # use in the actual generated code.  It will vary by lang.
	    if {$::gui::LANG(CUR) eq "tcl"} {
		set ns [$tree get $node -key -namespace]
		if {$ns eq ""} {
		    return [lindex $node 1]
		} else {
		    return ${ns}::[lindex $node 1]
		}
	    } elseif {$::gui::LANG(CUR) eq "perl"} {
		return [string toupper [lindex $node 1] 0 0]
	    } elseif {$::gui::LANG(CUR) eq "perltkx"} {
		set ns [$tree get $node -key -namespace]
		if {$ns eq ""} {
		    return [lindex $node 1]
		} else {
		    return ${ns}__[lindex $node 1]
		}
	    } elseif {$::gui::LANG(CUR) eq "ruby"} {
		set grp [lindex $node 0]
		if {$grp eq "Tk" || $grp eq "Menu"} {
		    return "Tk[string toupper [lindex $node 1] 0 0]"
		} elseif {$grp eq "BWidget" || $grp eq "Iwidgets"} {
		    return "Tk::${grp}::[string toupper [lindex $node 1] 0 0]"
		} else {
		    return "Tk::${grp}::[string toupper [lindex $node 1] 0 0]"
		}
	    } elseif {$::gui::LANG(CUR) eq "tkinter"} {
		set group [lindex $node 0]
		if {[lindex $node 1] eq "labelframe"} {
		    # Special case for "LabelFrame"
		    set wcmd "LabelFrame"
		} elseif {[lindex $node 1] eq "panedwindow"} {
		    # Special case for "PanedWindow"
		    set wcmd "PanedWindow"
		} else {
		    set wcmd [string toupper [lindex $node 1] 0 0]
		}
		if {$group eq "Tk" || $group eq "Menu"} {
		    set req "Tkinter"
		} else {
		    set req [$tree get $node -key -requires]
		}
		if {$req ne ""} {
		    set wcmd $req.$wcmd
		}
		return $wcmd
	    } else {
		return -code error "unknown lang $::gui::LANG(CUR)"
	    }
	    return -code error "INVALID INSTANCE COMMAND"
	}
	wid	 { return [lindex $node 1] }
	language -
	image -
	description -
	namespace -
	requires -
	equivalent {
	    return [$tree get $node -key -$what]
	}
	option {
	    # return info on just one option
	    array set opts [$tree get $node -key -options]
	    set opt [lindex $args 0]
	    if {[info exists opts($opt)]} {
		if {[llength $args] > 1} {
		    # get one specific category of the option
		    set cat [lindex $args 1]
		    array set cats $opts($opt)
		    if {[info exists cats($cat)]} {
			return $cats($cat)
		    } else {
			return -code error "no known category '$cat'\
				for option '$opt' for $node"
		    }
		} else {
		    return $opts($opt)
		}
	    } else {
		# ... error - unknown option given
		return -code error "no known option '$opt' for $node"
	    }
	}
	options {
	    set opts [$tree get $node -key -$what]
	    if {$args eq "-all"} {
		return $opts
	    }
	    set out [list]
	    set len  [llength $args]
	    set type [lindex $args 0]
	    set val  [lindex $args 1]
	    set ver  [targetVersion]
	    foreach {opt attrs} $opts {
		array set tmp $attrs
		if {![package vsatisfies $ver $tmp(-version)] \
			|| ($tmp(-category) eq "ignore")} {
		    continue
		}
		if {$len == 0} {
		    lappend out $opt
		    continue
		}
		if {![info exists tmp($type)]} {
		    return -code error "bad option attribute '$type'"
		}
		if {$len == 1} {
		    # just a type was specified, so output opt + type
		    lappend out $opt $tmp($type)
		} elseif {[string match $tmp($type) $val]} {
		    # type val was specified, so output options that
		    # match the requested type val (glob matching)
		    lappend out $opt
		}
	    }
	    return $out
	}
	default {
	    return -code error "Hey what '$what'?"
	}
    }
}

proc ::widget::configure {cmd args} {
    # configure just the option information for a widget type
    set tree [gettree widgets]
    set node [_wnode $cmd]

    array set opts [$tree get $node -key -options]
    set len [llength $args]
    if {$len == 0} {
	# return option value pairs
	set out ""
	foreach opt [lsort -dictionary [array names opts]] {
	    array set cats $opts($opt)
	    lappend out $opt $cats(-default)
	}
	return $out
    } elseif {$len == 1} {
	# return value for this option
	set opt [lindex $args 0]
	if {![info exists opts($opt)]} {
	    # ... error - unknown option given
	    return -code error "no known option '$opt' for $node"
	}
	array set cats $opts($opt)
	return $cats(-default)
    } elseif {$len & 1} {
	# bad arg count
	return -code error "bad arg count"
    } else {
	# set option value pairs
	foreach {opt val} $args {
	    if {![info exists opts($opt)]} {
		# ... error - unknown option given
		return -code error "no known option '$opt' for $node"
	    }
	    array set cats $opts($opt)
	    # FIX: should we validate type?
	    set cats(-default) $val
	    set opts($opt) [array get cats]
	    unset cats
	}
	$tree set $node -key -options [array get opts]
	return
    }
}

proc ::widget::define {group cmd args} {
    variable A_CATEGORIES
    # define core button ?opts?
    array set opts {
	-language    ""
	-version     8.0
	-image       unknown.gif
	-namespace   ""
	-inherit     ""
	-options     ""
	-description ""
	-requires    ""
	-equivalent  ""
    }
    # option name ?opts?
    array set attrOpts {
	-version  8.0
	-default  ""
	-type     string
	-category advanced
	-reflect  1
    }
    #-value    ""

    foreach {key val} $args {
	set arg [array names opts -exact $key]
	if {[llength $arg] == 0} {
	    set arg [array names opts -glob $key*]
	}
	set len [llength $arg]
	if {$len==1} {
	    # found matching key, validate and overwrite default value
	    #lappend validArgs $arg $val
	    switch -exact -- $arg {
		-language {
		    foreach lang $val {
			if {![info exists ::gui::LANGS($lang)]
			    && $lang ne "menu"} {
			    return -code error "unrecognized target language\
				\"$lang\", must be one of:\
				[array names ::gui::LANGS]"
			}
		    }
		}
		-version {
		    # version check
		    if {[catch {package vsatisfies $val 8.0} ok] || !$ok} {
			return -code error \
			    "invalid package version '$val' for $cmd"
		    }
		}
		-image {
		    if {[lsearch -exact [image names] $val] == -1} {
			return -code error "no known image '$val' for $cmd"
		    }
		}
	    }
	    set opts($arg) $val
	} elseif {$len} {
	    # ambiguous match
	    return -code error "ambiguous option \"$key\",\
			must be one of: [join $arg {, }]"
	} else {
	    # no match
	    return -code error "unknown option \"$key\",\
			must be one of: [join [array names opts] {, }]"
	}
    }

    if {[llength $opts(-inherit)]} {
	foreach {igroup icmd} $opts(-inherit) { break }
	set iopts [::widget::inherit [lindex $opts(-language) 0] \
		       $igroup $icmd $opts(-namespace)]
	set opts(-options) [concat $iopts $opts(-options)]
    }

    array set options {}
    # process widget attributes
    foreach opt $opts(-options) {
	set ocmd [lindex $opt 0]
	if {$ocmd == ""} {
	    return -code error "specify a command bozo"
	}
	set name [lindex $opt 1]
	switch -exact -- $ocmd {
	    "inherit" {
		set igroup [lindex $opt 1]
		set itype  [lindex $opt 2]
		continue
	    }
	    "configure" {
		set optArgs [lrange $opt 2 end]
		# don't reset with default
		if {![info exists options($name)]} {
		    set options($name) ""
		}
	    }
	    "option" {
		set optArgs [lrange $opt 2 end]
		# start with defaults
		set options($name) [array get attrOpts]
	    }
	    default {
		return -code error "invalid option command \"$ocmd\""
	    }
	}
	foreach {key val} $optArgs {
	    set arg [array names attrOpts -exact $key]
	    if {[llength $arg] == 0} {
		set arg [array names attrOpts -glob $key*]
	    }
	    set len [llength $arg]
	    if {$len==1} {
		# found matching key, overwrite default value
		#lappend validArgs $arg $val
		lappend options($name) $arg $val
	    } elseif {$len} {
		# ambiguous match
		return -code error "ambiguous option \"$key\",\
			must be one of: [join $arg {, }]"
	    } else {
		# no match
		return -code error "unknown option \"$key\",\
			must be one of: [join [array names attrOpts] {, }]"
	    }
	}

	# remove redundant options
	catch {unset tmp}
	array set tmp $options($name)

	# the default is a subst'ed value
	if {[info exists tmp(-default)]} {
	    set tmp(-default) [subst $tmp(-default)]
	}
	set options($name) [array get tmp]

	# post-process values
	foreach {key val} $options($name) {
	    switch -exact -- $key {
		-category {
		    if {![info exists A_CATEGORIES($val)]} {
			return -code error "invalid category \"$val\",\
				must be one of:\
				[join [lsort [array names A_CATEGORIES]] {, }]"
		    }
		}
		-version {
		    # version check
		    if {[catch {package vsatisfies $val 8.0} ok] || !$ok} {
			return -code error \
			    "invalid package version '$val' for $cmd"
		    }
		}
		-type {
		    # type and default are linked
		    if {![::widget::validate $val $tmp(-default)]} {
			return -code error \
			    "invalid type '$val' or default '$tmp(-default)' for $cmd"
		    }
		}
	    }
	}
    }

    set tree [gettree widgets]
    set node [list $group $cmd]
    if {![$tree exists $group]} {
	$tree insert root end $group
	$tree set $group $group
	$tree set $group -key -image unknown.gif
    }

    if {![$tree exists $node]} {
	$tree insert $group end $node
    } else {
	# Rededefining an existing node?  Just overwrite data
    }
    $tree set $node $node
    foreach opt [array names opts] {
	if {$opt eq "-options"} {
	    $tree set $node -key $opt [array get options]
	} else {
	    $tree set $node -key $opt $opts($opt)
	}
    }
}

proc ::wbuilder::show {args} {
    variable W

    wm deiconify $W(root)
    raise $W(root)
    focus -force $W(root)
}

proc ::wbuilder::dialog {root args} {
    variable W

    set W(root) $root
    if {![winfo exists $root]} {
	toplevel $root
	wm withdraw $root
	wm title $root "Widget Builder"
	wm protocol $root WM_DELETE_WINDOW [list wm withdraw $root]
	wm group $root $::W(ROOT)
	#wm transient $root $::W(ROOT)
	bind $root <Destroy> [subst { if {"$root" eq "%W"} \
		{ after idle [info level 0] } }]
	bind $root <MouseWheel> [list ::wbuilder::MouseWheel %W %D]
    }

    # For what language?

    # Name of widget?

    # Create a specialized tree w/ frames for the various property types
    set sw [widget::scrolledwindow $root.sw]
    set sf [ScrollableFrame $root.sw.sf -constrainedwidth 1]
    $sw setwidget $sf
    set W(frame) $sf
    set sff [$sf getframe]

    foreach name {Basic Advanced Ignore} {
	label $sff.l$name -text "$name Properties" -font defaultBoldFont
	label $sff.new$name -image new.gif -width 18 -height 18
	
    }

    # oddly this config doesn't stick at creation time
    $sw configure -relief groove -borderwidth 1

    grid columnconfigure $sff 0 -weight 1

    set btns [frame $root.btns]
    button $btns.ok  -width 8 -text "OK" \
	    -command {::config::accept}
    set W(apply) [button $btns.app -width 8 -text "Apply" -state disabled \
	    -command {::config::apply} -default active]
    set W(cancel) [button $btns.can -width 8 -text "Cancel" \
	    -command {::config::cancel}]

    bind $root <Return> [list $W(apply) invoke]

    grid $W(widgetimg) -row 0 -column 0 -sticky news -padx 4 -pady 4
    grid $W(widget)    -row 0 -column 1 -sticky news -padx {0 4} -pady 4
    grid $sw           -row 1 -sticky nsew -columnspan 2 -padx 4
    grid $btns         -row 3 -sticky ew -columnspan 2

    grid x $btns.ok $btns.can $btns.app -padx 4 -pady {6 4}
    grid configure $btns.app -padx [list 4 [pad corner]]
    grid columnconfigure $btns 0 -weight 1

    # make the space with the tabnotebook grow
    grid rowconfigure    $root 1 -weight 1
    grid columnconfigure $root 1 -weight 1

    return $root
}

proc ::widget::load_cache_nodes {tree parent children} {
    foreach childset $children {
	set child [lindex $childset 0]
	set subchildren [lindex $childset 1]
	$tree insert $parent end $child
	load_cache_nodes $tree $child $subchildren
    }
}

proc ::widget::load_cache {file} {
    if {![file exists $file]} { return 0 }

    if {[catch {open $file} fd]} {
	set err [string replace $fd 100 end ...]
	tk_messageBox -title "Error Loading Cache" \
	    -type ok -message \
	    "Error loading widget cache file '$file':\n  $err\
		\n\n$::gui::APPNAME will continue loading, ignoring cache."
	return 0
    }

    set line [gets $fd]
    if {![string match "$::gui::FILEID WIDGET CACHE $::gui::FULLVER" $line]} {
	# Ignore the cache if it doesn't match down to exact build number
	close $fd
	return 0
    }

    # Read in the remaining data.  The first line is only ID.
    set data [read $fd]
    close $fd

    set tree [gettree widgets]
    if {[catch {llength $data} len] || $len != 2
	|| [lindex $data 0 0] ne "root"
	|| [catch {
	    set nodes [lindex $data 0]
	    load_cache_nodes $tree [lindex $nodes 0] [lindex $nodes 1]
	    foreach {node keydata} [lindex $data 1] {
		foreach {key val} $keydata {
		    $tree set $node -key $key $val
		}
	    }
	}]} {
	reset_data
	tk_messageBox -title "Error Loading Cache" \
	    -type ok -message \
	    "Invalid format for widget cache file '$file'.\
		\n\n$::gui::APPNAME will continue loading, ignoring cache."
	return 0
    }

    return 1
}

proc ::widget::reset_data {} {
    # in case of cache load failure (or whatever), reset all known
    # widget definition data
    set tree [gettree widgets]
    $tree destroy
    return [struct::tree::tree $tree]
}

proc ::widget::save_cache {file} {
    set tree [gettree widgets]

    if {[catch {open $file w} fid]} {
	# no error reporting on saving cache
	return 0
    }

    if {[catch {
	puts $fid "$::gui::FILEID WIDGET CACHE $::gui::FULLVER"
	puts $fid [$tree serialize root]
	close $fid
    }]} {
	catch {close $fid ; file delete -force $file}
	return 0
    }

    return 1
}

proc ::widget::init {args} {
    set cache [::port::widget_cache_file]
    if {[::widget::load_cache $cache]} {
	::widget::init_userdata
	return
    }

    ## Menu widget
    ## Specially created to be used by menu builder
    ::widget::define Menu menu -image menu.gif -requires Tk \
	-inherit {Tk menu} -options {
	    {configure -type -reflect 0 -category ignore}
	}
    ::widget::define Menu command -image button.gif -requires Tk \
	-inherit {Menu command} -options {
	    {configure -compound -version 8.4}
	}
    ::widget::define Menu separator -image separator.gif -requires Tk \
	-inherit {Menu separator}
    ::widget::define Menu checkbutton -image checkbutton.gif -requires Tk \
	-inherit {Menu checkbutton} -options {
	    {configure -compound -version 8.4}
	}
    ::widget::define Menu radiobutton -image radiobutton.gif -requires Tk \
	-inherit {Menu radiobutton} -options {
	    {configure -compound -version 8.4}
	}
    ::widget::define Menu cascade -image menu.gif -requires Tk \
	-inherit {Menu cascade} -options {
	    {configure -compound -version 8.4}
	}

    ## Containers
    ##
    #set group Containers
    set group Tk
    ::widget::define $group frame -image frame.gif -requires Tk \
	-inherit {Tk frame} -options {
	    {configure -container -reflect 0}
	    {configure -class -reflect 0 -category ignore}
	    {configure -colormap -reflect 0 -category ignore}
	    {configure -visual -reflect 0 -category ignore}
	}
    ::widget::define $group labelframe -image frame.gif -requires Tk \
	-version 8.4 \
	-inherit {Tk labelframe} -options {
	    {configure -container -reflect 0}
	    {configure -class -reflect 0 -category ignore}
	    {configure -colormap -reflect 0 -category ignore}
	    {configure -visual -reflect 0 -category ignore}
	}

    ## Core widgets
    ##
    ::widget::define Tk button -image button.gif -requires Tk \
	-inherit {Tk button} -options {
	    {configure -state -type buttonstate}
	    {configure -textvariable -reflect 0}
	    {configure -compound -version 8.4}
	    {configure -overrelief -version 8.4}
	    {configure -repeatdelay -version 8.4}
	    {configure -repeatinterval -version 8.4}
	}
    ::widget::define Tk canvas -image canvas.gif -requires Tk \
	-inherit {Tk canvas} -options {
	    {configure -state -version 8.3}
	}
    ::widget::define Tk checkbutton -image checkbutton.gif -requires Tk \
	-inherit {Tk checkbutton} -options {
	    {configure -state -type buttonstate}
	    {configure -textvariable -reflect 0}
	    {configure -variable -reflect 0}
	    {configure -compound -version 8.4}
	    {configure -overrelief -version 8.4}
	    {configure -offrelief -version 8.4}
	}
    ::widget::define Tk entry -image entry.gif -requires Tk \
	-inherit {Tk entry} -options {
	    {configure -state -type entrystate}
	    {configure -textvariable -reflect 0}
	    {configure -invalidcommand -version 8.3 -reflect 0}
	    {configure -validate -version 8.3 -reflect 0}
	    {configure -validatecommand -version 8.3 -reflect 0}
	    {configure -disabledbackground -version 8.4}
	    {configure -disabledforeground -version 8.4}
	    {configure -readonlybackground -version 8.4}
	}
    ::widget::define Tk label -image label.gif -requires Tk \
	-inherit {Tk label} -options {
	    {configure -state -type buttonstate}
	    {configure -textvariable -reflect 0}
	    {configure -compound -version 8.4}
	}
    ::widget::define Tk listbox -image listbox.gif -requires Tk \
	-inherit {Tk listbox} -options {
	    {configure -activestyle -version 8.4}
	    {configure -listvariable -version 8.3 -reflect 0}
	    {configure -disabledforeground -version 8.4}
	    {configure -setgrid -reflect 0}
	    {configure -state -version 8.4}
	}
    ::widget::define Tk panedwindow -image panedwindow.gif -requires Tk \
	-version 8.4 \
	-inherit {Tk panedwindow}
    ::widget::define Tk radiobutton -image radiobutton.gif -requires Tk \
	-inherit {Tk radiobutton} -options {
	    {configure -state -type buttonstate}
	    {configure -textvariable -reflect 0}
	    {configure -variable -reflect 0}
	    {configure -compound -version 8.4}
	    {configure -overrelief -version 8.4}
	    {configure -offrelief -version 8.4}
	}
    ::widget::define Tk scale -image scale.gif -requires Tk \
	-inherit {Tk scale} -options {
	    {configure -state -type buttonstate}
	    {configure -variable -reflect 0}
	}
    ::widget::define Tk scrollbar -image scrollbar.gif -requires Tk \
	-inherit {Tk scrollbar}
    ::widget::define Tk spinbox -image spinbox.gif -requires Tk \
	-version 8.4 \
	-inherit {Tk spinbox} -options {
	    {configure -state -type entrystate}
	    {configure -textvariable -reflect 0}
	    {configure -invalidcommand -reflect 0}
	    {configure -validate -reflect 0}
	    {configure -validatecommand -reflect 0}
	}
    ::widget::define Tk text -image text.gif -requires Tk \
	-inherit {Tk text} -options {
	    {configure -autoseparators -version 8.4}
	    {configure -setgrid -reflect 0}
	    {configure -undo -version 8.4}
	}

    # Initialize extra widget sets
    ::widget::init_Ttk
    ::widget::init_BWidget
    ::widget::init_Iwidgets

    #
    # Source every file matching *_widgets.tcl in our source base.
    #
    set errors 0
    foreach i [glob -nocomplain -directory $::gui::BASEDIR *_widgets.tcl] {
	if {[catch {uplevel \#0 [list source $i]} err]} {
	    # truncate long error messages
	    set err [string replace $err 100 end ...]
	    set code [tk_messageBox -title "Error Sourcing $i" \
			  -type retrycancel -message \
			  "Error sourcing widget definition file '$i':\n  $err\
			\n\n$::gui::APPNAME can continue loading, but may\
			not function correctly.\
			\nSelect Retry to continue or Cancel to exit."]
	    if {$code eq "cancel"} {
		exit 1
	    }
	    incr errors
	}
    }

    if {$errors == 0} {
	# Only save the cache when no load errors occured
	::widget::save_cache $cache
    }

    widget::init_userdata
}

proc ::widget::init_Ttk {args} {
    # Check that Ttk (tile) got loaded
    if {![package vsatisfies [package present Tk] 8.5]
	&& [catch {package present tile}]} { return }

    ## Themed Tk
    set group "Themed Tk"
    # frame
    # labelframe
    # sizegrip
    foreach {cmd img xopts} {
	button      button.gif      {}
	checkbutton checkbutton.gif {{configure -variable -reflect 0}}
	combobox    combobox.gif    {}
	entry       entry.gif       {}
	label       label.gif       {}
	menubutton  menubutton.gif  {}
	notebook    notebook.gif    {}
	panedwindow panedwindow.gif {}
	progressbar progressbar.gif {}
	radiobutton radiobutton.gif {{configure -variable -reflect 0}}
	scale       scale.gif       {}
	scrollbar   scrollbar.gif   {}
	treeview    tree.gif        {}
    } {
	# Perl/Tkx can handle Tcl packages
	# We could pass -inherit [list $group $cmd], but this allows
	# us to reuse the Tcl option set for Perl/Tkx
	lappend xopts \
	    {configure -class -reflect 0 -category ignore} \
	    {configure -style -reflect 0 -category ignore}
	set cmd ttk::$cmd
	set opts [concat [::widget::inherit tcl $group $cmd ""] $xopts]
	::widget::define $group $cmd -image $img -requires Tk \
	    -lang {tcl ruby perltkx} -version 8.5 -options $opts
    }
}

proc ::widget::init_BWidget {args} {
    # Check that BWidget got loaded
    if {[catch {package require BWidget}]} { return }

    ## BWidget
    set group BWidget
    foreach {cmd img xopts} {
	ArrowButton button.gif      {{configure -state -type buttonstate}}
	Button      button.gif      {{configure -state -type buttonstate}}
	ComboBox    combobox.gif    {}
	Entry       entry.gif       {}
	Label       label.gif       {}
	LabelEntry  entry.gif       {}
	ListBox     listbox.gif     {}
	NoteBook    notebook.gif    {}
	ProgressBar progressbar.gif {}
	SpinBox     spinbox.gif     {}
	Tree        tree.gif        {}
    } {
	# Perl/Tkx can handle Tcl packages
	# We could pass -inherit [list $group $cmd], but this allows
	# us to reuse the Tcl option set for Perl/Tkx
	set opts [concat [::widget::inherit tcl $group $cmd ""] $xopts]
	::widget::define $group $cmd -image $img -requires $group \
	    -lang {tcl ruby perltkx} -version 8.2 -options $opts
    }
    #ButtonBox   button.gif
    #ScrollableFrame ScrolledWindow LabelFrame
}

proc ::widget::init_Iwidgets {args} {
    # Check that Iwidgets got loaded
    if {[catch {package require Iwidgets}]} { return }

    ## Iwidgets
    set group Iwidgets
    foreach {cmd img xopts} {
	calendar		calendar.gif      {}
	canvasprintbox		canvas.gif        {}
	checkbox		checkbutton.gif   {}
	combobox		combobox.gif      {{configure -state -type entrystate}}
	dateentry		entry.gif         {{configure -state -type entrystate}}
	datefield		entry.gif         {{configure -state -type entrystate}}
	disjointlistbox		listbox.gif       {}
	entryfield		entry.gif         {{configure -state -type entrystate} {configure -validate -type command}}
	extbutton		button.gif        {}
	extfileselectionbox	unknown.gif       {}
	feedback		progressbar.gif   {}
	fileselectionbox	unknown.gif       {}
	hierarchy		tree.gif          {}
	hyperhelp		unknown.gif       {}
	messagebox		unknown.gif       {}
	notebook		notebook.gif      {}
	optionmenu		combobox.gif      {}
	pushbutton		button.gif        {}
	radiobox		radiobutton.gif   {}
	scrolledcanvas		canvas.gif        {}
	scrolledframe		scrolledframe.gif {}
	scrolledhtml		text.gif          {}
	scrolledlistbox		listbox.gif       {}
	scrolledtext		text.gif          {}
	selectionbox		unknown.gif       {}
	spindate		spinbox.gif       {}
	spinint			spinbox.gif       {{configure -state -type entrystate}}
	spinner			spinbox.gif       {{configure -state -type entrystate}}
	spintime		spinbox.gif       {}
	tabnotebook		notebook.gif      {}
	tabset			notebook.gif      {}
	timeentry		unknown.gif       {}
	timefield		unknown.gif       {}
	toolbar			unknown.gif       {}
	watch			unknown.gif       {}
    } {
	# We could pass -inherit [list $group $cmd], but this allows
	# us to reuse the Tcl option set for Perl/Tkx
	set opts [concat [::widget::inherit tcl $group $cmd iwidgets] $xopts]
	# Perl/Tkx can handle Tcl packages too
	::widget::define $group $cmd -image $img -requires $group \
	    -namespace iwidgets -lang {tcl ruby perltkx} -version 8.2 \
	    -options $opts
    }
    #buttonbox			button.gif
    #labeledframe		unknown.gif
    #labeledwidget		unknown.gif
    #panedwindow		unknown.gif
}

proc ::widget::init_userdata {args} {
    #
    # Source all widget*.tcl files in the GUI Builder homedir.
    # These will not be cached, as users may be doing all sorts of
    # funky stuff.
    #
    foreach i [glob -nocomplain -directory [::port::appdatadir] widget*.tcl] {
	if {[catch {uplevel \#0 [list source $i]} err]} {
	    # truncate long error messages
	    set err [string replace $err 100 end ...]
	    set code [tk_messageBox -title "Error Sourcing $i" \
			  -type retrycancel -message \
			  "Error sourcing widget definition file '$i':\n  $err\
			\n\n$::gui::APPNAME can continue loading, but may\
			not function correctly.\
			\nSelect Retry to continue or Cancel to exit."]
	    if {$code eq "cancel"} {
		exit 1
	    }
	}
    }
}
