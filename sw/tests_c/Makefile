include ../common/common.mk

RISCV_GCC_OPTS = -nostartfiles -march=$(MARCH) -mabi=$(MABI) -T $(LD_SCRIPT)

.PHONY: all
all: tests_c.elf tests_c.bin tests_c.debug

tests_c.elf: tests_c.c $(STARTUP)
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $^ -o $@

tests_c.bin: tests_c.elf
	$(RISCV_OBJCOPY) -O binary $^ $@

tests_c.debug: tests_c.elf
	$(RISCV_OBJDUMP) $^ --source > $@

.PHONY: clean
clean:
	rm -f *.elf *.bin *.debug