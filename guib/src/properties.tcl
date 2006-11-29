# properties.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# Build the Properties (widget configuration) dialog
#

namespace eval ::config {
    variable placed 0
    variable lastWidget
    # allow for resourcing
    if {![info exists lastWidget]} { set lastWidget "" }
}

# ::config::accept --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::config::accept {} {
    variable W
    if {[::config::apply]} {
	wm withdraw $W(root)
    }
}

# ::config::apply --
#
#   Validate attribute changes.
#
# Arguments:
#   args	comments
# Results:
#   Returns 0 if an error occurs applying, 1 otherwise
#
proc ::config::apply {} {
    variable W
    variable DATA
    variable DIRTY
    variable OPTS
    variable lastWidget

    # Do strict type validation first
    foreach opt [array names DIRTY] {
	set value $DIRTY($opt)
	if {$opt eq "ID"} {
	    # 'ID' won't have optinfo
	} else {
	    # Here we validate a few option types that allow freeform
	    # input, but that have strict types
	    set optinfo $OPTS(t.$opt)
	    set opttype [lindex $optinfo 0]
	    #set optargs [lindex $optinfo 1]
	    set ok 1
	    switch -exact $opttype {
		"double"  { set ok [string is double -strict $value] }
		"integer" { set ok [string is integer -strict $value] }
		"pixels"  { set ok [expr {![catch {winfo pixels . $value}]}] }
	    }
	    if {!$ok} {
		tk_messageBox -parent $W(root) -title "Invalid $opt value" \
		    -icon error -type ok -message \
		    "Invalid $opttype specification \"$value\""
		return 0
	    }
	}
	if {![filter output $opt $lastWidget value]} {
	    # filter output will set the value to the error message
	    tk_messageBox -parent $W(root) -title "Invalid $opt value" \
		-icon error -type ok -message $value
	    return 0
	}
    }

    set isMenu [::widget::isMenu $lastWidget]
    set update ""
    if {[info exists DIRTY(ID)]} {
	# This can only happen for application widgets
	# (not palette widgets or Container)
	if {$isMenu} {
	    # menu item label changed
	    # update has to occur after apply
	    set update menu
	    set title "Menu item $DIRTY(ID) Properties"
	} else {
	    # update has to occur after apply
	    set update app
	    set title "[::widget::type $lastWidget] $DIRTY(ID) Properties"
	}
	wm title $W(root) $title
    }

    set dirty 0
    # determine if it was an application widget or palette widget
    set isAppOrMenuWidget [::widget::exists $lastWidget]
    foreach opt [array names DIRTY] {
	set val $DIRTY($opt)
	if {$isMenu && $opt eq "ID"} {
	    # we mask the ID under -label
	    set useOpt "-label"
	} else {
	    set useOpt $opt
	}
	# The GM: in $opt aligns with that used in widget data
	if {$isAppOrMenuWidget} {
	    set oldVal [::widget::data $lastWidget $useOpt]
	} else {
	    set oldVal [::widget::configure $lastWidget $useOpt]
	}
	if {$val != $oldVal} {
	    set dirty 1
	    # This is to update the dirty checking.  Take this out
	    # if we are going to allow some form of revert in the future.
	    set DATA($opt) $val
	    if {$isAppOrMenuWidget} {
		# This sets the value into the widget instance's data array.
		::widget::data $lastWidget $useOpt $val
	    } else {
		# This sets the palette widget's default value.
		::widget::configure $lastWidget $useOpt $val
	    }
	}
	if {$::TILE && $opt ne "ID"} {
	    $OPTS(l.$opt) state !invalid
	} else {
	    $OPTS(l.$opt) configure -fg black
	}
    }
    catch {unset DIRTY}
    $W(apply) configure -state disabled
    if {$update ne ""} {
	# if we changed the item name, update the tree with the new name
	# Refresh the application palette which calls ::config::update_tree
	::palette::refresh $update
    }
    if {$dirty} {
	dirty yes
	sync_all
    }
    return 1
}

# ::config::cancel --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::config::cancel {} {
    variable W
    variable DATA
    variable DIRTY
    catch {unset DIRTY}
    catch {unset DATA}
    wm withdraw $W(root)
}

