	GUIB (Formerly ActiveState GUI Builder)
	version 3.0

	http://sourceforge.net/projects/spectcl/

Guib is a Tk user interface builder for several of the languages that
support the Tk toolkit, including:

	Perl/Tk
	Perl/Tkx
	Python/Tkinter
	Ruby/Tk
	Tcl/Tk

It runs on any platform that Tcl/Tk runs on.  Guib is designed for making
GUIs easier to prototype and build.

Guib is open source (under the Tcl license).  It was in development by
ActiveState as part of the Komodo IDE (http://www.activestate.com/Komodo),
and released into open source in November, 2006.

Guib was originally based on SpecTcl, but became a complete rewrite over
time.  It's open source home is with SpecTcl on SourceForge, as the guib
module.

Guib requires Tcl 8.4 plus a few extensions.  ActiveTcl 8.4.11+ will
suffice to run it.  It can be run simply with:

	wish /path/to/src/startup.tcl

In the tools/ subdirectory there is a buildkit.tcl script that will
assemble a single-file executable for deployment to machines without Tcl
installed.

Planned work (TODO):

 * Create an extension to ActiveState's Komodo 4 IDE to allow Komodo users
   to reintroduce GUI Builder integration.
