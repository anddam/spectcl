DOC=menueditor.HTML save.HTML

# Make automatically generated documentation
doc: $(DOC)

clean:
	-rm $(DOC)

.SUFFIXES: .HTML .tk .tcl
 
.tk.HTML:
	robodoc $< $@ HTML

.tcl.HTML:
	robodoc $< $@ HTML

