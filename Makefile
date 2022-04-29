.PHONY: all clean

all: work/work-obj93.cf

WORKDIR=work

$(WORKDIR):
	mkdir $@

WAVESDIR=waves

$(WAVESDIR):
	mkdir $@

RTL_SRC=$(wildcard ./rtl/*)
TBS_SRC=$(wildcard ./tbs/*)

GHDL=ghdl
GHDLFLAGS=--workdir=$(WORKDIR) --ieee=synopsys

$(WORKDIR)/work-obj93.cf: $(RTL_SRC) $(TBS_SRC) $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(RTL_SRC) $(TBS_SRC)

$(WAVESDIR)/%.ghw: ./tbs/%.vhdl $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) $*
	$(GHDL) -r $(GHDLFLAGS) $* --ieee-asserts=disable --wave=$@

ARCH_TEST_DIR=../riscv-arch-test/

export TARGETDIR ?= $(shell pwd)/arch-test/
export XLEN=32
export RISCV_TARGET=leaf

.PHONY: arch-test
arch-test: $(WORKDIR)/work-obj93.cf
	$(MAKE) -C $(ARCH_TEST_DIR) clean build
	$(GHDL) -m $(GHDLFLAGS) core_tb
	bins=$$(find $(ARCH_TEST_DIR)/work/rv32i_m/I/ -name "*.bin"); \
	for bin in $$bins; do \
        test=$$(basename -s .elf.bin $$bin); \
        echo "running test: $$test"; \
        $(GHDL) -r $(GHDLFLAGS) core_tb --max-stack-alloc=0 --ieee-asserts=disable -gPROGRAM_FILE=$$bin -gDUMP_FILE=$(ARCH_TEST_DIR)/work/rv32i_m/I/$$test.signature.output -gMEM_SIZE=2097152; \
    done
	$(MAKE) -C $(ARCH_TEST_DIR) verify clean

BOOTSRC=./sw/boot.S
BINDIR=./bins

RV_CC=riscv32-unknown-elf-gcc
RV_CFLAGS=-nostartfiles

$(BINDIR):
	mkdir $@;

$(BINDIR)/boot: $(BOOTSRC) $(BINDIR)
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x0 $(BOOTSRC) -o $@;
#	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $(BOOTSRC) -o $@;

$(BINDIR)/boot.bin: $(BINDIR)/boot
	riscv32-unknown-elf-objcopy -O binary $(BINDIR)/boot $(BINDIR)/boot.bin

# $(BINDIR)/hello: sw/hello.S $(BINDIR)
# 	$(RV_CC) $(RV_CFLAGS) -Ttext 0x200 sw/hello.S -o $@;

# $(BINDIR)/hello: sw/crt0.S sw/hello.c $(BINDIR)
# 	$(RV_CC) $(RV_CFLAGS) -T sw/fwu.ld sw/crt0.S sw/hello.c -o $@

clean:
	rm -rf work;
	rm -rf waves;
# rm -rf bins;

# simulator development
SIM_SRC=$(wildcard ./sim/*.vhdl)
$(WAVESDIR)/sim.ghw: $(SIM_SRC) $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -i $(GHDLFLAGS) $(SIM_SRC);
	$(GHDL) -m $(GHDLFLAGS) sim;
	$(GHDL) -r $(GHDLFLAGS) sim --max-stack-alloc=0 --ieee-asserts=disable --wave=$@ -gPROGRAM_FILE=$(PROGRAM_FILE) -gDUMP_FILE=$(DUMP_FILE) -gMEMORY_SIZE=2097152;

.PHONY: compliance-test
compliance-test: $(WORKDIR)/work-obj93.cf
	$(MAKE) -C $(ARCH_TEST_DIR) build;
	$(GHDL) -i $(GHDLFLAGS) $(SIM_SRC);
	$(GHDL) -m $(GHDLFLAGS) sim;
	bins=$$(find $(ARCH_TEST_DIR)/work/rv32i_m/I/ -name "*.bin"); \
	for bin in $$bins; do \
        test=$$(basename -s .elf.bin $$bin); \
        echo "running test: $$test"; \
        $(GHDL) -r $(GHDLFLAGS) sim --max-stack-alloc=0 --ieee-asserts=disable -gPROGRAM_FILE=$$bin -gDUMP_FILE=$(ARCH_TEST_DIR)/work/rv32i_m/I/$$test.signature.output -gMEMORY_SIZE=2097152; \
    done
	$(MAKE) -C $(ARCH_TEST_DIR) verify