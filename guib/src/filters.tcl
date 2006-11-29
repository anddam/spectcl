# filters.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# This file contains the data filtering and validation filters.
#
# The input filter is invoked just as the data is written onto the form if the
# input conversion fails, the result should be set to {}.  This does not change
# the stored value of the data, just what might be used in generated of saved
# code.
#
# The output filter translates the data on the form to the format used by the
# application.  Upon failure, an error message is placed into the argument,
# instead of the conversion.  The output filter is called any time the user
# tries to apply the data to the widget (on "OK" or "Apply").
#
# output filters take 3 arguments:
#	The name of the widget
#	The option being filtered
#	The name of the variable the old/new value is to be stored in

namespace eval ::filter {
    # the various filter classes
    variable WIDGETTYPE
    variable INPUT
    variable OUTPUT
}

proc filter {cmd args} {
    return [uplevel 1 [list ::filter::$cmd] $args]
}

proc ::filter::filters {type what cmd} {
    if {![regexp {^(widgettype|input|output)$} $type]} {
	return -code error "unknown filter type '$type':\
		must be widgettype, input or output"
    }
    set out ""
    foreach filter [array names FILTER [lindex $args 0]] {
	lappend out $filter $FILTER($filter)
    }
    return $out
}

proc ::filter::add {type what cmd} {
    if {![regexp {^(widgettype|input|output)$} $type]} {
	return -code error "unknown filter type '$type':\
		must be widgettype, input or output"
    }
    variable [string toupper $type]
    upvar 0 [string toupper $type] var
    set var($what) $cmd
}

proc ::filter::delete {type what} {
    if {![regexp {^(widgettype|input|output)$} $type]} {
	return -code error "unknown filter type '$type':\
		must be widgettype, input or output"
    }
    variable [string toupper $type]
    upvar 0 [string toupper $type] var
    catch {unset var($what)}
}

proc ::filter::widgettype {type widget} {
    variable WIDGETTYPE
    # We don't error on non-existent filter requests
    if {[info exists WIDGETTYPE($type)]} {
	return [uplevel 1 $WIDGETTYPE($type) [list $widget]]
    }
    return 1
}

proc ::filter::input {type value args} {
    variable INPUT
    # We don't error on non-existent filter requests
    if {[info exists INPUT($type)]} {
	return [uplevel 1 $INPUT($type) [list $value] $args]
    }
    return $value
}

proc ::filter::output {type widget varName args} {
    variable OUTPUT
    # We don't error on non-existent filter requests
    if {[info exists OUTPUT($type)]} {
	return [uplevel 1 $OUTPUT($type) [list $widget $type $varName] $args]
    }
    return 1
}

# geometry manager row/colum mangling (not much error checking for now)!
# These should be combined
# internally, widgets are in: 2,4,6...
# - The "odd" indexes are where the grid lines go
# - Index "0" is reserved
# externally they go in:   1,2,3...

proc ::filter::_in_rowcol {value args} {
    return [expr {$value / 2}]
}

proc ::filter::_in_span {value args} {
    return [expr {1 + ($value / 2)}]
}

# Images
#
proc ::filter::_in_image {value args} {
    if {$value eq ""} { return "" }
    if {[lsearch -exact [image names] $value] == -1} {
	set imgval $value ; # copy to not change actual value
	if {[file pathtype $value] ne "absolute"} {
	    set imgval [file normalize [file join [::project::get dir] $value]]
	}
	if {[catch {image create photo $value} err]} {
	    tk_messageBox -title "Error Creating Image" -type ok -icon error \
		-message "Unable to create image for \"$value\":\n$err"
	    return ""
	}
	if {[file exists $imgval]} {
	    $value configure -file $imgval
	} else {
	    tk_messageBox -title "Invalid Image File" -type ok -icon error \
		-message "Image file \"$imgval\" does not exist.\
		\nPlease correct filename before saving project."
	}
    }
    return $value
}

proc ::filter::_out_image {widget option varname args} {
    upvar 1 $varname value

    if {$value eq ""} { return "" }
    set imgval $value ; # copy to not change actual value
    if {[file pathtype $value] ne "absolute"} {
	set imgval [file normalize [file join [::project::get dir] $value]]
    }
    if {[lsearch -exact [image names] $imgval] == -1} {
	# On output, validate that the file really exists first
	if {![file exists $imgval]} {
	    set value "Image file \"$imgval\" does not exist"
	    return 0
	}
	if {[catch {image create photo $value -file $imgval} err]} {
	    set value "Unable to create image from \"$imgval\":\n$err"
	    return 0
	}
    }
    return 1
}

