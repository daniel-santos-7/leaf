# leaf project

# VHDL simulator
GHDL = ghdl
GHDLFLAGS = --workdir=$(WORKDIR) --ieee=synopsys
GHDLXOPTS = --ieee-asserts=disable --max-stack-alloc=0

WORKDIR  = work
WAVESDIR = waves

CPU_RTL  = $(wildcard ./cpu/rtl/*.vhdl)
CPU_TBS  = $(wildcard ./cpu/tbs/*.vhdl)
UART_RTL = $(wildcard ./uart/rtl/*.vhdl)
UART_TBS = $(wildcard ./uart/rtl/*.vhdl)
SOC_RTL  = $(wildcard ./soc/rtl/*.vhdl)
SOC_TBS  = $(wildcard ./soc/tbs/*.vhdl)
SIM_RTL  = $(wildcard ./sim/rtl/*.vhdl)
SIM_TBS  = $(wildcard ./sim/tbs/*.vhdl)

RTL_SRC  = $(CPU_RTL) $(UART_RTL) $(SOC_RTL) $(SIM_RTL)
TBS_SRC  = $(CPU_TBS) $(UART_TBS) $(SOC_TBS) $(SIM_TBS)

PROGRAM ?= ./sw/hello_world/hello_world.bin

$(WORKDIR):
	mkdir $@

$(WAVESDIR):
	mkdir $@

$(WORKDIR)/work-obj93.cf: $(RTL_SRC) $(TBS_SRC) $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(RTL_SRC) $(TBS_SRC)

$(WAVESDIR)/%.ghw: ./**/tbs/%.vhdl $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) $*
	$(GHDL) -r $(GHDLFLAGS) $* --ieee-asserts=disable --wave=$@

$(WAVESDIR)/leaf_soc_tb.ghw: ./soc/tbs/leaf_soc_tb.vhdl $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) leaf_soc_tb
	$(GHDL) -r $(GHDLFLAGS) leaf_soc_tb $(GHDLXOPTS) --stop-time=100us -gPROGRAM=$(PROGRAM) --wave=$@

$(WAVESDIR)/leaf_sim.ghw: $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	@$(GHDL) -m $(GHDLFLAGS) leaf_sim;
	@$(GHDL) -r $(GHDLFLAGS) leaf_sim $(GHDLXOPTS) --stop-time=100us -gPROGRAM=$(PROGRAM) --wave=$@;

.PHONY: leaf_soc_tb
leaf_soc_tb: $(WORKDIR)/work-obj93.cf
	$(GHDL) -m $(GHDLFLAGS) leaf_soc_tb
	$(GHDL) -r $(GHDLFLAGS) leaf_soc_tb $(GHDLXOPTS) -gPROGRAM=$(PROGRAM)

.PHONY: leaf_sim
leaf_sim: $(WORKDIR)/work-obj93.cf
	@$(GHDL) -m $(GHDLFLAGS) leaf_sim;
	@$(GHDL) -r $(GHDLFLAGS) leaf_sim $(GHDLXOPTS) -gPROGRAM=$(PROGRAM);

.PHONY: clean
clean:
	rm -rf $(WORKDIR) $(WAVESDIR)