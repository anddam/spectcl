# droptree.tcl --
#
#	Definition of the Droptree Bwidgets megawidget.
#	This is a modification of the combobox which uses a Tree
#	instead of a listbox.
#
# -----------------------------------------------------------------------------
#  Index of commands:
#     - Droptree::create
#     - Droptree::configure
#     - Droptree::cget
#     - Droptree::setvalue
#     - Droptree::getvalue
#     - Droptree::_create_popup
#     - Droptree::_mapliste
#     - Droptree::_unmapliste
#     - Droptree::_select
# -----------------------------------------------------------------------------
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package require Tk 8.3
#package require struct 1.2

namespace eval Droptree {
    ArrowButton::use
    Entry::use

    Widget::tkinclude Droptree frame :cmd \
	    include {-relief -borderwidth -bd -background} \
	    initialize {-relief sunken -borderwidth 2} \

    Widget::bwinclude Droptree Entry .e \
        remove {-relief -bd -borderwidth -bg} \
	    rename {-background -entrybg}

    Widget::declare Droptree {
        {-height      TkResource 0  0 listbox}
	{-tree        String     "" 0}
        {-images      String     "" 0}
        {-indents     String     "" 0}
        {-modifycmd   String     "" 0}
        {-postcommand String     "" 0}
    }

    Widget::addmap Droptree ArrowButton .a {
        -background {} -foreground {} -disabledforeground {} -state {}
    }

    Widget::syncoptions Droptree Entry .e {-text {}}

    ::bind BwDroptree <FocusIn> [list after idle {BWidget::refocus %W %W.e}]
    ::bind BwDroptree <Destroy> {Widget::destroy %W; rename %W {}}

    proc ::Droptree { path args } { return [eval Droptree::create $path $args] }
    proc use {} {}
}


# Droptree::create --
#
#	Create a droptree widget with the given options.
#
# Arguments:
#	path	name of the new widget.
#	args	optional arguments to the widget.
#
# Results:
#	path	name of the new widget.

proc Droptree::create { path args } {
    array set maps [list Droptree {} :cmd {} .e {} .a {}]
    array set maps [Widget::parseArgs Droptree $args]

    eval [list frame $path] $maps(:cmd) -highlightthickness 0 \
	    -takefocus 0 -class Droptree
    Widget::initFromODB Droptree $path $maps(Droptree)

    bindtags $path [list $path BwDroptree [winfo toplevel $path] all]

    set entry [eval [list Entry::create $path.e] $maps(.e) \
                   -relief flat -borderwidth 0 -takefocus 1]
    ::bind $path.e <FocusIn>  [list $path _focus_in]
    ::bind $path.e <FocusOut> [list $path _focus_out]

    if {[string equal $::tcl_platform(platform) "unix"]} {
        set ipadx 0
        set width 11
    } else {
        set ipadx 2
        set width 15
    }
    set height [winfo reqheight $entry]
    set arrow [eval ArrowButton::create $path.a $maps(.a) \
                   -width $width -height $height \
                   -highlightthickness 0 -borderwidth 1 -takefocus 0 \
                   -dir   bottom \
                   -type  button \
		   -ipadx $ipadx \
                   -command [list "Droptree::_mapliste $path"]]

    pack $arrow -side right -fill y
    pack $entry -side left  -fill both -expand yes

    if {[Widget::cget $path -editable]} {
	::bind $entry <ButtonPress-1> [list Droptree::_unmapliste $path]
	Entry::configure $path.e -editable true
    } else {
	::bind $entry <ButtonPress-1> [list ArrowButton::invoke $path.a]
	Entry::configure $path.e -editable false
	if {[Widget::cget $path -state] != "disabled"} {
	    Entry::configure $path.e -takefocus 1
	}
    }

    ::bind $path  <ButtonPress-1> [list Droptree::_unmapliste $path]
    ::bind $entry <Key-Up>        [list Droptree::_unmapliste $path]
    ::bind $entry <Key-Down>      [list Droptree::_mapliste $path]

    rename $path ::$path:cmd
    proc ::$path { cmd args } "return \[eval Droptree::\$cmd $path \$args\]"

    return $path
}


