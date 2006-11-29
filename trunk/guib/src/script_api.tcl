# script_api.tcl --
#
#	This file implements the scripting API.
#	3rd party apps can use this API to control execution.
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::api {
    variable CHAN
    variable isinteractive
    if {![info exists isinteractive]} { set isinteractive 0 }
}

proc ::api::_connect {host port} {
    # we've been passed a port to listen on
    if {[catch {socket $host $port} sock]} {
	set ok [tk_messageBox -icon error -type retrycancel \
		    -title "Failed to Connect - $::gui::APPNAME" \
		    -message "$::gui::APPNAME failed to connect to port $port.\
			\nChoose Retry to reattempt the connection."]
	if {$ok eq "retry"} {
	    return [_connect $host $port]
	}
	return ""
    }
    # cache them for debugging purposes - not used otherwise
    set ::api::port $port
    set ::api::sock $sock
    return $sock
}

proc ::api::_Interactive {{inChan stdin} {outChan stdout}} {
    variable CHAN
    set CHAN(IN)  $inChan
    set CHAN(OUT) $outChan
    fconfigure $inChan -buffering line -blocking 0
    fconfigure $outChan -buffering line -blocking 0
    # we set this on here, although we may not be ready to read input yet
    variable isinteractive 1
}
proc ::api::_Ready {} {
    variable CHAN
    if {[info exists CHAN(IN)]} {
	fileevent $CHAN(IN) readable [list ::api::_ReadInput $CHAN(IN)]
	_Notify "interactive on"
    }
}

proc ::api::IsInteractive {} {
    variable isinteractive
    return $isinteractive
}

proc ::api::_ReadInput {chan} {
    if {[gets $chan line] == -1} {
	if {[eof $chan]} {
	    fileevent $chan readable ""
	    if {$chan != "stdin"} {
		catch {close $chan}
	    }
	    variable isinteractive 0
	    variable CHAN
	    catch {unset CHAN(IN)}
	    _Notify "error input channel lost"
	}
	return
    }
    if {$line != ""} {
	#tk_messageBox -message "Received: $line" -type ok
	_Handle $line
    }
}

proc ::api::_Notify {msg} {
    variable CHAN
    if {$msg != ""} {
	#tk_messageBox -message $msg -type ok
	if {[info exists CHAN(OUT)] \
		&& [catch {puts $CHAN(OUT) $msg; flush $CHAN(OUT)}]} {
	    if {$CHAN(OUT) != "stdout"} { catch {close $CHAN(OUT)} }
	    unset CHAN(OUT)
	    variable isinteractive 0
	    status_message "Interactive Session Lost"
	    bell
	}
    }
}

proc ::api::Notify {type args} {
    if {[info exists ::Current(project)]} {
	set project $::Current(project)
    } else {
	set project $::P(project)
    }
    set val [lindex $args 0]
    switch $type {
	dirty	{ set msg "$type $project $val" }
	edit	{ set msg "$type $project [normalize $val]" }
	exit	{ set msg "exit" }
	help	{ set msg "help [normalize $val]" }
	language { set msg "$type $project $val" }
	load	{ set msg "$type $project [normalize $val]" }
	project	{ set msg "$type $project [normalize $val]" }
	save	{ set msg "$type $project [normalize $val]" }
	startup	{ set msg "$type $project [normalize $val]" }
	interpreter { set msg "$type [targetLanguage]" }
	default {
	    # the final join here destroys protected lists, but may mask
	    # bugs on the other end of the pipe
	    set msg "$type $project [join $args]"
	}
    }
    _Notify $msg
}

proc ::api::_Handle {cmd} {
    set code [catch $cmd msg]
    _Notify "$code $msg"
}

proc ::api::pong {} {
    # XXX: This should not be necessary, but on Win2K only the
    # guibuilder can hang when not getting data down the stdin
    # pipe - so this exists to ping/pong.
    # See also menucmds ping and koGuiBuilderService.py
    update idle
}

