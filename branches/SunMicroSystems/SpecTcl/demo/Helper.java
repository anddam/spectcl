/*
 * Helper class for simple database app
 * This example demonstrates one method of hooking SpecJava code
 * into an application.  The instance variable "db" is used as a
 * handle to call database methods from the "action" entries of the
 * user interface fields.  The "gui" variable is a kludge to let
 * this class have full access to the SpecJava generated class
 */

import java.awt.*;
public abstract class Helper extends java.applet.Applet {		

// These methods are always defined by the SpecJava generated class
abstract String[] getNames();
abstract Object[] getWidgets();

protected Database db;
protected Demo2 gui;

/*
 * Initialization function for application.  This gets called as soon
 * as the GUI is created.
 */

public void init() {
	db = new Database("Demo2.db");
	gui = (Demo2) this;
}

/*
 * This sample method is used to package user interface stuff
 * for dispatch to the "database engine".
 */

public void getData() {
	String value = (String) db.get(gui.name.getText());
	if (value == null) {
		gui.message.setText("Key not found in database");
	} else {
		gui.phone.setText(value);
		gui.message.setText("");
	}
}
}
