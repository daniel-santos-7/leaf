RISCV_PREFIX  = riscv32-unknown-elf-
RISCV_GCC     = $(RISCV_PREFIX)gcc
RISCV_OBJDUMP = $(RISCV_PREFIX)objdump
RISCV_OBJCOPY = $(RISCV_PREFIX)objcopy

MARCH = rv32i
MABI  = ilp32

STARTUP  ?= ../common/crt0.S
SYSCALLS ?= ../common/syscalls.c
LDSCRIPT ?= ../common/link.ld

RISCV_GCC_OPTS ?= -nostartfiles -T $(LDSCRIPT) -march=$(MARCH) -mabi=$(MABI) -O0

APP_EXE ?= out
APP_SRC ?= $(wildcard ./*.c) $(wildcard ./*.S)

.PHONY: all
all: $(APP_EXE).elf $(APP_EXE).bin $(APP_EXE).debug

$(APP_EXE).elf: $(APP_SRC)
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $(STARTUP) $(SYSCALLS) $^ -o $@

$(APP_EXE).bin: $(APP_EXE).elf
	$(RISCV_OBJCOPY) -O binary $^ $@

$(APP_EXE).debug: $(APP_EXE).elf
	$(RISCV_OBJDUMP) $^ --source > $@

.PHONY: clean
clean:
	rm -f $(APP_EXE).elf $(APP_EXE).bin $(APP_EXE).debug