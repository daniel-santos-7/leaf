# leaf project

# Directories
RTL_DIR   = rtl
TBS_DIR   = tbs
WORK_DIR  = work
SYN_DIR   = syn
YOSYS_SCRIPT = $(SYN_DIR)/leaf_analysis.ys

RTL_TOP = leaf
TBS_TOP = leaf_tb

# VHDL simulator
SIM = ghdl
SIMFLAGS = --workdir=$(WORK_DIR) --ieee=synopsys
SIMXOPTS =
WAVEFORM ?= $(TBS_TOP).ghw
ifdef WAVEFORM
SIMXOPTS += --wave=$(WAVEFORM)
endif

# Source files
RTL_SRC = $(wildcard $(RTL_DIR)/*.vhdl)
TBS_SRC = $(wildcard $(TBS_DIR)/*.vhdl)

PROGRAM   = verif/tests/dump/out.bin
DUMP_FILE = verif/tests/dump/out.dump
REG_FILE  ?= 32

$(WORK_DIR):
	@mkdir $@

$(WORK_DIR)/.import: $(RTL_SRC) $(TBS_SRC) | $(WORK_DIR)
	@$(SIM) import $(SIMFLAGS) $(RTL_SRC) $(TBS_SRC) | tee $@

$(WORK_DIR)/.make: $(WORK_DIR)/.import
	@$(SIM) make $(SIMFLAGS) $(TBS_TOP) | tee $@

$(WORK_DIR)/$(RTL_TOP).v: $(RTL_SRC) $(WORK_DIR)/.make Makefile
	@$(SIM) synth $(SIMFLAGS) --latches --out=verilog -gREG_FILE_SIZE=$(REG_FILE) $(RTL_TOP) > $@

$(WORK_DIR)/$(RTL_TOP).rpt: $(WORK_DIR)/$(RTL_TOP).v $(YOSYS_SCRIPT)
	@yosys -q -l $@ $(YOSYS_SCRIPT)

.PHONY: run synthesis clean
run: $(WORK_DIR)/.make $(PROGRAM)
	@$(SIM) run  $(TBS_TOP) $(SIMXOPTS) -gPROGRAM=$(PROGRAM) -gDUMP_FILE=$(DUMP_FILE)

synthesis: $(WORK_DIR)/$(RTL_TOP).rpt

clean:
	$(SIM) clean --workdir=$(WORK_DIR)
	@rm -rf $(WORK_DIR)