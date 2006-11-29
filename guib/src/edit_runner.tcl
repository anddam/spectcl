# SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
#
# See the file "license.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# This file is a placeholder to allow SpecTcl to start up an external
# editor, allowing this process to block, but sending a note back
# to SpecTcl to get SpecTcl to re-read the file when done.

# argv is:
#   {editor filename port}
# the editor is execed to edit the file '$filename', and when done,
# this process connects to SpecTcl to say "Okay, all done."

wm withdraw .

set editor [lindex $argv 0]
set filename [lindex $argv 1]
set port [lindex $argv 2]

if {![catch {eval "exec $editor $filename"} msg]} {
    set result Success
} else {
    set result Failure
}

if {![catch "socket localhost $port" file]} {
    puts $file $result
}

destroy .