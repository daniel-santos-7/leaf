APP_EXE  = boot
APP_SRC  = start.S

RISCV_GCC_OPTS = -nostartfiles -nostdlib -Ttext 0x00000100 -march=$(MARCH) -mabi=$(MABI) -O0

include ../common/common.mk