// Simple database management class (c) 1996, Sun Microsystems
// by C. Perdue and S. Uhler
// Extend the "properties" class to read and write hash tables from
// a file.

import java.util.*;
import java.io.*;
public class Database extends Properties {		

private File file;

public Database(String fileName) {
	read(fileName);
}

public boolean read(String fileName) {
	file = new File(fileName);
	try {
		FileInputStream fd = new FileInputStream(file);
		load(fd);
		return true;
	} catch(IOException error) {
		return false;
	}
}

public boolean write() {
	try {
		FileOutputStream fd = new FileOutputStream(file);
		save(fd,"Simple Database File");
		return true;
	} catch(IOException error) {
		return false;
	}
}

public boolean write(String fileName) {
	file = new File(fileName);
	return write();
}
}
