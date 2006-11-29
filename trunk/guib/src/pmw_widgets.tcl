# pmw_widgets.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

::widget::define Pmw ComboBox -lang tkinter -version 8.3 -requires Pmw -image combobox.gif -equivalent "BWidget ComboBox" -options {
    {option -autoclear -reflect 0 -type boolean -category basic -default 0}
    {option -buttonaspect -reflect 0 -type {double {0.5 2.0 0.1}} -category advanced -default 1.0}
    {option -labelmargin -reflect 0 -type {pixels {0 8 1}} -category advanced -default 0}
    {option -labelpos -reflect 0 -type {list {None n s e w}} -category advanced -default None}
    {option -selectioncommand -reflect 0 -type command -category advanced -default None}
    {option -dropdown -reflect 0 -type boolean -category advanced -default 1}
    {option -fliparrow -reflect 0 -type boolean -category advanced -default 0}
    {option -listheight -reflect 0 -type integer -category advanced -default 200}
    {option -unique -reflect 0 -type boolean -category basic -default 1}
    {option -history -reflect 0 -type boolean -category basic -default 1}
}

::widget::define Pmw Counter -lang tkinter -version 8.3 -requires Pmw -image entry.gif -equivalent "Iwidgets datefield" -options {
    {option -autorepeat -reflect 0 -type boolean -category advanced -default 1}
    {option -buttonaspect -reflect 0 -type {double {0.5 2.0 0.1}} -category advanced -default 1.0}
    {option -datatype -reflect 0 -type {list {numeric integer real time date}} -category advanced -default numeric}
    {option -increment -reflect 0 -type integer -category advanced -default 1}
    {option -initwait -reflect 0 -type integer -category advanced -default 300}
    {option -labelmargin -reflect 0 -type {pixels {0 8 1}} -category advanced -default 0}
    {option -labelpos -reflect 0 -type {list {None n s e w}} -category advanced -default None}
    {option -pady -reflect 0 -type pixels -category advanced -default 0}
    {option -padx -reflect 0 -type pixels -category advanced -default 0}
    {option -orient -reflect 0 -type orient -category basic -default horizontal}
    {option -repeatrate -reflect 0 -type integer -category advanced -default 50}
}

::widget::define Pmw HistoryText -lang tkinter -version 8.3 -requires Pmw -image text.gif -equivalent "Tk text" -options {
    {option -borderframe -reflect 0 -type boolean -category basic -default 0}
    {option -columnheader -reflect 0 -type boolean -category basic -default 0}
    {option -compressany -reflect 0 -type boolean -category advanced -default 1}
    {option -compresstail -reflect 0 -type boolean -category advanced -default 1}
    {option -historycommand -reflect 0 -type command -category advanced -default None}
    {option -hscrollmode -reflect 0 -type {list {none static dynamic}} -category advanced -default dynamic}
    {option -labelmargin -reflect 0 -type {pixels {0 8 1}} -category advanced -default 0}
    {option -labelpos -reflect 0 -type {list {None n s e w}} -category advanced -default None}
    {option -rowcolumnheader -reflect 0 -type boolean -category advanced -default 0}
    {option -rowheader -reflect 0 -type boolean -category advanced -default 0}
    {option -scrollmargin -reflect 0 -type {pixels {0 8 1}} -category advanced -default 2}
    {option -usehullsize -reflect 0 -type boolean -category advanced -default 0}
    {option -vscrollmode -reflect 0 -type {list {none static dynamic}} -category advanced -default dynamic}
}

::widget::define Pmw NoteBook -lang tkinter -version 8.3 -requires Pmw \
    -image notebook.gif -equivalent "BWidget NoteBook" -options {
    {option -arrownavigation -reflect 0 -type boolean -category advanced -default 1}
    {option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category basic -default 2}
    {option -createcommand -reflect 0 -type string -category advanced -default None}
    {option -lowercommand -reflect 0 -type string -category advanced -default None}
    {option -pagemargin -reflect 0 -type {pixels {0 8 1}} -category basic -default 4}
    {option -raisecommand -reflect 0 -type string -category advanced -default None}
    {option -tabpos -reflect 0 -type {list {None n}} -category advanced -default n}
}

::widget::define Pmw PanedWidget -lang tkinter -version 8.3 -requires Pmw -image panedwindow.gif -equivalent "Tk panedwindow" -options {
    {option -command -reflect 0 -type command -category advanced -default None}
    {option -handlesize -reflect 0 -type {pixels {0 12 1}} -category basic -default 8}
    {option -orient -reflect 0 -type orient -category basic -default vertical}
    {option -separatorrelief -reflect 0 -type relief -category advanced -default sunken}
    {option -separatorthickness -reflect 0 -type {integer {0 4 1}} -category advanced -default 2}
}

