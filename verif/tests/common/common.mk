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

.PHONY: run all clean

run: $(APP_OUT).bin $(APP_OUT).signature
	@$(MAKE) -C ../../../ run PROGRAM=$(CURDIR)/$< DUMP_FILE=$(CURDIR)/$(APP_OUT).dump

all: $(APP_OUT).elf $(APP_OUT).bin $(APP_OUT).debug $(APP_OUT).spike.elf $(APP_OUT).spike.bin $(APP_OUT).spike.debug $(APP_OUT).signature

clean:
	@rm -f $(APP_OUT).elf $(APP_OUT).bin $(APP_OUT).debug
	@rm -f $(APP_OUT).spike.elf $(APP_OUT).spike.bin $(APP_OUT).spike.debug $(APP_OUT).signature

$(APP_OUT).elf: $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/leaf.S $(COMMON_DIR)/leaf.ld
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T $(COMMON_DIR)/leaf.ld $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/leaf.S -o $@

$(APP_OUT).bin: $(APP_OUT).elf
	$(RISCV_OBJCOPY) -O binary $^ $@

$(APP_OUT).debug: $(APP_OUT).elf
	$(RISCV_OBJDUMP) $^ --source > $@

$(APP_OUT).spike.elf: $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/spike.S $(COMMON_DIR)/spike.ld
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T $(COMMON_DIR)/spike.ld $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/spike.S -o $@

$(APP_OUT).spike.bin: $(APP_OUT).spike.elf
	$(RISCV_OBJCOPY) -O binary $^ $@

$(APP_OUT).spike.debug: $(APP_OUT).spike.elf
	$(RISCV_OBJDUMP) $^ --source > $@

$(APP_OUT).signature: $(APP_OUT).spike.elf
	$(SPIKE) --isa=$(SPIKE_ISA) +signature=$@ +signature-granularity=4 $<
