RTL_SRC=$(wildcard ./rtl/*)
TBS_SRC=$(wildcard ./tbs/*)

WORKDIR=work
WAVESDIR=waves

GHDL=ghdl
GHDLFLAGS=--workdir=$(WORKDIR)

BOOTSRC=sw/boot.S
BINDIR=bins

RV_CC=riscv32-unknown-elf-gcc
RV_CFLAGS=-nostartfiles

.PHONY: all clean

all: work/work-obj93.cf

$(WORKDIR):
	mkdir $@;

$(WAVESDIR):
	mkdir $@;

$(WORKDIR)/work-obj93.cf: $(RTL_SRC) $(TBS_SRC) $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(RTL_SRC) $(TBS_SRC);

$(WAVESDIR)/leaf_chip_tb.ghw: $(WORKDIR)/work-obj93.cf $(WAVESDIR)
	$(GHDL) -m $(GHDLFLAGS) leaf_chip_tb;
	$(GHDL) -r $(GHDLFLAGS) leaf_chip_tb --ieee-asserts=disable --wave=$@;

$(BINDIR):
	mkdir $@;

$(BINDIR)/boot: $(BOOTSRC)
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $^ -o $@;

$(BINDIR)/uart_test: sw/uart_test.S
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $^ -o $@;

sw/boot: sw/boot.S
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $^ -o $@ 

sw/byte_test: sw/byte_test.S
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $^ -o $@ 

sw/hello: sw/crt0.S sw/hello.c
	$(RV_CC) $(RV_CFLAGS) -T sw/fwu.ld $^ -o $@

clean:
	rm -rf work;
	rm -rf waves;