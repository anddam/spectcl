# perl_widgets.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# Tk::DirSelect
# Tk::FontDialog

::widget::define Perl MListbox -lang perl -version 8.0 \
    -requires Tk::MListbox -image listbox.gif -equivalent "Tk listbox" \
    -options {
	{option -background -reflect 1 -type color -category basic -default {[default color normalbackground]}}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -class -reflect 0 -type string -category ignore -default Frame}
	{option -colormap -reflect 0 -type custom -category ignore -default {}}
	{option -columns -reflect 0 -type special -category advanced -default undef}
	{option -configurecommand -reflect 0 -type special -category advanced -default undef}
	{option -container -reflect 0 -type boolean -category ignore -default 0}
	{option -cursor -reflect 0 -type cursor -category basic -default {}}
	{option -font -reflect 0 -type font -category basic -default {{MS Sans Serif} 8}}
	{option -foreground -reflect 1 -type color -category basic -default {[default color normalforeground]}}
	{option -height -reflect 1 -type integer -category advanced -default 10}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 1 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -moveable -reflect 0 -type special -category advanced -default 1}
	{option -offset -reflect 0 -type custom -category advanced -default {0 0}}
	{option -relief -reflect 1 -type relief -category advanced -default flat}
	{option -resizeable -reflect 0 -type special -category advanced -default 1}
	{option -selectbackground -reflect 0 -type color -category advanced -default {[default color selectbackground]}}
	{option -selectborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 1}
	{option -selectforeground -reflect 0 -type color -category advanced -default {[default color selectforeground]}}
	{option -selectmode -reflect 0 -type selectmode -category basic -default browse}
	{option -separatorcolor -reflect 0 -type special -category advanced -default black}
	{option -separatorwidth -reflect 0 -type special -category advanced -default 1}
	{option -sortable -reflect 0 -type special -category advanced -default 1}
	{option -takefocus -reflect 0 -type boolean -category basic -default 1}
	{option -textwidth -reflect 0 -type special -category advanced -default 10}
	{option -tile -reflect 0 -type special -category advanced -default undef}
	{option -visual -reflect 0 -type custom -category advanced -default {}}
	{option -width -reflect 0 -type integer -category advanced -default undef}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default undef}
	{option -yscrollcommand -reflect 0 -type command -category advanced -default undef}
    }

