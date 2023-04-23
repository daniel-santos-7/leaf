APP_EXE  = uart_io
APP_SRC  = main.c ../common/leaf.h ../common/leaf.c $(STARTUP)
LDSCRIPT = ../common/sim.ld
RISCV_GCC_OPTS = -nostartfiles -T $(LDSCRIPT) -march=$(MARCH) -mabi=$(MABI) -O2
include ../common/common.mk