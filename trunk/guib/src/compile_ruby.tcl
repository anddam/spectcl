# compile_ruby.tcl --
#
#	This file implements ruby/tk code generation and testing
#
# Copyright (c) 2006 ActiveState Software Inc
#
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# For lack of a better place, the tcl language init code is here
namespace eval ::ruby {}
namespace eval ::compile::ruby {}

# ::ruby::init --
#
#   Called whenever Tcl is being used as the target language (Tk 8.3)
#
# Arguments:
#   args	comments
# Results:
#   Returns ...
#
proc ::ruby::init {version interp args} {
    variable interpreter $interp

    if {$interp == "" || ![file exists $interp]} {
	set interpreter [auto_execok ruby]
    }

    set ::P(file_suffix)	".ui"	;# user interface file suffix
    set ::P(target_suffix)	"_ui.rb";# generated code file suffix
    set ::P(include_suffix)	".rb"	;# included code file suffix
}

proc ::ruby::interpreter {{interp ""} args} {
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
proc ::compile::ruby::init {ver args} {
    # ruby SPECIFIC
    variable use_images ; catch {unset use_images} ; array set use_images {}
    variable uid 0
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
# Results:
#   Returns string in form ready to be placed in ""ed script.
#
proc ::compile::ruby::quote {str} {
    # [[=]] is the marker to indicate user-exact syntax.
    if {[string range $str 0 4] eq {[[=]]}} {
	return [string range $str 5 end]
    } elseif {[string is double -strict $str]} {
	# int or double, don't quote
	return $str
    } elseif {0 && ![string is ascii $str]} {
	# Contains high-bit chars - we translate to utf-8 automatically
    }
    if {$str eq "nil"} {
	# bareword 'nil' keyword
	return $str
    } else {
	# use single quotes to allow \ interpolation
	return \"$str\"
    }
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
proc ::compile::ruby::comment {txt {prenew 2} args} {
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
proc ::compile::ruby::command {prefix name arglist body {desc ""} args} {
    variable indent

    set script ""
    append script "${indent}# $name --\n${indent}#\n"
    if {$desc != ""} {
	append script [comment $desc 0]
    } else {
	append script "${indent}#   add comments here ...\n"
    }
    if {0} {
	# This is mostly just *args
	append script "${indent}#\n${indent}# ARGS:\n"
	if {![llength $arglist]} {
	    append script "${indent}#    <NONE>\n"
	} else {
	    foreach arg $arglist {
		append script "${indent}#    $arg\n"
	    }
	}
    } else {
    }
    append script "${indent}def ${name}($arglist)\n$body\n${indent}end\n"
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
proc ::compile::ruby::option {cmd name option value args} {
    # ruby process textvariables
    variable use_images
    variable use_vars
    variable uid

    # get variable refs to be TkVariable
    if {[string match "-*variable" $option] && [string match "@*" $value]} {
	lappend use_vars $value
    }
    if {$option eq "-image" && $value ne ""} {
	# This image should already be created by name, but the name
	# may be a relative path - ensure it's "relatively absolute"
	set img @image[incr uid]
	if {[file pathtype $value] eq "relative"} {
	    set use_images($value) [list $img "File.dirname(__FILE__) + '/$value'"]
	} else {
	    set use_images($value) [list $img "'$value'"]
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
proc ::compile::ruby::require {type w args} {
    # We want to check the require type to get package require's right
    variable REQS
    set req [::widget::get $type requires]
    if {$req eq "Tk"} {
	# ruby uses a lower-case tk
	set REQS($req) "tk"
    } elseif {$req eq "icons"} {
	set REQS($req) "tkextlib/ICONS"
    } elseif {$req eq "Img"} {
	set REQS($req) "tkextlib/tkimg"
    } elseif {$req eq "tkdnd"} {
	set REQS($req) "tkextlib/tkDND"
    } elseif {$req eq "Tkhtml"} {
	set REQS($req) "tkextlib/tkHTML"
    } else {
	set REQS($req) "tkextlib/[string tolower $req]"
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
proc ::compile::ruby::targetHeader {file uifile prefix args} {
    variable REQS

    append script [::compile::fileHeader $file $uifile] \
	"# THIS IS AN AUTOGENERATED FILE AND SHOULD NOT BE EDITED.\n" \
	"# The associated callback file should be modified instead.\n" \
	"#\n\n" \
	"# Use UTF-8 encoding\n" \
	"\$KCODE = 'U'\n\n"

    append script "require 'tk'\n"
    foreach grp [array names REQS] {
	if {$grp ne "Tk"} { append script "require '$REQS($grp)'\n" }
    }
    append script "\n"

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
proc ::compile::ruby::targetFooter {prefix args} {
    return "\n"
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
proc ::compile::ruby::includeHeader {file uifile prefix args} {
    set script ""
    if {[string equal $::tcl_platform(platform) "unix"]} {
	append script [unix_stub]
    }
    append script [::compile::fileHeader $file $uifile] \
	    "# This file is auto-generated.  Only the code within\n" \
	    "#    '# BEGIN USER CODE (global|class)'\n" \
	    "#    '# END USER CODE (global|class)'\n" \
	    "# and code inside the callback defs will be round-tripped.\n" \
	    "#\n\n"

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
proc ::compile::ruby::uiProcBegin {prefix args} {
    variable indent [string repeat " " 4]
    variable use_images
    variable use_vars

    # This is output when we want to create a stand-alone script
    set baseclass [string toupper $prefix 0 0]_ui

    append script "class ${baseclass}\n"
    append script "  def initialize(root)\n"
    append script "${indent}@root = root\n"
    # These come from -(text)variables - we need to create magic linked vars
    foreach var [lsort -unique $use_vars] {
	append script "${indent}$var = TkVariable.new\n"
    }
    foreach img [lsort -dictionary [array names use_images]] {
	# This image should already be created by name
	set id [lindex $use_images($img) 0]
	set fn [lindex $use_images($img) 1]
	append script "${indent}$id = TkPhotoImage.new('file' => $fn)\n"
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
proc ::compile::ruby::uiProcEnd {args} {
    variable indent ""
    # end initialize def and class
    return "  end\nend\n"
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
proc ::compile::ruby::widget {type name master options args} {
    variable indent
    variable widget_cmds
    variable use_images

    # start of widget command
    set wcmd [::widget::get $type instance]

    set script ""
    append script "${indent}@$name = ${wcmd}.new(${master},"

    # setting of options
    set in2 "${indent}  "
    foreach {opt value} $options {
	set opt [string trimleft $opt -]
	if {[regexp command $opt]} {
	    # XXX VALIDATE
	    if {[string match "< * >" $value]} {
		switch [lindex $value 1] {
		    scroll {
			set w [::widget::data [lindex $value 2] ID]
			# XXX Does this get the right scope?
			set value "lambda { |*args| @$w.[lindex $value 3] *args }"
		    }
		    command {
			set value "lambda { |*args| [lindex $value 2]_[lindex $value 3] *args }"
		    }
		}
	    } elseif {$value == ""} {
		# This is for stub functions
		set value "lambda { ${name}_$opt }"
	    } elseif {![regexp {^(proc|lambda)\s*\{} $value]} {
		# No 'lambda { ... }' wrapping - make sure it's a deferred proc
		set value "lambda { $value }"
	    }
	    append widget_cmds "\n${indent}@$name.configure(\n${in2}'$opt' => $value\n${indent})"
	} elseif {[string match "*variable" $opt]} {
	    append script "\n${in2}'$opt' => $value,"
	} elseif {$opt eq "image" && $value ne ""} {
	    # This image should already be created by name
	    append script "\n${in2}'$opt' => [lindex $use_images($value) 0],"
	} else {
	    append script "\n${in2}'$opt' => [quote $value],"
	}
    }

    # no trailing comma allowed
    set script [string trimright $script ,]
    # end of widget command
    append script "\n${indent})\n"

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
proc ::compile::ruby::bindtags {type name tags args} {
    variable indent
    variable bindtags

    append bindtags "${indent}@$name.bindtags($tags)\n"
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
proc ::compile::ruby::postWidgets {args} {
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
    # Note: user needs to use rubyish tags here:
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
proc ::compile::ruby::menu {master type options args} {
    variable indent

    set script ""
    append script "${indent}@$master.add\('$type',"
    foreach {opt value} $options {
	set opt [string trimleft $opt -]
	if {$opt eq "menu"} {
	    append script "\n${indent}  '$opt' => @$value,"
	} elseif {[regexp command $opt]} {
	    # Don't quote *command* values
	    if {![regexp {^(proc|lambda)\s*\{} $value]} {
		# No 'lambda { ... }' wrapping - make sure it's a deferred proc
		set value "lambda { $value }"
	    }
	    append script "\n${indent}  '$opt' => $value,"
	} else {
	    append script "\n${indent}  '$opt' => [quote $value],"
	}
    }
    set script [string trimright $script ,]
    append script "\n${indent}\)\n"

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
proc ::compile::ruby::attachmenu {name args} {
    variable indent

    set script ""
    append script "${indent}@root.configure('menu' => @$name)\n"
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
proc ::compile::ruby::geometry {name master row column options args} {
    variable indent

    set script ""

    append script "${indent}@$name.grid(\n"
    append script "${indent}  'in'     => $master,\n"
    append script "${indent}  'column' => $column,\n"
    append script "${indent}  'row'    => $row"
    foreach {opt value} $options {
	set opt [string trimleft $opt -]
	append script ",\n${indent}  '$opt' => [quote $value]"
    }
    append script "\n${indent})\n"

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
proc ::compile::ruby::resizing {master dim weights minsizes pads args} {
    variable indent

    set script ""

    # We start at 1, although it is 0-based, to allow for
    # the expert user to fiddle with padding the 0 index.
    set index 0
    foreach weight $weights \
	    size   $minsizes \
	    pad    $pads {
	# original ruby gen limits weight to max 1.
	append script "${indent}TkGrid.${dim}configure($master,\
		[incr index],\
		'weight' => $weight, 'minsize' => $size, 'pad' => $pad)\n"
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
proc ::compile::ruby::standalone {prefix args} {
    variable indent "  "
    set indent2 $indent$indent
    set customclass [string toupper $prefix 0 0]
    set baseclass   ${customclass}_ui
    set script "\n# Standalone Code Initialization - DO NOT EDIT\n#\n"
    append script "if \$0 == __FILE__
${indent}begin
${indent2}userinit
${indent}rescue NameError
${indent2}\# Ignore userinit not being defined
${indent}end
${indent}root = Tk.root
${indent}root.title('$prefix')
${indent}dlg = ${customclass}.new(root)\n
${indent}\#root.protocol('WM_DELETE_WINDOW', lambda { exit })
${indent}begin
${indent2}run
${indent}rescue NameError
${indent2}\# Ignore run not being defined
${indent}end
${indent}Tk.mainloop
end
"

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
proc ::compile::ruby::translate {name} {
    if {$name == "" || [::gui::isContainer $name]} {
	return @root
    } else {
	return @$name
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
proc ::compile::ruby::test {name {validate ""} args} {
    set exe $::ruby::interpreter
    if {![file exists $exe]} {
	if {$exe == ""} {
	    status_message "No known ruby interpreter"
	} else {
	    status_message "Invalid ruby interpreter \"$exe\""
	}
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

    # We will capture both stdout and stderr in the fileevent
    if {[catch {open "|[list $exe] \"$file\" 2>@1" r+} fid]} {
	::compile::runlog "Execution failed for \"$file\":\n$fid\n"
	busy_off "Execution failed for \"$file\""
	kill_test
	return 0
    } else {
	set ::ruby::fid $fid
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
proc ::compile::ruby::kill_test {args} {
    if {[info exists ::ruby::fid]} {
	catch {kill [pid $::ruby::fid]}
	catch {close $::ruby::fid}
	unset ::ruby::fid
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
proc ::compile::ruby::isTestRunning {args} {
    return [info exists ::ruby::fid]
}

# parseCallbacks --
#
#	parses the callbacks code.
#
# Arguments:
#
proc ::compile::ruby::parseCallbacks {code} {
    variable CMDS ; array unset CMDS

    # this regexp parses "[ws]def[ws]funcName(args)\n...[ws]end\n"
    # ensure all non-greedy matches
    set defRE {(\s*?)def\s+(\w+)\s*?\(([^\)]*?)\)\n(.*?)\1end\M}

    foreach {match ws name arglist body} [regexp -all -inline $defRE $code] {
	# XXX Should we trim out empty bodies?
	set CMDS($name) [list $arglist $body]
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
proc ::compile::ruby::parseInclude {prefix file} {
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

    variable CODE ; array unset CODE
    variable CMDS ; array unset CMDS

    # Catch all code with user/callback code comment blocks
    set exp {(?w)^(\s*)\# BEGIN (USER|CALLBACK) CODE( ?)(\w*)\n(.*)^\1\# END \2 CODE\3\4$}

    set blocks [regexp -all -inline $exp $data]
    if {[llength $blocks]} {
	foreach {match space type s name code} $blocks {
	    if {$type eq "USER"} {
		set CODE($name) [string trimright $code]
	    } elseif {$type eq "CALLBACK"} {
		parseCallbacks [string trimright $code]
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
proc ::compile::ruby::compileInclude {
    prefix autocmds uiFile targetFile includeFile
} {

    # populated by parseInclude
    variable CMDS ; array unset CMDS
    variable CODE ; array unset CODE

    if {[file exists $includeFile] && [file size $includeFile]} {
	# This may return an error, which I let filter up at this point
	parseInclude $prefix $includeFile
    }

    set targetModule [file rootname [file tail $targetFile]]
    set customclass  [string toupper $prefix 0 0]
    set baseclass    ${customclass}_ui

    # This will contain the end script
    set script ""

    # Allow for language specific code generation initialization
    append script [init include $includeFile]

    # Script header
    append script [includeHeader $includeFile $uiFile $prefix]

    # Include ui generated file if one was specified.
    append script "\# Add script's directory to lib load path\n"
    append script "\$:.unshift File.dirname(__FILE__)\n"
    append script "require '$targetModule'\n"
    # Require Tk after UI class in case we use utf-8 strings
    # As the .ui file will add the magic $KCODE='u'
    append script "require 'tk'\n"

    # User code block - global
    append script "\n# BEGIN USER CODE global\n"
    if {[info exists CODE(global)]} {
	append script $CODE(global)
    }
    append script "\n# END USER CODE global\n"

    variable indent "  "
    append script "\nclass ${customclass} < $baseclass\n"
    # Ruby will automatically call the super for us
    #append script "${indent}def initialize(root)\n"
    #append script "${indent}${indent}super\n"
    #append script "${indent}end\n"

    # Callback code block
    append script "\n${indent}# BEGIN CALLBACK CODE\n" \
	"${indent}# ONLY EDIT CODE INSIDE THE def FUNCTIONS.\n"
    foreach cmd [lsort -dictionary $autocmds] {
	append script "\n"
	# Create main proc
	if {[llength $cmd] == 2} {
	    # This is the $widget $option variety
	    foreach {widget option} $cmd break
	    set name    "${widget}_[string trimleft ${option} -]"
	    set arglist "*args"
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
    append script "\n${indent}# END CALLBACK CODE\n"

    # User code block - class
    append script "\n${indent}# BEGIN USER CODE class\n"
    if {[info exists CODE(class)]} {
	append script $CODE(class)
    }
    append script "\n${indent}# END USER CODE class\n"
    append script "end\n"

    # Standalone code block
    append script [standalone $prefix]

    return $script
}