::widget::define Pmw ScrolledText -lang tkinter -version 8.3 -requires Pmw -image text.gif -equivalent "Tk text" -options {
    {option -borderframe -reflect 0 -type boolean -category basic -default 0}
    {option -columnheader -reflect 0 -type boolean -category basic -default 0}
    {option -labelmargin -reflect 0 -type {pixels {0 8 1}} -category advanced -default 0}
    {option -labelpos -reflect 0 -type {list {None n s e w}} -category advanced -default None}
    {option -hscrollmode -reflect 0 -type {list {none static dynamic}} -category advanced -default dynamic}
    {option -rowcolumnheader -reflect 0 -type boolean -category basic -default 0}
    {option -rowheader -reflect 0 -type boolean -category basic -default 0}
    {option -scrollmargin -reflect 0 -type {integer {0 4 1}} -category advanced -default 2}
    {option -usehullsize -reflect 0 -type boolean -category advanced -default 0}
    {option -vscrollmode -reflect 0 -type {list {none static dynamic}} -category advanced -default dynamic}
}

::widget::define Pmw TimeCounter -lang tkinter -version 8.3 -requires Pmw -image unknown.gif -equivalent "Iwidgets spintime" -options {
    {option -autorepeat -reflect 0 -type boolean -category basic -default 1}
    {option -buttonaspect -reflect 0 -type {double {0.5 2.0 0.1}} -category advanced -default 1.0}
    {option -command -reflect 0 -type command -category advanced -default None}
    {option -initwait -reflect 0 -type integer -category advanced -default 300}
    {option -labelmargin -reflect 0 -type {pixels {0 8 1}} -category advanced -default 0}
    {option -labelpos -reflect 0 -type {list {None n s e w}} -category advanced -default None}
    {option -min -reflect 0 -type string -category advanced -default None}
    {option -max -reflect 0 -type string -category advanced -default None}
    {option -padx -reflect 0 -type pixels -category advanced -default 0}
    {option -pady -reflect 0 -type pixels -category advanced -default 0}
    {option -repeatrate -reflect 0 -type integer -category advanced -default 50}
    {option -value -reflect 0 -type string -category advanced -default None}
}

#
# UNUSED PMW WIDGETS
#

