CFLAGS=-O3
SPIN=spin
PANFLAGS=-m1000000

all: hashcode.exe hashcode-alg.exe

check: hashcode.log hashcode-alg.log hashcode-alg-hash0.log hashcode-alg-hash1.log

%.exe: %.c
	$(CC) $(CFLAGS) -o $@ $<

%.c: %.pml
	$(SPIN) -a $<
	mv pan.c $@

hashcode.log: hashcode.exe
	./$< $(PANFLAGS) -N p_consistency > $@

hashcode-alg.log: hashcode-alg.exe
	./$< $(PANFLAGS) -N p_consistency > $@

hashcode-alg-hash0.log: hashcode-alg.exe
	./$< $(PANFLAGS) -N p_hash0 > $@

hashcode-alg-hash1.log: hashcode-alg.exe
	./$< $(PANFLAGS) -N p_hash1 > $@

