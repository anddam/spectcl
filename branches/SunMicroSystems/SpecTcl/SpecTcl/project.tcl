# SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
#
# See the file "license.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# edit the current project file.
proc project_edit {} {
    if {[info comm .project] == ""} {
	toplevel .project
	project_ui .project
    } else {
	raise .project
    }
}

# add files to this project.
proc project_add_file {} {
    global file_select_types P
    while {[set filename [tk_getOpenFile -filetypes $file_select_types -initialdir $P(project_dir)]] != ""} {
	.project.items insert 0 $filename
    }
}

# delete files from this project.
proc project_delete_file {} {
    global P
}

# hide the project dialog box
proc project_hide {} {
    destroy .project
}