////////////////////////////////////////////////////////////////////////////
//
// @(#)EmbeddedAppletStub.java	1.1 25 Jan 1996 09:41:30
//
// Copyright 25 Jan 1996 Sun Microsystems, Inc. All Rights Reserved
//
////////////////////////////////////////////////////////////////////////////

import java.applet.*;
import java.net.*;
import java.util.Hashtable;

/* Class to provide support for Applets embedded as Panels
   inside other Applets.  Each of these has its own parameters,
   but gets the rest of its state from the containing applet.
   */
public class EmbeddedAppletStub implements AppletStub {

private Applet applet;
private Hashtable parms;

public EmbeddedAppletStub(Applet a, Hashtable p) {
    parms = p;
    applet = a;
}

public boolean isActive() {
    return applet.isActive();
}

public URL getDocumentBase() {
    return applet.getDocumentBase();
}

public URL getCodeBase() {
    return applet.getCodeBase();
}

public String getParameter(String name) {
    return (String)parms.get(name);
}

public AppletContext getAppletContext() {
    return applet.getAppletContext();
}

public void appletResize(int w, int h) {
}

}
