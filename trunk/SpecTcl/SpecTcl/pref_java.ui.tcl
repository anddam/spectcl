# interface generated by SpecTcl version 1.0 from pref_java.ui
#   root     is the parent window for this user interface

proc pref_java_ui {root args} {

	# this treats "." as a special case

	if {$root == "."} {
	    set base ""
	} else {
	    set base $root
	}
    
	frame $base.frame#1

	label $base.label#2 \
		-anchor e \
		-borderwidth 1 \
		-text package

	entry $base.entry#1 \
		-borderwidth 1 \
		-cursor {} \
		-highlightthickness 1 \
		-textvariable p(package)

	label $base.label#6 \
		-anchor e \
		-borderwidth 1 \
		-text imports

	entry $base.entry#6 \
		-borderwidth 1 \
		-cursor {} \
		-highlightthickness 1 \
		-textvariable p(imports)

	label $base.label#3 \
		-anchor e \
		-borderwidth 1 \
		-text extends

	entry $base.entry#2 \
		-borderwidth 1 \
		-cursor {} \
		-highlightthickness 1 \
		-textvariable p(extends)

	label $base.label#4 \
		-anchor e \
		-borderwidth 1 \
		-text implements

	entry $base.entry#3 \
		-borderwidth 1 \
		-cursor {} \
		-highlightthickness 1 \
		-textvariable p(implements)

	label $base.label#5 \
		-anchor e \
		-borderwidth 1 \
		-text {global variables list}

	entry $base.entry#4 \
		-borderwidth 1 \
		-cursor {} \
		-highlightthickness 1 \
		-textvariable p(arg)

	label $base.label#7 \
		-anchor e \
		-borderwidth 1 \
		-text {init method}

	entry $base.entry#7 \
		-borderwidth 1 \
		-cursor {} \
		-highlightthickness 1 \
		-textvariable p(init)
                
        label $base.label#8 \
		-anchor e \
		-borderwidth 1 \
		-text {frame name}

	entry $base.entry#8 \
		-borderwidth 1 \
		-cursor {} \
		-highlightthickness 1 \
		-textvariable p(frame_name)

	checkbutton $base.checkbutton#1 \
		-borderwidth 1 \
		-highlightthickness 1 \
		-text {Include comments in code} \
		-variable p(java_include_comments)

	button $base.button#3 \
		-borderwidth 1 \
		-command {array set p [array get Jdefault]} \
		-highlightthickness 1 \
		-text Defaults


	# Geometry management

	grid $base.frame#1 -in $root	-row 9 -column 1  \
		-columnspan 2 \
		-sticky ew
	grid $base.label#2 -in $root	-row 1 -column 1  \
		-sticky e
	grid $base.entry#1 -in $root	-row 1 -column 2  \
		-sticky ew
	grid $base.label#6 -in $root	-row 2 -column 1  \
		-sticky e
	grid $base.entry#6 -in $root	-row 2 -column 2  \
		-sticky ew
	grid $base.label#3 -in $root	-row 3 -column 1  \
		-sticky e
	grid $base.entry#2 -in $root	-row 3 -column 2  \
		-sticky ew
	grid $base.label#4 -in $root	-row 4 -column 1  \
		-sticky e
	grid $base.entry#3 -in $root	-row 4 -column 2  \
		-sticky ew
	grid $base.label#5 -in $root	-row 5 -column 1  \
		-sticky e
	grid $base.entry#4 -in $root	-row 5 -column 2  \
		-sticky ew
	grid $base.label#7 -in $root	-row 6 -column 1  \
		-sticky e
	grid $base.entry#7 -in $root	-row 6 -column 2  \
		-sticky ew
        grid $base.label#8 -in $root	-row 7 -column 1  \
		-sticky e
	grid $base.entry#8 -in $root	-row 7 -column 2  \
		-sticky ew        
                
	grid $base.checkbutton#1 -in $root	-row 8 -column 1  \
		-columnspan 2
	grid $base.button#3 -in $base.frame#1	-row 1 -column 3  \
		-sticky e

	# Resize behavior management

	grid rowconfigure $root 1 -weight 0 -minsize 12
	grid rowconfigure $root 2 -weight 0 -minsize 13
	grid rowconfigure $root 3 -weight 0 -minsize 12
	grid rowconfigure $root 4 -weight 0 -minsize 5
	grid rowconfigure $root 5 -weight 0 -minsize 6
	grid rowconfigure $root 6 -weight 0 -minsize 6
	grid rowconfigure $root 7 -weight 0 -minsize 9
	grid rowconfigure $root 8 -weight 1 -minsize 6
	grid rowconfigure $root 9 -weight 0 -minsize 30
	grid columnconfigure $root 1 -weight 0 -minsize 30
	grid columnconfigure $root 2 -weight 1 -minsize 30

	grid rowconfigure $base.frame#1 1 -weight 0 -minsize 30
	grid columnconfigure $base.frame#1 1 -weight 0 -minsize 30
	grid columnconfigure $base.frame#1 2 -weight 0 -minsize 30
	grid columnconfigure $base.frame#1 3 -weight 1 -minsize 30
# additional interface code
# end additional interface code

}


# Allow interface to be run "stand-alone" for testing

catch {
    if {$argv0 == [info script]} {
	wm title . "Testing pref_java"
	pref_java_ui .
    }
}