if {0} {
    ::widget::define Pmw ButtonBox -lang tkinter -version 8.3 -requires Pmw -image unknown.gif -equivalent "" -options {
	{option -pady -reflect 0 -type string -category advanced -default 3}
	{option -padx -reflect 0 -type string -category advanced -default 3}
	{option -labelmargin -reflect 0 -type string -category advanced -default 0}
	{option -labelpos -reflect 0 -type string -category advanced -default None}
	{option -orient -reflect 0 -type string -category advanced -default horizontal}
    }

    ::widget::define Pmw EntryField -lang tkinter -version 8.3 -requires Pmw -image entry.gif -equivalent "Tk entry" -options {
	{option -command -reflect 0 -type command -category advanced -default None}
	{option -errorbackground -reflect 0 -type color -category advanced -default pink}
	{option -extravalidators -reflect 0 -type string -category ignore -default {}}
	{option -invalidcommand -reflect 0 -type string -category advanced -default Pmw.EntryField.bell}
	{option -labelmargin -reflect 0 -type string -category advanced -default 0}
	{option -labelpos -reflect 0 -type string -category advanced -default None}
	{option -modifiedcommand -reflect 0 -type string -category advanced -default None}
	{option -validate -reflect 0 -type string -category advanced -default None}
	{option -value -reflect 0 -type string -category advanced -default }
    }

    ::widget::define Pmw LabeledWidget -lang tkinter -version 8.3 -requires Pmw -image unknown.gif -equivalent "" -options {
	{option -labelmargin -reflect 0 -type {pixels {0 8 1}} -category basic -default 0}
	{option -labelpos -reflect 0 -type {list {None n s e w}} -category basic -default None}
    }

    ::widget::define Pmw MessageBar -lang tkinter -version 8.3 -requires Pmw -image unknown.gif -equivalent "" -options {
	{option -messagetypes -reflect 0 -type string -category advanced -default {'usererror': (4, 5, 1, 0), 'systemevent': (2, 5, 0, 0), 'busy': (3, 0, 0, 0), 'help': (1, 5, 0, 0), 'state': (0, 0, 0, 0), 'systemerror': (5, 10, 2, 1), 'userevent': (2, 5, 0, 0)}}
	{option -labelmargin -reflect 0 -type string -category advanced -default 0}
	{option -labelpos -reflect 0 -type string -category advanced -default None}
	{option -silent -reflect 0 -type string -category advanced -default 0}
    }

    ::widget::define Pmw RadioSelect -lang tkinter -version 8.3 -requires Pmw -image radiobutton.gif -equivalent "" -options {
	{option -selectmode -reflect 0 -type string -category advanced -default single}
	{option -labelmargin -reflect 0 -type string -category advanced -default 0}
	{option -labelpos -reflect 0 -type string -category advanced -default None}
	{option -padx -reflect 0 -type string -category advanced -default 5}
	{option -pady -reflect 0 -type string -category advanced -default 5}
	{option -command -reflect 0 -type string -category advanced -default None}
	{option -orient -reflect 0 -type string -category advanced -default horizontal}
	{option -buttontype -reflect 0 -type string -category advanced -default button}
    }

    ::widget::define Pmw ScrolledCanvas -lang tkinter -version 8.3 -requires Pmw -image canvas.gif -equivalent "" -options {
	{option -labelmargin -reflect 0 -type string -category advanced -default 0}
	{option -labelpos -reflect 0 -type string -category advanced -default None}
	{option -scrollmargin -reflect 0 -type string -category advanced -default 2}
	{option -hscrollmode -reflect 0 -type string -category advanced -default dynamic}
	{option -usehullsize -reflect 0 -type string -category advanced -default 0}
	{option -canvasmargin -reflect 0 -type string -category advanced -default 0}
	{option -vscrollmode -reflect 0 -type string -category advanced -default dynamic}
	{option -borderframe -reflect 0 -type string -category advanced -default 0}
    }

    ::widget::define Pmw ScrolledField -lang tkinter -version 8.3 -requires Pmw -image scrolledframe.gif -equivalent "" -options {
	{option -text -reflect 0 -type string -category advanced -default }
	{option -labelmargin -reflect 0 -type string -category advanced -default 0}
	{option -labelpos -reflect 0 -type string -category advanced -default None}
    }

    ::widget::define Pmw ScrolledFrame -lang tkinter -version 8.3 -requires Pmw -image scrolledframe.gif -equivalent "BWidget ScrollableFrame" -options {
	{option -borderframe -reflect 0 -type borderframe -category advanced -default 1}
	{option -horizflex -reflect 0 -type {list {fixed expand shrink elastic}} -category advanced -default fixed}
	{option -horizfraction -reflect 0 -type {double {0 1.0 0.05}} -category advanced -default 0.05}
	{option -hscrollmode -reflect 0 -type {list {none static dynamic}} -category advanced -default dynamic}
	{option -labelmargin -reflect 0 -type {pixels {0 8 1}} -category advanced -default 0}
	{option -labelpos -reflect 0 -type {list {None n s e w}} -category advanced -default None}
	{option -scrollmargin -reflect 0 -type {integer {0 4 1}} -category advanced -default 2}
	{option -usehullsize -reflect 0 -type boolean -category advanced -default 0}
	{option -vertfraction -reflect 0 -type {double {0 1.0 0.05}} -category advanced -default 0.05}
	{option -vscrollmode -reflect 0 -type {list {none static dynamic}} -category advanced -default dynamic}
	{option -vertflex -reflect 0 -type {list {fixed expand shrink elastic}} -category advanced -default fixed}
    }

    ::widget::define Pmw ScrolledListBox -lang tkinter -version 8.3 -requires Pmw -image listbox.gif -equivalent "" -options {
	{option -labelmargin -reflect 0 -type string -category advanced -default 0}
	{option -labelpos -reflect 0 -type string -category advanced -default None}
	{option -selectioncommand -reflect 0 -type string -category advanced -default None}
	{option -scrollmargin -reflect 0 -type string -category advanced -default 2}
	{option -usehullsize -reflect 0 -type string -category advanced -default 0}
	{option -hscrollmode -reflect 0 -type string -category advanced -default dynamic}
	{option -items -reflect 0 -type string -category advanced -default ()}
	{option -vscrollmode -reflect 0 -type string -category advanced -default dynamic}
	{option -dblclickcommand -reflect 0 -type string -category advanced -default None}
    }
}
