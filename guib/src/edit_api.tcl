# edit_api.tcl --
#
# Based on SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# This file contains misc. routines that should be rewritten
# to support these three functions on your particular editor.

namespace eval ::edit {
    # This is the name of the file currently being editted by an external
    # viewer. Used as a flag to indicate if external viewer is running.
    variable FILE ""
}

# procedure to edit code

proc edit_code {{name untitled}} {
    global env f P

    if {![save_if_dirty]} {
	return 0
    }

    set file [::project::get include]
    if {[api::IsInteractive]} {
	::api::Notify edit $file
	return 1
    }

    set fid  [open $file r]
    set data [read $fid]
    close $fid

    # External editor stuff ignored at this point.
    set editor {}
    if {[info exists env(VISUAL)]} {
	set editor "$env(VISUAL)"
    } elseif {[info exists env(EDITOR)]} {
	if {$::tcl_platform(platform) == "unix"} {
	    set editor "xterm -e "
	}
	append editor "$env(EDITOR)"
    }
    if {$P(use-external-editor) != 1 \
	    || ($editor == {} && $P(external-editor-command) == {})} {
	# show with internal editor
	set w .__editor
	destroy $w
	toplevel $w
	wm title $w "$name Code"
	wm group $w $::W(ROOT)
	edit_ui $w $data
    } else {
	if {$P(external-editor-command) != ""} {
	    set editor $P(external-editor-command)
	}
	edit_openFile $editor $name $data
    }
    return 1
}

# The procedure called to (re)open a file in the editor, possibly
# providing a line number.
proc edit_openFile {editor filename data {line {}}} {
    variable ::edit::FILE
    set filename [subs_uniquefile $filename]
    if {![catch {open $filename w} msg] && $msg != ""} {
	set file $msg
	puts -nonewline $file $data
	close $file
	set startport 9000
	while {![catch {socket localhost $startport}]} {
	    incr startport
	}
	if {![catch {socket -server edit_socketService $startport} msg]} {
	    exec [info nameofexecutable] \
		    [file join $gui::BASEDIR edit_runner.tcl] \
		    $editor $filename $startport &
	    set FILE $filename
	} else {
	    tk_messageBox -title "Edit Error" -type ok -icon error \
		    -message "Can't open communications socket on\
		    port $startport."
	    return 1
	}
    }
    return 0
}

proc edit_socketService {channel address port} {
    fconfigure $channel -blocking 0 -buffering none
    fileevent $channel readable [list edit_doneCallback $channel $port]
}

# Attempt to tell the editor to save the file
# returns:
#  0 - Successfully told the editor to save the file.
#  1 - Couldn't tell the editor to save the file.
proc edit_saveFile {filename} {
    return 1
}

# This procedure should return numeric status codes
# 0 - No file loaded/File has no changes/File saved
# 1 - File has changes to save
proc edit_statusFile {filename} {
    variable ::edit::FILE
    return [expr {$FILE != ""}]
}

proc edit_doneCallback {ch file} {
    variable ::edit::FILE

    fileevent $ch r {}
    close $ch
    set filename $FILE
    if {![catch {open $filename r} msg] && $msg != ""} {
	set file $msg
	if {![catch {read $file} msg]} {
	    global f
	    set f(code) $msg
	} else {
	    tk_messageBox -title "Edit Callback Error" -type ok -icon error \
		    -message "Error reading $filename back into\
		    $::gui::APPNAME."
	}
	catch {close $file}
	catch {file delete $filename}
    } else {
	tk_messageBox -title "Edit Callback Error" -type ok -icon error \
		-message "Error attempting to reread '$filename':\n$msg"
    }
    set FILE ""
}

# procedure to find a temporary file name.

proc subs_uniquefile {{name {}}} {
    set idx 0
    set id gui-[pid]-
    while {[file exists $id$idx$name]} {
	incr idx
    }
    set ::edit::TEMPFILES([file join [pwd] $id$idx$name]) 1
    return $id$idx$name
}
