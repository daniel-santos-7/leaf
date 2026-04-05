SPIKE      ?= spike
SPIKE_ISA  ?= rv32i
SIGNATURE  ?= main.signature
SIGNATURE_WORDS ?= 4
APP_SRC    := $(wildcard *.S)
APP_OUT    := main
RISCV_GCC_OPTS = -nostartfiles -nostdlib -T link.ld -march=$(MARCH) -mabi=$(MABI) -O0 -g -DSIGNATURE_WORDS=$(SIGNATURE_WORDS)

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

$(SIGNATURE): $(APP_OUT).elf
	$(SPIKE) --isa=$(SPIKE_ISA) +signature=$@ +signature-granularity=4 $<
