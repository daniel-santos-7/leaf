RISCV_PREFIX  = riscv32-unknown-elf
RISCV_GCC     = $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP = $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY = $(RISCV_PREFIX)-objcopy

MARCH = rv32i
MABI  = ilp32

RISCV_GCC_OPTS ?= -nostartfiles -nostdlib -Ttext 0x00000000 -march=$(MARCH) -mabi=$(MABI) -O0 -g -I./common

TEST ?= dump

APP_SRC  ?= $(wildcard $(TEST)/*.s) $(wildcard $(TEST)/*.S)
APP_OUT  ?= $(TEST)/out

.PHONY: run all clean

run: $(APP_OUT).bin
	@$(MAKE) -C .. run PROGRAM=$(CURDIR)/$<

all: $(APP_OUT).elf $(APP_OUT).bin $(APP_OUT).debug

clean:
	@rm -f $(APP_OUT).elf $(APP_OUT).bin $(APP_OUT).debug

$(APP_OUT).elf: $(APP_SRC)
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $^ -o $@

$(APP_OUT).bin: $(APP_OUT).elf
	$(RISCV_OBJCOPY) -O binary $^ $@

$(APP_OUT).debug: $(APP_OUT).elf
	$(RISCV_OBJDUMP) $^ --source > $@
