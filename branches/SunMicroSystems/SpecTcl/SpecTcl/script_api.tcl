# script_api.tcl --
#
#	This file implements the scripting API to SpecTcl. 3rd party
#	applications can use this API to control the execution of SpecTcl.
#
# Copyright (c) 1997 Sun Microsystems, Inc. All rights reserved.
#
# SCCS: @(#) script_api.tcl 1.3 97/05/22 17:49:17


# spectcl::DesignFrame --
#
#	Returns the pathname of the design frame (the frame used to
#	display the widgets during design time).
#
# Arguments:
#	none.
#
# Result:
#	pathname of the design frame

proc spectcl::DesignFrame {} {
    return .can.f
}

# spectcl::AddWidget --
#
#	Adds a new widget of the given type to row,column.
#
# Arguments:
#	type		The type of the widget.
# 	master		The frame to manage the widget in.
#  	row,column	where to put it -- (1,1) is the top-left corner.
#
# Result:
#	Returns the pathname of the new widget. 

proc spectcl::AddWidget {type master row column} {
    global Current

    set R [expr $row * 2]
    set C [expr $column * 2]

    set on [grid slaves $Current(frame) -row $R -column $C]
    if [string compare $on ""] {
	error "($row,$column) is already occupied"
    }

    return [add_widget $type $master $R $C]
}

# spectcl::AddToolButton
#
#	Creates a user-defined button in the toolbar. (BUG: the button
#	doesn't appear in the toolbar right now)
#
# Arguments:
#	name	unique name of the button. Shouldn't contain "." and space
#		chars.
#	args	Option-value pairs to configure the options of the button.
#
# Return value:
#	The pathname of the button

proc spectcl::AddToolButton {name args} {
    eval button .$name $args
    pack .$name -in .buttons -side left
    return .$name
}

# spectcl::ConfigWidget
#
#	Configures the options of a widget in the design grid.
#
# Arguments:
#	win	pathname (returned by an earlier call to spectcl::AddWidget)
#	args	Option-value pairs to configure the options of the widget.
#
# Return value:
#	None

proc spectcl::ConfigWidget {win args} {
    if {([llength $args]%2) == 1} {
	error "wrong # of arguments"
    }
    foreach {option value} $args {
	regsub ^- $option "" option
	set result [validate_field $win $option $value]
	if ![string match "" $result] {
	    error $result
	}
    }
    return ""
}

