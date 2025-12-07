# leaf project

# Directories
RTL_DIR   = rtl
TBS_DIR   = tbs
WORK_DIR  = work
WAVES_DIR = waves
STEPS_DIR = steps

RTL_TOP = leaf
TBS_TOP = leaf_tb

# VHDL simulator
SIM = ghdl
SIMFLAGS = --workdir=$(WORK_DIR) --ieee=synopsys
SIMXOPTS = --wave=$(WAVES_DIR)/$(TBS_TOP).ghw

# Source files
RTL_SRC = $(wildcard $(RTL_DIR)/*.vhdl)
TBS_SRC = $(wildcard $(TBS_DIR)/*.vhdl)

PROGRAM = program.bin

$(WORK_DIR) $(WAVES_DIR) $(STEPS_DIR):
	@mkdir $@

$(STEPS_DIR)/import: $(RTL_SRC) $(TBS_SRC) | $(STEPS_DIR) $(WORK_DIR) 
	@$(SIM) import $(SIMFLAGS) $(RTL_SRC) $(TBS_SRC) | tee $@

$(STEPS_DIR)/make: $(STEPS_DIR)/import
	@$(SIM) make $(SIMFLAGS) $(TBS_TOP) | tee $@

$(STEPS_DIR)/run: $(STEPS_DIR)/make | $(WAVES_DIR)
	@$(SIM) run  $(TBS_TOP) $(SIMXOPTS) -gPROGRAM=$(PROGRAM) | tee $@

.PHONY: run clean
run: $(STEPS_DIR)/run

clean:
	$(SIM) clean --workdir=$(WORK_DIR)
	@rm -rf $(WORK_DIR) $(WAVES_DIR) $(STEPS_DIR)