# a widget's user-defined name should only contain alnum chars
#
proc ::filter::_out_ID {widget option varname args} {
    upvar 1 $varname value
    if {$widget eq $value} {
	return 1
    } elseif {![string length $value]} {
	set value "Widget name must be non-empty"
	return 0
    } elseif {[::widget::isMenu $widget]} {
	# A menu widget only needs the non-empty check (it's the label)
	return 1
    } elseif {![regexp {^[a-zA-Z0-9_]+$} $value]} {
	set value "Use only alphanumeric characters in widget names"
	return 0
    } elseif {[string is upper [string index $value 0]]} {
	set value "Widget name cannot start with an upper-case letter"
	return 0
    } elseif {[have_name $value $widget]} {
	set value "The name \"$value\" is already in use"
	return 0
    }
    return 1
}

# see if the application has a widget by this name

proc ::filter::have_name {name curwidget} {
    foreach w [::widget::widgets] {
	if {[::widget::data $w ID] eq $name && $w ne $curwidget} {
	    return 1
	}
    }
    return 0
}

# install the filters into the configuration database

proc install_filters {} {
    filter add input  GM:-row		::filter::_in_rowcol
    filter add input  GM:-column	::filter::_in_rowcol
    filter add input  GM:-rowspan	::filter::_in_span
    filter add input  GM:-columnspan	::filter::_in_span

    filter add output ID	::filter::_out_ID
    filter add input  -image	::filter::_in_image
    filter add output -image	::filter::_out_image

    # The widget type specific creation filters go here, at least for now

    filter add widgettype {Tk labelframe}	::filter::create_frame
    filter add widgettype {Tk frame}		::filter::create_frame
    filter add widgettype {Tk scrollbar} 	orient_create
    filter add widgettype {Tk scale}		orient_create

    filter add widgettype {Tk panedwindow} \
	[list ::filter::_createExpanded news [list -width 0 -height 0]]
    filter add widgettype {Tk text} \
	[list ::filter::_createExpanded news [list -width 0 -height 0]]
    filter add widgettype {Tk canvas} \
	[list ::filter::_createExpanded news [list -width 0 -height 0]]
    filter add widgettype {Tk listbox} \
	[list ::filter::_createExpanded news [list -width 0 -height 0]]
    filter add widgettype {Tk entry} \
	[list ::filter::_createExpanded ew [list -width 0]]

    filter add widgettype {BWidget NoteBook}	::filter::create_NoteBook
}

##
## WIDGET TYPE FILTERS
##
## These get called when a widget of a specified type is added
## to the workspace.
##

# do this when we create a frame
# The current setup is experimenting with sub-grids
#   win:  The name of the new sub-frame

proc ::filter::create_frame {w {rows 4} {cols 4}} {
    if {$rows > 1} {
	grid_create $w $rows $cols
    }
    set ::Frames($w) 1
    # create resizing rows/cols by default for embedded frames
    # as well as making it sticky news by default
    arrow_create $::W(CAN_ROW) row $w all 2
    arrow_create $::W(CAN_COL) column $w all 2
    arrow_activate $::W(CANVAS) $::Current(frame)
    ::widget::geometry $w -sticky news
    # readjust the frame levels
    set_frame_level $::W(FRAME)
    return 1
}

# make these -sticky nsew and width and height 0
#
proc ::filter::create_NoteBook {w} {
    $w insert end default -text [winfo name $w]
    ::widget::geometry $w -sticky news
}

# make these -sticky nsew and width and height 0
#
proc ::filter::_createExpanded {dir wargs w} {
    if {[llength $wargs]} {
	eval [linsert $wargs 0 ::widget::data $w]
    }
    ::widget::geometry $w -sticky $dir
}

# we need to set the row/column resize and appropriate sticky value for:
#  scales
#  scrollbars

proc orient_create {widget} {
    if {[string match v* [$widget cget -orient]]} {
	set what  row
	set stick ns
    } else {
	set what  column
	set stick ew
    }

    ::widget::geometry $widget -sticky $stick
    sync_all sticky

    set master [::widget::data $widget master]

    set other column
    foreach dim {row column} {
	set val     [::widget::geometry $widget -$dim]
	set index   [expr {$val/2 - 1}]
	set resize  [::widget::geometry $master resize_$dim]
	set current [lindex $resize $index]
	set isdim   [string equal $dim $what]

	# if the current value is "odd"  don't change value
	if {$current != "" && !($current&1)} {
	    ::widget::geometry $master resize_$dim \
		[lreplace $resize $index $index [expr {$isdim ? 2 : 0}]]
	    ::widget::geometry $master weight_$dim \
		[lreplace [::widget::geometry $master weight_$dim] \
		     $index $index [expr {$isdim ? 1 : 0}]]
	    arrow_shape $::W(CANVAS) $master $dim $val $isdim
	}
	set other row
    }
}
