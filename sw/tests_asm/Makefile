APP_EXE  = tests_asm
APP_SRC  = start.S

RISCV_GCC_OPTS = -nostartfiles -nostdlib -Ttext 0x00010000 -march=$(MARCH) -mabi=$(MABI) -O0

include ../common/common.mk