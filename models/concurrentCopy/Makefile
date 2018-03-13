CFLAGS=-O3 -DSAFETY -DREACH
SPIN=spin
PANFLAGS=-m1000000

all: concurrentCopy-STM-SINGLE.exe concurrentCopy-STM-DOUBLE.exe concurrentCopy-STM-REFERENCE.exe concurrentCopy-STMNOFENCE-SINGLE.exe concurrentCopy-STMNOFENCE-DOUBLE.exe concurrentCopy-STMNOFENCE-REFERENCE.exe concurrentCopy-CAS-SINGLE.exe concurrentCopy-CAS-DOUBLE.exe concurrentCopy-CAS-REFERENCE.exe

check: concurrentCopy-STM-SINGLE.log concurrentCopy-STM-DOUBLE.log concurrentCopy-STM-REFERENCE.log concurrentCopy-STMNOFENCE-SINGLE.log concurrentCopy-STMNOFENCE-DOUBLE.log concurrentCopy-STMNOFENCE-REFERENCE.log concurrentCopy-CAS-SINGLE.log concurrentCopy-CAS-DOUBLE.log concurrentCopy-CAS-REFERENCE.log

concurrentCopy-STM-SINGLE.c: concurrentCopy.pml
	$(SPIN) -a -E-DSTM=1 -E-UNO_FENCE -E-UREFERENCE -E-UDOUBLE_WORD $<
	mv pan.c $@

concurrentCopy-STM-DOUBLE.c: concurrentCopy.pml
	$(SPIN) -a -E-DSTM=1 -E-UNO_FENCE -E-UREFERENCE -E-DDOUBLE_WORD=1 $<
	mv pan.c $@

concurrentCopy-STM-REFERENCE.c: concurrentCopy.pml
	$(SPIN) -a -E-DSTM=1 -E-UNO_FENCE -E-DREFERENCE=1 -E-UDOUBLE_WORD $<
	mv pan.c $@

concurrentCopy-STMNOFENCE-SINGLE.c: concurrentCopy.pml
	$(SPIN) -a -E-DSTM=1 -E-DNO_FENCE=1 -E-UREFERENCE -E-UDOUBLE_WORD $<
	mv pan.c $@

concurrentCopy-STMNOFENCE-DOUBLE.c: concurrentCopy.pml
	$(SPIN) -a -E-DSTM=1 -E-DNO_FENCE=1 -E-UREFERENCE -E-DDOUBLE_WORD=1 $<
	mv pan.c $@

concurrentCopy-STMNOFENCE-REFERENCE.c: concurrentCopy.pml
	$(SPIN) -a -E-DSTM=1 -E-DNO_FENCE=1 -E-DREFERENCE=1 -E-UDOUBLE_WORD $<
	mv pan.c $@

concurrentCopy-CAS-SINGLE.c: concurrentCopy.pml
	$(SPIN) -a -E-USTM -E-UNO_FENCE -E-UREFERENCE -E-UDOUBLE_WORD $<
	mv pan.c $@

concurrentCopy-CAS-DOUBLE.c: concurrentCopy.pml
	$(SPIN) -a -E-USTM -E-UNO_FENCE -E-UREFERENCE -E-DDOUBLE_WORD=1 $<
	mv pan.c $@

concurrentCopy-CAS-REFERENCE.c: concurrentCopy.pml
	$(SPIN) -a -E-USTM -E-UNO_FENCE -E-DREFERENCE=1 -E-UDOUBLE_WORD $<
	mv pan.c $@

%.exe: %.c
	$(CC) $(CFLAGS) -o $@ $<

%.c: %.pml
	$(SPIN) -a $<
	mv pan.c $@

%.log: %.exe
	./$< $(PANFLAGS) > $@