::widget::define Perl HistEntry -lang perl -version 8.0 \
    -requires Tk::HistEntry -image combobox.gif -equivalent "BWidget ComboBox" \
    -options {
	{option -arrowimage -reflect 0 -type special -category advanced -default undef}
	{option -auto -reflect 0 -type special -category advanced -default 0}
	{option -background -reflect 1 -type color -category basic -default {[default color SystemButtonFace]}}
	{option -bell -reflect 0 -type special -category advanced -default 1}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -browsecmd -reflect 0 -type special -category advanced -default undef}
	{option -case -reflect 0 -type special -category advanced -default 1}
	{option -colorstate -reflect 0 -type special -category advanced -default undef}
	{option -command -reflect 0 -type command -category basic -default undef}
	{option -cursor -reflect 0 -type cursor -category basic -default xterm}
	{option -disabledtile -reflect 0 -type special -category advanced -default undef}
	{option -dup -reflect 0 -type special -category advanced -default 1}
	{option -exportselection -reflect 0 -type boolean -category basic -default 1}
	{option -font -reflect 0 -type font -category basic -default {{MS Sans Serif} 8}}
	{option -foreground -reflect 1 -type color -category basic -default Black}
	{option -foregroundtile -reflect 0 -type special -category advanced -default undef}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertbackground -reflect 0 -type color -category advanced -default {[default color SystemWindowText]}}
	{option -insertborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertofftime -reflect 0 -type {integer {0 300 50}} -category advanced -default 300}
	{option -insertontime -reflect 0 -type {integer {0 300 50}} -category advanced -default 600}
	{option -insertwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -invalidcommand -reflect 0 -type command -category advanced -default undef}
	{option -justify -reflect 0 -type justify -category advanced -default left}
	{option -label -reflect 0 -type string -category basic -default undef}
	{option -labelActivetile -reflect 0 -type special -category advanced -default undef}
	{option -labelAnchor -reflect 0 -type special -category advanced -default center}
	{option -labelBackground -reflect 0 -type special -category advanced -default {[default color SystemButtonFace]}}
	{option -labelBitmap -reflect 0 -type special -category advanced -default {}}
	{option -labelBorderwidth -reflect 0 -type special -category advanced -default 2}
	{option -labelCursor -reflect 0 -type special -category advanced -default {}}
	{option -labelDisabledtile -reflect 0 -type special -category advanced -default undef}
	{option -labelFont -reflect 0 -type special -category advanced -default {{MS Sans Serif} 8}}
	{option -labelForeground -reflect 0 -type special -category advanced -default {[default color SystemButtonText]}}
	{option -labelHeight -reflect 0 -type special -category advanced -default 0}
	{option -labelHighlightbackground -reflect 0 -type special -category advanced -default {[default color SystemButtonFace]}}
	{option -labelHighlightcolor -reflect 0 -type special -category advanced -default {[default color SystemWindowFrame]}}
	{option -labelHighlightthickness -reflect 0 -type special -category advanced -default 0}
	{option -labelImage -reflect 0 -type special -category advanced -default undef}
	{option -labelJustify -reflect 0 -type special -category advanced -default center}
	{option -labelOffset -reflect 0 -type special -category advanced -default {0 0}}
	{option -labelPadx -reflect 0 -type special -category advanced -default 1}
	{option -labelPady -reflect 0 -type special -category advanced -default 1}
	{option -labelRelief -reflect 0 -type special -category advanced -default flat}
	{option -labelTakefocus -reflect 0 -type special -category advanced -default 0}
	{option -labelTile -reflect 0 -type special -category advanced -default undef}
	{option -labelUnderline -reflect 0 -type special -category advanced -default -1}
	{option -labelVariable -reflect 0 -type special -category advanced -default undef}
	{option -labelWidth -reflect 0 -type special -category advanced -default 0}
	{option -labelWraplength -reflect 0 -type special -category advanced -default 0}
	{option -limit -reflect 0 -type special -category advanced -default undef}
	{option -listcmd -reflect 0 -type special -category advanced -default undef}
	{option -listwidth -reflect 0 -type special -category advanced -default undef}
	{option -match -reflect 0 -type special -category advanced -default 0}
	{option -offset -reflect 0 -type custom -category advanced -default {0 0}}
	{option -relief -reflect 1 -type relief -category advanced -default sunken}
	{option -selectbackground -reflect 0 -type color -category advanced -default {[default color SystemHighlight]}}
	{option -selectborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -selectforeground -reflect 0 -type color -category advanced -default {[default color SystemHighlightText]}}
	{option -show -reflect 0 -type string -category advanced -default undef}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -takefocus -reflect 0 -type boolean -category basic -default undef}
	{option -textvariable -reflect 0 -type variable -category basic -default {}}
	{option -tile -reflect 0 -type special -category advanced -default undef}
	{option -validate -reflect 0 -type validate -category advanced -default undef}
	{option -validatecommand -reflect 0 -type command -category advanced -default undef}
	{option -width -reflect 0 -type integer -category advanced -default 20}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default {}}
    }