# ::config::_selectcolor --
#
#   Code to handle color selection
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::config::_selectcolor {e opt} {
    set curColor $::config::VAL($e)
    set color [SelectColor::menu $e.color [list below $e]]
    if {![string equal $color ""] && ![string equal $color $curColor]} {
	_isdirty $opt $color
	$e.fcol configure -bg $color
	set ::config::VAL($e) $color
    }
    return 1
}

# ::config::_selectimage --
#
#   Code to handle image selection
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::config::_selectimage {e opt} {
    variable lastdir
    set types {
	{"GIF Files" .gif}
	{"XBM Files" .xbm}
	{"PPM Files" .ppm}
	{"All Image Files" {.gif .jpg .pbm .ppm .xbm .png}}
	{"All Files" *}
    }
    if {![info exists lastdir]} {
	set lastdir [::project::get dir]
    }
    # work-around Aqua bug for -initialdir ""
    if {$::AQUA && ![file isdirectory $lastdir]} { set lastdir [pwd] }
    set val [tk_getOpenFile -parent [winfo toplevel $e] -filetypes $types \
	    -title "Select Image File" -initialdir $lastdir]
    if {$val != ""} {
	# The output filter on OK/Apply will verify if the image is OK
	# and the validate command on the entry will do _isdirty
	set lastdir [file dirname $val]
	set projdir [::project::get dir]
	if {($projdir ne "") && ([file pathtype $val] eq "absolute")} {
	    # Try and get a path relative to projdir
	    set target  [file normalize $val]
	    set relpath [relpath [file normalize $projdir] $target]
	    if {$relpath ne $target} {
		variable W
		set dlg $W(root)._selectimage
		if {![winfo exists $dlg]} {
		    widget::dialog $dlg -title "Use Relative Path?" \
			-parent [winfo toplevel $e] -transient 1 \
			-separator 1 -synchronous 1 -padding 4 \
			-modal local -place above -type custom
		    ttk::label $dlg.lbl \
			-text "Use relative path\n\t\"$relpath\"\
			\ninstead of absolute path\n\t\"$val\"?" \
			-justify left -anchor nw -font defaultBoldFont
		    $dlg setwidget $dlg.lbl
		    set yes [$dlg add button -text "Yes" \
				 -command [list $dlg close yes]]
		    set no  [$dlg add button -text "No" \
				 -command [list $dlg close no]]
		}
		if {[$dlg display] eq "yes"} {
		    set val $relpath
		}
	    }
	}
	$e delete 0 end
	$e insert 0 $val
    }
    return 1
}

proc ::config::set_sticky {w style} {
    _isdirty GM:-sticky $style
    grid configure $w.stickyf -sticky $style
}

proc ::config::sticky_menu {w} {
    # create the top level (if needed)
    set top $w.top
    destroy $top
    toplevel $top -bd 2 -relief ridge -cursor [cursor menu]
    wm overrideredirect $top 1
    set x [winfo rootx $w]
    set y [expr {[winfo rooty $w] + [winfo height $w]}]
    wm geometry $top +$x+$y

    # If the widget is a frame, and no row and/or column is resizable,
    # then alter the bindings so that things cannot be sticky so as to have
    # conflicting restraints.
    set widget $::config::lastWidget

    set resizecols 0
    set resizerows 0
    if {[::widget::isFrame $widget]} {
	set curcol [::widget::geometry $widget resize_column]
	set currow [::widget::geometry $widget resize_row]
	regsub -all {[01]} $curcol {} resizec
	regsub -all {[01]} $currow {} resizer
	set resizecols [expr {[llength $resizec]>0?0:1}]
	set resizerows [expr {[llength $resizer]>0?0:2}]
    }

    # pack in existing alignments, set bindings
    set Stickies   {nw n ne new w "" e ew sw s se sew nsw ns nse nsew}
    set Stickymods {0  0 0  1   0 0  0 1  0  0 0  1   2   2  2   3}
    set fsize 16
    set bsize [expr {$fsize/2}]
    set index 0
    foreach sticky $Stickies mod $Stickymods {
	set oksticky [expr {!(($resizecols & $mod) || ($resizerows & $mod))}]
	set f [frame $top.s$sticky -bd 1 -relief raised \
		-height $fsize -width $fsize]
	frame $f.f -height $fsize -width $fsize
	frame $f.b -height $bsize -width $bsize \
		-bg [expr {$oksticky ? "blue" : "#888"}]
	grid $f.f -row 0 -column 0
	grid $f.b -row 0 -column 0 -sticky $sticky
	grid $f -row [expr {$index/4}] -column [expr {$index%4}]
	incr index
	if {$oksticky} {
	    bind $f <ButtonRelease-1> [list ::config::set_sticky $w $sticky]
	    bind $f.b <ButtonRelease-1> [list ::config::set_sticky $w $sticky]
	    bind $f.f <ButtonRelease-1> [list ::config::set_sticky $w $sticky]
	    bind $f <Enter> { %W configure -relief sunken }
	    bind $f <Leave> { %W configure -relief raised }
	}
    }
    bind $top <ButtonRelease-1> [list destroy $top]
    catch {
	tkwait visibility $top
	grab $top
    }
}

