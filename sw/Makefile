RISCV_PREFIX  = riscv32-unknown-elf-
RISCV_GCC     = $(RISCV_PREFIX)gcc
RISCV_OBJDUMP = $(RISCV_PREFIX)objdump
RISCV_OBJCOPY = $(RISCV_PREFIX)objcopy

MARCH = rv32i
MABI  = ilp32

LD_SCRIPT = common/link.ld
STARTUP   = common/crt0.S
SYSCALLS  = common/syscalls.c

RISCV_GCC_OPTS = -nostartfiles -T $(LD_SCRIPT) -march=$(MARCH) -mabi=$(MABI) -O2

BUILD_DIR = build

$(BUILD_DIR): 
	mkdir $@

$(BUILD_DIR)/%.elf: %
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $(STARTUP) $(SYSCALLS) $(wildcard $^/*.c) -o $@

$(BUILD_DIR)/%.debug: $(BUILD_DIR)/%.elf
	$(RISCV_OBJDUMP) $^ --source > $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(RISCV_OBJCOPY) -O binary $^ $@

$(BUILD_DIR)/coremark.elf: $(STARTUP) $(SYSCALLS) $(wildcard coremark/*.c)
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $^ -DPERFORMANCE_RUN=1 -DITERATIONS=80 -o $@

.PHONY: clean
clean:
	rm -rf build