::widget::define Perl Date -lang perl -version 8.0 \
    -requires Tk::Date -image calendar.gif -equivalent "Iwidgets datefield" \
    -options {
	{option -background -reflect 1 -type color -category basic -default {[default color normalbackground]}}
	{option -bell -reflect 0 -type special -category advanced -default undef}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -class -reflect 0 -type string -category ignore -default Frame}
	{option -colormap -reflect 0 -type custom -category ignore -default {}}
	{option -command -reflect 0 -type command -category basic -default undef}
	{option -container -reflect 0 -type boolean -category advanced -default 0}
	{option -cursor -reflect 0 -type cursor -category basic -default {}}
	{option -decbitmap -reflect 0 -type special -category advanced -default Tk::FireButton::dec}
	{option -foreground -reflect 1 -type color -category basic -default {[default color normalforeground]}}
	{option -height -reflect 0 -type integer -category advanced -default 0}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -incbitmap -reflect 0 -type special -category advanced -default Tk::FireButton::inc}
	{option -innerbg -reflect 0 -type special -category advanced -default undef}
	{option -innerfg -reflect 0 -type special -category advanced -default undef}
	{option -label -reflect 0 -type string -category basic -default undef}
	{option -labelVariable -reflect 0 -type special -category advanced -default undef}
	{option -offset -reflect 0 -type custom -category advanced -default {0 0}}
	{option -precommand -reflect 0 -type special -category advanced -default undef}
	{option -relief -reflect 1 -type relief -category advanced -default flat}
	{option -repeatdelay -reflect 0 -type {integer {100 1000 100}} -category advanced -default 500}
	{option -repeatinterval -reflect 0 -type {integer {100 1000 100}} -category advanced -default 50}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -takefocus -reflect 0 -type boolean -category basic -default 0}
	{option -tile -reflect 0 -type special -category advanced -default undef}
	{option -value -reflect 0 -type special -category advanced -default undef}
	{option -variable -reflect 0 -type variable -category basic -default undef}
	{option -visual -reflect 0 -type custom -category advanced -default {}}
	{option -width -reflect 0 -type integer -category advanced -default 0}
}

#::widget::define Perl DateEntry -lang perl -version 8.0 \
    -requires Tk::Date -image frame.gif -equivalent "Tk frame" \
    -options {}

::widget::define Perl DatePick -lang perl -version 8.0 \
    -requires Tk::DatePick -image calendar.gif -equivalent "Iwidgets datefield" \
    -options {
	{option -background -reflect 1 -type color -category basic -default {[default color SystemButtonFace]}}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -cursor -reflect 0 -type cursor -category basic -default xterm}
	{option -disabledtile -reflect 0 -type special -category advanced -default undef}
	{option -exportselection -reflect 0 -type boolean -category basic -default 1}
	{option -file -reflect 0 -type special -category advanced -default undef}
	{option -font -reflect 0 -type font -category basic -default {{Courier New} 8}}
	{option -foreground -reflect 1 -type color -category basic -default Black}
	{option -height -reflect 0 -type integer -category advanced -default 24}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertbackground -reflect 0 -type color -category advanced -default {[default color SystemWindowText]}}
	{option -insertborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertofftime -reflect 0 -type {integer {0 300 50}} -category advanced -default 0}
	{option -insertontime -reflect 0 -type {integer {0 300 50}} -category advanced -default 600}
	{option -insertwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -label -reflect 0 -type string -category basic -default undef}
	{option -labelVariable -reflect 0 -type special -category advanced -default undef}
	{option -offset -reflect 0 -type custom -category advanced -default {0 0}}
	{option -overanchor -reflect 0 -type special -category advanced -default undef}
	{option -padx -reflect 0 -type {pixels {0 6 1}} -category advanced -default 5p}
	{option -pady -reflect 0 -type {pixels {0 6 1}} -category advanced -default 5p}
	{option -path -reflect 0 -type special -category advanced -default undef}
	{option -poddone -reflect 0 -type special -category advanced -default undef}
	{option -popanchor -reflect 0 -type special -category advanced -default undef}
	{option -popover -reflect 0 -type special -category advanced -default undef}
	{option -relief -reflect 1 -type relief -category advanced -default sunken}
	{option -scrollbars -reflect 0 -type special -category advanced -default w}
	{option -searchcase -reflect 0 -type special -category advanced -default 1}
	{option -selectbackground -reflect 0 -type color -category advanced -default {[default color SystemHighlight]}}
	{option -selectborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -selectforeground -reflect 0 -type color -category advanced -default {[default color SystemHighlightText]}}
	{option -setgrid -reflect 0 -type boolean -category advanced -default 0}
	{option -spacing1 -reflect 0 -type pixels -category advanced -default 0}
	{option -spacing2 -reflect 0 -type pixels -category advanced -default 0}
	{option -spacing3 -reflect 0 -type pixels -category advanced -default 0}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -tabs -reflect 0 -type string -category advanced -default {}}
	{option -takefocus -reflect 0 -type boolean -category basic -default undef}
	{option -tile -reflect 0 -type special -category advanced -default undef}
	{option -title -reflect 0 -type string -category advanced -default Pod}
	{option -width -reflect 0 -type integer -category advanced -default 80}
	{option -wrap -reflect 0 -type wrap -category advanced -default word}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default {}}
	{option -yscrollcommand -reflect 0 -type command -category advanced -default {}}
    }