# ::config::_isdirty --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::config::_isdirty {opt newVal} {
    variable DATA
    variable DIRTY
    variable W
    variable OPTS

    if {$DATA($opt) eq $newVal} {
	# update the appropriate label
	if {$::TILE && $opt ne "ID"} {
	    $OPTS(l.$opt) state !invalid
	} else {
	    $OPTS(l.$opt) configure -fg black
	}
	catch {unset DIRTY($opt)}
    } else {
	# update the appropriate label
	if {$::TILE && $opt ne "ID"} {
	    $OPTS(l.$opt) state invalid
	} else {
	    $OPTS(l.$opt) configure -fg red
	}
	set DIRTY($opt) $newVal
    }
    # change the Apply button to be appropriately (en|dis)abled
    $W(apply) configure -state \
	    [expr {[llength [array names DIRTY]] ? "normal" : "disabled"}]
    return 1
}

# ::config::_add --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   w		widget to add into
#   opt		type of option to add
#   val		current value of opt
#   update	specifies whether this is an update or an add.
#		updates do not create opts - only set them if they exist.
# Results:
#   Returns nothing
#
proc ::config::_add {w opt val updateOnly} {
    variable TYPES
    variable DATA
    variable DIRTY
    variable OPTS

    set optinfo $OPTS(t.$opt)
    set opttype [lindex $optinfo 0]
    set optargs [lindex $optinfo 1]

    # We attempt to create the widget for each opt type only once,
    # and just show the ones we need.
    set l $w.l$opt
    set e $w.e$opt
    if {$opt ne $opttype} {append e ,$opttype}

    if {![winfo exists $l]} {
	if {$updateOnly} { return 0 }
	set width [expr {[string length $opt] - 2}]; # proportional font fudge
	if {$width < 16} { set width 16 }
	if {[string match "GM:*" $opt]} {
	    set text [string range $opt 3 end]
	} else {
	    set text [string toupper $opt 0 0]
	}
	# XXX FIX: These should be -bg white
	ttk::label $l -text $text -width $width -anchor w
    }
    set sticky news
    if {![winfo exists $e]} {
	if {[info exists TYPES($opttype)] || $opttype eq "list"} {
	    # These specify known types with acceptable value lists
	    if {$::TILE} {
		ttk::combobox $e -state readonly
		bind $e <<ComboboxSelected>> "::config::_isdirty [list $opt] \
		    \[[list $e] get\]"
	    } else {
		ComboBox $e -bd 1 -editable no \
		    -modifycmd "::config::_isdirty [list $opt] \
		    \[[list $e] cget -text\]"
	    }
	} else {
	    switch -exact $opttype {
		boolean {
		    ttk::frame $e
		    ttk::radiobutton $e.1 -text "Yes/True" -value 1 \
			    -variable ::config::VAL($e) \
			    -command "::config::_isdirty [list $opt] \
			    \$::config::VAL($e)"
		    ttk::radiobutton $e.0 -text "No/False" -value 0 \
			    -variable ::config::VAL($e) \
			    -command "::config::_isdirty [list $opt] \
			    \$::config::VAL($e)"
		    grid $e.1 $e.0 -sticky w -padx 4
		    grid columnconfigure $e 2 -weight 1
		}
		color	{
		    ttk::frame $e
		    frame $e.fcol -width 25 -bd 1 -relief solid
		    ttk::label $e.cname -textvariable ::config::VAL($e)
		    grid $e.fcol  -row 0 -column 0 -sticky ns -pady 1
		    grid $e.cname -row 0 -column 1 -sticky e -padx 4
		    grid columnconfigure $e 2 -weight 1
		    set cmd [list ::config::_selectcolor $e $opt]
		    bind $e.fcol  <1> $cmd
		    bind $e.cname <1> $cmd
		}
		font	{
		    SelectFont $e -type toolbar \
			-styles {bold italic underline} \
			-command "::config::_isdirty [list $opt] \
			    \[[list $e] cget -font\]"
		    catch {
			foreach s {font size bold italic underline} {
			    $e.$s configure -bd 1; pack configure $e.$s -fill y
			}
		    }
		}
		double	-
		integer	-
		pixels	{
		    spinbox $e -bd 1 -validate key \
			-validatecommand [list ::config::_isdirty $opt %P]
		}

		image	{
		    # FIX: XXX we need to handle showing the image and
		    # loading it into Tk when entry is hand-edited
		    ttk::frame $e
		    ttk::entry $e.e -validate key -validatecommand \
			[list ::config::_isdirty $opt %P]
		    ttk::button $e.b -style Slim.Toolbutton -text "..." \
			-command [list ::config::_selectimage $e.e $opt]
		    pack $e.e -side left -fill both -expand 1
		    pack $e.b -side left -fill both
		}

		sticky {
		    # The size of the buttons on the bar
		    set size 18
		    set w $e
		    frame $w -width $size -height $size -relief raised -bd 1
		    frame $w.b -width $size -height $size
		    frame $w.stickyf -height [expr {$size*0.4}] \
			-width [expr {$size*0.4}] -bg blue
		    foreach s {nw ne sw se n s e w} {
			frame $w.s$s -width 2 -height 2 -bg gray -relief raised -bd 1
			grid $w.s$s -row 0 -column 0 -sticky $s
		    }
		    bind $w <ButtonRelease-1> \
			[list ::tbar::sticky_menu $w ::config::lastWidget \
			     [list ::config::set_sticky $w]]
		    bindtags $w.stickyf [linsert [bindtags $w.stickyf] 0 $w]
		    bindtags $w.b [linsert [bindtags $w.b] 0 $w]
		    grid $w.b -row 0 -column 0 -sticky news
		    grid $w.stickyf -row 0 -column 0
		}

		ID {
		    error "we should never 'add' the ID"
		}

		string	-
		custom	-
		command	-
		variable	-
		widget	-
		default	{
		    ttk::entry $e -validate key \
			-validatecommand [list ::config::_isdirty $opt %P]
		}
	    }
	}
	help::balloon $e "Requires valid $opttype specification"
    }

    set OPTS(l.$opt) $l
    set OPTS(e.$opt) $e

    if {![info exists DATA($opt)] || $updateOnly} {
	set DATA($opt) $val
	catch {unset DIRTY($opt)}
	if {$::TILE && $opt ne "ID"} {
	    $l state !invalid
	} else {
	    $l configure -fg black
	}
    }
    # The behavior should be that the label will become red when an opt
    # is changed, and return to normal when applied.
    if {[info exists TYPES($opttype)] || $opttype eq "list"} {
	if {[info exists TYPES($opttype)]} {
	    set vals [linsert $TYPES($opttype) 0 $val]
	} else {
	    set vals [linsert $optargs 0 $val]
	}
	# These specify known types with acceptable value lists
	$e configure -values $vals
	if {$::TILE} {
	    $e set [lindex $vals 0]
	} else {
	    $e setvalue @0
	}
    } else {
	switch -exact $opttype {
	    boolean	{
		set ::config::VAL($e) [string is true $val]
	    }
	    color	{
		$e.fcol configure -bg $val
		set ::config::VAL($e) $val
	    }
	    font	{
		$e configure -font $val
	    }
	    double	-
	    integer	-
	    pixels	{
		if {[llength $optargs]} {
		    set range $optargs
		} else {
		    # Use reasonable defaults
		    if {[string equal $opttype "double"]} {
			set range [list 0.0 1.0 0.1]
		    } else {
			set range [list 0 100 5]
		    }
		}
		foreach {from to inc} $range break
		$e configure -from $from -to $to -increment $inc
		$e delete 0 end
		$e insert 0 $val
	    }

	    image	{
		set vtype [$e.e cget -validate]
		$e.e configure -validate none
		$e.e delete 0 end
		$e.e insert 0 $val
		$e.e configure -validate $vtype
	    }

	    sticky	{
		grid configure $e.stickyf -sticky $val
		set sticky wns
	    }

	    ID	{ error "we should not be here" }

	    string	-
	    custom	-
	    command	-
	    variable	-
	    widget	-
	    default	{
		set vtype [$e cget -validate]
		$e configure -validate none
		$e delete 0 end
		$e insert 0 $val
		$e configure -validate $vtype
	    }
	}
    }
    if {!$updateOnly} {
	# The ipad ensures space around the label, and padx/y gets the
	# clean 1-pixel border look around the opts
	grid $l $e -sticky $sticky -pady {1 0} -padx {1 0}
    }
    return 1
}

