// SpecTcl generated class Demo2, version 0.01

import java.awt.*;

public class Demo2 extends Helper {		

// a slot to hold an arbitrary object pointer that can
// be filled in by the app. and referenced in actions
public Object arg;

public Panel frame_1;
public Button button_2;
public Label label_1;
public Button button_3;
public Button button_4;
public Button button_1;
public Label label_2;
public TextField name;
public Label label_3;
public TextField phone;
public Label message;

//methods to support form introspection
public static String names[] = {
	"frame_1","button_2","label_1","button_3","button_4","button_1","label_2","name","label_3","phone","message",
};
public String[] getNames() {
	return names;
}

//There should be an easier way to do this
public Object[] getWidgets() {
	Object[] list = new Object[11];
	list[0] = frame_1;
	list[1] = button_2;
	list[2] = label_1;
	list[3] = button_3;
	list[4] = button_4;
	list[5] = button_1;
	list[6] = label_2;
	list[7] = name;
	list[8] = label_3;
	list[9] = phone;
	list[10] = message;
	return list;
}

// Application specific widget data
private static String check_private[] = {
	null, null, null, null, null, null, null, null, "a*", null, "999-9999", null, 
};
public String[] check() {
	return check_private;
}


public void init() {

	// main panel
	GridBagLayout grid = new GridBagLayout();
	int rowHeights[] = {0,30,30,30,5,30,13};
	int columnWidths[] = {0,30,30};
	double rowWeights[] = {0.0,0.0,0.0,0.0,1.0,0.0,0.0};
	double columnWeights[] = {0.0,0.0,1.0};
	grid.rowHeights = rowHeights;
	grid.columnWidths = columnWidths;
	grid.rowWeights = rowWeights;
	grid.columnWeights = columnWeights;

	// container frame_1 in this.
	GridBagLayout frame_1_grid = new GridBagLayout();
	int frame_1_rowHeights[] = {0,30};
	int frame_1_columnWidths[] = {0,30,30,30,5,30};
	double frame_1_rowWeights[] = {0.0,0.0};
	double frame_1_columnWeights[] = {0.0,0.0,0.0,0.0,1.0,0.0};
	frame_1_grid.rowHeights = frame_1_rowHeights;
	frame_1_grid.columnWidths = frame_1_columnWidths;
	frame_1_grid.rowWeights = frame_1_rowWeights;
	frame_1_grid.columnWeights = frame_1_columnWeights;

	frame_1 = new Panel();
	this.add(frame_1);

	button_2 = new Button();
	button_2.setLabel("get");
	frame_1.add(button_2);

	label_1 = new Label();
	label_1.setFont(new Font("Helvetica",Font.PLAIN + Font.BOLD , 14));
	label_1.setText("Sample database app");
	this.add(label_1);

	button_3 = new Button();
	button_3.setLabel("set");
	frame_1.add(button_3);

	button_4 = new Button();
	button_4.setFont(new Font("Helvetica",Font.PLAIN + Font.BOLD , 12));
	button_4.setLabel("save");
	frame_1.add(button_4);

	button_1 = new Button();
	button_1.setLabel("quit");
	frame_1.add(button_1);

	label_2 = new Label();
	label_2.setText("name");
	this.add(label_2);

	name = new TextField(20);
	this.add(name);

	label_3 = new Label();
	label_3.setText("phone");
	this.add(label_3);

	phone = new TextField(20);
	this.add(phone);

	message = new Label();
	message.setText(".");
	this.add(message);

	// Geometry management
	GridBagConstraints con = new GridBagConstraints();
	reset(con);
	con.gridx = 1;
	con.gridy = 5;
	con.gridwidth = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.HORIZONTAL;
	grid.setConstraints(frame_1, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 1;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	frame_1_grid.setConstraints(button_2, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 1;
	con.gridwidth = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(label_1, con);

	reset(con);
	con.gridx = 2;
	con.gridy = 1;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	frame_1_grid.setConstraints(button_3, con);

	reset(con);
	con.gridx = 3;
	con.gridy = 1;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	frame_1_grid.setConstraints(button_4, con);

	reset(con);
	con.gridx = 5;
	con.gridy = 1;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	frame_1_grid.setConstraints(button_1, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 2;
	con.anchor = GridBagConstraints.EAST;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(label_2, con);

	reset(con);
	con.gridx = 2;
	con.gridy = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.HORIZONTAL;
	grid.setConstraints(name, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 3;
	con.anchor = GridBagConstraints.EAST;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(label_3, con);

	reset(con);
	con.gridx = 2;
	con.gridy = 3;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.HORIZONTAL;
	grid.setConstraints(phone, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 6;
	con.gridwidth = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.HORIZONTAL;
	grid.setConstraints(message, con);


	// Resize behavior management and parent heirarchy
	setLayout(grid);
	frame_1.setLayout(frame_1_grid);

	// Give the application a chance to do its initialization
	super.init();
}

public boolean handleEvent(Event event) {
	if (event.target == button_2 && event.id == event.ACTION_EVENT) {
		getData();
	} else
	if (event.target == button_3 && event.id == event.ACTION_EVENT) {
		db.put(name.getText(),phone.getText());
	} else
	if (event.target == button_4 && event.id == event.ACTION_EVENT) {
		db.write();message.setText("saved");
	} else
	if (event.target == button_1 && event.id == event.ACTION_EVENT) {
		System.exit(0);
	} else
	if (event.id==event.KEY_ACTION && event.key==event.F4 && event.modifiers==event.ALT_MASK) {  // Alt-F4 always exits
		System.exit(3);
	} else
		return super.handleEvent(event);
	return true;
}

// code sourced from Demo2.include.java
//  This code is inserted into the SpecJava class
//  directly.  It comes from the <project>.include.java
//  file in the current directory.  It can be editted either
//  with your favorite text editor, or via the "edit code"
//  option of the edit menu.


public static void main(String[] args) {
    Frame f = new Frame("Demo2 Test");
    Demo2 win = new Demo2();
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
