# error reporting for tcl
# This uses the httpd library in tcl8.0 alpha-1

# Send the following information in the request:
#  Current Stack trace
#  Copy of "ui file"
#  platform information
#  unique id
#  personal information

# Here we are replacing the default bg error routine with our own
# that can mail bug reports to us at Sun.  However, we need to keep
# the old bgerror command around for cases when we are running user
# code.

# Bug report feature has been disabled in spectcl 1.1
#
#
#if {[info commands bgerror] == ""} {
#    source [file join $tk_library bgerror.tcl]
#}
#rename bgerror old_bgerror
#proc bgerror {args} {
#    specerror {SpecTcl has detected an internal error.} [list $args]
#}

return

proc specerror {title args} {
    global tcl_platform P errorInfo BugData tk_version tcl_version

    # Stop error recursion

    if {[winfo exists .bugreport]} {
    	catch {incr BugData(count)}
    	return
    }

    if {![string match $title "SpecTcl has detected an internal error."]} {
	set errorInfo $title
    }
    set info $errorInfo
    catch {unset BugData}

    # gather the information

    set BugData(tk_version) $tk_version
    set BugData(tcl_version) $tcl_version
    set where [port_getproxy]
    set proxy_host [lindex $where 0]
    set proxy_port [lindex $where 1]
    set username [lindex $where 2]
    set email [lindex $where 3]
    foreach q {proxy_host proxy_port username email} {
	if {![info exists P($q)]} {
	    set P($q) [set $q]
        }
    }
    array set BugData [array get tcl_platform]
    set BugData(ErrorInfo) $info
    foreach i {username email version Version patchlevel} {
    	catch {set BugData($i) $P($i)}
    }
    catch {
	set BugData(project) [get_file_data]
    }

    set BugData(count) 1

    # display it to the user

    bug_ui [toplevel .bugreport]
    .bugreport.title config -text $title
    wm title .bugreport "SpecTcl Bug Report"
    if {$BugData(email) != ""} {
	# BUGFIX: This is to fix a bug with the deletion of windows not yet
        # mapped under the Mac.
        update idletasks

    	destroy .bugreport.optional
    }
    set space1 " "
    set space2 "\n\n"
    foreach name [lsort [array names BugData]] {
    	.bugreport.message_text insert end $name name \
    		$space1 space $BugData($name) value $space2 space2
    }
    .bugreport.message_text tag configure name -foreground blue
    .bugreport.message_text configure -state disabled
    tkwait visibility .bugreport
    focus .bugreport.bug_text
    catch {focus .bugreport.name}
    grab .bugreport
}

# send_bug_report --
#
#	Called from the "send" button in the modified bgerror routine.
#	This code gathers the info and sends the bug report and finally
#	destroys the error dialog box.
#
# Arguments:
#	None.
# Results:
#	None.  May send bug report and destroy bug report window.

proc send_bug_report {} {
    global BugData P _Message
    if {[winfo exists .bugreport.options]} {
    	set save 0
	if {[info exists BugData(email)] && $BugData(email) != ""} {
	    set P(email) BugData(email]
	    set save 1
	}
	if {[info exists BugData(username)] && $BugData(username) != ""} {
	    set P(username) BugData(username]
	    set save 1
	}
	if {$save} {
	    catch {save_preferences}
	    set _Message "Saving username and email"
	    update idletasks
	}
    }

    # Only send bug report if user actually wrote a description
    set BugData(Description) [.bugreport.bug_text get 0.0 end]
    if {[regexp "^\[ \t\n]*$" $BugData(Description)]} {
	tk_dialog .bugreport.error "No Description" \
	    "Please provide a description of how the bug occurred or \
	     press cancel to avoid sending bug report." error 0 Ok
	return
    }

    grab release .bugreport
    destroy .bugreport
    reportBug BugData
}

# report a bug - use the "data" array to post the results

proc reportBug {data} {
    global P _Message
    upvar $data query
    catch {http_config -proxyhost $P(proxy_host)}
    catch {http_config -proxyport $P(proxy_port)}
    http_config -useragent "SpecTcl $P(Version) Bug reporter" 
    set url http://redsonja.sunlabs.com/research/tcl/spectcl/bugreport.cgi
    set q [eval http_formatQuery [array get query]]
    if {[catch {http_get $url -query $q -command report_reply} token]} {
	set help "Check the settings under network preferences."
	tk_dialog .error "Bug Report Error" $token\n\n$help error 0 OK
	return 0
    }
    upvar #0 $token state
    set state(cancel) [after 180000 [list http_reset $token]]
    set _Message "Sending trouble report"
    update idletasks
}

proc report_reply {token} {
    upvar #0 $token state
    after cancel $state(cancel)
    if {$state(status) == "reset"} {
    	set state(body) "Timeout trying to connect to trouble server, check the settings under network preferences."
    }
    tk_dialog .report "Bug Report Status" $state(body) warning 0 OK
    unset state
}
