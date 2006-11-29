# compile_tkx.tcl --
#
#	This file implements perl/tkx code generation and testing
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# We need Tclx for the 'kill' command across platforms.
package require Tclx

namespace eval ::perltkx {}

# ::perltkx::init --
#
#   Called whenever Perl is being used as the target language
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::perltkx::init {version interp args} {
    variable interpreter $interp

    if {$interp == "" || ![file exists $interp]} {
	set interpreter [auto_execok perl]
    }

    set ::P(file_suffix)	".ui"	;# user interface file suffix
    set ::P(target_suffix)	"_ui.pm";# generated code file suffix
    set ::P(include_suffix)	".pl"	;# included code file suffix
}

proc ::perltkx::interpreter {{interp ""} args} {
    variable interpreter
    if {$interp != ""} {
	set interpreter $interp
    }
    return $interpreter
}

namespace eval ::compile::perltkx {}

# init --
#
#   initialize for generating script in target language
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::init {ver args} {
    # PERL SPECIFIC
    # also gather up all the perl variables used to write a 
    # use vars at the beginning and satisfy `strict'
    variable use_images ; catch {unset use_images} ; array set use_images {}
    variable use_vars ""
    variable indent ""
    variable widget_cmds ""
    variable bindtags ""
    variable REQS ; catch {unset REQS} ; array set REQS {}
}

# quote --
#
#   Quotes an option value appropriate to the language.
#
# Arguments:
#   str		string to quote
#   opt		option name
# Results:
#   Returns string in form ready to be placed in ""ed script.
#
proc ::compile::perltkx::quote {str opt} {
    # [[=]] is the marker to indicate user-exact syntax.
    if {[string range $str 0 4] eq {[[=]]}} {
	return [string range $str 5 end]
    } elseif {[string is double -strict $str]} {
	# int or double, don't quote
	return $str
    } elseif {![string is ascii $str]} {
	# Contains high-bit chars - translate
	set out ""
	foreach c [split $str ""] {
	    scan $c %c val
	    if {$val > 127} {
		append out "\\x{[format %X $val]}"
	    } else {
		append out $c
	    }
	}
	set str $out
    }
    if {[regexp {\\\$|\\&} $str]} {
	# variable or function reference - don't quote
	return $str
    }
    set opt [string trimleft $opt -]
    variable ::config::CONFIG
    if {[info exists CONFIG($opt)]
	&& ($CONFIG($opt) eq "font" || $CONFIG($opt) eq "image")} {
	# These options may have values with funny chars, but aren't
	# input by users - so prevent escapes
	return '$str'
    }
    # By default, use single quotes to allow \ interpolation
    return \"$str\"
}

# comment --
#
#   return commented text
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::comment {txt {prenew 2} args} {
    variable indent
    regsub -all {(\n)(\s*)(\S)} $txt "\\1${indent}#\\2\\3" txt
    return "[string repeat "\n" $prenew]${indent}# [string trimleft $txt]\n"
}

# command --
#
#   return command given parameters
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::command {prefix name arglist body {desc ""} args} {
    set script ""
    append script "# $name --\n#\n"
    if {$desc != ""} {
	append script [comment $desc 0]
    } else {
	append script "#   add comments here ...\n"
    }
    if {0} {
	append script "#\n# ARGS:\n"
	if {![llength $arglist]} {
	    append script "#    <NONE>\n"
	} else {
	    foreach arg $arglist {
		append script "#    $arg\n"
	    }
	}
    }
    append script "#\nsub $name \{$body\}\n"
    return $script
}

# option --
#
#   Filter widget options to arrange for any necessary begin/end code
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::option {cmd name option value args} {
    variable use_images
    variable use_vars

    # parse every line for a perl var reference

    foreach {match var} [regexp -all -inline {\\(\$\w+)} $value] {
	lappend use_vars $var
    }
    if {$option eq "-image" && $value ne ""} {
	# This image should already be created by name, but the name
	# may be a relative path - ensure it's "relatively absolute"
	if {[file pathtype $value] eq "relative"} {
	    set use_images($value) "\$RealBin . '/$value'"
	} else {
	    set use_images($value) "'$value'"
	}
    }
}

