JAVA NOTES

Introduction

SpecTcl is a GUI builder for Tcl/TK.  It was designed to permit
application specific extensions to be added to the builder.  This
current release includes an application specific extension to generate
java/awt code instead of Tcl/TK code, but the integration between
SpecTcl and Java isn't perfect.

See INSTALL.JAVA in this directory for installation instructions

See license.terms for the SpecJava licensing terms

The java support is enabled by using the "specJava" script to add in
the java support. It adds a -java flag to the SpecTcl command line.

The widgets names on the palette are currently the *tcl* names, and
not the *java* classes, even though the generated code uses the proper
java names.

The application behavior is added by entering java code in the
"action" entry of the property sheet for each widget.

Stephen Uhler
stephen.uhler@sun.com
