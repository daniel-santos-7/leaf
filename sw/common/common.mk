RISCV_PREFIX  ?= riscv32-unknown-elf-
RISCV_GCC     ?= $(RISCV_PREFIX)gcc
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump
RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy

MARCH ?= rv32i
MABI  ?= ilp32

LD_SCRIPT ?= ../common/link.ld
STARTUP   ?= ../common/crt0.S

RISCV_GCC_OPTS ?= -nostdlib -O0 -march=$(MARCH) -mabi=$(MABI) -T $(LD_SCRIPT)