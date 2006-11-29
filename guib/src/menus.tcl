# menus.tcl --
#
#	Menu defs file.
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::menu {
    variable W
    array set W {}
}

proc ::menu::accelerator {key args} {
    set shift   [string match -nocase *shift*   $args]
    set control [string match -nocase *control* $args]
    set meta    [string match -nocase *meta*    $args]
    set alt     [string match -nocase *alt*     $args]
    if {$::tcl_platform(platform) eq "windows"} {
	set space "    "
	array set m {
	    prefix "" suffix ""  shift0 "" shift1 "Shft+"
	    control0 "" control1 "Ctrl+"  meta0 "" meta1 "Meta+"
	    alt0 "" alt1 "Alt+"
	}
    } elseif {$::AQUA} {
	set space ""
	set key [string toupper $key]
	array set m {
	    prefix "" suffix ""  shift0 "" shift1 "Shift-"
	    control0 "" control1 "Command-"  meta0 "" meta1 "\240"
	    alt0 "" alt1 "Option-"
	}
    } else { # unix
	set space "    "
	array set m {
	    prefix "<" suffix ">"  shift0 "" shift1 "Shift-"
	    control0 "" control1 "Ctrl-"  meta0 "" meta1 "Meta-"
	    alt0 "" alt1 "Alt-"
	}
    }
    return "$space$m(prefix)$m(shift$shift)$m(control$control)$m(meta$meta)$m(alt$alt)$key$m(suffix)"
}

