#! /bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

# interface generated by SpecTcl version 1.1 from /home/msj/projects/SpecTcl/SpecTcl/menueditor.ui
#   root     is the parent window for this user interface

proc menueditor_ui {root args} {

	# this treats "." as a special case

	if {$root == "."} {
	    set base ""
	} else {
	    set base $root
	}
    
	frame $base.fSeparator \
		-borderwidth 1 \
		-relief sunken \
		-width 2

	frame $base.fr

	listbox $base.lbEntries \
		-exportselection 0 \
		-height 0 \
		-width 0

	button $base.view \
		-text Post/View

	button $base.add \
		-text Add

	label $base.lType \
		-text Type

	menubutton $base.mbType \
		-indicatoron 1 \
		-menu "$base.mbType.m" \
		-relief raised \
		-takefocus {} \
		-text command \
		-textvariable mbType.value

	button $base.new \
		-text New

	button $base.insert \
		-text Insert

	label $base.lLabel \
		-text Label

	entry $base.eLabel

	button $base.remove \
		-text Remove

	button $base.delete \
		-text Delete

	label $base.lCommand \
		-text Command

	entry $base.eCommand

	button $base.replace \
		-text Replace

	label $base.lVariable \
		-text Variable

	entry $base.eVariable

	label $base.lMenu \
		-text Menu

	entry $base.eMenu \
		-textvariable entry

	checkbutton $base.cbTearoff \
		-text Tearoff \
		-variable cbTearoff.value

	button $base.dismiss \
		-command "destroy $root" \
		-text Dismiss


	# Geometry management

	grid $base.fSeparator -in $root	-row 1 -column 3  \
		-pady 5 \
		-rowspan 6 \
		-sticky ns
	grid $base.fr -in $root	-row 1 -column 4  \
		-rowspan 6 \
		-sticky n
	grid $base.lbEntries -in $root	-row 1 -column 1  \
		-rowspan 6 \
		-sticky nesw
	grid $base.view -in $root	-row 1 -column 2 
	grid $base.add -in $root	-row 1 -column 6 
	grid $base.lType -in $base.fr	-row 1 -column 1 
	grid $base.mbType -in $base.fr	-row 1 -column 2 
	grid $base.new -in $root	-row 2 -column 2 
	grid $base.insert -in $root	-row 2 -column 6 
	grid $base.lLabel -in $base.fr	-row 2 -column 1 
	grid $base.eLabel -in $base.fr	-row 2 -column 2 
	grid $base.remove -in $root	-row 3 -column 2 
	grid $base.delete -in $root	-row 3 -column 6 
	grid $base.lCommand -in $base.fr	-row 3 -column 1 
	grid $base.eCommand -in $base.fr	-row 3 -column 2 
	grid $base.replace -in $root	-row 4 -column 6 
	grid $base.lVariable -in $base.fr	-row 4 -column 1 
	grid $base.eVariable -in $base.fr	-row 4 -column 2 
	grid $base.lMenu -in $base.fr	-row 5 -column 1 
	grid $base.eMenu -in $base.fr	-row 5 -column 2 
	grid $base.cbTearoff -in $root	-row 5 -column 2 
	grid $base.dismiss -in $root	-row 5 -column 6 

	# Resize behavior management

	grid rowconfigure $root 1 -weight 0 -minsize 30
	grid rowconfigure $root 2 -weight 0 -minsize 30
	grid rowconfigure $root 3 -weight 0 -minsize 30
	grid rowconfigure $root 4 -weight 0 -minsize 30
	grid rowconfigure $root 5 -weight 0 -minsize 30
	grid rowconfigure $root 6 -weight 1 -minsize 30
	grid columnconfigure $root 1 -weight 0 -minsize 30
	grid columnconfigure $root 2 -weight 0 -minsize 30
	grid columnconfigure $root 3 -weight 0 -minsize 30
	grid columnconfigure $root 4 -weight 0 -minsize 30
	grid columnconfigure $root 5 -weight 0 -minsize 30
	grid columnconfigure $root 6 -weight 0 -minsize 30

	grid rowconfigure $base.fr 1 -weight 0 -minsize 30
	grid rowconfigure $base.fr 2 -weight 0 -minsize 30
	grid rowconfigure $base.fr 3 -weight 0 -minsize 30
	grid rowconfigure $base.fr 4 -weight 0 -minsize 25
	grid rowconfigure $base.fr 5 -weight 0 -minsize 30
	grid columnconfigure $base.fr 1 -weight 0 -minsize 30
	grid columnconfigure $base.fr 2 -weight 0 -minsize 30
# additional interface code
source /home/msj/projects/SpecTcl/SpecTcl/menueditor.tk

# Initialise listbox
set ::menueditor::menulist [list]
foreach item [uplevel #0 array names Widgets] {
   upvar #0 $item wdata
   if {"$wdata(type)"=="menu"} {
      lappend ::menueditor::menulist [list $item $wdata(item_name)]
      $base.lbEntries insert end $wdata(item_name)
   }
}

# Menu for $base.mbType
::menueditor::CreateTheOptionmenu $base.mbType.m

# The demo menu
set mbase $base.demomenu
if {[catch {::menueditor::displaymenu $mbase} xxx]} {
   tk_messageBox -message $xxx
}

# Callbacks for buttons
$base.view config -command "
   $mbase post 0 0
   catch {$mbase activate 0}
"
$base.remove config -command "
   catch {$base.lbEntries delete active}
"
$base.add config -command "
   switch \${mbType.value} {
      checkbutton -
      radiobutton -
      command {
         $mbase add \${mbType.value} -label \[$base.eLabel get\] -command {$mbase post 0 0}
      }
      cascade {
         $mbase add cascade -label \[$base.eLabel get\] -menu $mbase.\[$base.eMenu get\]
         menu $mbase.\[$base.eMenu get\]
      }
      separator {
         $mbase add separator
      }
   }
   $mbase activate end
   catch {\[focus\] selection range 0 end\]}
