// SpecTcl generated class Demo1, version 0.01

import java.awt.*;

public class Demo1 extends Demo1App {		

// a slot to hold an arbitrary object pointer that can
// be filled in by the app. and referenced in actions
public Object arg;

public Panel frame_1;
public Label label_1;
public Button button_1;
public Button button_2;
public Label label_2;
public TextField entry_1;

//methods to support form introspection
public static String names[] = {
	"frame_1","label_1","button_1","button_2","label_2","entry_1",
};
public String[] getNames() {
	return names;
}

//There should be an easier way to do this
public Object[] getWidgets() {
	Object[] list = new Object[6];
	list[0] = frame_1;
	list[1] = label_1;
	list[2] = button_1;
	list[3] = button_2;
	list[4] = label_2;
	list[5] = entry_1;
	return list;
}

public void init() {

	// main panel
	GridBagLayout grid = new GridBagLayout();
	int rowHeights[] = {0,30,30,30};
	int columnWidths[] = {0,30,30};
	double rowWeights[] = {0.0,0.0,0.0,0.0};
	double columnWeights[] = {0.0,0.0,0.0};
	grid.rowHeights = rowHeights;
	grid.columnWidths = columnWidths;
	grid.rowWeights = rowWeights;
	grid.columnWeights = columnWeights;

	// container frame_1 in this.
	GridBagLayout frame_1_grid = new GridBagLayout();
	int frame_1_rowHeights[] = {0,30};
	int frame_1_columnWidths[] = {0,30,30};
	double frame_1_rowWeights[] = {0.0,0.0};
	double frame_1_columnWeights[] = {0.0,0.0,0.0};
	frame_1_grid.rowHeights = frame_1_rowHeights;
	frame_1_grid.columnWidths = frame_1_columnWidths;
	frame_1_grid.rowWeights = frame_1_rowWeights;
	frame_1_grid.columnWeights = frame_1_columnWeights;

	frame_1 = new Panel();
	this.add(frame_1);

	label_1 = new Label();
	label_1.setFont(new Font("Helvetica",Font.PLAIN + Font.BOLD , 16));
	label_1.setText("Demo 1");
	this.add(label_1);

	button_1 = new Button();
	button_1.setFont(new Font("Helvetica",Font.PLAIN + Font.BOLD , 16));
	button_1.setLabel("Yes");
	frame_1.add(button_1);

	button_2 = new Button();
	button_2.setFont(new Font("Helvetica",Font.PLAIN + Font.BOLD , 16));
	button_2.setLabel("No");
	frame_1.add(button_2);

	label_2 = new Label();
	label_2.setFont(new Font("Helvetica",Font.PLAIN + Font.BOLD , 16));
	label_2.setText("stuff:");
	this.add(label_2);

	entry_1 = new TextField(20);
	entry_1.setFont(new Font("Helvetica",Font.PLAIN , 16));
	this.add(entry_1);

	// Geometry management
	GridBagConstraints con = new GridBagConstraints();
	reset(con);
	con.gridx = 1;
	con.gridy = 3;
	con.gridwidth = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(frame_1, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 1;
	con.gridwidth = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(label_1, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 1;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	frame_1_grid.setConstraints(button_1, con);

	reset(con);
	con.gridx = 2;
	con.gridy = 1;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	frame_1_grid.setConstraints(button_2, con);

	reset(con);
	con.gridx = 1;
	con.gridy = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(label_2, con);

	reset(con);
	con.gridx = 2;
	con.gridy = 2;
	con.anchor = GridBagConstraints.CENTER;
	con.fill = GridBagConstraints.NONE;
	grid.setConstraints(entry_1, con);


	// Resize behavior management and parent heirarchy
	setLayout(grid);
	frame_1.setLayout(frame_1_grid);

	// Give the application a chance to do its initialization
	super.init();
}

public boolean handleEvent(Event event) {
	if (event.target == button_1 && event.id == event.ACTION_EVENT) {
		my_action("yes button");
	} else
	if (event.target == button_2 && event.id == event.ACTION_EVENT) {
		my_action("no button");
	} else
	if (event.target == entry_1 && event.id == event.ACTION_EVENT) {
		my_action(entry_1.getText());
	} else
	if (event.id==event.KEY_ACTION && event.key==event.F4 && event.modifiers==event.ALT_MASK) {  // Alt-F4 always exits
		System.exit(3);
	} else
		return super.handleEvent(event);
	return true;
}

public static void main(String[] args) {
    Frame f = new Frame("Demo1 Test");
    Demo1 win = new Demo1();
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