# require --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::require {type w args} {
    # We want to check the require type to get package require's right
    variable REQS
    set req [::widget::get $type requires]
    if {$req eq "Tk"} {
	# do nothing - we require Tkx first by default
    } else {
	# Currently all other supported widgets are Tcl-based
	set REQS($req) "Tkx::package_require('$req');"
    }
}

# targetHeader --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::targetHeader {file uifile prefix args} {
    append script [::compile::fileHeader $file $uifile] \
	    "# THIS IS AN AUTOGENERATED FILE AND SHOULD NOT BE EDITED.\n" \
	    "# The associated callback file should be modified instead.\n" \
	    "#\n\n" \
	    "# Declare the package for this dialog\n" \
	    "package $prefix;\n" \
	    "\n"
    return $script
}

# targetFooter --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::targetFooter {prefix args} {
    return "\n1;\n"
}

# includeHeader --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::includeHeader {file uifile prefix args} {
    set script ""
    if {[string equal $::tcl_platform(platform) "unix"]} {
	append script [unix_stub]
    }
    append script [::compile::fileHeader $file $uifile] \
	    "# This file is auto-generated.  Only the code within\n" \
	    "#    '# BEGIN USER CODE'\n" \
	    "#    '# END USER CODE'\n" \
	    "# and code inside the callback subroutines will be round-tripped.\n" \
	    "# The subroutine name 'ui' is reserved.\n" \
	    "#\n\n" \
	    "# Declare the package for this dialog\n" \
	    "package $prefix;\n" \
	    "\n"
    return $script
}

# uiProcBegin --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::uiProcBegin {prefix args} {
    variable indent [string repeat " " 4]
    variable use_images
    variable use_vars
    variable REQS

    # This is output when we want to create a stand-alone script
    if {$use_vars != ""} {
	append script "use vars qw( [join $use_vars " "] );\n"
    }
    # Get the use statement we need - should at least include Tkx
    append script "use Tkx;\n"
    foreach grp [lsort [array names REQS]] {
	append script "$REQS($grp)\n"
    }
    append script "\n"

    append script "# ${prefix}::ui --\n" \
	    "#\n" \
	    "# ARGS:\n" \
	    "#   root     the parent window for this form\n" \
	    "#\n" \
	    "sub ${prefix}::ui \{\n" \
	    "${indent}our(\$root) = @_;\n"
    foreach img [lsort -dictionary [array names use_images]] {
	# This image should already be created by name
	append script "${indent}Tkx::image_create_photo('$img',\
		-file => $use_images($img));\n"
    }

    return $script
}

# uiProcEnd --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::uiProcEnd {args} {
    variable indent ""
    return "\}\n"
}

# widget --
#
#   Handles instantiation of a widget
#
# Arguments:
#   type	type of widget
#   name	name of widget
#   master	parent widget
#   options	list of {option value} pairs
# Results:
#   Returns script to instantiate widget
#
proc ::compile::perltkx::widget {type name master options args} {
    variable indent
    variable widget_cmds

    # start of widget command
    set wcmd [::widget::get $type instance]

    set script ""
    append script "${indent}our(\$$name) = \$root->new_$wcmd\("

    # setting of options
    set in2 "\t"
    foreach {opt value} $options {
	# In perl, sub and var refs \& and \$ should not be quoted
	# -<foo>command should also not have quoted args
	# To get scrollbars to work, we need to put all command options
	# at end of widget creation, after they are all defined
	if {[regexp command $opt]} {
	    if {[string match {*%[%BWMR]*} $value]} {
		# Here we replace the magic %-subs that we allow with the
		# actual values.  We have to be tricky to get each element
		# eval'ed at the right time in the correct context.
		#
		# We replace %% with itself to avoid %%W being replaced,
		# as string map consumes each char only once.
		# Using format with XPG-specifiers allows us to avoid a
		# lot of special char escaping and substitution.
		set charMap [list %% %% \
			%W %1\$s %B %2\$s %R %3\$s %M %4\$s]
		set value [format [string map $charMap $value] \
			\$base.$name \$base \$root $master]
	    } elseif {[string match "< * >" $value]} {
		switch [lindex $value 1] {
		    scroll {
			set w [::widget::data [lindex $value 2] ID]
			set value "\[ \$$w => [lindex $value 3] \]"
		    }
		    command {
			set value "\\&[lindex $value 2]_[lindex $value 3]"
		    }
		}
	    } elseif {$value == ""} {
		set value "\\&${name}_[string trimleft $opt -]"
	    }
	    append widget_cmds "\n${indent}\$$name->configure(\n${in2}$opt => $value\n${indent});"
	} else {
	    append script "\n${in2}$opt => [quote $value $opt],"
	}
    }

    # end of widget command
    append script "\n${indent}\);\n"

    return $script
}

