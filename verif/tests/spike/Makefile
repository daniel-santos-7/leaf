RISCV_PREFIX ?= riscv32-unknown-elf
RISCV_GCC    ?= $(RISCV_PREFIX)-gcc

SPIKE      ?= spike
SPIKE_ISA  ?= rv32i
SIGNATURE  ?= main.signature
APP_SRC    := $(wildcard *.S)

main.elf: $(APP_SRC) link.ld
	$(RISCV_GCC) \
	    -nostartfiles \
		-nostdlib \
		-T link.ld \
		-march=rv32i \
		-mabi=ilp32 \
		-O0 \
		-g \
		-o $@ $(APP_SRC)

.PHONY: run signature clean

run: signature

signature: $(SIGNATURE)

$(SIGNATURE): main.elf
	$(SPIKE) --isa=$(SPIKE_ISA) +signature=$@ +signature-granularity=4 $<

clean:
	rm -f main.elf $(SIGNATURE)
