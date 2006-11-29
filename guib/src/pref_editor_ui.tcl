# pref_editor_ui.tcl
#
#	Starts up application, reporting any start-up errors.
#
# Copyright (c) 2006 ActiveState Software Inc.
#
# See the file "license.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::prefs {}

proc ::prefs::editor_useext {e b cacheVar} {
    set state [expr {[set ${cacheVar}(use-external-editor)] \
	    ? "normal" : "disabled"}]
    $e configure -state $state
    $b configure -state $state
}

proc ::prefs::editor_select {root cacheVar} {
    set tmp [tk_getOpenFile -parent $root -title "Select External Editor"]
    if {$tmp != ""} {
	set ${cacheVar}(external-editor-command) $tmp
    }
}

proc ::prefs::ui_editor {root cacheVar args} {
    # this treats "." as a special case
    set base [expr {($root == ".") ? "" : $root}]

    set enableCmd [list editor_useext $base.entry $base.browse $cacheVar]

    checkbutton $base.use -text "Use an external editor" \
	    -variable ${cacheVar}(use-external-editor) \
	    -command [namespace code $enableCmd]

    entry $base.entry -textvariable ${cacheVar}(external-editor-command)

    button $base.browse -text ... -pady 0 -padx 0 \
	    -command [namespace code [list editor_select $root $cacheVar]]

    eval $enableCmd

    label $base.msg -anchor nw -justify left

    # Geometry management
    grid $base.use	-row 0 -column 0 -columnspan 2 -sticky w
    grid $base.entry	-row 1 -column 0 -sticky ew
    grid $base.browse	-row 1 -column 1 -sticky news
    grid $base.msg	-row 2 -column 0 -columnspan 2 -sticky nesw

    # Resize behavior management
    grid rowconfigure    $root 2 -weight 1
    grid columnconfigure $root 0 -weight 1

    # Add message
    if {$::tcl_platform(platform) == "windows"} {
	$base.msg configure -text "
Under Windows, you must either use forward slashes '/' to divide
the path, or use double backslashes '\\' for each path element.
Environment variables EDITOR and VISUAL are respected.
  Examples:
     c:/windows/notepad.exe
     c:\\\\windows\\\\notepad.exe"
    } elseif {$::tcl_platform(platform) == "unix"} {
	$base.msg configure -text "
If the external editor box is checked, but no command is given,
the EDITOR and VISUAL environment are used to figure out what
command to use, in that order."
    } else {
	$base.msg configure -text \
		"This doesn't work on this platform yet, sorry."
    }
}
