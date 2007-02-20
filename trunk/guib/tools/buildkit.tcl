#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# This will build us a tkkit if we have TDK.
#
# The script is actually x-platform, but unless we had access to
# all the installed bits from a single platform, it's easier to
# run this on each platform.

# require minimum version we want to use
set ver [package require ActiveTcl 8.4.11]
package require vfs

if {[file exists /Library/Tcl]} {
    # special case for OS X
    set libdir /Library/Tcl
    set noedir /Library/Tcl/basekits
} else {
    set libdir [file dirname $tcl_library]
    set noedir [file dirname [info nameofexecutable]]
}
set toollib [file dirname [info script]]
set srcdir  [file dirname $toollib]/src
set ext     [info sharedlib]
set suffix  [expr {$::tcl_platform(platform) eq "windows" ? ".exe" : ""}]

proc usage {{fid stderr}} {
    puts $fid "$::argv0 ?options?"
    puts $fid "\t-modules list   add the listed Tcl modules"
    puts $fid "\t-excludes list  glob pattern of file to exclude in modules"
    puts $fid "\t-mini bool      install minimal components (default: fat)"
    puts $fid "\t-wish prog      default external wish to use"
    puts $fid "\t-basekit file   default basekit to use"
    puts $fid "\t-help           print out this message"
    exit [string equal stderr $fid]
}

set prefix  "guibuilder"
set basekit ""
set mini    0 ; # use minimal components
set dir     [pwd]
set modules  ""
set excludes ""
set wish     [auto_execok wish]

# This is the module list as needed from ActiveTcl 8.4.14
set modules [list tklib0.?/widget itcl3.? itk3.? iwidgets4.* \
		 tcllib1.?/snit tile0.* bwidget1.? tclx8.?]

foreach {key val} $argv {
    switch -glob -- $key {
	"-min*" {
	    set mini [string is true -strict $val]
	}
	"-module*" {
	    eval [list lappend modules] $val
	}
	"-exc*" {
	    eval [list lappend excludes] $val
	}
	"-wi*" {
	    set wish $val
	}
	"-base*" {
	    set basekit $val
	}
	"\?" - "help" - "-help" - "usage" {
	    usage stdout
	}
	default {
	    puts stderr "unknown option '$key'"
	    usage stderr
	}
    }
}

puts "Build with ActiveTcl $ver"

if {$basekit eq ""} {
    set basekit $dir/$::prefix$::suffix
    set srckit [glob -nocomplain -directory $noedir base-tk-*$::suffix]
    if {![file exists $srckit]} {
	puts stderr "Couldn't find base dll kit:\
		ActiveTcl 8.4.9+ is required for operation"
	exit 1
    }
    puts "Using $srckit as source for $basekit"
    if {[file exists $basekit]} {
	puts "$basekit exists - deleting"
	file delete -force $basekit
    }
    file copy $srckit $basekit
} else {
    set newbasekit $dir/$::prefix$::suffix
    if {![file exists $basekit]} {
	puts stderr "Couldn't find '$basekit'"
	exit 1
    }
    file delete -force $newbasekit
    file copy $basekit $newbasekit
    puts "Updating $basekit as source for $newbasekit"
    set basekit $newbasekit
}

puts "Mounting - [file tail $basekit]: [file size $basekit] bytes"
vfs::mk4::Mount $basekit $basekit

#
# Binary components
#

if {[file exists $basekit/lib/tk8.4]} {
    puts "Tk appears to exist already ..."
} else {
    puts "Copying in Tk ..."
    if {$tcl_platform(platform) eq "windows"} {
	file copy $noedir/tk84$::ext $basekit/bin/
    } elseif {$tcl_platform(os) eq "Darwin"} {
	puts stderr "Use a tkkit on OS X"
	exit 1
    } else {
	file copy $libdir/libtk8.4$::ext $basekit/lib/
    }
    file copy $libdir/tk8.4 $basekit/lib
    file delete -force $basekit/lib/tk8.4/demos
    file delete -force $basekit/lib/tk8.4/tkAppInit.c
}

#
# Script-only components
#
proc add_code {} {
    if {![file isdirectory $::srcdir]} {
	puts stderr "Invalid source directory '$::srcdir'"
	exit 1
    }
    puts "Copying in source code ..."
    eval [list file copy] [glob $::srcdir/*.tcl] [list $::basekit]
    file copy $::srcdir/images $::basekit
    set fid [open $::basekit/main.tcl w]
    puts $fid "# init script"
    puts $fid "package require starkit"
    puts $fid "starkit::startup"
    puts $fid "# Jump to wrapped application"
    puts $fid "set startup \[file join \$starkit::topdir startup.tcl]"
    puts $fid "set ::argv0 \$startup"
    puts $fid "source      \$startup"
    close $fid
}
add_code

proc add_modules {modules} {
    puts "Add modules from '$::libdir' ..."
    foreach mod $modules {
	puts "Copying in $mod ..."
	set real [glob $::libdir/$mod*]
	if {[llength $real] != 1} {
	    puts stderr "Did not find exactly one version of '$mod':\n\t$real"
	    exit 1
	}
	catch {file delete -force [glob $::basekit/lib/$mod*]}
	file copy $real $::basekit/lib
    }
}
add_modules $modules

proc exclude_files {excludes} {
    foreach exc $excludes {
	catch {eval [list file delete -force] [glob $::basekit/lib/$exc]}
    }
}
exclude_files $excludes

::vfs::unmount $basekit
puts "Done - $basekit: [file size $basekit] bytes"

puts "***************************************************"
puts "NOT FOR REDISTRIBUTION - SOURCES ARE NOT OBFUSCATED"
puts "***************************************************"