proc ::menu::init {top args} {
    # This treats '.' as a special case.
    set base [expr {($top == ".") ? "" : $top}]

    set menu $base.menu
    menu $menu
    $menu add cascade -menu $menu.file -label File -underline 0
    $menu add cascade -menu $menu.edit -label Edit -underline 0
    $menu add cascade -menu $menu.cmds -label Commands -underline 0
    $top config -menu $menu

    if {$::AQUA} {
	$menu add cascade -menu $menu.apple
	$menu add cascade -menu $menu.help
	set ctrl Command
    } else {
	$menu add cascade -menu $menu.help -label Help -underline 0
	set ctrl Control
    }

    ## FILE menu
    set m $menu.file
    menu $m -tearoff 0

    if {![::api::IsInteractive]} {
	$m add command -label "New" -underline 0 \
		-accelerator [accelerator n control] \
		-command ::project::new

	$m add command -label "Open..." -underline 0 \
		-accelerator [accelerator o control] \
		-command ::project::openp
    }

    $m add command -label "Save" -underline 0 \
	    -accelerator [accelerator s control] \
	    -command { ::project::save [::project::get ui] }

    if {![::api::IsInteractive]} {
	$m add command -label "Save As..." -underline 5 \
		-command ::project::save

	$m add separator

	menu $m.mru -tearoff 0 -postcommand [list ::menu::MruPostCmd $m.mru]
	$m add cascade -label "Recent Projects" -underline 0 -menu $m.mru
    }

    $m add separator

    $m add command -label "Project Settings" -underline 0 \
	    -command ::project::settings

    $m add separator

    $m add command -label "Exit" -underline 1 \
	    -accelerator [accelerator q control] \
	    -command mainmenu_quit

    ## EDIT menu
    set m $menu.edit
    menu $m -tearoff 0 \
	    -postcommand [list ::menu::EditPostCmd $m]

    $m add command -label "Edit Text Property" -underline 5 \
	    -accelerator [accelerator F2] \
	    -command mainmenu_edit_label -state disabled

    $m add command -label "Widget Properties..."  -underline 0 \
	    -accelerator [accelerator w control] \
	    -command ::menu::widgetOptions \

    $m add command -label "Row & Column Properties..." -underline 0 \
	    -command ::rowcol::OpenWindow -state disabled

    $m add separator

    $m add checkbutton -label "View Menus..." -underline 0 \
	-accelerator [accelerator m control] \
	-variable ::menued::show -command [list ::menued::show 0]

    $m add separator

    $m add command -label "Delete" -underline 2 \
	-accelerator [expr {$::AQUA ? [accelerator d control] : ""}] \
	-command mainmenu_delete

    $m add command -label "Insert" -underline 0 \
	-accelerator [expr {$::AQUA ? [accelerator i control] : ""}] \
	-command mainmenu_insert

    $m add command -label "Cut" -underline 2 \
	    -accelerator [accelerator x control] \
	    -command mainmenu_cut

    $m add command -label "Copy" -underline 0 \
	    -accelerator [accelerator c control] \
	    -command mainmenu_copy

    $m add command -label "Paste" -underline 0 \
	    -accelerator [accelerator v control] \
	    -command mainmenu_paste

    if {!$::AQUA} {
	$m add separator

	$m add command -label "Preferences..." -underline 3 \
	    -accelerator [accelerator p control] \
	    -command ::prefs::popup
    }

    ## COMMANDS menu
    set m $menu.cmds
    menu $m -tearoff 0 \
	    -postcommand ::menu::CommandsPostCmd

    $m add command -label "Start Test" -underline 6 \
	    -accelerator [accelerator t control] \
	    -command ::compile::build_test

    $m add command -label "Stop Test" -underline 0 \
	    -accelerator [accelerator k control] \
	    -command ::compile::kill_test -state disabled

    $m add command -label "View Code" -underline 0 \
	    -command mainmenu_view_code

    $m add command -label "Load Project into Frame..." -underline 0 \
	-command mainmenu_load_project_into_frame -state disabled

    $m add command -label "Attach Scrollbars" -underline 0 \
	    -command mainmenu_attach_scrollbars

    if 0 {
	$m add command -label "Reapply Toolbar" -underline 0 \
		-accelerator [accelerator r control] \
		-command mainmenu_reapply_toolbar
    }

    $m add cascade -label "Navigate" -underline 0 \
	    -command mainmenu_navigate -menu $menu.cmds.nav

    if {[info commands tkcon] != ""} {
	# We don't allow for 'console', as we only want tkcon as our
	# debugging console
	$m add separator

	$m add command -label {Show Console} -underline 5 \
		-accelerator [accelerator F12] \
		-command [list tkcon show]

	$m add command -label {Hide Console} -underline 0 \
		-accelerator [accelerator F11] \
		-command [list tkcon hide]

	bind all <F11> [list tkcon hide]
	bind all <F12> [list tkcon show]
    }

    if {[package provide comm] != ""} {
	# This will exist when we request debugging
	$m add separator
	$m add command -label "Comm Port: [comm::comm self]" -state disabled
    }

    set m $menu.cmds.nav
    menu $m -tearoff 0

    $m add command -label "Next Widget" -underline 0 \
	    -accelerator [accelerator Right shift] \
	    -command {move_to_widget right}

    $m add command -label "Previous Widget" -underline 0 \
	    -accelerator [accelerator Left shift] \
	    -command {move_to_widget left}

    $m add command -label "Select Parent" -underline 11 \
	    -accelerator [accelerator Up] \
	    -command leave_subgrid \
	    -state disabled

    $m add command -label "Select 1st Child" -underline 8 \
	    -accelerator [accelerator Down] \
	    -command enter_subgrid \
	    -state disabled

    ## HELP menu
    set m [menu $menu.help -tearoff 0]
    $m add command -label "Help Contents" -underline 0 \
	    -accelerator [accelerator F1] \
	    -command ::help::launch

    $m add separator

    $m add checkbutton -label "Show Tooltips" \
	    -variable ::P(show-tooltips) \
	    -command {::help::tooltips $::P(show-tooltips)}

    if {$::AQUA} {
	set apple [menu $menu.apple -tearoff 0]

	$apple add command -command about \
		-label "About $::gui::APPNAME..."
	$apple add separator

	$apple add command -label "Preferences..." -underline 3 \
	    -accelerator [accelerator , control] \
	    -command ::prefs::popup
    } else {
	$m add separator

	$m add command -command about \
		-label "About $::gui::APPNAME" -underline 0
    }

    foreach {to evt keys cmd} {
	all <<Help>> {<Help> <F1>} ::help::launch
	all <<Exit>> {<$ctrl-q>}   {::menu::checkKey %W mainmenu_quit}

	$top <<New>>  <$ctrl-n> {::menu::checkKey %W ::project::new}
	$top <<Open>> <$ctrl-o> {::menu::checkKey %W ::project::openp}
	$top <<Save>> <$ctrl-s>
	{::menu::checkKey %W {::project::save [::project::get ui]}}

	$top <<ShowMenu>>    <$ctrl-m>
	{::menu::checkKey %W ::menued::show}

	all <<Properties>>  <$ctrl-w>
	{::menu::checkKey %W ::menu::widgetOptions}
	all <<Build>>       <$ctrl-t>
	{::menu::checkKey %W ::compile::build_test}
	all <<Kill>>        <$ctrl-k>
	{::menu::checkKey %W ::compile::kill_test}
	all <<Preferences>> {<$ctrl-p> <$ctrl-comma>}
	{::menu::checkKey %W ::prefs::popup}

	$top <<Insert>> {<Insert> <$ctrl-i>}
	{::menu::checkKey %W mainmenu_insert}
	$top <<Delete>> {<Delete> <$ctrl-d>}
	{::menu::checkKey %W mainmenu_delete}
	$top <<Cut>>   <$ctrl-x>   {::menu::checkKey %W mainmenu_cut}
	$top <<Copy>>  <$ctrl-c>   {::menu::checkKey %W mainmenu_copy}
	$top <<Paste>> <$ctrl-v>   {::menu::checkKey %W mainmenu_paste}

	$top <<WidgetNext>> <Shift-Right>
	{::menu::checkKey %W {move_to_widget right}}
	$top <<WidgetPref>> <Shift-Left>
	{::menu::checkKey %W {move_to_widget left}}
	$top <<WidgetDown>> <Down>
        {::menu::checkKey %W enter_subgrid}
	$top <<WidgetUp>>   <Up>
	{::menu::checkKey %W leave_subgrid}

	$top <<Abort>>      <Escape>
	{::menu::checkKey %W {::palette::unselect *}}
	$top <<EditLabel>>  <F2>  {mainmenu_edit_label}

    } {
	eval [list event add $evt] [subst $keys] ; # subst $ctrl
	bind [subst $to] $evt $cmd
    }
    #bind $toplevel <$ctrl-r> {::menu::checkKey %W mainmenu_reapply_toolbar}
    if {$::AQUA} {
	# This is an old Classic default define - remove it
	event delete <<Cut>> <F2>
    }

    return $menu
}

