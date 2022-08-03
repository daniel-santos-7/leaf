include ../common/common.mk

.PHONY: all
all: tests_asm.elf tests_asm.bin tests_asm.debug

tests_asm.elf: tests_asm.S
	$(RISCV_GCC) -c $^ -o $@

tests_asm.bin: tests_asm.elf
	$(RISCV_OBJCOPY) -O binary $^ $@

tests_asm.debug: tests_asm.elf
	$(RISCV_OBJDUMP) $^ --source > $@

.PHONY: clean
clean:
	rm -f *.elf *.bin *.debug