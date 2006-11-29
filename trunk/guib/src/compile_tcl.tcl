# compile_tcl.tcl --
#
#	This file implements tcl code generation and testing
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# For lack of a better place, the tcl language init code is here
namespace eval ::tcl {}
namespace eval ::compile::tcl {}

# ::tcl::init --
#
#   Called whenever Tcl is being used as the target language (Tk 8.3)
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::tcl::init {version interp args} {
    variable interpreter $interp

    if {$interp == "" || ![file exists $interp]} {
	set interpreter [auto_execok wish]
    }

    set ::P(file_suffix)	".ui"	;# user interface file suffix
    set ::P(target_suffix)	"_ui.tcl";# generated code file suffix
    set ::P(include_suffix)	".tcl"	;# included code file suffix
}

proc ::tcl::interpreter {{interp ""} args} {
    variable interpreter
    if {$interp != ""} {
	set interpreter $interp
    }
    return $interpreter
}


# init --
#
#   initialize for generating script in target language
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::compile::tcl::init {ver args} {
    variable use_images ; catch {unset use_images} ; array set use_images {}
    variable indent ""
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
proc ::compile::tcl::quote {str opt} {
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
		append out \\u[format %.4X $val]
	    } else {
		append out $c
	    }
	}
	set str $out
    }
    set opt [string trimleft $opt -]
    variable ::config::CONFIG
    if {[info exists CONFIG($opt)]
	&& ($CONFIG($opt) eq "font" || $CONFIG($opt) eq "image")} {
	# These options may have values with funny chars, but aren't
	# input by users - so prevent escapes
	return [list $str]
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
proc ::compile::tcl::comment {txt {prenew 2} args} {
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
proc ::compile::tcl::command {prefix name arglist body {desc ""} args} {
    set script ""
    append script "# [list ${prefix}::$name] --\n#\n"
    if {$desc != ""} {
	append script [comment $desc 0]
    } else {
	append script "#   add comments here ...\n"
    }
    append script "#\n# ARGS:\n"
    if {[llength $arglist]} {
	append script "#    <NONE>\n"
    } else {
	foreach arg $arglist {
	    append script "#    [list $arg]\n"
	}
    }
    # Don't list-ify the body because if it uses \ line continuation,
    # the list stringify will output it as one line of escaped chars.
    append script "#\n[list proc ${prefix}::$name $arglist] {$body}\n"
    return $script
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
proc ::compile::tcl::targetHeader {file uifile prefix args} {
    variable REQS

    set script ""

    append script [::compile::fileHeader $file $uifile] \
	"# THIS IS AN AUTOGENERATED FILE AND SHOULD NOT BE EDITED.\n" \
	"# The associated callback file should be modified instead.\n" \
	"#\n\n" \
	"# Declare the namespace for this dialog\n" \
	"namespace eval [list $prefix] {}\n" \
	"\n"

    foreach grp [array names REQS] {
	if {$REQS($grp) ne ""} {
	    append script "package require [list $grp] $REQS($grp)\n"
	} else {
	    append script "package require [list $grp]\n"
	}
    }

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
proc ::compile::tcl::targetFooter {prefix args} {
    return ""
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
proc ::compile::tcl::includeHeader {file uifile prefix args} {
    set script ""
    if {[string equal $::tcl_platform(platform) "unix"]} {
	append script [unix_stub]
    }
    append script [::compile::fileHeader $file $uifile] \
	"# This file is auto-generated.  Only the code within\n" \
	"#    '# BEGIN USER CODE'\n" \
	"#    '# END USER CODE'\n" \
	"# and code inside the callback subroutines will be round-tripped.\n" \
	"# The proc names 'ui' and 'init' are reserved.\n" \
	"#\n\n" \
	"package require Tk [targetVersion]\n\n" \
	"# Declare the namespace for this dialog\n" \
	"namespace eval [list $prefix] {}\n" \
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
proc ::compile::tcl::uiProcBegin {prefix args} {
    variable indent [string repeat " " 4]
    variable use_images

    append script "# [list ${prefix}::ui] --\n" \
	"#\n" \
	"#   Create the UI for this dialog.\n" \
	"#\n" \
	"# ARGS:\n" \
	"#   root     the parent window for this form\n" \
	"#   args     a catch-all for other args, but none are expected\n"\
	"#\n" \
	"proc [list ${prefix}::ui] {root args} \{\n" \
	$indent "# this handles '.' as a special case\n" \
	$indent {set base [expr {($root == ".") ? "" : $root}]} "\n" \
	"${indent}variable ROOT \$root\n" \
	"${indent}variable BASE \$base\n" \
	"${indent}variable SCRIPTDIR ; \# defined in main script\n"
    foreach img [lsort -dictionary [array names use_images]] {
	# This image should already be created by name
	append script "${indent}image create photo [list $img] -file $use_images($img)\n"
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
proc ::compile::tcl::uiProcEnd {prefix args} {
    variable indent ""
    return "\}\n"
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
proc ::compile::tcl::option {cmd name option value args} {
    variable use_images

    if {$option eq "-image" && $value ne ""} {
	# This image should already be created by name, but the name
	# may be a relative path - ensure it's "relatively absolute"
	if {[file pathtype $value] eq "relative"} {
	    set use_images($value) "\[file join \$SCRIPTDIR [list $value]\]"
	} else {
	    set use_images($value) [list $value]
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
proc ::compile::tcl::require {type w args} {
    # We want to check the require type to get package require's right
    variable REQS
    set req [::widget::get $type requires]
    if {[llength $req] > 1} {
	set grp [lindex $req 0]
	set ver [lindex $req 1]
	set REQS($grp) $ver
    } else {
	set REQS($req) ""
    }
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
proc ::compile::tcl::widget {type name master options args} {
    variable indent

    # start of widget command
    set wcmd [::widget::get $type instance]

    append script "${indent}variable $name \[$wcmd \$BASE.$name"

    # process options
    set in2 " \\\n\t${indent}"
    foreach {opt value} $options {
	#
	# Do post-validity checking of options here
	# (like command, font, color, cursor, ...)
	#
	if {[regexp {command|variable} $opt]} {
	    if {[string match {*%[%BWMR]*} $value]} {
		# Here we replace the magic %-subs that we allow with the
		# actual values.  We have to be tricky to get each element
		# eval'ed at the right time in the correct context.
		#
		# %W   name of widget
		# %B   base name of parent
		# %R   name of root widget
		# %M   name of widget's geometry master
		#
		# We replace %% with itself to avoid %%W being replaced,
		# as string map consumes each char only once.
		# Using format with XPG-specifiers allows us to avoid a
		# lot of special char escaping and substitution.
		set charMap [list %% %% \
			%W %1\$s %B %2\$s %R %3\$s %M %4\$s]
		set value [format [string map $charMap $value] \
			\$BASE.$name \$BASE \$ROOT $master]
		set value "\[list $value\]"
	    } elseif {[regexp command $opt] && \
			  ($value == "" || [string match "< * >" $value])} {
		if {$value == ""} {
		    set value "\[namespace code \[list ${name}_[string trimleft $opt -]\]\]"
		} else {
		    switch [lindex $value 1] {
			scroll {
			    set w [::widget::data [lindex $value 2] ID]
			    set value "\[list \$BASE.[list $w [lindex $value 3]]\]"
			}
			command {
			    set value "\[namespace code \[list [lindex $value 2]_[lindex $value 3]\]\]"
			}
		    }
		}
	    } else {
		set value [quote $value $opt]
	    }
	} elseif {$opt eq "-menu"} {
	    set value "\"\$BASE.$name.$value\""
	} else {
	    set value [quote $value $opt]
	}
	append script "${in2}$opt $value"
    }

    # end of widget command
    append script "\]\n"

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
proc ::compile::tcl::bindtags {type name tags args} {
    variable indent
    variable bindtags

    append bindtags "${indent}bindtags \$BASE.$name [list $tags]\n"
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
proc ::compile::tcl::postWidgets {args} {
    variable indent
    variable bindtags

    # print out any binding tags
    if {$bindtags != ""} {
	return "\n${indent}# binding tags\n\n$bindtags\n"
    }
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
proc ::compile::tcl::menu {master type options args} {
    variable indent

    set script ""

    append script "${indent}\$BASE.$master add $type"
    foreach {opt value} $options {
	if {$opt eq "-menu"} {
	    append script " \\\n\t${indent}$opt \$BASE.$value"
	} else {
	    append script " \\\n\t${indent}$opt [quote $value $opt]"
	}
    }
    append script "\n"

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
proc ::compile::tcl::attachmenu {name args} {
    variable indent

    set script ""
    append script "${indent}\$ROOT configure -menu \$BASE.$name\n"
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
proc ::compile::tcl::geometry {name master row column options args} {
    variable indent

    set script ""

    #append script "\n\n${indent}# $name geometry management\n"
    append script "\n${indent}grid \$BASE.$name -in $master\
	    -row $row -column $column"
    foreach {opt value} $options {
	append script " \\\n\t${indent}$opt [quote $value $opt]"
    }

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
proc ::compile::tcl::resizing {master dim weights minsizes pads args} {
    variable indent

    set script ""

    #append script "\n\n${indent}# $master resize behavior\n"
    # We start at 1, although it is 0-based, to allow for
    # the expert user to fiddle with padding the 0 index.
    set index 0
    foreach weight $weights \
	    size   $minsizes \
	    pad    $pads {
	append script "${indent}grid ${dim}configure $master\
		[incr index] -weight $weight -minsize $size -pad $pad\n"
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
proc ::compile::tcl::standalone {prefix args} {
    variable indent

    # template for running ui file stand-alone
    set STANDALONE {
# %1$s::init --
#
#   Call the optional userinit and initialize the dialog.
#   DO NOT EDIT THIS PROCEDURE.
#
# Arguments:
#   root   the root window to load this dialog into
#
# Results:
#   dialog will be created, or a background error will be thrown
#
proc %1$s::init {root args} {
    # Catch this in case the user didn't define it
    catch {%1$s::userinit}
    if {[info exists embed_args]} {
	# we are running in the plugin
	%1$s::ui $root
    } elseif {$::argv0 == [info script]} {
	# we are running in stand-alone mode
	wm title $root %1$s
	if {[catch {
	    # Create the UI
	    %1$s::ui  $root
	} err]} {
	    bgerror $err ; exit 1
	}
    }
    catch {%1$s::run $root}
}
%1$s::init .
}
    return [format "$STANDALONE\n" [list $prefix]]
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
proc ::compile::tcl::test {name args} {
    # compute frame stacking and tabbing order
    set_frame_level $::W(FRAME)

    status_message "Starting test application"
    update idletasks

    kill_test
    set test [interp create test_interp]
    foreach {var val} {argv0 "" argv "" argc 0} {
	$test eval [list set $var $val]
    }
    # exit in the slave should be confined to deleting the slave
    interp alias $test exit {} ::compile::tcl::exit_interp $test

    set file [::project::get include]

    ::compile::runlog "Running $file ...\n"
    update idletasks

    set init [subst {
	load {} Tk
	tk appname "test_$name"
	wm title . "$name - $::gui::APPNAME"
	bind . <Destroy> {if {"%W" == "."} exit}
	wm protocol . WM_DELETE_WINDOW exit
	source [list $file]
	[list ${name}::ui] .
    }
    ]
    if {[catch {$test eval $init} msg]} {
	::compile::runlog "Error in user defined code:\n$msg\n"
	kill_test
	return 0
    }
    return 1
}

# exit in the slave should be confined to deleting the slave
#
proc ::compile::tcl::exit_interp {name args} {
    catch {
	$name eval {bind . <Destroy> {}}
	$name eval {destroy .}
    }
    catch {interp delete $name}
    disable_kill_test
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
proc ::compile::tcl::kill_test {args} {
    catch {test_interp eval exit}
    catch {interp delete test_interp}
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
proc ::compile::tcl::isTestRunning {args} {
    return [expr {[interp exists test_interp] && \
	    [test_interp eval [list info exists tk_version]]}]
}

# parseCallbacks --
#
#	parses the callback code.
#
# Arguments:
#  code
#
proc ::compile::tcl::parseCallbacks {code} {
    variable CMDS

    set cmds [::compile::CmdSplit $code]
    foreach cmd $cmds {
	if {[lindex $cmd 0] eq "proc"} {
	    foreach {p name arglist body} $cmd break
	    # stick all procs in our prefixed namespace
	    set name [namespace tail $name]
	    # beware reserved procs
	    if {$name eq "ui" || $name eq "init"} continue
	    set CMDS($name) [list $arglist $body]
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
proc ::compile::tcl::parseInclude {prefix file} {
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
	# try and convert the old way
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
proc ::compile::tcl::compileInclude {
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

    # Include ui generated file.
    set scriptvar [list ${prefix}::SCRIPTDIR]
    append script "# Source the ui file, which must exist\n" \
	"set $scriptvar \[file dirname \[info script\]\]\n" \
	"source \[file join \$$scriptvar [list [file tail $targetFile]]\]\n"

    # User code block
    append script "\n# BEGIN USER CODE\n"
    if {[info exists CODE(global)]} {
	append script $CODE(global)
    }
    append script "\n# END USER CODE\n"

    append script "\n# BEGIN CALLBACK CODE\n" \
	"# ONLY EDIT CODE INSIDE THE PROCS.\n"
    foreach cmd [lsort -dictionary $autocmds] {
	append script "\n"
	# Create main proc
	if {[llength $cmd] == 2} {
	    # This is the $widget $option variety
	    foreach {widget option} $cmd break
	    set name    "${widget}_[string trimleft ${option} -]"
	    set arglist "args"
	    set body    ""
	    set comment "Callback to handle $widget widget option $option"
	    if {[info exists CMDS($name)]} {
		foreach {arglist body} $CMDS($name) break
		# remove this reference after processing it
		unset CMDS($name)
	    }
	    append script [command $prefix $name $arglist $body $comment]
	} else {
	    # Don't know what to do with this yet
	    append script [comment "Callback to handle:\n$cmd"]
	}
    }
    foreach name [lsort -dictionary [array names CMDS]] {
	append script "\n"
	set arglist ""
	set body    ""
	foreach {arglist body} $CMDS($name) break
	append script [command $prefix $name $arglist $body \
			   "Legacy command found in callback code.\
			    Add user comments inside body."]
    }
    append script "\n# END CALLBACK CODE\n"

    # Standalone code block
    append script [standalone $prefix]

    return $script
}
