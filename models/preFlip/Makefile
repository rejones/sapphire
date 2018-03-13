CFLAGS=-O3 -DSAFETY # -DREACH
SPIN=spin
PANFLAGS=-m1000000

all: preFlip-TYPE1.exe preFlip-TYPE2.exe

check: preFlip-TYPE1.log preFlip-TYPE2.log

preFlip-TYPE1.c: preFlip.pml
	$(SPIN) -a -E-UTYPE_II $<
	mv pan.c $@

preFlip-TYPE2.c: preFlip.pml
	$(SPIN) -a -E-DTYPE_II=1 $<
	mv pan.c $@

%.exe: %.c
	$(CC) $(CFLAGS) -o $@ $<

%.c: %.pml
	$(SPIN) -a $<
	mv pan.c $@

%.log: %.exe
	./$< $(PANFLAGS) > $@