# bindtags --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::bindtags {type name tags args} {
    variable indent
    variable bindtags

    append bindtags "${indent}\$$name->g_bindtags(\[$tags\]);\n"
    return ""
}

# postWidgets --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::postWidgets {args} {
    variable indent
    variable bindtags
    variable widget_cmds

    set script ""

    # ok, now we can set all the commands without worrying about 
    # undefined widgets

    if {$widget_cmds != ""} {
	append script "\n${indent}# widget commands\n$widget_cmds\n"
    }

    # print out any binding tags
    # Note: user needs to use Perlish tags here: 
    # $b for .b
    # $b->toplevel for .
    # 'all' for all
    # if b is a Button, ref($b) for Button
    # all put into a comma delimited list

    if {$bindtags != ""} {
	append script "\n${indent}# binding tags\n\n$bindtags\n"
    }

    return $script
}

# menu --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::menu {master type options args} {
    variable indent

    set script ""

    append script "${indent}\$$master->add_$type\("
    foreach {opt value} $options {
	if {$opt eq "-menu"} {
	    append script "\n\t$opt => \$$value,"
	} elseif {[regexp command $opt] && $value ne "exit"} {
	    # Don't quote command values, except if eq 'exit'
	    append script "\n\t$opt => $value,"
	} else {
	    append script "\n\t$opt => [quote $value $opt],"
	}
    }
    append script "\n${indent});\n"

    return $script
}

# attachmenu --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::attachmenu {name args} {
    variable indent

    set script ""
    append script "${indent}\$root->configure(-menu => \$$name)\n"
    return $script
}

# geometry --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::geometry {name master row column options args} {
    variable indent

    #set script "\n${indent}# $name geometry management\n"
    append script "${indent}\$$name->g_grid(\n"
    append script "\t-in     => $master,\n"
    append script "\t-column => $column,\n"
    append script "\t-row    => $row"
    foreach {opt value} $options {
	append script ",\n\t$opt => [quote $value $opt]"
    }
    append script "\n${indent});\n"

    return $script
}

# resizing --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::resizing {master dim weights minsizes pads args} {
    variable indent

    set script ""

    #append script "\n\n${indent}# $master resize behavior\n"
    # We start at 1, although it is 0-based, to allow for
    # the expert user to fiddle with padding the 0 index.
    set index 0
    foreach weight $weights \
	    size   $minsizes \
	    pad    $pads {
	# original perl gen limits weight to max 1.
	append script "${indent}$master->g_grid_${dim}configure([incr index],\
		-weight => $weight, -minsize => $size, -pad => $pad);\n"
    }

    return $script
}