proc ::api::new {{name {}} {lang {}}} {
    return [::project::new $name $lang]
}
proc ::api::load {{file ""} args} {
    return [::project::openp $file]
}
proc ::api::save {{file {}} args} {
    if {[llength [info level 0]] == 1} {
	# "file" was not specified
	return [::project::save [::project::get ui]]
    } else {
	return [::project::save $file]
    }
}

# Allow the controlling app to set the language and interpreter
proc ::api::language {{lang {}} {ver {}} {interp {}}} {
    if {$lang ne ""} {
	# FIX: This should be consolidated into a language switching function.
	# This is taken from startup.tcl:handle_args
	variable ::gui::LANGS
	if {![info exists LANGS($lang)]} {
	    return -code error "unrecognized target language \"$val\",\
		must be one of: [array names LANGS]"
	}
	if {$ver eq ""} {
	    # pick default version
	    set ver [lindex $LANGS($lang) 1 0]
	}
    }
    return [targetLanguage $lang $ver $interp]
}

proc ::api::languages {} {
    return [lsort [array names ::gui::LANGS]]
}

proc ::api::interpreter {lang {interp ""}} {
    return [::${lang}::interpreter $interp]
}

proc ::api::raise {{w {}}} {
    if {[llength [info level 0]] == 2} {
	uplevel #0 [info level 0]
    } else {
	wm deiconify .
	raise .
	focus -force .
    }
}

proc ::api::exit {} {
    return [mainmenu_quit]
}

proc ::api::normalize {file} { return [file normalize $file] }

proc ::api::xsplit {str {exp {[^A-Za-z0-9_\./]}}} {
    # This function is a variation of a regexp-based split that
    # returns a list which includes the matched expression as well
    if {![string length $str]} { return {} }
    if {![string length $exp]} { return [::split $str ""] }
    set out   {}
    set start 0
    while {[regexp -start $start -indices -- $exp $str match submatch]} {
        foreach {subStart subEnd} $submatch {matchStart matchEnd} $match break
        lappend out [string range $str $start [expr {$matchStart-1}]] \
		[string range $str $matchStart $matchEnd]
        if {$subStart >= $start} {
            lappend out [string range $str $subStart $subEnd]
        }
        set start [expr {$matchEnd+1}]
    }
    lappend out [string range $str $start end]
    return $out
}

# file2uri --
#
#	Convert a filename to a file:// uri.
#
# Examples:
#     \\americano\QA\DevBuilds\test.tcl
#->   file://///americano/QA/DevBuilds/test.tcl
#     C:/Program Files/über/builder.txt
#->   file:///C:/Program%20Files/%fcber/builder.txt
#
# Arguments:
#	name	input file to convert to uri
#
proc ::api::file2uri {name} {
    # Avoid thing that already look like a uri
    if {[string match "????://*" $name]} { return $name }

    set name  [::api::normalize $name]
    set parts [file split $name]
    if {$::tcl_platform(platform) == "windows"} {
	# Windows uses an extra / in the uri, and we also make sure that
	# any drive letter gets capitalized.
	set uri "file:///[string totitle [lindex $parts 0]]"
    } else {
	set uri "file://[lindex $parts 0]"
    }
    set map ""
    foreach part [lrange $parts 1 end] {
	# Don't use file join - it must always be / for uris
	append map "/$part"
    }
    # Map the whole thing - we make the regexp ignore /
    foreach {str c} [xsplit [string trimleft $map /] {[^A-Za-z0-9_\./]}] {
	append uri $str
	if {[string length $c]} {
	    append uri %[format %.2x [scan $c %c]]
	}
    }
    return $uri
}

# uri2file --
#
#	Convert a file:// uri to a regular filename.
#
# Arguments:
#	name	input uri to convert to file
#
proc ::api::uri2file {name} {
    # Avoid thing that don't like a uri
    if {![string match "????://*" $name]} { return $name }

    # remove "file://"
    if {$::tcl_platform(platform) == "windows"} {
	# Windows uses an extra / in the uri.
	set map [string range $name 8 end]
    } else {
	set map [string range $name 7 end]
    }
    set file ""
    foreach {str c} [xsplit $map {%[[:xdigit:]]{2}}] {
	append file $str
	if {[string length $c]} {
	    append file [format %c [scan $c %%%x]]
	}
    }
    return $file
}