# Droptree::configure --
#
#	Configure subcommand for Droptree widgets.  Works like regular
#	widget configure command.
#
# Arguments:
#	path	Name of the Droptree widget.
#	args	Additional optional arguments:
#			?-option?
#			?-option value ...?
#
# Results:
#	Depends on arguments.  If no arguments are given, returns a complete
#	list of configuration information.  If one argument is given, returns
#	the configuration information for that option.  If more than one
#	argument is given, returns nothing.

proc Droptree::configure { path args } {
    set res [Widget::configure $path $args]

    if {[Widget::hasChangedX $path -editable]} {
        if {[Widget::cget $path -editable]} {
            ::bind $path.e <ButtonPress-1> [list Droptree::_unmapliste $path]
	    Entry::configure $path.e -editable true
	} else {
	    ::bind $path.e <ButtonPress-1> [list ArrowButton::invoke $path.a]
	    Entry::configure $path.e -editable false

	    # Make sure that non-editable droptreees can still be tabbed to.
	    if {[Widget::cget $path -state] != "disabled"} {
		Entry::configure $path.e -takefocus 1
	    }
        }
    }

    if {[Widget::hasChangedX $path -tree]} {
	# update the tree anytime in an idle handler.
	variable IDLE
	catch {after cancel $IDLE($path)}
	set IDLE($path) [after idle [list [namespace current]::refresh $path]]
    }

    return $res
}

proc Droptree::refresh {path} {
    set listb $path.shell.listb
    if {[winfo exists $listb]} {
	$listb delete [$listb nodes root]
	set tree [Widget::cget $path -tree]
	if {$tree != "" && [info commands $tree] == $tree} {
	    $tree walk root -command [list [namespace current]::_update_tree \
		    $path $listb $tree %n]
	}
    }
    update idletasks
}

proc Droptree::_update_tree {path w tree node} {
    if {$node == "root"} { return }
    #puts "$tree ([$tree parent $node]->)$node [$tree getall $node]"
    set sel 1
    if {[$tree keyexists $node -key selectable]} {
	set sel [$tree get $node -key selectable]
    }
    if {[$tree keyexists $node -key image]} {
	$w insert end [$tree parent $node] $node -open yes -selectable $sel \
		-text [$tree get $node] -image [$tree get $node -key image]
    } else {
	$w insert end [$tree parent $node] $node -open yes -selectable $sel \
		-text [$tree get $node]
    }
}

# -----------------------------------------------------------------------------
#  Command Droptree::cget
# -----------------------------------------------------------------------------
proc Droptree::cget { path option } {
    return [Widget::cget $path $option]
}


# -----------------------------------------------------------------------------
#  Command Droptree::setvalue
# -----------------------------------------------------------------------------
proc Droptree::setvalue { path node } {
    # Also allow the user to setvalue to ""
    if {$node == ""} {
	Entry::configure $path.e -text ""
	return 1
    }
    set tree [Widget::cget $path -tree]
    if {$tree != "" && [info commands $tree] == $tree} {
	if {[$tree exists $node]} {
	    Entry::configure $path.e -text [$tree get $node]
	    return 1
	}
    }
    return 0
}

# -----------------------------------------------------------------------------
#  Command Droptree::getvalue
# -----------------------------------------------------------------------------
proc Droptree::getvalue {path {node 0}} {
    set listb $path.shell.listb
    if {$node && [winfo exists $listb]} {
	return [$listb selection get]
    }
    return [Entry::cget $path.e -text]
}


# -----------------------------------------------------------------------------
#  Command Droptree::bind
# -----------------------------------------------------------------------------
proc Droptree::bind { path args } {
    return [eval ::bind $path.e $args]
}