proc ::config::show {group widget {show true}} {
    variable lastWidget
    variable W
    variable DATA
    variable DIRTY
    variable OPTS
    variable TYPES

    if {$group eq "sample"} {
	set type [::widget::get $widget node]
    } elseif {$group eq "menu"} {
	if {$widget eq "MENU"} {
	    set type [::widget::type $widget]
	} else {
	    set type [::widget::menutype $widget]
	}
    } else {
	set type [::widget::type $widget]
    }

    if {$widget ne $lastWidget} {
	set lastWidget $widget
	# reset the label background of those opts that were dirty
	foreach opt [array names DIRTY] {
	    if {$::TILE && $opt ne "ID"} {
		$OPTS(l.$opt) state !invalid
	    } else {
		$OPTS(l.$opt) configure -fg black
	    }
	}
	catch {unset DATA}
	catch {unset DIRTY}
	catch {unset OPTS}

	# We don't need to unselect anything because that should have
	# occured before this is called.
	if {$group eq "sample"} {
	    ::palette::select_palette $type
	} elseif {$group eq "container"} {
	    ::palette::select_widget $widget
	} elseif {$group eq "widget"} {
	    ::palette::select_widget $widget
	} elseif {$group eq "menu"} {
	    ::palette::select_menu $widget
	} else {
	    #error [info level 0]
	}
	sync_all
    }

    # The ID field is handled specially
    catch {unset DIRTY(ID)}
    if {$group eq "widget"} {
	set DATA(ID) [::widget::data $widget ID]
    } elseif {$group eq "menu"} {
	# we use the -label option for menu items as the ID
	set DATA(ID) [::widget::id $widget]
    }
    set OPTS(l.ID) [set e $W(widget)]
    $e configure -fg black -validate none
    $e setvalue $widget
    $W(widgetimg) configure -image [::widget::get $type image]

    if {$group eq "sample"} {
	# DEFAULT WIDGET PROPERTIES
	wm title $W(root) "Default $type Properties"
	$e configure -editable no -entrybg grey
	help::balloon $e "These are the default $type properties"
	foreach btn [list $W(bgeometry)] {
	    if {[$btn cget -image] eq "arrow_down.gif"} { $btn invoke }
	    $btn configure -state disabled
	}
	foreach btn [list $W(badvanced)] {
	    $btn configure -state normal
	    if {[$btn cget -image] eq "arrow_right.gif"} { $btn invoke }
	}
    } elseif {$group eq "container"} {
	# CONTAINER PROPERTIES
	wm title $W(root) "Master Container Properties"
	$e configure -editable no -entrybg grey
	help::balloon $e "The master container frame"
	foreach btn [list $W(badvanced) $W(bgeometry)] {
	    if {[$btn cget -image] eq "arrow_down.gif"} { $btn invoke }
	    $btn configure -state disabled
	}
    } elseif {$group eq "widget"} {
	# WIDGET INSTANCE PROPERTIES
	wm title $W(root) "$type $DATA(ID) Properties"
	$e configure -editable yes -invalidcommand bell -entrybg white \
	    -validate key -validatecommand {expr {[regexp {^[A-Za-z0-9_]*$} %P] \
					   && [::config::_isdirty ID %P]}}
	help::balloon $e "The name for the widget in your code"
	foreach btn [list $W(badvanced) $W(bgeometry)] {
	    $btn configure -state normal
	    if {[$btn cget -image] eq "arrow_right.gif"} { $btn invoke }
	}
    } elseif {$group eq "menu"} {
	# MENU ITEM PROPERTIES
	if {$widget eq "MENU"} {
	    wm title $W(root) "Menu Properties"
	    $e configure -editable no -entrybg grey
	} else {
	    wm title $W(root) "Menu item $DATA(ID) Properties"
	    $e configure -editable yes -invalidcommand bell -entrybg white \
		-validate key -validatecommand [list ::config::_isdirty ID %P]
	}
	help::balloon $e "The menu widget"
	foreach btn [list $W(bgeometry)] {
	    if {[$btn cget -image] eq "arrow_down.gif"} { $btn invoke }
	    $btn configure -state disabled
	}
	foreach btn [list $W(badvanced)] {
	    $btn configure -state normal
	    if {[$btn cget -image] eq "arrow_right.gif"} { $btn invoke }
	}
    } else {
	error "Uknown group '$group'"
    }

    foreach {opt opttype} [::widget::get $type options -type] {
	set OPTS(t.$opt) $opttype
    }

    # Retrieve all the attributes of a widget by type
    # Add the opts to the appropriate frame
    # Make sure that we scroll back to top and that each frame loses
    # the previous widget options
    $W(frame) yview moveto 0
    if {$group eq "sample"} {
	array set vals [::widget::configure $type]
    }
    foreach frame {basic advanced} {
	set f $W(f$frame)
	catch {eval grid forget [winfo children $f]}
	grid columnconfigure $f 1 -weight 1
	set opts [::widget::get $type options -category $frame]
	foreach opt [lsort $opts] {
	    # Don't forget to call the input filter (if any)
	    if {$group eq "menu" && $opt eq "-label"} {
		# skip -label for menus - we use that for the ID
		continue
	    }
	    if {$group eq "sample"} {
		set val $vals($opt)
	    } else {
		set val [::widget::data $widget $opt]
	    }
	    _add $f $opt [filter input $opt $val] 0
	}
    }
    # Handle the Geometry info
    set f $W(fgeometry)
    catch {eval grid forget [winfo children $f]}
    grid columnconfigure $f 1 -weight 1
    if {$group eq "widget"} {
	array set geomDefs {
	    -columnspan 1	-rowspan    1	-sticky     ""
	    -ipadx      0	-ipady      0	-padx       0	-pady       0
	}
	foreach opt [lsort [array names geomDefs]] {
	    # row/col info is not configurable in properties dialog
	    if {[regexp {(row|column)} $opt]} { continue }
	    set OPTS(t.GM:$opt) [::widget::opt_type "" "" $opt]
	    # Don't forget to call the input filter (if any)
	    _add $f GM:$opt \
		[filter input GM:$opt [::widget::geometry $widget $opt]] 0
	}
    }

    $W(apply) configure -state \
	    [expr {[llength [array names DIRTY]] ? "normal" : "disabled"}]

    if {$show} {
	variable placed
	if {!$placed} {
	    ::gui::PlaceWindow $W(root) widget $::W(ROOT) right
	    set placed 1
	}
	wm deiconify $W(root)
	raise $W(root)
	focus -force $W(root)
    }
}

