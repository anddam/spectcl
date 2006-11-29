# undo.tcl --
#
# Based on SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# This will be undo someday

# Undo stuff that is just stubbed here until
#
#
namespace eval ::undo {
    variable count 0 ; # number of undos in stack
    variable log     ; # array with undo commands
}

# log --
#
#	Add an entry onto the undo log.
#	Current just sets the dirty flag.
#
proc ::undo::log {type args} {
    variable count
    variable log

    dirty 1
    if {$count} {
	lappend log($count) "$type $args"
    }
    return $count
}

# mark --
#
# mark the start of an undo transaction
#
proc ::undo::mark {{why ""}} {
    variable count

    incr count
    set log($count) ""
    return $count
}

# reset --
#
# reset the undo log
#
proc ::undo::reset {}  {
    variable count
    variable log

    set count 0
    catch {unset log}
}

# undo --
#
# undo the last entry in the undo log
#
proc ::undo::undo {} {
    variable count

    if {$count} {
	variable log
	foreach i $log($count) {
	    dputs "Undo: $i"
	    catch ::undo::$i
	}
	unset log($count)
	incr count -1
    }
    return $count
}
