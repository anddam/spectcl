# perl_widgets.tcl --
#
# Copyright (c) 2006 ActiveState Software Inc
# Copyright (c) 2011 Leonid Landsman, leonid.landsman@nih.gov, leonid.landsman@gmail.com
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# Tk::DirSelect
# Tk::FontDialog

::widget::define MWidget Table -lang r -version 8.5 \
    -requires Tktable -image listbox.gif -equivalent "Tk listbox" \
    -options {
	{option -anchor -reflect 0 -type anchor -category advanced -default center}
	{option -autoclear -reflect 0 -type special -category advanced -default 0}
	{option -background -reflect 1 -type color -category basic -default {[default color SystemButtonFace]}}
	{option -bordercursor -reflect 0 -type cursor -category advanced -default crosshair}
	{option -borderwidth -reflect 1 -type {pixels {0 4 1}} -category advanced -default 1}
	{option -browsecommand -reflect 0 -type special -category advanced -default {}}
	{option -cache -reflect 0 -type special -category advanced -default 0}
	{option -colorigin -reflect 0 -type special -category advanced -default 0}
	{option -cols -reflect 0 -type special -category advanced -default 10}
	{option -colseparator -reflect 0 -type special -category advanced -default {	}}
	{option -colstretchmode -reflect 0 -type colstretchmode -category advanced -default none}
	{option -coltagcommand -reflect 0 -type special -category advanced -default {}}
	{option -colwidth -reflect 0 -type special -category advanced -default 10}
	{option -command -reflect 0 -type command -category basic -default {}}
	{option -cursor -reflect 0 -type cursor -category basic -default xterm}
	{option -drawmode -reflect 0 -type drawmode -category advanced -default compatible}
	{option -ellipsis -reflect 0 -type ellipsis -category advanced -default {}}
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
	{option -invertselected -reflect 0 -type boolean -category advanced -default 0}
	{option -ipadx -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -ipady -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -justify -reflect 0 -type justify -category advanced -default left}
	{option -maxheight -reflect 0 -type special -category advanced -default 600}
	{option -maxwidth -reflect 0 -type special -category advanced -default 800}
	{option -multiline -reflect 0 -type boolean -category advanced -default 1}
	{option -padx -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -pady -reflect 0 -type {pixels {0 6 1}} -category advanced -default 0}
	{option -relief -reflect 1 -type relief -category advanced -default sunken}
	{option -resizeborders -reflect 0 -type resizeborders -category advanced -default both}
	{option -rowheight -reflect 0 -type special -category advanced -default 1}
	{option -roworigin -reflect 0 -type special -category advanced -default 0}
	{option -rows -reflect 0 -type special -category advanced -default 10}
	{option -rowseparator -reflect 0 -type special -category advanced -default {	}}
	{option -rowstretchmode -reflect 0 -type rowstretchmode -category advanced -default none}
	{option -rowtagcommand -reflect 0 -type special -category advanced -default {}}
	{option -selectioncommand -reflect 0 -type special -category advanced -default {}}
	{option -selectmode -reflect 0 -type selectmode -category basic -default browse}
	{option -selecttitles -reflect 0 -type boolean -category advanced -default 0}
	{option -selecttype -reflect 0 -type selecttype -category advanced -default cell}
	{option -sparsearray -reflect 0 -type boolean -category advanced -default 1}
	{option -state -reflect 0 -type state -category advanced -default normal}
	{option -takefocus -reflect 0 -type boolean -category basic -default {}}
	{option -titlecols -reflect 0 -type special -category advanced -default 0}
	{option -titlerows -reflect 0 -type special -category advanced -default 0}
	{option -usecommand -reflect 0 -type boolean -category advanced -default 0}
	{option -variable -reflect 0 -type variable -category basic -default {}}
	{option -validate -reflect 0 -type validate -category advanced -default 0}
	{option -validatecommand -reflect 0 -type command -category advanced -default {}}
	{option -width -reflect 0 -type integer -category advanced -default 0}
	{option -wrap -reflect 0 -type boolean -category advanced -default 0}
	{option -xscrollcommand -reflect 0 -type command -category advanced -default {}}
	{option -yscrollcommand -reflect 0 -type command -category advanced -default {}}
    }