proc ::config::MouseWheel {w D} {
    variable W
    if {![string equal $w $W(frame)]} {
	$W(frame) yview scroll [expr {- ($D / 120) * 4}] units
    }
}

proc ::config::dlg_modify_cmd {t} {
    set node [lindex [$t getvalue 1] 0]
    ::palette::unselect *
    if {[::widget::exists $node]} {
	if {[::gui::isContainer $node]} {
	    ::config::show container $node
	} elseif {[::widget::isWidget $node]} {
	    ::config::show widget $node
	} elseif {[::widget::isMenu $node]} {
	    ::config::show menu $node
	} else {
	    # FIX: how would one get here?
	    error [info level 0]
	}
    } else {
	::config::show sample $node
    }
}

# make an option entry form, make it tough to destroy
# this will be expanded later.
# Make sure its OK for the user to destroy the window.

proc ::config::dialog {root} {
    variable W
    variable lastWidget ""

    set W(root) $root
    destroy $root

    toplevel $root
    wm withdraw $root
    wm title $root "Widget Properties"
    wm protocol $root WM_DELETE_WINDOW [list wm withdraw $root]
    wm group $root $::W(ROOT)
    wm transient $root $::W(ROOT)
    bind $root <Destroy> [subst { if {"$root" eq "%W"} \
				      { after idle [info level 0] } }]
    bind $root <MouseWheel> [list ::config::MouseWheel %W %D]

    # gettree will create the tree if it does not already exist
    set W(widget) [Droptree $root.dtree -tree [gettree] -modifycmd \
		       [list ::config::dlg_modify_cmd $root.dtree]]
    # The widget images are 16x16
    set W(widgetimg) [label $root.wimg -image frame.gif \
	    -relief solid -bd 1 -width 20 -height 18]

    # Create a specialized tree w/ frames for the various property types
    set sw [widget::scrolledwindow $root.sw]
    set sf [ScrollableFrame $root.sw.sf -constrainedwidth 1]
    $sw setwidget $sf
    set W(frame) $sf
    set sff [$sf getframe]
    set row -1
    foreach {frame name} {
	basic    "Basic"
	advanced "Advanced"
	geometry "Geometry"
    } {
	if {0 && $::TILE} {
	    set b [ttk::button $sff.b$frame -text $name -image arrow_down.gif \
		       -anchor w -compound left]
	} else {
	    set b [button $sff.b$frame -text $name -image arrow_down.gif \
		       -anchor w -compound left -bd 1 -relief flat \
		       -font defaultBoldFont]
	}
	$b configure -command [format {
	    # Collapse/hide table and change image
	    if {[%1$s cget -image] eq "arrow_down.gif"} {
		# table is showing
		%1$s configure -image arrow_right.gif
		grid remove %2$s
	    } else {
		%1$s configure -image arrow_down.gif
		grid %2$s
	    }
	} $sff.b$frame $sff.f$frame]
	set f [ttk::frame $sff.f$frame]
	grid columnconfigure $f 1 -weight 1 -pad 1
	set W(b$frame) $sff.b$frame
	set W(f$frame) $f

	grid $sff.b$frame -row [incr row] -sticky ew
	grid $sff.f$frame -row [incr row] -sticky news -padx {16 0}
    }
    # oddly this config doesn't stick at creation time
    $sw configure -relief groove -borderwidth 1
    grid columnconfigure $sff 0 -weight 1

    # [OK] [Cancel] [Apply]
    set btns [ttk::frame $root.btns]
    ttk::button $btns.ok  -width 8 -text "OK" \
	-command {::config::accept}
    ttk::button $btns.app -width 8 -text "Apply"\
	-state disabled -default active \
	-command {::config::apply}
    ttk::button $btns.can -width 8 -text "Cancel" \
	-command {::config::cancel}

    grid x $btns.ok $btns.can $btns.app -padx 4 -pady {6 4}
    grid configure $btns.app -padx [list 4 [pad corner]]
    grid columnconfigure $btns 0 -weight 1

    bind $root <Return> [list $btns.app invoke]
    bind $root <Escape> [list $btns.can invoke]
    set W(apply) $btns.app

    grid $W(widgetimg) -row 0 -column 0 -sticky news -padx 4 -pady 4
    grid $W(widget)    -row 0 -column 1 -sticky news -padx {0 4} -pady 4
    grid $sw           -row 1 -sticky nsew -columnspan 2 -padx 4
    grid $btns         -row 3 -sticky ew -columnspan 2

    # make the space with the tabnotebook grow
    grid rowconfigure    $root 1 -weight 1
    grid columnconfigure $root 1 -weight 1

    return $root
}