::widget::define Perl XMLViewer -lang perl -version 8.0 \
    -requires Tk::XMLViewer -image text.gif -equivalent "Tk text" \
    -options {
	{option -background -reflect 1 -type color -category basic -default {[default color SystemButtonFace]}}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -cursor -reflect 0 -type cursor -category basic -default xterm}
	{option -disabledtile -reflect 0 -type special -category advanced -default undef}
	{option -exportselection -reflect 0 -type boolean -category basic -default 1}
	{option -font -reflect 0 -type font -category basic -default {{Courier New} 8}}
	{option -foreground -reflect 1 -type color -category basic -default Black}
	{option -height -reflect 1 -type integer -category advanced -default 24}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertbackground -reflect 0 -type color -category advanced -default {[default color SystemWindowText]}}
	{option -insertborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertofftime -reflect 0 -type {integer {0 300 50}} -category advanced -default 300}
	{option -insertontime -reflect 0 -type {integer {0 300 50}} -category advanced -default 600}
	{option -insertwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -offset -reflect 0 -type custom -category advanced -default {0 0}}
	{option -padx -reflect 0 -type {pixels {0 6 1}} -category advanced -default 1}
	{option -pady -reflect 0 -type {pixels {0 6 1}} -category advanced -default 1}
	{option -relief -reflect 1 -type relief -category advanced -default sunken}
	{option -selectbackground -reflect 0 -type color -category advanced -default {[default color SystemHighlight]}}
	{option -selectborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -selectforeground -reflect 0 -type color -category advanced -default {[default color SystemHighlightText]}}
	{option -setgrid -reflect 0 -type boolean -category advanced -default 0}
	{option -spacing1 -reflect 0 -type pixels -category advanced -default 0}
	{option -spacing2 -reflect 0 -type pixels -category advanced -default 0}
	{option -spacing3 -reflect 0 -type pixels -category advanced -default 0}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -tabs -reflect 0 -type string -category advanced -default {}}
	{option -takefocus -reflect 0 -type boolean -category basic -default undef}
	{option -tile -reflect 0 -type special -category advanced -default undef}
	{option -width -reflect 1 -type integer -category advanced -default 80}
	{option -wrap -reflect 0 -type wrap -category advanced -default char}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default {}}
	{option -yscrollcommand -reflect 0 -type command -category advanced -default {}}
    }

