# Based on SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1997 Sun Microsystems, Inc.
# Copyright (c) 2002-2006 ActiveState Software Inc.
#
# See the file "license.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# routines that are needed to port things properly between systems

namespace eval ::port {
    namespace export -clear pad
    variable PAD
    switch -exact [tk windowingsystem] {
	win32 {
	    set PAD(x) 4
	    set PAD(y) 4
	    set PAD(corner) 4
	    set PAD(labelframe) 4
	    set PAD(notebook) 8
	    set PAD(default) 4
	}
	aqua {
	    # http://developer.apple.com/documentation/UserExperience/Conceptual/OSXHIGuidelines/index.html
	    set PAD(x) 8
	    set PAD(y) 8
	    set PAD(corner) 14
	    set PAD(labelframe) 8
	    set PAD(notebook) 8
	    set PAD(default) 4
	}
	x11 -
	default {
	    set PAD(x) 4
	    set PAD(y) 4
	    set PAD(corner) 4
	    set PAD(labelframe) 2
	    set PAD(notebook) 4
	    set PAD(default) 2
	}
    }
}

# ::port::pad --
#
#   Return various padding widths based on widget element
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::port::pad {elem} {
    variable PAD
    if {[info exists PAD($elem)]} {
	return $PAD($elem)
    }
    return $PAD(default)
}
namespace eval :: { namespace import -force ::port::pad }

# ::port::seticon --
#
#   set the toplevel icon to what we are using
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::port::seticon {w {name icon}} {
    if {![winfo exists $w] || [wm overrideredirect $w]} { return }
    if {$::tcl_platform(platform) eq "unix"} {
	set file [file join $::gui::BASEDIR images $name.xbm]
	if {[file exists $file]} {
	    wm iconbitmap $w @$file
	    wm iconmask $w @$file
	}
    } elseif {$::tcl_platform(platform) eq "windows"} {
	set file [file join $::gui::BASEDIR images $name.ico]
	if {[file exists $file]} {
	    wm iconbitmap $w -default $file
	}
    }
}

proc ::port::loadsplash {} {
    # just for loading the splash for snappier startup feel
    if {[info exists ::BETA] && $::BETA} {
	set file splash_BETA.gif
    } else {
	set file splash.gif
    }
    image create photo splash.gif -file [file join $::gui::BASEDIR images $file]
    foreach file {splash_feather.gif heart.gif} {
	image create photo $file -file [file join $::gui::BASEDIR images $file]
    }
}

proc ::port::loadimages {} {
    foreach i [glob -nocomplain [file join $::gui::BASEDIR images *.gif]] {
	if {[string match "*splash.gif" $i]} { continue }
	image create photo [file tail $i] -file $i
    }
}

proc ::port::ownFile {filename {readonly 0}} {
    # Remove write permissions from a file
    if {$::tcl_platform(platform) eq "windows"} {
	if {$readonly} {
	    file attributes $filename -readonly 1
	}
    } elseif {$::tcl_platform(platform) eq "unix"} {
	global P
	if {[info exists P(unix-perm)] && $P(unix-perm) != ""} {
	    catch {file attributes $filename -permissions $P(unix-perm)}
	}
	if {$readonly} {
	    file attributes $filename -permissions -w
	}
    }
    return [file writable $filename]
}

proc ::port::writable {filename {throwError 0}} {
    # Remove write permissions from a file
    if {![file exists $filename]} {
	return -1
    }
    if {$::tcl_platform(platform) eq "windows"} {
	set code [catch {file attributes $filename -readonly 0} err]
    } elseif {$::tcl_platform(platform) eq "unix"} {
	set code [catch {file attributes $filename -permissions u+w} err]
    }
    if {$code && $throwError} {
	# only throw errors if caller asked to
	return -code $code $err
    }
    return [file writable $filename]
}

# This function tries (not too hard currently) to figure out a 
# good place for a home file is, and return the address.
proc ::port::appdatadir {{file {}}} {
    global env

    set rc ""
    if {[info exists env(HOME)]} {
	set rc [file join $env(HOME) .$::gui::COMPANY $::gui::APPSHORT]
    }
    if {$::tcl_platform(platform) eq "windows"} {
	# Need to add code here to find real data dir
	if {[info exists env(APPDATA)]} {
	    set rc [file join $env(APPDATA) $::gui::COMPANY $::gui::APPSHORT]
	}
    } elseif {$::tcl_platform(os) eq "Darwin"} {
	set appdir "~/Library/Application Support"
	if {[file isdirectory $appdir]} {
	    set rc [file join $appdir $::gui::APPSHORT]
	}
    }
    set dir ""
    foreach part [file split $rc] {
	set dir [file join $dir $part]
	if {![file isdirectory $dir]} {
	    file mkdir $dir
	}
    }
    if {$file ne ""} {
	return [file join $rc $file]
    } else {
	return $rc
    }
}

proc ::port::rc_file {} {
    return [appdatadir gel-rc.tcl]
}

proc ::port::widget_cache_file {} {
    return [appdatadir gel-cache.tcl]
}
