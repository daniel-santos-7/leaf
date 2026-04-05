RISCV_PREFIX  ?= riscv32-unknown-elf
RISCV_GCC     ?= $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP ?= $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY ?= $(RISCV_PREFIX)-objcopy
SPIKE         ?= spike
SPIKE_ISA     ?= rv32i

MARCH ?= rv32i
MABI  ?= ilp32
DUMP_SIZE ?= 128

COMMON_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RISCV_GCC_OPTS ?= -nostartfiles -nostdlib -march=$(MARCH) -mabi=$(MABI) -O0 -g -I$(COMMON_DIR) -Wl,--defsym=DUMP_SIZE=$(DUMP_SIZE)

APP_SRC ?= $(wildcard *.s) $(wildcard *.S)
APP_OUT ?= out

.PHONY: run run-leaf run-spike all all-leaf all-spike clean clean-leaf clean-spike compare

run: run-leaf run-spike

run-leaf: $(APP_OUT).leaf.dump

run-spike: $(APP_OUT).spike.signature

all: all-leaf all-spike

all-leaf: $(APP_OUT).leaf.elf $(APP_OUT).leaf.bin $(APP_OUT).leaf.debug

all-spike: $(APP_OUT).spike.elf $(APP_OUT).spike.bin $(APP_OUT).spike.debug

clean: clean-leaf clean-spike

clean-leaf:
	@rm -f $(APP_OUT).leaf.elf $(APP_OUT).leaf.bin $(APP_OUT).leaf.debug $(APP_OUT).leaf.dump

clean-spike:
	@rm -f $(APP_OUT).spike.elf $(APP_OUT).spike.bin $(APP_OUT).spike.debug $(APP_OUT).spike.signature

compare: run
	@leaf_tmp=$$(mktemp); spike_tmp=$$(mktemp); \
	trap 'rm -f $$leaf_tmp $$spike_tmp' EXIT; \
	tr '[:upper:]' '[:lower:]' < $(APP_OUT).leaf.dump > $$leaf_tmp; \
	tr '[:upper:]' '[:lower:]' < $(APP_OUT).spike.signature > $$spike_tmp; \
	if diff -u $$leaf_tmp $$spike_tmp; then \
		echo "🟢 Leaf dump matches Spike signature"; \
	else \
		echo "🔴 Leaf dump differs from Spike signature"; \
		exit 1; \
	fi

$(APP_OUT).leaf.elf: $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/leaf.S $(COMMON_DIR)/leaf.ld
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T $(COMMON_DIR)/leaf.ld $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/leaf.S -o $@

$(APP_OUT).leaf.bin: $(APP_OUT).leaf.elf
	$(RISCV_OBJCOPY) -O binary $^ $@

$(APP_OUT).leaf.debug: $(APP_OUT).leaf.elf
	$(RISCV_OBJDUMP) $^ --source > $@

$(APP_OUT).leaf.dump: $(APP_OUT).leaf.bin
	@$(MAKE) -C ../../../ run PROGRAM=$(CURDIR)/$< DUMP_FILE=$(CURDIR)/$@

$(APP_OUT).spike.elf: $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/spike.S $(COMMON_DIR)/spike.ld
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T $(COMMON_DIR)/spike.ld $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/spike.S -o $@

$(APP_OUT).spike.bin: $(APP_OUT).spike.elf
	$(RISCV_OBJCOPY) -O binary $^ $@

$(APP_OUT).spike.debug: $(APP_OUT).spike.elf
	$(RISCV_OBJDUMP) $^ --source > $@

$(APP_OUT).spike.signature: $(APP_OUT).spike.elf
	$(SPIKE) --isa=$(SPIKE_ISA) +signature=$@ +signature-granularity=4 $<
