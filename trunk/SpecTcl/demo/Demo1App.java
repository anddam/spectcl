// helper class for generated class test, version 0.01

import java.awt.*;
public abstract class Demo1App extends java.applet.Applet {		

// These methods are always defined by the SpecJava generated class
abstract String[] getNames();
abstract Object[] getWidgets();


// this gets called after the GUI init method
public void init() {
	System.out.println("My init");
}

// This gets called to handle all events not handled by the GUI class
public boolean handleEvent(Event event) {
	System.out.println("Unhandled event: " + event);
	return false;
}

// Define any methods here that will be called by the GUI actions

public void my_action(String s) {
	System.out.println("my action: " + s);
}
}
