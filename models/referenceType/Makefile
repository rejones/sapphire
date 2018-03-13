SPIN=spin
CFLAGS=-O2
SPIN_GEN_FLAGS=-a
SPIN_CHECK_FLAGS=-m1000000 -a -f -i
PML=referenceType.pml
BIN=referenceType.bin
GSTR='warning\|error\|states'

.SUFFIXES: .pml .bin

check: check-safety check-consistency check-termination

clean:
	rm -f $(BIN)
	rm -f pan.*
	rm -f *.trail
	rm -f *.[012]
	rm -f _spin_nvr.tmp

.pml.bin:
	$(SPIN) $(SPIN_GEN_FLAGS) $<
	$(CC) $(CFLAGS) -o $@ pan.c
	rm -f pan.*

check-safety: $(BIN)
	./$< $(SPIN_CHECK_FLAGS) -N p_safety0  | tee $@.0 | grep $(GSTR)
	./$< $(SPIN_CHECK_FLAGS) -N p_safety1  | tee $@.1 | grep $(GSTR)
	./$< $(SPIN_CHECK_FLAGS) -N p_safety2  | tee $@.2 | grep $(GSTR)
	rm -f _spin_nvr.tmp $(PML).trail

check-consistency: $(BIN)
	./$< $(SPIN_CHECK_FLAGS) -N p_consistency0  | tee $@.0 | grep $(GSTR)
	./$< $(SPIN_CHECK_FLAGS) -N p_consistency1  | tee $@.1 | grep $(GSTR)
	./$< $(SPIN_CHECK_FLAGS) -N p_consistency2  | tee $@.2 | grep $(GSTR)
	rm -f _spin_nvr.tmp $(PML).trail

check-termination: $(BIN)
	./$< $(SPIN_CHECK_FLAGS) -N p_termination | tee $@.0 | grep $(GSTR)
	rm -f _spin_nvr.tmp $(PML).trail