::widget::define Perl TableMatrix -lang perl -version 8.0 \
    -requires Tk::TableMatrix -image listbox.gif -equivalent "Tk listbox" \
    -options {
	{option -anchor -reflect 0 -type anchor -category advanced -default center}
	{option -autoclear -reflect 0 -type special -category advanced -default 0}
	{option -background -reflect 1 -type color -category basic -default {[default color SystemButtonFace]}}
	{option -bordercursor -reflect 0 -type special -category advanced -default crosshair}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 1}
	{option -browsecommand -reflect 0 -type special -category advanced -default {}}
	{option -cache -reflect 0 -type special -category advanced -default 0}
	{option -colorigin -reflect 0 -type special -category advanced -default 0}
	{option -cols -reflect 0 -type special -category advanced -default 10}
	{option -colseparator -reflect 0 -type special -category advanced -default {	}}
	{option -colstretchmode -reflect 0 -type special -category advanced -default none}
	{option -coltagcommand -reflect 0 -type special -category advanced -default undef}
	{option -colwidth -reflect 0 -type special -category advanced -default 10}
	{option -command -reflect 0 -type command -category basic -default {}}
	{option -cursor -reflect 0 -type cursor -category basic -default xterm}
	{option -drawmode -reflect 0 -type special -category advanced -default compatible}
	{option -exportselection -reflect 0 -type boolean -category basic -default 1}
	{option -flashmode -reflect 0 -type special -category advanced -default 0}
	{option -flashtime -reflect 0 -type special -category advanced -default 2}
	{option -font -reflect 0 -type font -category basic -default {{MS Sans Serif} 8}}
	{option -foreground -reflect 1 -type color -category basic -default black}
	{option -height -reflect 0 -type integer -category advanced -default 0}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 0 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -insertbackground -reflect 0 -type color -category advanced -default Black}
	{option -insertborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertofftime -reflect 0 -type {integer {0 300 50}} -category advanced -default 300}
	{option -insertontime -reflect 0 -type {integer {0 300 50}} -category advanced -default 600}
	{option -insertwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -invertselected -reflect 0 -type special -category advanced -default 0}
	{option -ipadx -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -ipady -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -justify -reflect 0 -type justify -category advanced -default left}
	{option -maxheight -reflect 0 -type special -category advanced -default 600}
	{option -maxwidth -reflect 0 -type special -category advanced -default 800}
	{option -multiline -reflect 0 -type special -category advanced -default 1}
	{option -padx -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -pady -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -relief -reflect 1 -type relief -category advanced -default sunken}
	{option -resizeborders -reflect 0 -type special -category advanced -default both}
	{option -rowheight -reflect 0 -type special -category advanced -default 1}
	{option -roworigin -reflect 0 -type special -category advanced -default 0}
	{option -rows -reflect 0 -type special -category advanced -default 10}
	{option -rowstretchmode -reflect 0 -type special -category advanced -default none}
	{option -rowtagcommand -reflect 0 -type special -category advanced -default undef}
	{option -selectioncommand -reflect 0 -type special -category advanced -default undef}
	{option -selectmode -reflect 0 -type selectmode -category basic -default browse}
	{option -selecttitles -reflect 0 -type special -category advanced -default 0}
	{option -selecttype -reflect 0 -type special -category advanced -default cell}
	{option -sparsearray -reflect 0 -type special -category advanced -default 1}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -takefocus -reflect 0 -type boolean -category basic -default undef}
	{option -titlecols -reflect 0 -type special -category advanced -default 0}
	{option -titlerows -reflect 0 -type special -category advanced -default 0}
	{option -usecommand -reflect 0 -type special -category advanced -default 1}
	{option -variable -reflect 0 -type variable -category basic -default undef}
	{option -validate -reflect 0 -type validate -category advanced -default 0}
	{option -validatecommand -reflect 0 -type command -category advanced -default {}}
	{option -width -reflect 0 -type integer -category advanced -default 0}
	{option -wrap -reflect 0 -type wrap -category advanced -default 0}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default undef}
	{option -yscrollcommand -reflect 0 -type command -category advanced -default undef}
    }


