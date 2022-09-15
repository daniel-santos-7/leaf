GHDL = ghdl
GHDLFLAGS = --workdir=$(WORKDIR) --ieee=synopsys

WORKDIR  = work
WAVESDIR = waves

CPU_RTL  = $(wildcard ./cpu/rtl/*.vhdl)
CPU_TBS  = $(wildcard ./cpu/tbs/*.vhdl)
UART_RTL = $(wildcard ./uart/rtl/*.vhdl)
UART_TBS = $(wildcard ./uart/rtl/*.vhdl)
SOC_RTL  = $(wildcard ./soc/rtl/*.vhdl)
SOC_TBS  = $(wildcard ./soc/tbs/*.vhdl)
SIM_RTL  = $(wildcard ./sim/rtl/*.vhdl)

$(WORKDIR):
	mkdir $@

$(WAVESDIR):
	mkdir $@

$(WORKDIR)/work-obj93.cf: $(CPU_RTL) $(CPU_TBS) $(SIM_RTL) $(SOC_RTL) $(SOC_TBS) $(UART_RTL) $(UART_TBS) $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(CPU_RTL) $(CPU_TBS) $(SIM_RTL) $(SOC_RTL) $(SOC_TBS) $(UART_RTL) $(UART_TBS)

$(WAVESDIR)/%.ghw: ./**/tbs/%.vhdl $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) $*
	$(GHDL) -r $(GHDLFLAGS) $* --ieee-asserts=disable --wave=$@

$(WAVESDIR)/leaf_soc_tb.ghw: ./soc/tbs/leaf_soc_tb.vhdl $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) leaf_soc_tb
	$(GHDL) -r $(GHDLFLAGS) leaf_soc_tb --ieee-asserts=disable -gPROGRAM=$(BIN_FILE) --wave=$@

.PHONY: leaf_soc_tb
leaf_soc_tb: ./soc/tbs/leaf_soc_tb.vhdl $(WORKDIR)/work-obj93.cf
	$(GHDL) -m $(GHDLFLAGS) leaf_soc_tb
	$(GHDL) -r $(GHDLFLAGS) leaf_soc_tb --max-stack-alloc=0 --ieee-asserts=disable -gPROGRAM=$(BIN_FILE)

$(WAVESDIR)/sim.ghw: $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) sim;
	$(GHDL) -r $(GHDLFLAGS) sim --stop-time=1us --max-stack-alloc=0 --ieee-asserts=disable -gBIN_FILE=$(BIN_FILE) --wave=$@;

.PHONY: sim
sim: $(WORKDIR)/work-obj93.cf
	$(GHDL) -m $(GHDLFLAGS) sim;
	$(GHDL) -r $(GHDLFLAGS) sim --ieee-asserts=disable --max-stack-alloc=0 -gBIN_FILE=$(BIN_FILE);

RV_ARCH_TEST_DIR=../riscv-arch-test/
export TARGETDIR ?= $(shell pwd)/compliance/
export XLEN=32
export RISCV_TARGET=leaf

.PHONY: compliance-test
compliance-test: $(WORKDIR)/work-obj93.cf
	$(MAKE) -C $(RV_ARCH_TEST_DIR) build;
	$(GHDL) -m $(GHDLFLAGS) sim;
	bins=$$(find $(RV_ARCH_TEST_DIR)/work/rv32i_m/I/ -name "*.bin"); \
	for bin in $$bins; do \
        test=$$(basename -s .elf.bin $$bin); \
        echo "running test: $$test"; \
        $(GHDL) -r $(GHDLFLAGS) sim --max-stack-alloc=0 --ieee-asserts=disable -gBIN_FILE=$$bin | xxd -c 4 -p > $(RV_ARCH_TEST_DIR)/work/rv32i_m/I/$$test.signature.output; \
    done
	$(MAKE) -C $(RV_ARCH_TEST_DIR) verify

.PHONY: clean
clean:
	rm -rf $(WORKDIR) $(WAVESDIR)
	$(MAKE) -C $(RV_ARCH_TEST_DIR) clean;