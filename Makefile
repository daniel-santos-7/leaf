RTL_SRC=$(wildcard ./rtl/*)
TBS_DIR=$(wildcard ./tbs/*)

WORKDIR=work
WAVESDIR=waves

GHDL=ghdl
GHDLFLAGS= --workdir=$(WORKDIR)

RV_CC= riscv32-unknown-elf-gcc
RV_CFLAGS= -nostartfiles

.PHONY: all clean

all: work/work-obj93.cf

$(WORKDIR):
	mkdir $@;

$(WAVESDIR):
	mkdir $@;

$(WORKDIR)/work-obj93.cf: $(RTL_SRC) $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(RTL_SRC);

waves/leaf_chip_tb.ghw: work/work-obj93.cf waves
	ghdl -m --workdir=work leaf_chip_tb;
	ghdl -r --workdir=work leaf_chip_tb --ieee-asserts=disable --wave=waves/leaf_chip_tb.ghw;

waves/uart.ghw: work/work-obj93.cf
	test -d waves || mkdir waves;
	ghdl -m --workdir=work uart_tb;
	ghdl -r --workdir=work uart_tb --ieee-asserts=disable --wave=waves/uart_tb.ghw;

sw/boot: sw/boot.S
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $^ -o $@ 

sw/byte_test: sw/byte_test.S
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $^ -o $@ 

sw/hello: sw/crt0.S sw/hello.c
	$(RV_CC) $(RV_CFLAGS) -T sw/fwu.ld $^ -o $@

clean:
	rm -rf work;
	rm -rf waves;

sw/clean:
	rm sw/hello;