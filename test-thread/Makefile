JAVAC = javac

CLASSES = \
	ComputeTask.class \
	EmptyTest.class \
	ListTask.class \
	TreeTask.class

all: $(CLASSES)

%.class: %.java
	$(JAVAC) -source 1.5 -target 1.5 $<

clean:
	rm -f *.class