# standalone --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::standalone {prefix args} {
    variable indent "    "
    set script "\n# Standalone Code Initialization - DO NOT EDIT\n#\n"
    # Call init
    append script "${prefix}::userinit() if defined &${prefix}::userinit;\n\n"
    append script "our(\$top) = Tkx::widget->new('.');\n"
    append script "\$top->g_wm_title('$prefix');\n"
    append script "${prefix}::ui(\$top);\n\n"
    append script "${prefix}::run() if defined &${prefix}::run;\n\n"
    append script "Tkx::MainLoop();\n"
    append script "\n1;\n"
    set indent ""

    return $script
}

# translate --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
# find the real master of this window, as the user may have changed its name.
proc ::compile::perltkx::translate {name} {
    if {$name == "" || [::gui::isContainer $name]} {
	return \$root
    } else {
	return \$$name
    }
}

# test --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::test {name {validate ""} args} {
    set exe $::perltkx::interpreter
    if {![file exists $exe]} {
	status_message "Invalid perl interpreter \"$exe\""
	return 0
    }

    # compute frame stacking and tabbing order
    set_frame_level $::W(FRAME)

    status_message "Starting test application"

    kill_test

    set file [::project::get include]

    busy_on "Running $exe $file ..."
    ::compile::runlog "Running $exe $file ...\n"
    update idletasks

    if {$validate == ""} { set validate [expr {![::api::IsInteractive]}] }
    if {$validate != 0} {
	# compile the app and see if the syntax is ok
	catch {exec $exe -c "$file"} msg
	if {![regexp {syntax OK} $msg]} {
	    ::compile::runlog "Error compiling $exe $file:\n$msg\n"
	    busy_off "Error compiling $exe $file"
	    return 0
	}
    }

    if {[catch {open "|[list $exe] \"$file\" 2>@1" r+} fid]} {
	::compile::runlog "Execution failed for \"$file\":\n$fid\n"
	busy_off "Perl Execution failed: $fid"
	kill_test
	return 0
    } else {
	set ::perltkx::fid $fid
	# Watch the test to see if the user kills it off without
	# using our Stop button.
	fconfigure $fid -blocking 0
	fileevent $fid readable [list ::compile::read_test $fid]
    }
    busy_off "Running $exe $file ..."
    return 1
}

# kill_test --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::kill_test {args} {
    if {[info exists ::perltkx::fid]} {
	catch {kill [pid $::perltkx::fid]}
	catch {close $::perltkx::fid}
	unset ::perltkx::fid
    }
    disable_kill_test
}

# isTestRunning --
#
#   ADD COMMENTS HERE
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::perltkx::isTestRunning {args} {
    return [info exists ::perltkx::fid]
}

# parseCallbacks --
#
#	parses the callback code.
#
# Arguments:
#  code
#
proc ::compile::perltkx::parseCallbacks {code} {
    variable CMDS

    set cmds [::compile::CmdSplit $code]
    foreach cmd $cmds {
	if {[string match "sub *" $cmd]} {
	    foreach {p name body} [string trimright $cmd ";"] break
	    # We own the 'ui' command
	    if {$name eq "ui"} continue
	    set CMDS($name) $body
	}
    }
}