if {0} {
::widget::define Perl Pod -lang perl -version 8.0 \
    -requires Tk::Pod -image text.gif -equivalent "Tk text" \
    -options {
	{option -background -reflect 1 -type color -category basic -default {[default color SystemButtonFace]}}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -cursor -reflect 0 -type cursor -category basic -default xterm}
	{option -disabledtile -reflect 0 -type special -category advanced -default undef}
	{option -exportselection -reflect 0 -type boolean -category basic -default 1}
	{option -file -reflect 0 -type special -category advanced -default undef}
	{option -font -reflect 0 -type font -category basic -default {{Courier New} 8}}
	{option -foreground -reflect 1 -type color -category basic -default Black}
	{option -height -reflect 0 -type integer -category advanced -default 24}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertbackground -reflect 0 -type color -category advanced -default {[default color SystemWindowText]}}
	{option -insertborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertofftime -reflect 0 -type {integer {0 300 50}} -category advanced -default 0}
	{option -insertontime -reflect 0 -type {integer {0 300 50}} -category advanced -default 600}
	{option -insertwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -label -reflect 0 -type string -category basic -default undef}
	{option -labelVariable -reflect 0 -type special -category advanced -default undef}
	{option -offset -reflect 0 -type custom -category advanced -default {0 0}}
	{option -overanchor -reflect 0 -type special -category advanced -default undef}
	{option -padx -reflect 0 -type {pixels {0 6 1}} -category advanced -default 5p}
	{option -pady -reflect 0 -type {pixels {0 6 1}} -category advanced -default 5p}
	{option -path -reflect 0 -type special -category advanced -default undef}
	{option -poddone -reflect 0 -type special -category advanced -default undef}
	{option -popanchor -reflect 0 -type special -category advanced -default undef}
	{option -popover -reflect 0 -type special -category advanced -default undef}
	{option -relief -reflect 1 -type relief -category advanced -default sunken}
	{option -scrollbars -reflect 0 -type special -category advanced -default w}
	{option -searchcase -reflect 0 -type special -category advanced -default 1}
	{option -selectbackground -reflect 0 -type color -category advanced -default {[default color SystemHighlight]}}
	{option -selectborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -selectforeground -reflect 0 -type color -category advanced -default {[default color SystemHighlightText]}}
	{option -setgrid -reflect 0 -type boolean -category advanced -default 0}
	{option -spacing1 -reflect 0 -type pixels -category advanced -default 0}
	{option -spacing2 -reflect 0 -type pixels -category advanced -default 0}
	{option -spacing3 -reflect 0 -type pixels -category advanced -default 0}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -tabs -reflect 0 -type string -category advanced -default {}}
	{option -takefocus -reflect 0 -type boolean -category basic -default undef}
	{option -tile -reflect 0 -type special -category advanced -default undef}
	{option -title -reflect 0 -type string -category advanced -default Pod}
	{option -width -reflect 0 -type integer -category advanced -default 80}
	{option -wrap -reflect 0 -type wrap -category advanced -default word}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default {}}
	{option -yscrollcommand -reflect 0 -type command -category advanced -default {}}
    }

