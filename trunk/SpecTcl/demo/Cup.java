// cup animation

import java.awt.*;


public class Cup extends Animator {

public void init(java.applet.Applet a) {
    java.util.Hashtable p = new java.util.Hashtable();
    p.put("PAUSE", "100");
    p.put("REPEAT", "true");
    p.put("IMAGESOURCE", "./images");
	p.put("IMAGES", "1|2|3|1|2|3|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|10|11|12|13|14|15|10|11|12|13|14|15|10|11|12|13|14|15|10|11|12|13|14|15|10|11|12|13|14|15");
    setStub(new EmbeddedAppletStub(a, p));
	super.init();
	// This is not technically correct to call this here.
	super.start();
}
}
