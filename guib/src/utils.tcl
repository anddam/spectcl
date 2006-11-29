# utils.tcl
#
#	Utility procs (mostly taken from tkcon)
#
# Copyright (c) 2002 Jeffrey Hobbs.
#

# simple puts style debugging support

proc dputs {args} {
    global Debug Show_stack
    if {![info exists Debug]} {
	return
    }
    #puts [list [info level -1] $args]; return
    set level [expr {[info level] - 1}]
    if {$level > 0} {
	set caller [lindex [info level $level] 0]
    } else {
	set caller toplevel
    }

    # experimental!

    if {[info exists Show_stack]} {
	append caller " ("
	while {[incr level -1] > 0} {
	    append caller \t[string replace [info level $level] 70 end ...]\n
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

proc relpath {basedir target} {
    # Try and make a relative path to a target file/dir from base directory
    set bparts [file split $basedir]
    set tparts [file split $target]

    if {[lindex $bparts 0] eq [lindex $tparts 0]} {
	# If the first part doesn't match - there is no good relative path
	set blen [llength $bparts]
	set tlen [llength $tparts]
	for {set i 1} {$i < $blen && $i < $tlen} {incr i} {
	    if {[lindex $bparts $i] ne [lindex $tparts $i]} { break }
	}
	set path [lrange $tparts $i end]
	for {} {$i < $blen} {incr i} {
	    set path [linsert $path 0 ..]
	}
	return [eval [list file join] $path]
    }

    return $target
}

##
## COLOR ROUTINES
##

# default --
#
# pseudo-named colors, fonts, etc (defaults)
#
array set ::COLOR {
    SystemButtonFace	"#D4D0C8"
    SystemButtonText	"#000000"
    SystemDisabledText	"#808080"
    SystemHighlight	"#A0426A"
    SystemHighlightText	"#FFFFFF"
    SystemMenu		"#D4D0C8"
    SystemMenuText	"#000000"
    SystemScrollbar	"#D4D0C8"
    SystemWindow	"#FFFFFF"
    SystemWindowText	"#000000"
    SystemWindowFrame	"#000000"

    normalbackground	"#D4D0C8"
    normalforeground	"#000000"
    activebackground	"#D4D0C8"
    textforeground	"#000000"
    selectbackground	"#A0426A"
    selectforeground	"#FFFFFF"
    trough		"#D4D0C8"
    indicator		"#FFFFFF"
    disabledforeground	"#808080"
    menubackground	"#D4D0C8"
    menuforeground	"#000000"
    highlight		"#000000"
}
if {$::tcl_platform(platform) eq "windows"} {
    array set ::FONT {
	default		"{MS Sans Serif} 8"
	defaultBold	"{MS Sans Serif} 8 bold"
    }
} else {
    array set ::FONT {
	default		"Helvetica -12"
	defaultBold	"Helvetica -12 bold"
    }
}
proc default {type name} {
    if {$type eq "font"} {
	if {[info exists ::FONT($name)]} {
	    return $::FONT($name)
	} else {
	    return $::FONT(default)
	}
    } elseif {$type eq "color"} {
	if {[info exists ::COLOR($name)]} {
	    return $::COLOR($name)
	} else {
	    return "#000000"
	}
    } else {
	return -code error "unknown type '$type': must be one of color or font"
    }
}

# rgb2dec --
#
#   Turns #rgb into 3 elem list of decimal vals.
#
# Arguments:
#   c		The #rgb hex of the color to translate
# Results:
#   Returns a #RRGGBB or #RRRRGGGGBBBB color
#
proc rgb2dec c {
    set c [string tolower $c]
    if {[regexp -nocase {^#([0-9a-f])([0-9a-f])([0-9a-f])$} $c x r g b]} {
	# double'ing the value make #9fc == #99ffcc
	scan "$r$r $g$g $b$b" "%x %x %x" r g b
    } else {
	if {![regexp {^#([0-9a-f]+)$} $c junk hex] || \
		[set len [string length $hex]]>12 || $len%3 != 0} {
	    if {[catch {winfo rgb . $c} rgb]} {
		return -code error "bad color value \"$c\""
	    } else {
		return $rgb
	    }
	}
	set len [expr {$len/3}]
    	scan $hex "%${len}x%${len}x%${len}x" r g b
    }
    return [list $r $g $b]
}

# shade --
#
#   Returns a shade between two colors
#
# Arguments:
#   orig	start #rgb color
#   dest	#rgb color to shade towards
#   frac	fraction (0.0-1.0) to move $orig towards $dest
# Results:
#   Returns a shade between two colors based on the
# 
proc shade {orig dest frac} {
    if {$frac >= 1.0} { return $dest } elseif {$frac <= 0.0} { return $orig }
    foreach {origR origG origB} [rgb2dec $orig] \
	    {destR destG destB} [rgb2dec $dest] {
	set shade [format "\#%02x%02x%02x" \
		[expr {int($origR+double($destR-$origR)*$frac)}] \
		[expr {int($origG+double($destG-$origG)*$frac)}] \
		[expr {int($origB+double($destB-$origB)*$frac)}]]
	return $shade
    }
}

# complement --
#
#   Returns a complementary color
#   Does some magic to avoid bad complements of grays
#
# Arguments:
#   orig	start #rgb color
# Results:
#   Returns a complement of a color
# 
proc complement {orig {grays 1}} {
    foreach {r g b} [rgb2dec $orig] {break}
    set r [expr {$r%256}]
    set g [expr {$g%256}]
    set b [expr {$b%256}]
    set R [expr {(~$r)%256}]
    set G [expr {(~$g)%256}]
    set B [expr {(~$b)%256}]
    if {$grays && abs($R-$r) < 32 && abs($G-$g) < 32 && abs($B-$b) < 32} {
	set R [expr {($r+128)%256}]
	set G [expr {($g+128)%256}]
	set B [expr {($b+128)%256}]
    }
    return [format "\#%02x%02x%02x" $R $G $B]
}

##
## UTILITY CODE TAKEN FROM tkcon
##

## lremove - remove items from a list
# OPTS:
#   -all	remove all instances of each item
#   -glob	remove all instances matching glob pattern
#   -regexp	remove all instances matching regexp pattern
# ARGS:	l	a list to remove items from
#	args	items to remove (these are 'join'ed together)
##
proc lremove {args} {
    array set opts {-all 0 pattern -exact}
    while {[string match -* [lindex $args 0]]} {
	switch -glob -- [lindex $args 0] {
	    -a*	{ set opts(-all) 1 }
	    -g*	{ set opts(pattern) -glob }
	    -r*	{ set opts(pattern) -regexp }
	    --	{ set args [lreplace $args 0 0]; break }
	    default {return -code error "unknown option \"[lindex $args 0]\""}
	}
	set args [lreplace $args 0 0]
    }
    set l [lindex $args 0]
    foreach i [join [lreplace $args 0 0]] {
	if {[set ix [lsearch $opts(pattern) $l $i]] == -1} continue
	set l [lreplace $l $ix $ix]
	if {$opts(-all)} {
	    while {[set ix [lsearch $opts(pattern) $l $i]] != -1} {
		set l [lreplace $l $ix $ix]
	    }
	}
    }
    return $l
}

## echo
## Relaxes the one string restriction of 'puts'
# ARGS:	any number of strings to output to stdout
##
proc echo args { puts stdout [concat $args] }

## dump - outputs variables/procedure/widget info in source'able form.
## Accepts glob style pattern matching for the names
#
# ARGS:	type	- type of thing to dump: must be variable, procedure, widget
#
# OPTS: -nocomplain
#		don't complain if no items of the specified type are found
#	-filter pattern
#		specifies a glob filter pattern to be used by the variable
#		method as an array filter pattern (it filters down for
#		nested elements) and in the widget method as a config
#		option filter pattern
#	--	forcibly ends options recognition
#
# Returns:	the values of the requested items in a 'source'able form
## 
proc dump {type args} {
    set whine 1
    set code  ok
    if {![llength $args]} {
	## If no args, assume they gave us something to dump and
	## we'll try anything
	set args $type
	set type any
    }
    while {[string match -* [lindex $args 0]]} {
	switch -glob -- [lindex $args 0] {
	    -n* { set whine 0; set args [lreplace $args 0 0] }
	    -f* { set fltr [lindex $args 1]; set args [lreplace $args 0 1] }
	    --  { set args [lreplace $args 0 0]; break }
	    default {return -code error "unknown option \"[lindex $args 0]\""}
	}
    }
    if {$whine && ![llength $args]} {
	return -code error "wrong \# args: [lindex [info level 0] 0] type\
		?-nocomplain? ?-filter pattern? ?--? pattern ?pattern ...?"
    }
    set res {}
    switch -glob -- $type {
	c* {
	    # command
	    # outputs commands by figuring out, as well as possible, what it is
	    # this does not attempt to auto-load anything
	    foreach arg $args {
		if {[llength [set cmds [info commands $arg]]]} {
		    foreach cmd [lsort $cmds] {
			if {[lsearch -exact [interp aliases] $cmd] > -1} {
			    append res "\#\# ALIAS:   $cmd =>\
				    [interp alias {} $cmd]\n"
			} elseif {
			    [llength [info procs $cmd]] ||
			    ([string match *::* $cmd] &&
			    [llength [namespace eval [namespace qual $cmd] \
				    info procs [namespace tail $cmd]]])
			} {
			    if {[catch {dump p -- $cmd} msg] && $whine} {
				set code error
			    }
			    append res $msg\n
			} else {
			    append res "\#\# COMMAND: $cmd\n"
			}
		    }
		} elseif {$whine} {
		    append res "\#\# No known command $arg\n"
		    set code error
		}
	    }
	}
	v* {
	    # variable
	    # outputs variables value(s), whether array or simple.
	    if {![info exists fltr]} { set fltr * }
	    foreach arg $args {
		if {![llength [set vars [uplevel 1 info vars [list $arg]]]]} {
		    if {[uplevel 1 info exists $arg]} {
			set vars $arg
		    } elseif {$whine} {
			append res "\#\# No known variable $arg\n"
			set code error
			continue
		    } else { continue }
		}
		foreach var [lsort $vars] {
		    if {[uplevel 1 [list info locals $var]] == ""} {
			# use the proper scope of the var, but namespace which
			# won't id locals or some upvar'ed vars correctly
			set new [uplevel 1 \
				[list namespace which -variable $var]]
			if {$new != ""} {
			    set var $new
			}
		    }
		    upvar 1 $var v
		    if {[array exists v] || [catch {string length $v}]} {
			set nst {}
			append res "array set [list $var] \{\n"
			if {[array size v]} {
			    foreach i \
				    [lsort -dictionary [array names v $fltr]] {
				upvar 0 v\($i\) __a
				if {[array exists __a]} {
				    append nst "\#\# NESTED ARRAY ELEM: $i\n"
				    append nst "upvar 0 [list $var\($i\)] __a;\
					    [dump v -filter $fltr __a]\n"
				} else {
				    append res "    [list $i]\t[list $v($i)]\n"
				}
			    }
			} else {
			    ## empty array
			    append res "    empty array\n"
			    if {$var == ""} {
				append nst "unset (empty)\n"
			    } else {
				append nst "unset [list $var](empty)\n"
			    }
			}
			append res "\}\n$nst"
		    } else {
			append res [list set $var $v]\n
		    }
		}
	    }
	}
	p* {
	    # procedure
	    foreach arg $args {
		if {
		    ![llength [set procs [info proc $arg]]] &&
		    ([string match *::* $arg] &&
		    [llength [set ps [namespace eval \
			    [namespace qualifier $arg] \
			    info procs [namespace tail $arg]]]])
		} {
		    set procs {}
		    set namesp [namespace qualifier $arg]
		    foreach p $ps {
			lappend procs ${namesp}::$p
		    }
		}
		if {[llength $procs]} {
		    foreach p [lsort $procs] {
			set as {}
			foreach a [info args $p] {
			    if {[info default $p $a tmp]} {
				lappend as [list $a $tmp]
			    } else {
				lappend as $a
			    }
			}
			append res [list proc $p $as [info body $p]]\n
		    }
		} elseif {$whine} {
		    append res "\#\# No known proc $arg\n"
		    set code error
		}
	    }
	}
	w* {
	    # widget
	    ## The user should have Tk loaded
	    if {![llength [info command winfo]]} {
		return -code error "winfo not present, cannot dump widgets"
	    }
	    if {![info exists fltr]} { set fltr .* }
	    foreach arg $args {
		if {[llength [set ws [info command $arg]]]} {
		    foreach w [lsort $ws] {
			if {[winfo exists $w]} {
			    if {[catch {$w configure} cfg]} {
				append res "\#\# Widget $w\
					does not support configure method"
				set code error
			    } else {
				append res "\#\# [winfo class $w]\
					$w\n$w configure"
				foreach c $cfg {
				    if {[llength $c] != 5} continue
				    ## Check to see that the option does
				    ## not match the default, then check
				    ## the item against the user filter
				    if {[string compare [lindex $c 3] \
					    [lindex $c 4]] && \
					    [regexp -nocase -- $fltr $c]} {
					append res " \\\n\t[list [lindex $c 0]\
						[lindex $c 4]]"
				    }
				}
				append res \n
			    }
			}
		    }
		} elseif {$whine} {
		    append res "\#\# No known widget $arg\n"
		    set code error
		}
	    }
	}
	a* {
	    ## see if we recognize it, other complain
	    if {[regexp {(var|com|proc|widget)} \
		    [set types [uplevel 1 what $args]]]} {
		foreach type $types {
		    if {[regexp {(var|com|proc|widget)} $type]} {
			append res "[uplevel 1 dump $type $args]\n"
		    }
		}
	    } else {
		set res "dump was unable to resolve type for \"$args\""
		set code error
	    }
	}
	default {
	    return -code error "bad [lindex [info level 0] 0] option\
		    \"$type\": must be variable, command, procedure,\
		    or widget"
	}
    }
    return -code $code [string trimright $res \n]
}
