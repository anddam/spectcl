SpecJava installation instructions (For Unix)

1) unpack this distribution

2) edit the script: specJava and change the variables DIR and WISH
   to appropriate locations.  DIR is this directory. You may need
   to set the TCL_LIBRARY and TK_LIBRARY environment variables if
   your version of wish is not installed correctly.  For anyone in
   the "eng" domain, the current value for WISH should work OK.

3) put specJava somewhere in your path

4) Make sure a version of java is accessable from your path.  If java
   is installed in a non-standard way, then "java_init.tk" might need to be
   modified so specJava can find the Java documentation.

5) A version of tcl7.6 and tk4.2 or greater for your platform.

6) Type "specJava" to begin.

7) Create a new directory for your java project.  Make an interface, 
   and save it.  The .java file will be created.  use the 'Java' command
   from the commands menu to compile it.

Stephen Uhler, Ken Corey
spectcl@eng.sun.com
