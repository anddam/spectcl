# SpecTcl, by S. A. Uhler and Ken Corey
# Copyright (c) 1994-1995 Sun Microsystems, Inc.
#
# See the file "license.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# go render a page.  We have to make sure we don't render one page while
# still rendering the previous one.

proc HMlink_callback {win {file history}} {
    global Help_dir tcl_platform P
    upvar #0 Help$win Help_message Hist$win Help_history
    append Help_history ""

    set P(delete_help) 0
    
    set fragment ""
    regexp {([^\#]*)\#(.+)} $file dummy file fragment
    if {$file == "" && $fragment != ""} {
	HMgoto $win $fragment
	return
    }
    
    if {[winfo exists $win]} {
	$win config -state normal
    }

    if {$file == "history"} {
	if {[llength $Help_history] <2} {
	    set Help_message "Already at first page"
	    if {[winfo exists $win]} {
		$win config -state disabled
	    }
	    return
	}
	set file [lindex $Help_history 1]
	set Help_history [lrange $Help_history 1 end]
    } elseif {[lindex $Help_history 0] != $file} {
	set Help_history "$file $Help_history"
    }
    
    HMreset_win $win
    if {$fragment != ""} {
	HMgoto $win $fragment
    }
    if {$tcl_platform(platform) == "macintosh"} {
	if {![catch {resource read TEXT $file} msg] ||
		![catch {resource getTEXT $file} msg]} {
	    HMparse_html $msg "HMrender $win"
	    HMset_state $win -stop 1
	} else {
	    set Help_message "Sorry, couldn't find help file $file"
	    if {[winfo exists @$win]} {
		$win config -state disabled
	    }
	    return
	}
    } else {
	set path [file join $Help_dir $file]
	if {[catch {set fd [open "$path" r]}]} {
	    set Help_message "Sorry, couldn't find help file $path"
	    if {[winfo exists $win]} {
		$win config -state disabled
	    }
	    return
	}
	HMparse_html [read $fd] "HMrender $win"

	# stop rendering previous page if busy
	HMset_state $win -stop 1
	close $fd
    }
    if {[winfo exists $win]} {
	$win config -state disabled
    }
    if {$P(delete_help)} {
#	destroy $win
    }
}

# supply an image callback function
# Read in an image if we don't already have one
# callback to library for display

proc HMset_image {win handle src} {
    global Help_dir tcl_platform pictures
    upvar #0 Help$win Help_message
    set image [file join $Help_dir $src]
    if {[lsearch [image names] Image_$image] >= 0} {
	HMgot_image $handle Image_$image
    } else {
	set Help_message "fetching image $src"
	update idletasks
	global TRANSPARENT_GIF_COLOR
	set TRANSPARENT_GIF_COLOR [$win cget -bg]
	if {$tcl_platform(platform) == "macintosh"} {
	    set image [image create photo Image_$image -data $pictures($src)]
	    unset pictures($src)
	} else {
	    catch {image create photo Image_$image -file $image} image
	}
	HMgot_image $handle $image
    }
}

# Lets invent a new HTML tag, just for fun.
# Change the color of the text. Use html tags of the form:
# <color value=blue> ... </color>
# We can invent a new tag for the display stack.  If it starts with "T"
# it will automatically get mapped directly to a text widget tag.

proc HMtag_color {win param text} {
	upvar #0 HM$win var
	set value bad_color
	HMextract_param $param value
	$win tag configure $value -foreground $value
	HMstack $win "" "Tcolor $value"
}

proc HMtag_/color {win param text} {
	upvar #0 HM$win var
	set value bad_color
	HMstack $win / "Tcolor {}"
}

# allow to dynamic text substitution, based on current values.
# Run text through "subst" to do variable substitutions

proc HMtag_subst {win param text} {
	global Tmp
	upvar $text data
	uplevel #0 "set Tmp \[subst -nobackslashes -nocommands [list $data]]"
	set data $Tmp
	unset Tmp
}

# downloading fonts can take a long time.  We'll override the default
# font-setting routine to permit better user feedback on fonts.  We'll
# keep our own list of installed fonts on the side, to guess when delays
# are likely

proc HMset_font {win tag font} {
	global Fonts
	upvar #0 Help$win Help_message
	if {![info exists Fonts($font)]} {
		set Fonts($font) 1
		set Help_message "downloading font [string range $font 0 30]..."
		update idletasks
	}
	set Help_message ""
	catch {$win tag configure $tag -font $font} message
}

# This is a vvariation of the netscape BODY tag to configure the page
# colors.  The following parameters are handled (each takes a color)
#  link:	the color of the links
#  text:	the text color
#  bgcolor:	the text background color
#  mark:	the color of the list markers

proc HMtag_body {win param text} {
	upvar #0 HM$win var
	foreach i {link text bgcolor mark} {
		if {[HMextract_param $param $i]} {
			switch $i {
				mark {
					catch {$win tag configure mark -foreground $mark}
				}
				link {
					catch {$win tag configure link -foreground $link}
				}
				text {
					catch {$win configure -fg $text}
				}
				bgcolor {
					catch {$win configure -bg $bgcolor}
				}
			}
		}
	}
}
