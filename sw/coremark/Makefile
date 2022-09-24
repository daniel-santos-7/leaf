APP_EXE  = coremark

CORE_DEBUG ?= 1

RISCV_GCC_OPTS = -nostartfiles -T $(LDSCRIPT) -march=$(MARCH) -mabi=$(MABI) -O1 -w -fdata-sections -ffunction-sections -mno-fdiv -Wl,--gc-sections -lm -lc -lgcc -lc -DPERFORMANCE_RUN=1 -DCORE_DEBUG=$(CORE_DEBUG) -DITERATIONS=1000

include ../common/common.mk