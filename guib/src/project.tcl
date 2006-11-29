# project.tcl --
#
#	This file implements package project, which  ...
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval project {
    variable current
    variable dir
    variable name
}; # end of namespace project


# ::project::setp --
#
#   Set the project name
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::project::setp {file} {
    global P Current
    if {($file == $P(project)) || ($file == "")} {
	# default untitled project
	set P(file_untitled) 1
	set P(project_dir) [pwd]
	set file $P(project)
    } else {
	set P(file_untitled) 0
	set P(project_dir) [file normalize [file dirname $file]]
	if {![file isdirectory $P(project_dir)]} {
	    set P(project_dir) [pwd]
	}
    }
    set_title [set Current(project) [file root [file tail $file]]]
    return $Current(project)
}

# ::project::get --
#
#   Returns the current project file name, normalized.
#   If the current project is untitled, returns "".
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::project::get {{type {}}} {
    global P Current
    if {$P(file_untitled)} { return "" }
    set file [file join $P(project_dir) $Current(project)]
    switch -exact $type {
	base		{ # do not add a suffix }
	dir		{ return $P(project_dir) }
	target - lang	{ append file $P(target_suffix)   ;# ie: ".ui.tcl" }
	include		{ append file $P(include_suffix)  ;# ie: ".tcl" }
	ui - file - default { append file $P(file_suffix) ;# ie: ".ui" }
    }
    return $file
}


# ::project::new --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   name	optional new project name
# Results:
#   0: some abort of the action 1 caused
#   1: success
#
proc ::project::new {{name {}} {lang {}}} {
    if {![save_if_dirty]} {
	return 0
    }
    clear_all
    # Query for a different target language and reinit
    if {$lang eq ""} {
	set lang [queryLanguage]
    }
    targetLanguage $lang
    ::project::setp $name
    return 1
}

# ::project::save --
#
#   Writes the project to a file.
#   If $file == "", the user is queried for a filename.
#   Also compiles the project file.
#
# Arguments:
#   file		Name of the file.
# Results:
#	1: if file successfully saved.
#	0: if the action has been aborted.
#
# Side effects:
#	The Current(dirty) flag is cleared.
#
proc ::project::save {{file {}} {compile 1}} {
    global P Current

    if {$file == ""} {
	# When no or empty file is given, do this like Save As ...
	set file [tk_getSaveFile -filetypes $::gui::FILE_TYPES \
		-defaultextension $P(file_suffix)]
	if {$file == ""} { return 0 }
	if {![string is ascii $file]} {
	    tk_messageBox -type ok -icon error -title "Filename Error" \
		    -message "Filename must be ascii only for cross\
		    platform compatability."
	    return 0
	}

	# (Patch): some versions of Tk don't handle the -defaultext switch
	if {[file extension $file] == ""} { append file $P(file_suffix) }
    }

    if {$file == ""} { return 0 }

    if {[edit_statusFile $file] != 0} {
	tk_messageBox -type ok -icon warning -message \
		"Please exit the external editor before attempting\
		to save this file."
	return 0
    }

    if {[file exists $file]} {
	# Attempt to backup the current file if it exists.
	if {[catch {
	    file delete -force $file.bak
	    file copy   -force $file $file.bak
	} err]} {
	    tk_messageBox -type ok -icon error -title "File Backup Error" \
		    -message "Error writing backup file \"$file.bak\":\
		    \"$file\" will be saved without a backup."
	}
    }

    if {[catch {::port::writable $file; ::open $file w} fd]} {
	tk_messageBox -type ok -icon error -title "Save Error" -message \
		"Error opening \"$file\" for writing:\n$fd"
	status_message "Can't save to file \"$file\""
	return 0
    }

    ::project::setp $file

    busy_on

    # Use utf-8 consistently for the .ui file
    fconfigure $fd -encoding utf-8
    puts $fd [::gui::get_file_data]
    close $fd
    ::port::ownFile $file 1 ; # readonly

    update idletasks

    status_message "save completed"
    set uiFile [::project::get ui]
    ::api::Notify save    $uiFile
    ::api::Notify project $uiFile

    # Append to the MRU list in "time file" tuples
    # then sort unique to remove multiple of the same file
    # then resort unique by time to get the 10 most recent
    lappend P(MRU) [list [clock seconds] $uiFile]
    set P(MRU) [lsort -unique -dictionary -index 1 $P(MRU)]
    set P(MRU) [lrange [lsort -unique -integer -decreasing \
	    -index 0 $::P(MRU)] 0 9]

    dirty 0

    # Generate code when saving if requested (default == 1).
    if {$compile} {
	::compile::project
    }

    busy_off
    return 1
}

# ::project::openp --
#
#	Opens a new ui project to be passed to load.
#
# Arguments:
#	file	if specified, open the given name, otherwise query user.
#
# Result:
#	1 - if the operation has successfully completed.
#	0 - if the operation has been aborted by the user
#
proc ::project::openp {{file ""}} {
    global P

    if {![save_if_dirty]} {
	return 0
    }

    set fileNotGiven [string equal $file ""]
    if {$fileNotGiven} {
	# When no or empty file is given, query the user.
	set idir [::project::get dir]
	# work-around Aqua bug for -initialdir ""
	if {$::AQUA && ![file isdirectory $idir]} { set idir [pwd] }
	set file [tk_getOpenFile -filetypes $::gui::FILE_TYPES \
	    -initialdir $idir \
	    -defaultextension $P(file_suffix)]
	if {$file == ""} { return 0 }

	# (Patch): some versions of Tk don't handle the -defaultext switch
	if {[file extension $file] == ""} { append file $P(file_suffix) }
    }

    # Clear the grid

    foreach dim {rows cols} {
	set $dim $P(max$dim)
	set P(max$dim) 4
    }
    clear_all
    set P(maxrows) $rows
    set P(maxcols) $cols

    # Load the file
    if {$fileNotGiven} {
	if {![load_project $file]} {
	    clear_all
	    ::project::setp ""
	    return 0
	} else {
	    ::project::setp $file
	    sync_all
	    return 1
	}
    } else {
	load_project $file
	if {[wm state .] != "normal"} {
	    wm deiconify .
	}
	return 1
    }
}

# ::project::convert --
#
#   Convert UI data from older format to the current format
#
# Arguments:
#   data	UI data in old format
#   format	id of old format
#
# Results:
#   Returns the data in the UI file in an acceptable format.
#
proc ::project::convert {old fmt} {
    if {$fmt ne "1.0"} {
	return -code error "unknown data file format '$fmt'"
    }

    array set geomMap {
	column -column row -row
	columnspan -columnspan rowspan -rowspan sticky -sticky
	iwadx -ipadx iwady -ipady wadx -padx wady -pady
    }
    array set geomOther {
	min_column 0 min_row 0 pad_column 0 pad_row 0
	resize_column 0 resize_row 0 weight_column 0 weight_row 0
    }
    set new ""
    set cmds [::compile::CmdSplit $old]
    foreach cmd $cmds {
	if {[lindex $cmd 0] eq "widget"} {
	    # widget name subs
	    foreach {wcmd name subs} $cmd { break }
	    if {$name eq "f"} {
		set name [::gui::container]
	    }
	    set type ""
	    set opts ""
	    foreach sub [::compile::CmdSplit $subs] {
		foreach {op tag value} $sub { break }
		if {$op eq "other"} {
		    if {[info exists geomOther($tag)]} {
			append opts "\t[list geometry $tag $value]\n"
		    } elseif {$tag eq "item_name"} {
			append opts "\t[list data ID $value]\n"
		    } elseif {$tag eq "master"} {
			set value [string trimleft $value .]
			append opts "\t[list data MASTER $value]\n"
		    } elseif {$tag eq "type"} {
			set type "Tk $value"
			append opts "\t[list data GROUP Tk]\n"
			append opts "\t[list data TYPE $type]\n"
		    } elseif {$tag eq "pathname"} {
			# in v2 pathname == $name, do nothing
		    } else {
			# $tag eq "level"
			append opts "\t[list data $tag $value]\n"
		    }
		} elseif {$op eq "configure"} {
		    append opts "\t[list configure -$tag $value]\n"
		} elseif {$op eq "geometry"} {
		    if {[info exists geomMap($tag)]} {
			append opts "\t[list geometry $geomMap($tag) $value]\n"
		    } else {
			return -code error "bad geometry tag '$tag'"
		    }
		} else {
		    return -code error "unknown widget operation '$op' in $subs"
		}
	    }
	    if {$type eq ""} {
		return -code error "no type specified for $name"
	    }
	    append new "widget [list $type $name] \{\n"
	    append new $opts
	    append new "\}\n"
	} elseif {[lindex $cmd 0] eq "language"} {
	    set lang [lindex $cmd 1]
	    if {$lang eq "tcl84"} {
		set lang "tcl 8.4"
	    }
	    append new "language $lang\n"
	} else {
	    # Do we want to error on modified files?
	}
    }
    return $new
}


# ::project::loadui --
#
#   This gets the data out of the UI file.
#
# Arguments:
#   file	file from which we expect to get the data
#
# Results:
#   Returns the data in the UI file in an acceptable format.
#   An error is thrown with message otherwise.
#
proc ::project::loadui {file} {
    if {[catch {open $file r} fd]} {
	return -code error "Cannot open '$file' for reading:\n$fd"
    }

    # Use utf-8 consistently for the .ui file
    fconfigure $fd -encoding utf-8

    set line [gets $fd]
    if {![string match "$::gui::FILEID*" $line]} {
	close $fd
	return -code error "Invalid format for project file '$file'"
    }

    # Read in the remaining data.  The first line is only ID.
    set data [read $fd]
    close $fd

    if {$line eq "# GUIBUILDER FILE v1.0"} {
	# This is a v1.0 guibuilder file that requires updating
	return [convert $data "1.0"]
    }
    return $data
}

# save_if_dirty --
#
#	If the UI has been modified, ask the user whether the UI should be
#	saved.
#
# Arguments:
#	askUser: false iff file should be saved automatically if it's dirty.
#
# Result:
#	0 - UI has been modified and user selected "CANCEL"
#	1 - all other cases.
#		- UI has not been modified.
#		- UI has been modified and user selected "NO" (discard changes)
#		- UI has been modified, user selected "YES" and file has
#		  been saved.
# SOURCE

proc save_if_dirty {{askUser 1} {message ""} {type yesnocancel}} {
    global Current P

    check_project_file_exist

    if {![dirty]} {
	return 1
    }

    set answer yes
    if {$askUser} {
	if {$message == ""} {
	    set message "\"$Current(project)\" has been modified.\
		    Save all changes?"
	}
	set answer [tk_messageBox -title "Save Changes?" -message $message \
		-type $type -icon warning]
    }

    switch -- $answer {
	yes	{ return [::project::save [::project::get ui]] }
	no	{ return 1 }
	cancel	{ return 0 }
    }
}

proc check_project_file_exist {} {
    global Current P

    if {!$P(file_untitled)} {
	#
	# Someone may have removed the .ui file after it was generated.
	# This code is the only way to test whether the file is indeed
	# removed -- [file exists] may return stale info on an NFS. We must
	# do a read on the file to make sure.
	#
	set projectFile [::project::get ui]
	if {![file exists $projectFile] \
		|| ([file size $projectFile] == 0) \
		|| [catch {set fd [::open $projectFile RDONLY]; read $fd 1}]} {
	    dirty 1
	}
	catch {close $fd}
    }
}

# ::project::settings --
#
#   Create Project Settings dialog
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::project::settings {} {
    set w .tproject
    if {![winfo exists $w]} {
	toplevel $w
	wm withdraw $w
	wm protocol $w WM_DELETE_WINDOW [list wm withdraw $w]
	wm transient $w $::W(ROOT)
	wm title $w "$::gui::APPNAME Project Settings"

	if {$::TILE} {
	    set nb [ttk::notebook $w.f -padding [pad notebook]]
	} else {
	    # Use a BWidget notebook
	    set nb [NoteBook $w.f -font defaultFont]
	}

	set panel "Project"
	if {$::TILE} {
	    set frm [ttk::frame $nb.[string tolower $panel] \
			 -padding [pad labelframe]]
	    $nb add $frm -sticky news -text $panel
	    $nb select $frm
	} else {
	    set frm [$nb insert end $panel -text $panel]
	}

	# Language information
	set fl [ttk::frame $frm.lang]
	ttk::label $fl.lbl -text "Language:"
	ttk::label $fl.lang -textvariable ::gui::LANG(NAME)
	ttk::label $fl.ver -textvariable ::gui::LANG(VER)

	grid $fl.lbl $fl.lang $fl.ver -sticky ew
	grid $fl -sticky ew -ipadx 2 -ipady 2
	grid columnconfigure $fl 3 -weight 1

	# Interpreter information
	set fi [ttk::frame $frm.interp]
	ttk::label $fi.lbl -text "Interpreter:"
	ttk::label $fi.int -textvariable ::gui::LANG(INTERP)

	grid $fi.lbl $fi.int -sticky ew
	grid $fi -sticky ew -ipadx 2 -ipady 2
	grid columnconfigure $fi 3 -weight 1

	# File extension information
	if {$::TILE} {
	    set fe [ttk::labelframe $frm.title -text "File Extensions:" \
			-padding [pad labelframe]]
	    foreach {lbl var} {
		"Intermediate UI:" ::P(file_suffix)
		"Generated Code:" ::P(target_suffix)
		"Include Code:" ::P(include_suffix)
	    } {
		ttk::label $fe.lbl$lbl -text $lbl -anchor e -state disabled
		ttk::entry $fe.e$lbl -textvariable $var -width 10 \
		    -state disabled
		grid $fe.lbl$lbl $fe.e$lbl -sticky ew
	    }
	    grid columnconfigure $fe 1 -weight 1
	} else {
	    set fe [labelframe $frm.title -text "File Extensions:"]
	    LabelEntry $fe.file    -width 8 -textvariable ::P(file_suffix) \
		-labelwidth 14 -labelanchor e -label "Intermediate UI:" \
		-state disabled
	    LabelEntry $fe.target  -width 8 -textvariable ::P(target_suffix) \
		-labelwidth 14 -labelanchor e -label "Generated Code:" \
		-state disabled
	    LabelEntry $fe.include -width 8 -textvariable ::P(include_suffix) \
		-labelwidth 14 -labelanchor e -label "Include Code:" \
		-state disabled
	    grid $fe.file    -sticky w
	    grid $fe.target  -sticky w
	    grid $fe.include -sticky w
	    grid columnconfigure $fe 0 -weight 1
	}

	grid $fe -sticky news -ipadx 2 -ipady 2
	grid rowconfigure    $fe 3 -weight 1

	grid rowconfigure    $frm 2 -weight 1
	grid columnconfigure $frm 0 -weight 1

	if {!$::TILE} {
	    $nb compute_size
	    $nb raise $panel
	}

	# [OK] [Cancel] [Apply]
	set btns [ttk::frame $w.b]
	ttk::button $btns.ok  -width 8 -text "OK" -default active \
	    -command [list ::project::dismiss $w 1]
	ttk::button $btns.app -width 8 -text "Apply" -state disabled \
	    -command [list ::project::apply]
	ttk::button $btns.can -width 8 -text "Cancel" \
	    -command [list ::project::dismiss $w 0]

	grid x $btns.ok $btns.can $btns.app -padx 4 -pady {6 4}
	grid configure $btns.app -padx [list 4 [pad corner]]
	grid columnconfigure $btns 0 -weight 1

	bind $w <Return> [list $btns.ok invoke]
	bind $w <Escape> [list $btns.can invoke]

	grid $w.f -row 0 -column 0 -sticky nsew
	if {!$::TILE} {
	    grid configure $w.f -padx 5 -pady 5
	}
	grid $w.b -row 1 -column 0 -sticky ew
	grid rowconfigure    $w 0 -weight 1
	grid columnconfigure $w 0 -weight 1

	::gui::PlaceWindow $w widget $::W(ROOT)
    }
    set ::gui::LANG(INTERP) [::[targetLanguage]::interpreter]

    wm deiconify $w
    raise $w
}

proc ::project::dismiss {w save} {
    if {$save} {
	::project::apply
    }
    wm withdraw $w
}

proc ::project::apply {} {
}
