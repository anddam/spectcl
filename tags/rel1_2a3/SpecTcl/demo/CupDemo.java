// SpecTcl generated class CupDemo, version 0.01

import java.awt.*;

public class CupDemo extends java.applet.Applet {		

// a slot to hold an arbitrary object pointer that can
// be filled in by the app. and referenced in actions
public Object arg;

public Label label_2;
public Checkbox radiobutton_1;
public CheckboxGroup type = new CheckboxGroup();
public Cup canvas_1;
public Checkbox radiobutton_2;
public Checkbox radiobutton_3;
public Checkbox radiobutton_4;
public Button button_2;

//methods to support form introspection
public static String names[] = {
	"label_2","type","radiobutton_1","canvas_1","radiobutton_2","radiobutton_3","radiobutton_4","button_2",
};
public String[] getNames() {
	return names;
}

//There should be an easier way to do this
public Object[] getWidgets() {
	Object[] list = new Object[8];
	list[0] = label_2;
	list[1] = type;
	list[2] = radiobutton_1;
	list[3] = canvas_1;
	list[4] = radiobutton_2;
	list[5] = radiobutton_3;
	list[6] = radiobutton_4;
	list[7] = button_2;
	return list;
}

public void init() {

	// main panel
	GridBagLayout grid = new GridBagLayout();
	int rowHeights[] = {0,30,5,30,30,30,30};
	int columnWidths[] = {0,30,26};
	double rowWeights[] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0};
	double columnWeights[] = {0.0,0.0,0.0};
	grid.rowHeights = rowHeights;
	grid.columnWidths = columnWidths;
	grid.rowWeights = rowWeights;
	grid.columnWeights = columnWeights;

	label_2 = new Label();
	label_2.setText("Choose your beverage");
	this.add(label_2);

	radiobutton_1 = new Checkbox();
	radiobutton_1.setLabel("water");
	radiobutton_1.setCheckboxGroup(type);
	this.add(radiobutton_1);

	canvas_1 = new Cup();
	canvas_1.init(this);	// Cup initialization
	canvas_1.setBackground(new Color(48830/256,48830/256,48830/256));
	this.add(canvas_1);

	radiobutton_2 = new Checkbox();
	radiobutton_2.setLabel("milk");
	radiobutton_2.setCheckboxGroup(type);
	this.add(radiobutton_2);

	radiobutton_3 = new Checkbox();
	radiobutton_3.setLabel("tea");
	radiobutton_3.setCheckboxGroup(type);
	this.add(radiobutton_3);

	radiobutton_4 = new Checkbox();
	radiobutton_4.setLabel("other");
	radiobutton_4.setCheckboxGroup(type);
	this.add(radiobutton_4);

	button_2 = new Button();
	button_2.setLabel("OK");
	this.add(button_2);

	// Geometry management
	GridBagConstraints con = new GridBagConstraints();
	reset(con);
	con.gridx = 1;
	con.gridy = 1;
	con.gridwidth = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(label_2, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 2;
	con.anchor = GridBagConstraints.WEST;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(radiobutton_1, con);

	reset(con);
	con.gridx = 2;
	con.gridy = 2;
	con.gridheight = 4;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.BOTH;
	grid.setConstraints(canvas_1, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 3;
	con.anchor = GridBagConstraints.WEST;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(radiobutton_2, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 4;
	con.anchor = GridBagConstraints.WEST;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(radiobutton_3, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 5;
	con.anchor = GridBagConstraints.WEST;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(radiobutton_4, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 6;
	con.gridwidth = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(button_2, con);


	// Resize behavior management and parent heirarchy
	setLayout(grid);

	// Give the application a chance to do its initialization
	super.init();
}

public boolean handleEvent(Event event) {
	if (event.target == button_2 && event.id == event.ACTION_EVENT) {
		System.exit(1);
	} else
	if (event.id==event.KEY_ACTION && event.key==event.F4 && event.modifiers==event.ALT_MASK) {  // Alt-F4 always exits
		System.exit(3);
	} else
		return super.handleEvent(event);
	return true;
}

public static void main(String[] args) {
    Frame f = new Frame("CupDemo Test");
    CupDemo win = new CupDemo();
    win.init();
    f.add("Center", win);
    f.pack();
    f.show();
}

private void reset(GridBagConstraints con) {
    con.gridx = GridBagConstraints.RELATIVE;
    con.gridy = GridBagConstraints.RELATIVE;
    con.gridwidth = 1;
    con.gridheight = 1;
 
    con.weightx = 0;
    con.weighty = 0;
    con.anchor = GridBagConstraints.CENTER;
    con.fill = GridBagConstraints.NONE;
 
    con.insets = new Insets(0, 0, 0, 0);
    con.ipadx = 0;
    con.ipady = 0;
}

}