# parseInclude --
#
#	parses the callbacks file.
#	this file may have user-defined code and must first be parsed
#	before we can write it out again.
#
# Arguments:
#
#  prefix	The procedure prefix (project name)
#  file		include file to parse
#
proc ::compile::perltkx::parseInclude {prefix file} {
    if {[catch {open $file r} fd]} {
	return -code error "Cannot open '$file' for reading:\n$fd"
    }

    # Here we would check the format if we used an ID
    set file [file tail $file]
    set line [gets $fd]
    set fmt  "# $file --*"
    if {![string match $fmt $line]} {
	set i 0
	if {[string match "#!/*" $line]} {
	    # Try to skip past a unix #!/bin/sh style header, not more
	    # than 5 lines though, looking for the id.
	    while {[gets $fd line] != -1 && [incr i] < 5} {
		if {[string match $fmt $line]} {
		    break
		}
	    }
	}
	if {$i == 0 || $i >= 5} {
	    # We never found the format id.
	    seek $fd 0
	    set answer [tk_messageBox -title "Overwrite Include File?" \
		    -type yesno -icon warning \
		    -message "Include file '$file' may not be in a parseable\
		    format.\nShall I attempt to parse anyway?"]
	    if {$answer == "no"} {
		close $fd
		return -code error "Aborted parsing of '$file'"
	    }
	}
    }

    # Read in the remaining data.
    set data [read $fd]
    close $fd

    variable CMDS ; array unset CMDS
    variable CODE ; array unset CODE

    # Catch all code with user/callback code comment blocks
    #set exp {(?w)^\# BEGIN (USER|CALLBACK) CODE( ?)(\w*)\n(.*)^\# END \1 CODE\2\3$}
    set exp {(?w)^\# BEGIN (USER|CALLBACK) CODE\n(.*)^\# END \1 CODE$}
    set blocks [regexp -all -inline $exp $data]
    if {[llength $blocks]} {
	foreach {match type code} $blocks {
	    if {$type eq "USER"} {
		set CODE(global) [string trim $code]
	    } elseif {$type eq "CALLBACK"} {
		parseCallbacks $code
	    } else {
		return -code error "Unexpected code block '$type'"
	    }
	}
    } else {
	# We are going to assume that this is older code that we will
	# try and convert the old way.  Start from first sub.
	regsub -- {\nsub .*$} $data {&} data
	parseCallbacks $data
    }
    return
}

# ::compile::$lang::compileInclude --
#
#	generate the callbacks file.
#	this file may have user-defined code and must first be parsed
#	before we can write it out again.
#
# Arguments:
#
#  prefix	The procedure prefix (project name)
#  autocmds	Commands that the app needs to have at least stubs for
#  uiFile	the unix file containing the ui description
#  targetFile	The language-specific file to write
#  includeFile	Optional include file
#
proc ::compile::perltkx::compileInclude {
    prefix autocmds uiFile targetFile includeFile
} {

    # populated by parseInclude
    variable CMDS ; array unset CMDS
    variable CODE ; array unset CODE

    if {[file exists $includeFile] && [file size $includeFile]} {
	# This may return an error, which I let filter up at this point
	parseInclude $prefix $includeFile
    }

    # This will contain the end script
    set script ""

    # Allow for language specific code generation initialization
    append script [init include $includeFile]

    # Script header
    append script [includeHeader $includeFile $uiFile $prefix]

    # Include ui generated file if one was specified.
    set module [file rootname [file tail $targetFile]]
    append script "# Locate this script so we can load the ui module\n" \
	"use FindBin qw(\$RealBin); use lib \$RealBin; use $module;\n"

    # User code block
    append script "\n# BEGIN USER CODE\n"
    if {[info exists CODE(global)]} {
	append script $CODE(global)
    }
    append script "\n# END USER CODE\n"

    # Callback code block
    append script "\n# BEGIN CALLBACK CODE\n" \
	"# ONLY EDIT CODE WITHIN THE SUB COMMANDS.\n"
    foreach cmd [lsort -dictionary $autocmds] {
	append script "\n"
	# Create main proc
	if {[llength $cmd] == 2} {
	    # This is the $widget $option variety
	    foreach {widget option} $cmd break
	    set name    "${widget}_[string trimleft ${option} -]"
	    set body    ""
	    set comment "Callback to handle \$$widget widget option $option"
	    if {[info exists CMDS($name)]} {
		set body $CMDS($name)
		# remove this reference after processing it
		unset CMDS($name)
	    }
	    append script [command $prefix $name "" $body $comment]
	} else {
	    # Don't know what to do with this yet
	    append script [comment "Callback to handle:\n$cmd"]
	}
    }
    foreach name [lsort -dictionary [array names CMDS]] {
	append script "\n"
	set body $CMDS($name)
	append script [command $prefix $name "" $body \
			   "Legacy command found in callback code.\
			    Add user comments inside body."]
    }
    append script "\n# END CALLBACK CODE\n"

    # Standalone code block
    append script [standalone $prefix]

    return $script
}
