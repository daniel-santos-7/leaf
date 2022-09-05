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

# $(BUILD_DIR)/coremark.elf: $(STARTUP) $(SYSCALLS) $(wildcard coremark/*.c)
# 	$(RISCV_GCC) $(RISCV_GCC_OPTS) $^ -DPERFORMANCE_RUN=1 -DCORE_DEBUG=1 -DITERATIONS=10 -o $@

$(BUILD_DIR)/coremark.elf: $(wildcard coremark/*.c)
	$(RISCV_GCC) -nostartfiles -T $(LD_SCRIPT) $(STARTUP) $^ -DPERFORMANCE_RUN=1 -DCORE_DEBUG=1 -DITERATIONS=10 -o $@

$(BUILD_DIR)/tests_asm.elf: tests_asm/tests_asm.S
	$(RISCV_GCC) -nostartfiles -nostdlib -Ttext 0x00010000 $^ -o $@

$(BUILD_DIR)/boot.elf: boot/start.S
	$(RISCV_GCC) -nostartfiles -nostdlib -Ttext 0x00000100 $^ -o $@

$(BUILD_DIR)/tests_c.elf: tests_c/main.c 
	$(RISCV_GCC) -nostartfiles -nostdlib -T $(LD_SCRIPT) $(STARTUP) $^ -o $@

.PHONY: clean
clean:
	rm -rf build