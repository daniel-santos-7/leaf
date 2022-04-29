WORKDIR=work

$(WORKDIR):
	mkdir $@

WAVESDIR=waves

$(WAVESDIR):
	mkdir $@

RTL_SRC=$(wildcard ./rtl/*.vhdl)
TBS_SRC=$(wildcard ./tbs/*.vhdl)
COMPLIANCE_SRC=$(wildcard ./compliance/*.vhdl)

GHDL=ghdl
GHDLFLAGS=--workdir=$(WORKDIR) --ieee=synopsys

$(WORKDIR)/work-obj93.cf: $(RTL_SRC) $(TBS_SRC) $(COMPLIANCE_SRC) $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(RTL_SRC) $(TBS_SRC) $(COMPLIANCE_SRC)

$(WAVESDIR)/%.ghw: ./tbs/%.vhdl $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) $*
	$(GHDL) -r $(GHDLFLAGS) $* --ieee-asserts=disable --wave=$@

RV_ARCH_TEST_DIR=../riscv-arch-test/

export TARGETDIR ?= $(shell pwd)/compliance/
export XLEN=32
export RISCV_TARGET=leaf

.PHONY: compliance-test
compliance-test: $(WORKDIR)/work-obj93.cf
	$(MAKE) -C $(RV_ARCH_TEST_DIR) build;
	$(GHDL) -m $(GHDLFLAGS) compliance;
	bins=$$(find $(RV_ARCH_TEST_DIR)/work/rv32i_m/I/ -name "*.bin"); \
	for bin in $$bins; do \
        test=$$(basename -s .elf.bin $$bin); \
        echo "running test: $$test"; \
        $(GHDL) -r $(GHDLFLAGS) compliance --max-stack-alloc=0 --ieee-asserts=disable -gPROGRAM_FILE=$$bin -gDUMP_FILE=$(RV_ARCH_TEST_DIR)/work/rv32i_m/I/$$test.signature.output -gMEMORY_SIZE=2097152; \
    done
	$(MAKE) -C $(RV_ARCH_TEST_DIR) verify

.PHONY: clean
clean:
	rm -rf $(WORKDIR);
	rm -rf $(WAVESDIR);