::widget::define Perl MDI -lang perl -version 8.0 \
    -requires Tk::MDI -image frame.gif -equivalent "Tk frame" \
    -options {
	{option -arrowimage -reflect 0 -type special -category advanced -default undef}
	{option -auto -reflect 0 -type special -category advanced -default 0}
	{option -background -reflect 1 -type color -category basic -default {[default color SystemButtonFace]}}
	{option -bell -reflect 0 -type special -category advanced -default 1}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -browsecmd -reflect 0 -type special -category advanced -default undef}
	{option -case -reflect 0 -type special -category advanced -default 1}
	{option -colorstate -reflect 0 -type special -category advanced -default undef}
	{option -command -reflect 0 -type command -category basic -default undef}
	{option -cursor -reflect 0 -type cursor -category basic -default xterm}
	{option -disabledtile -reflect 0 -type special -category advanced -default undef}
	{option -dup -reflect 0 -type special -category advanced -default 1}
	{option -exportselection -reflect 0 -type boolean -category basic -default 1}
	{option -font -reflect 0 -type font -category basic -default {{MS Sans Serif} 8}}
	{option -foreground -reflect 0 -type color -category basic -default Black}
	{option -foregroundtile -reflect 0 -type special -category advanced -default undef}
	{option -highlightbackground -reflect 0 -type color -category advanced -default {[default color SystemButtonFace]}}
	{option -highlightcolor -reflect 0 -type color -category advanced -default {[default color SystemWindowFrame]}}
	{option -highlightthickness -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertbackground -reflect 0 -type color -category advanced -default {[default color SystemWindowText]}}
	{option -insertborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -insertofftime -reflect 0 -type {integer {0 300 50}} -category advanced -default 300}
	{option -insertontime -reflect 0 -type {integer {0 300 50}} -category advanced -default 600}
	{option -insertwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 2}
	{option -invalidcommand -reflect 0 -type command -category advanced -default undef}
	{option -justify -reflect 0 -type justify -category advanced -default left}
	{option -label -reflect 0 -type string -category basic -default undef}
	{option -labelActivetile -reflect 0 -type special -category advanced -default undef}
	{option -labelAnchor -reflect 0 -type special -category advanced -default center}
	{option -labelBackground -reflect 0 -type special -category advanced -default {[default color SystemButtonFace]}}
	{option -labelBitmap -reflect 0 -type special -category advanced -default {}}
	{option -labelBorderwidth -reflect 0 -type special -category advanced -default 2}
	{option -labelCursor -reflect 0 -type special -category advanced -default {}}
	{option -labelDisabledtile -reflect 0 -type special -category advanced -default undef}
	{option -labelFont -reflect 0 -type special -category advanced -default {{MS Sans Serif} 8}}
	{option -labelForeground -reflect 0 -type special -category advanced -default {[default color SystemButtonText]}}
	{option -labelHeight -reflect 0 -type special -category advanced -default 0}
	{option -labelHighlightbackground -reflect 0 -type special -category advanced -default {[default color SystemButtonFace]}}
	{option -labelHighlightcolor -reflect 0 -type special -category advanced -default {[default color SystemWindowFrame]}}
	{option -labelHighlightthickness -reflect 0 -type special -category advanced -default 0}
	{option -labelImage -reflect 0 -type special -category advanced -default undef}
	{option -labelJustify -reflect 0 -type special -category advanced -default center}
	{option -labelOffset -reflect 0 -type special -category advanced -default {0 0}}
	{option -labelPadx -reflect 0 -type special -category advanced -default 1}
	{option -labelPady -reflect 0 -type special -category advanced -default 1}
	{option -labelRelief -reflect 0 -type special -category advanced -default flat}
	{option -labelTakefocus -reflect 0 -type special -category advanced -default 0}
	{option -labelTile -reflect 0 -type special -category advanced -default undef}
	{option -labelUnderline -reflect 0 -type special -category advanced -default -1}
	{option -labelVariable -reflect 0 -type special -category advanced -default undef}
	{option -labelWidth -reflect 0 -type special -category advanced -default 0}
	{option -labelWraplength -reflect 0 -type special -category advanced -default 0}
	{option -limit -reflect 0 -type special -category advanced -default undef}
	{option -listcmd -reflect 0 -type special -category advanced -default undef}
	{option -listwidth -reflect 0 -type special -category advanced -default undef}
	{option -match -reflect 0 -type special -category advanced -default 0}
	{option -offset -reflect 0 -type custom -category advanced -default {0 0}}
	{option -relief -reflect 1 -type relief -category advanced -default sunken}
	{option -selectbackground -reflect 0 -type color -category advanced -default {[default color SystemHighlight]}}
	{option -selectborderwidth -reflect 0 -type {pixels {0 4 1}} -category advanced -default 0}
	{option -selectforeground -reflect 0 -type color -category advanced -default {[default color SystemHighlightText]}}
	{option -show -reflect 0 -type string -category advanced -default undef}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -takefocus -reflect 0 -type boolean -category basic -default undef}
	{option -textvariable -reflect 0 -type variable -category basic -default {}}
	{option -tile -reflect 0 -type special -category advanced -default undef}
	{option -validate -reflect 0 -type validate -category advanced -default undef}
	{option -validatecommand -reflect 0 -type command -category advanced -default undef}
	{option -width -reflect 0 -type integer -category advanced -default 20}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default {}}
    }
}
