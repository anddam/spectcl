# SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
#
# See the file "license.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# simple stuff to support interactive variable tracing
#  - print value any time global variable changes

# Basic Usage:
#  T			print variables with traces
#  T <x>		put a write trace on variable <x>
#  X <x>		remove trace on variable <x>

# Advanced usage (subject to change):
#  T <x> <how>				put a <how> trace on variable <x>.  How = r(ead), w(rite), or u(nset)
#  T <x> <how> <function>	use <function> instead of _tprint for tracing


# print traced variable (standard trace function)

proc _tprint {n1 n2 op} {
	upvar $n1 value

	set level [expr [info level] - 1]
	if {$level > 0} {
		set proc [lindex [info level $level] 0]
	} else {
		set proc Toplevel
	}
	if {$n2 == ""} {
		puts "TRACE: $n1 = $value (in $proc)"
	} else {
		puts "TRACE: ${n1}($n2) = $value($n2) (in $proc)"
	}
}

# set [or query] a global variable trace
proc T {{_x_ "?"} {op w} {function _tprint}} {
	global $_x_ _traces
	if {$_x_ == "?"} {
		puts "Current traces:"
		catch "parray _traces"
	} elseif {[info exists _traces($_x_)]} {
		puts "Replacing existing trace for $_x_"
	} else {
		puts "Setting trace for $_x_"
		set _traces($_x_) $op
	}
	eval trace variable $_x_ \$op \$function
}

# delete all traces on a variable

proc X {{_x_ ?}} {
	global $_x_ _traces
	if {$_x_ == "?"} {
		puts "Usage: X <var_name> (remove trace on var_name>"
		return ""
	}
	catch "unset _traces($_x_)"
	foreach trace [trace vinfo $_x_] {
		puts "Trace remove: $_x_ $trace"
		eval "trace vdelete $_x_ $trace"
	}
}

# trace calls to a procedure
# Print proc name, args, calling info

proc Trace {{name ?} {stack ""}} {
	if {$name == "?"} {
		puts "Usage: \"Trace <procedure_name>\", toggles the Trace state"
		puts "Procedures being traced:"
		regsub -all {.oLd} [info commands *.oLd] {} list
		puts "  $list"
		return
	}
	if {[info commands $name.oLd] != ""} {
		puts "Untracing $name"
		if {![regexp {!!trace!!} [info body $name]]} {
			puts "OOps, traced version of procedure appears to be gone!"
			rename $name.oLd {}
		} else {
			catch {rename $name ""}
			rename $name.oLd $name
		}
	} else {
		# procedure template
		set template {
			proc %s {args} {
				# !!trace!!
				puts "Trace: %s $args"	
				%s
				uplevel "%s.oLd $args"
			}
		}
		# template for adding stack trace to procedure
		set stack_template {
			set level [info level]
			while {[incr level -1] > 0} {
				puts " called from: [info level $level]"
			}
		}

		rename $name $name.oLd
		if {$stack == "stack"} {set stack $stack_template} {set stack ""}
		eval [format $template $name $name $stack $name]
		puts "Tracing $name"
	}		
}

# simple puts style debugging support

proc dputs {args} {
	global Debug Show_stack
	if {![info exists Debug]} {
		return
	}
	set level [expr [info level] - 1]
	if {$level > 0} {
		set caller [lindex [info level $level] 0]
	} else {
		set caller toplevel
	}

	# experimental!

	if {[info exists Show_stack]} {
		append caller " ("
		while {[incr level -1] > 0} {
			lappend caller [lindex [info level $level] 0]
		}
		append caller ")"
	}

	# puts "Debug: $caller in <$Debug> <$args>"
	foreach pattern $Debug {
		if {[string match $pattern $caller]} {
			puts "$caller: $args"
			break
		}
	}
}