"

# Still needs work
$base.replace config -command "
   $mbase entryconfig \[$mbase index active\] -label \[$base.eLabel get\]
"

$base.cbTearoff config -command "$mbase config -tearoff \${cbTearoff.value}"

# Bindings
bind $root <Key-Up> "
   catch {$mbase activate \[expr \[$mbase index active\]-1\]}
"
bind $root <Key-Down> "
   catch {$mbase activate \[expr \[$mbase index active\]+1\]}
"
bind $root <Key-Left> "bell"
bind $root <Key-Right> "
   catch {$mbase postcascade \[$mbase index active\]}
"
# Arrow keys in entry widgets must override arrow keys in
# $root except at the beginning or end of the input string
foreach item {Label Command Variable Menu} {
   set w $base.e$item
   bind $w <Key-Left> "
      if {\[$w index insert\]>0} {
         $w icursor \[expr {\[$w index insert\]-1}\]
         break  ;# So that $root binding is not executed
      }
   "
   bind $w <Key-Right> "
      if {\[$w index insert\]<\[$w index end\]} {
         $w icursor \[expr {\[$w index insert\]+1}\]
         break  ;# So that $root binding is not executed
      }
   "
}
# Fast button invoking
bind $root <Key-Return> "$base.add invoke"
bind $root <Key-Insert> "$base.insert invoke"
bind $root <Key-Delete> "$base.delete invoke"
bind $root <Key-Escape> "$base.dismiss invoke"

# Selection callback in listbox
set l $base.lbEntries
rename $l ::menueditor::.l
proc $l {args} "
   puts \$args
   if {\[regexp {^selection\$} \[lindex \$args 0\]\] &&
       \[regexp {^set\$} \[lindex \$args 1\]\]} {
      ::menueditor::displaymenu $mbase \[::menueditor::.l index \[lindex \$args 2\]\]
   }
   uplevel ::menueditor::.l \$args
"

#$l selection set 0















# end additional interface code

}


# Allow interface to be run "stand-alone" for testing

catch {
    if [info exists embed_args] {
	# we are running in the plugin
	menueditor_ui .
    } else {
	# we are running in stand-alone mode
	if {$argv0 == [info script]} {
	    wm title . "Testing menueditor_ui"
	    menueditor_ui .
	}
    }
}
