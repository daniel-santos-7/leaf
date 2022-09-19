APP_EXE  = tests_c
APP_SRC  = main.c $(STARTUP)
LDSCRIPT = ../common/link.ld
RISCV_GCC_OPTS = -nostartfiles -nostdlib -T $(LDSCRIPT) -march=$(MARCH) -mabi=$(MABI) -O2

include ../common/common.mk