# -----------------------------------------------------------------------------
#  Command Droptree::_create_popup
# -----------------------------------------------------------------------------
proc Droptree::_create_popup { path } {
    set shell $path.shell
    if {![winfo exists $path.shell]} {
        set shell [toplevel $path.shell -relief solid -bd 1]
        wm overrideredirect $shell 1
        wm transient $shell [winfo toplevel $path]
        wm withdraw  $shell
	catch {wm attributes $shell -topmost 1}

        set sw    [widget::scrolledwindow $shell.sw]

	set h     [Widget::cget $path -height]
	if { $h <= 0 } {
	    set h 10
	}
	set listb [Tree $shell.listb \
		       -deltax 8 -deltay 18 \
		       -relief flat -borderwidth 0 -highlightthickness 0 \
		       -height $h -selectfill 1 \
		       -linestipple gray50]

		   #-selectcommand [list Droptree::_select $path]]

	# If we are just creating the popup, add the values that were
	# given to us now.
	refresh $path

        pack $sw -fill both -expand yes
        $sw setwidget $listb

	# node id will be added
	set cmd [list Droptree::_select $path $listb]
	$listb bindImage <ButtonRelease-1> $cmd
	$listb bindText  <ButtonRelease-1> $cmd

        ::bind $shell <Return> "$cmd \[lindex \[[list $listb] selection get\] 0\]; break"
	::bind $shell <Escape> "Droptree::_unmapliste [list $path]; break"
	# when losing focus to some other app, make sure we drop the listbox
	::bind $listb <FocusOut> "Droptree::_focus_out [list $path]; break"
    }
}


# -----------------------------------------------------------------------------
#  Command Droptree::_mapliste
# -----------------------------------------------------------------------------
proc Droptree::_mapliste { path } {
    set listb $path.shell.listb
    if {[winfo exists $path.shell] && [wm state $path.shell] == "normal"} {
	_unmapliste $path
        return
    }

    if { [Widget::cget $path -state] == "disabled" } {
        return
    }
    if { [set cmd [Widget::getMegawidgetOption $path -postcommand]] != "" } {
        uplevel \#0 $cmd
    }
    _create_popup $path

    ArrowButton::configure $path.a -relief sunken
    update

    $listb selection clear
    set curval [Entry::cget $path.e -text]
    # We should select and see the current entry value

    BWidget::place $path.shell [winfo width $path] 0 below $path
    wm deiconify $path.shell
    raise $path.shell
    BWidget::focus set $listb
    BWidget::grab global $path
}


# -----------------------------------------------------------------------------
#  Command Droptree::_unmapliste
# -----------------------------------------------------------------------------
proc Droptree::_unmapliste { path {refocus 1} } {
    if {[winfo exists $path.shell] && \
	    ![string compare [wm state $path.shell] "normal"]} {
        BWidget::grab release $path
        BWidget::focus release $path.shell.listb $refocus
	# Update now because otherwise [focus -force...] makes the app hang!
	if {$refocus} {
	    update
	    focus -force $path.e
	}
        wm withdraw $path.shell
        ArrowButton::configure $path.a -relief raised
    }
}


# -----------------------------------------------------------------------------
#  Command Droptree::_select
# -----------------------------------------------------------------------------
proc Droptree::_select { path tree node } {
    # check to see if anything was really selected
    if {![llength [$tree selection get]]} { return }
    _unmapliste $path
    if { [setvalue $path $node] } {
	set cmd [Widget::getMegawidgetOption $path -modifycmd]
	if { $cmd != "" } {
	    uplevel \#0 $cmd
	}
    }
    $path.e selection clear
    if {[Widget::cget $path -editable]} {
	$path.e selection range 0 end
    }
}


# ----------------------------------------------------------------------------
#  Command Droptree::_focus_in
# ----------------------------------------------------------------------------
proc Droptree::_focus_in { path } {
    if {[$path.e selection present] != 1} {
	# Autohighlight the selection, but not if one existed
	$path.e selection range 0 end
    }
}


# ----------------------------------------------------------------------------
#  Command Droptree::_focus_out
# ----------------------------------------------------------------------------
proc Droptree::_focus_out { path } {
    if {[focus] == ""} {
	# we lost focus to some other app, make sure we drop the listbox
	_unmapliste $path 0
    }
}
