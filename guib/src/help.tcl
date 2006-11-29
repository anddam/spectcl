# help.tcl --
#
#	Help (status bar and tooltips)
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::help {
    # after ID of the balloonhelp erase
    variable FORGETPENDING {}
    # whether we should make status help go away
    variable FORGET 0
    # delay to wait before making it go away again, in millisecs
    variable DURATION 3000
}

# test simple field help
# enable or disable help on a field by field basis

proc ::help::status {{on 1}} {
    if {$on} {
	bind all <Leave> {::help::statusClear}
	bind all <Enter> {::help::statusField %W %X %Y}
    } else {
	bind all <Leave> {}
	bind all <Enter> {}
    }
}

# enable or disable tooltips
proc ::help::tooltips {{on 1}} {
    ::help::balloon [string is true -strict $on]
}

# display a help message for a widget
# Widget could be destroyed in the mean time

proc ::help::statusField {w X Y} {
    if {![winfo exists $w]}  {
	statusClear
    } elseif {[::widget::exists $w]} {
	set type [::widget::type $w]
	set id   [::widget::data $w ID]
	set msg "$type $id"
	statusShow $msg
    } elseif {[regexp {(.*)\.(row|column)@([0-9]+)} $w - master what index]} {
	if {$master eq $::W(FRAME)} {
	    set master master
	} else {
	    set master [::widget::data $master master]
	}
	statusShow "Click to select $master $what [expr {$index/2}]\
		for insert or delete"
    } elseif {[regexp {_outline:(..?)} $w - what]} {
	statusShow "Click and drag to change column or row span"
    }
}

# Actually show the text of the balloon message, and set the status line
# up to be cleared.
proc ::help::statusShow {t} {
    variable ::help::FORGETPENDING
    variable ::help::FORGET
    variable ::help::DURATION

    # cancel any existing erasepending id
    after cancel $FORGETPENDING
    # This is the textvariable for the help status bar
    set ::G(HELPMSG) $t
    if {$FORGET} {
        set FORGETPENDING [after $DURATION ::help::statusClear]
    }
}

# Finally clear the status line.
proc ::help::statusClear {} {
    # This is the textvariable for the help status bar
    set ::G(HELPMSG) ""
}

##
## Handle the Help files
##

proc ::help::launch {{topic {}}} {
    set dirs [list]
    lappend dirs [file join [file dirname [info nameofexecutable]] docs]
    lappend dirs [file join $::gui::BASEDIR .. docs]
    foreach dir $dirs {
	if {[file exists [file join $dir index.html]]} {
	    set file [file join $dir index.html]
	    break
	}
    }
    if {[::api::IsInteractive]} {
	if {![info exists file]} {
	    set file "notfound"
	}
	::api::Notify help $file
    } else {
	if {![info exists file]} {
	    tk_messageBox -title "Help Not Found" -icon error -type ok \
		-message "Could not find $::gui::APPNAME help files in any of:\
		\n[join $dirs \n]"
	    return
	}
	urlOpen [::api::file2uri $file]
    }
}

#
# These procs are adapted from the wiki to open up a url in the
# system's default browser (or any browser it can find).
#
proc ::help::findExecutable {progname varname} {
    upvar 1 $varname result
    set progs [auto_execok $progname]
    if {[llength $progs]} {
	set result [lindex $progs 0]
    }
    return [llength $progs]
}

proc ::help::urlOpen {url} {
    global env
    switch [tk windowingsystem] {
        "x11" {
	    set redir ">&/dev/null </dev/null"
	    if {[info exists env(BROWSER)]} {
		set browser $env(BROWSER)
	    }
            expr {
                [info exists browser] ||
                [findExecutable netscape  browser] ||
                [findExecutable iexplorer browser] ||
                [findExecutable mozilla   browser] ||
                [findExecutable opera     browser] ||
                [findExecutable lynx      browser]
            }
            # lynx can also output formatted text to a variable
            # with the -dump option, as a last resort:
            # set formatted_text [ exec lynx -dump $url ] - PSE
	    if {![info exists browser]} {
		return -code error "Could not find a browser to use"
	    }
	    # perhaps browser doesn't understand -remote flag
            if {([catch {exec $browser -remote $url &}] \
		    && [catch {exec $browser $url &} emsg])} {
		return -code error "Error displaying $url in browser\n$emsg"
		# Another possibility is to just pop a window up
		# with the URL to visit in it. - DKF
            }
        }
        "win32" {
	    set redir ">NUL: <NUL:"
            if {$tcl_platform(os) == "Windows NT"} {
                set rc [catch {eval exec $redir [list $env(COMSPEC) /c start $url] &} emsg]
            } else {
		# Windows 95/98
		set rc [catch {eval exec $redir [list start $url] &} emsg]
            }
            if {$rc} {
                return -code error "Error displaying $url in browser\n$emsg"
            }
        }
        "aqua" {
            if {![info exists env(BROWSER)]} {
                set env(BROWSER) "Safari"
            }
            if {[catch {
		package require Tclapplescript
                AppleScript execute "tell application \"$env(BROWSER)\" \
			to open location \"$url\""
	    } emsg]} {
                return -code error "Error displaying $url in browser\n$emsg"
            }
        }
    }
}