# ::menu::checkKey --
#
#	Evalute a keyboard accelerators only if the event did not not
#	occur in certain contexts (inside entry, text or listbox
#	widgets).
#
# Arguments:
#	win	the widget inside which the event has occured
#	cmd	the command to execute
#
# Result:
#	None.
#
proc ::menu::checkKey {win cmd} {
    switch -exact [winfo class $win] {
	Entry - Listbox - Text { return }
    }
    eval $cmd
}

# bring up widget Properties dialog for the currently active item
#
proc ::menu::widgetOptions {} {
    if {$::Current(widget) != ""} {
	# Dialog widget selected
	::palette::activate app 1 $::Current(widget)
    } elseif {$::Current(palette_widget) != ""} {
	# Language-specific palette widget
	::palette::activate lang 1 $::Current(palette_widget)
    } else {
	# by default just show the main container
	::palette::activate app 1 $::W(FRAME)
    }
}

#
# present the most recently used projects
#
proc ::menu::MruPostCmd {m} {
    $m delete 0 end
    # the MRU list is in "time file" pairs
    foreach pair $::P(MRU) {
	set file [lindex $pair 1]
	$m add command -label $file -command [list ::project::openp $file]
    }
}

#
# set the proper menu options of the Edit menu to normal/disabled
#
proc ::menu::EditPostCmd {m} {
    global Current

    # items that need a selected widget
    set state [expr {$Current(widget) == "" ? "disabled" : "normal"}]
    foreach i {{Widget Properties...} Cut Copy} {
	catch {$m entryconfigure $i -state $state}
    }

    # items that need a row or column specified
    set state [expr {"$Current(row)$Current(column)" == "" ? "disabled" : "normal"}]
    catch {$m entryconfigure "Row & Column Properties..." -state $state}

    # items that need lots of data specified
    set state [expr {"$Current(widget)$Current(row)$Current(column)$Current(gridline)" == "" ? "disabled" : "normal"}]
    catch {$m entryconfigure Delete -state $state}
    catch {$m entryconfigure Insert -state $state}

    # items that need something in the clipboard
    set state [expr {![from_clipboard 1] ? "disabled" : "normal"}]
    catch {$m entryconfigure Paste -state $state}
}

