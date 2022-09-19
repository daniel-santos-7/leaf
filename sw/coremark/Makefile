APP_EXE  = coremark

RISCV_GCC_OPTS = -nostartfiles -T $(LDSCRIPT) -march=$(MARCH) -mabi=$(MABI) -O1 -w -DPERFORMANCE_RUN=1 -DCORE_DEBUG=1 -DITERATIONS=10

include ../common/common.mk