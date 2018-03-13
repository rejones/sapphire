CFLAGS=-O3 -DSAFETY
SPIN=spin
PANFLAGS=-m1000000


all:  preMark-TYPE1.exe preMark-TYPE2.exe

check: preMark-TYPE1.log preMark-TYPE2.log

preMark-TYPE1.c : preMark.pml
	$(SPIN) -a -E-UTYPE_II $<
	mv pan.c $@

preMark-TYPE2.c : preMark.pml
	$(SPIN) -a -E-DTYPE_II=1 $<
	mv pan.c $@

%.exe: %.c
	$(CC) $(CFLAGS) -o $@ $<

%.c: %.pml
	$(SPIN) -a $<
	mv pan.c $@

%.log: %.exe
	./$< $(PANFLAGS) > $@