proc ::menu::CommandsPostCmd {} {
    set current $::Current(widget)

    # We can Stop Test only if it is running
    set state [expr {[::compile::isTestRunning] ? "normal" : "disabled"}]
    ::menu::setstate "Stop Test" $state

    # We can test only if 1+ widgets are present
    set state [expr {[llength [::widget::widgets]]>1 ? "normal" : "disabled"}]
    ::menu::setstate "Start Test" $state

    # We can view code if there is a file to view
    set state [expr {[file exists [::project::get include]] ? \
			 "normal" : "disabled"}]
    ::menu::setstate "View Code" $state

    # If the current widget is an empty frame, we can load a project into it
    set state disabled
    if {[::widget::isFrame $current]} {
	set min_row    [::widget::geometry $current min_row]
	set min_column [::widget::geometry $current min_column]
	if {[llength [concat $min_row $min_column]] == 2} {
	    set empty 1
	    foreach slave [grid slaves $current] {
		if {[::widget::exists $slave]} {
		    set empty 0
		    break
		}
	    }
	    if {$empty} {
		set state normal
	    }
	}
    }
    ::menu::setstate "Load Project into Frame..." $state

    # We can Reapply if there is a known repeat event
    set state [expr {$::Current(repeat) != "" ? "normal" : "disabled"}]
    ::menu::setstate "Reapply Toolbar" $state

    # Enable/disable the "Select 1st Child" menu item depending
    # on whether the select widget is a frame that contains some child(ren).
    #
    # Enable/disable the "Select Parent" menu item depending
    # on whether the selected widget is in a subframe.
    #
    set childstate  disabled
    set parentstate disabled
    set scrollstate disabled

    if {$current != ""} {
	if {[widget::isFrame $current]} {
	    foreach slave [grid slaves $current] {
		if {[::widget::exists $slave]} {
		    set childstate normal
		    break
		}
	    }
	}
	if {[::widget::scrollable $current]} {
	    set scrollstate normal
	}

        set master [::widget::data $current master]
        if {$master ne $::W(FRAME) && $master ne ""} {
	    set parentstate normal
        }
    }
    ::menu::setstate "Select Parent" $parentstate
    ::menu::setstate "Select 1st Child" $childstate

    # We can attach scrollbar only if the current widget is scrollable
    # and this is set above in the widget check.
    # We also check to see if there are any scrollbars to attach to.
    set sbs [::widget::widgets "Tk scrollbar"]
    set state [expr {[llength $sbs] ? $scrollstate : "disabled"}]
    ::menu::setstate "Attach Scrollbars" $state
}

# ::menu::getmenu --
#
#	Returns the menu widget that contains the given label.
#
# Arguments:
#	w:	   pathname of the widget to start searching.
#	itemlabel: find the menu that contains the item that has this label.
#
# Results:
#	pathname of the menu widget if found, otherwise an empty string.
#
proc ::menu::getmenu {w itemlabel} {
    if {[winfo class $w] eq "Menu" && ![catch {$w index $itemlabel}]} {
	return $w
    }
    set result ""
    foreach child [winfo children $w] {
        if {[set result [::menu::getmenu $child $itemlabel]] != ""} {
	    return $result
	}
    }
    return $result
}

proc ::menu::setstate {item state} {
    if {$state == 0} {
	set state disabled
    } elseif {$state == 1} {
	set state normal
    }

    set m [::menu::getmenu $::W(MENU) $item]
    if {$m != ""} {
	$m entryconfig [$m index $item] -state $state
    }
}
