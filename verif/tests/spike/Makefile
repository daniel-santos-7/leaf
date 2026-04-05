SPIKE      ?= spike
SPIKE_ISA  ?= rv32i
SIGNATURE  ?= main.signature
APP_SRC    = $(filter-out spike.S signature.S,$(wildcard *.S)) $(COMMON_DIR)/spike.S
APP_OUT    := main
RISCV_GCC_OPTS = -nostartfiles -nostdlib -T $(COMMON_DIR)/spike.ld -march=$(MARCH) -mabi=$(MABI) -O0 -g -I$(COMMON_DIR) -DDUMP_SIZE=$(DUMP_SIZE)

include ../common/common.mk

.PHONY: run all clean

run: $(SIGNATURE)
	@true

all: $(APP_OUT).elf $(SIGNATURE)

clean:
	rm -f $(APP_OUT).elf $(APP_OUT).bin $(APP_OUT).debug $(SIGNATURE)

$(APP_OUT).bin:
	@true

$(APP_OUT).debug:
	@true

$(APP_OUT).elf: $(APP_SRC) $(COMMON_DIR)/common.S $(COMMON_DIR)/spike.ld
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $(APP_SRC) $(COMMON_DIR)/common.S -o $@

$(SIGNATURE): $(APP_OUT).elf
	$(SPIKE) --isa=$(SPIKE_ISA) +signature=$@ +signature-granularity=4 $<