proc ::config::gettree {} {
    # Create the tree struct for the droptree.  If we had one before, then
    # destroy that and start again.
    variable TREE
    if {![info exists TREE]} {
	set TREE [::struct::tree::tree ::config::WIDGETTREE]
    }
    return $TREE
}

proc ::config::reset {} {
    # If we had a tree, destroy that and start again.
    variable TREE
    if {[info exists TREE]} {
	$TREE destroy
	unset TREE
	update_tree
    }
    if {[info exists ::W(CONFIG)] && [winfo exists $::W(CONFIG)]} {
	wm withdraw $::W(CONFIG)
    }
}

# ::config::update_tree --
#
#   Create the hierarchy of the currently built GUI as a tree structure.
#
# Arguments:
#   node	optional node if only one node needs updating
#		this would be used for a name change
# Results:
#   Returns the tree name
#
proc ::config::update_tree {{node ""}} {
    variable W

    #set f    [::gui::container]
    set f $::W(FRAME)
    set tree [gettree]
    if {![$tree size]} {
	# We create the class nodes just once
	# This is called again between language/ver changes

	# adapted from ::palette::show
	# FIX: we should cache this
	set widgets [::widget::palette [targetLanguage] [targetVersion]]
	foreach {group children} $widgets {
	    $tree insert root end $group
	    $tree set $group "GROUP DEFAULTS: $group"
	    $tree set $group -key selectable 0
	    foreach child $children {
		$tree insert $group end $child
		$tree set $child $child
		$tree set $child -key image [::widget::get $child image]
	    }
	}
    }
    if {$node != "" && [$tree exists $node]} {
	# just update the given node
	set w $node
	# this doesn't account for master changes
	$tree set $w [::widget::data $w ID]
	$tree set $w -key image [::widget::get [::widget::type $w] image]
    } else {
	# At this point, we recreate the user widget hierarchy
	catch {$tree delete $f}

	# $::W(FRAME) eq CONTAINER
	$tree insert root 0 $f
	$tree set $f "CONTAINER"
	$tree set $f -key image frame.gif
	foreach w [lsort -command frameLevelSort [::widget::widgets]] {
	    if {[::gui::isContainer $w]} { continue }
	    set master [::widget::data $w master]
	    if {[::gui::isContainer $master] || $master eq ""} {
		# the master is the container
		set master $f
	    }
	    $tree insert $master end $w
	    $tree set $w [::widget::data $w ID]
	    $tree set $w -key image \
		[::widget::get [::widget::type $w] image]
	}

	# also define the menu hierarchy
	set m "MENU"
	catch {$tree delete $m}
	$tree insert root 1 $m
	$tree set $m "MENU"
	$tree set $m -key image menu.gif
	foreach w [::widget::menus] {
	    set master [::widget::parent $w]
	    $tree insert $master end $w
	    $tree set $w [::widget::id $w]
	    $tree set $w -key image [::widget::getimage $w]
	}
    }
    if {[info exists W(widget)] && [winfo exists $W(widget)]} {
	# refresh the droptree widget - the tree should already be attached.
	$W(widget) refresh
    }
    return $tree
}

# sync_form --
#
# update the current form (if any) given a new widget value
#
proc ::config::synchronize {w what args} {
    variable ::config::lastWidget

    # update the properties dialog for the opt (if it exists)
    if {$lastWidget ne $w} { return 0 }

    variable OPTS
    if {$what eq "geometry"} {
	foreach {opt val} $args {
	    if {[info exists OPTS(l.GM:$opt)]} {
		set val [filter input $opt $val]
		::config::_add [winfo parent $OPTS(l.GM:$opt)] GM:$opt $val 1
	    }
	}
    } else {
	foreach {opt val} $args {
	    if {[info exists OPTS(l.$opt)]} {
		# 1 == update only
		set val [filter input $opt $val]
		::config::_add [winfo parent $OPTS(l.$opt)] $opt $val 1
	    }
	}
    }
    return 1
}
