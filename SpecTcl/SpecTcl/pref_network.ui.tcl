# interface generated by SpecTcl version 1.0 from pref_network.ui
#   root     is the parent window for this user interface

proc pref_network_ui {root args} {

	# this treats "." as a special case

	if {$root == "."} {
	    set base ""
	} else {
	    set base $root
	}
    
	label $base.label#4 \
		-background grey \
		-text {Information required for Error Reporting:}

	label $base.label#3 \
		-background grey \
		-text {Http ProxyHost:}

	entry $base.entry#1 \
		-cursor {} \
		-textvariable p(proxy_host)

	label $base.label#2 \
		-background grey \
		-text {Http Proxy Port:}

	entry $base.entry#2 \
		-cursor {} \
		-textvariable p(proxy_port) \
		-width 5

	label $base.label#7 \
		-background grey \
		-borderwidth 2 \
		-text {Your Name}

	entry $base.entry#4 \
		-cursor {} \
		-textvariable p(username)

	label $base.label#6 \
		-background grey \
		-borderwidth 2 \
		-text {Your Email Address}

	entry $base.entry#5 \
		-cursor {} \
		-textvariable p(email)


	# Geometry management

	grid $base.label#4 -in $root	-row 2 -column 1  \
		-columnspan 3 \
		-sticky w
	grid $base.label#3 -in $root	-row 3 -column 2  \
		-sticky e
	grid $base.entry#1 -in $root	-row 3 -column 3  \
		-sticky ew
	grid $base.label#2 -in $root	-row 4 -column 2  \
		-sticky e
	grid $base.entry#2 -in $root	-row 4 -column 3  \
		-sticky w
	grid $base.label#7 -in $root	-row 5 -column 2  \
		-sticky e
	grid $base.entry#4 -in $root	-row 5 -column 3  \
		-sticky ew
	grid $base.label#6 -in $root	-row 6 -column 2  \
		-sticky e
	grid $base.entry#5 -in $root	-row 6 -column 3  \
		-sticky ew

	# Resize behavior management

	grid rowconfigure $root 1 -weight 0 -minsize 7
	grid rowconfigure $root 2 -weight 0 -minsize 9
	grid rowconfigure $root 3 -weight 0 -minsize 5
	grid rowconfigure $root 4 -weight 0 -minsize 5
	grid rowconfigure $root 5 -weight 0 -minsize 2
	grid rowconfigure $root 6 -weight 0 -minsize 5
	grid rowconfigure $root 7 -weight 1 -minsize 2
	grid columnconfigure $root 1 -weight 0 -minsize 64
	grid columnconfigure $root 2 -weight 0 -minsize 88
	grid columnconfigure $root 3 -weight 0 -minsize 119
# additional interface code
# end additional interface code

}


# Allow interface to be run "stand-alone" for testing

catch {
    if {$argv0 == [info script]} {
	wm title . "Testing pref_network"
	pref_network_ui .
    }
}
