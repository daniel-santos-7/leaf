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

$(BINDIR)/boot: $(BOOTSRC) $(BINDIR)
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x100 $(BOOTSRC) -o $@;

$(BINDIR)/hello: sw/hello.S $(BINDIR)
	$(RV_CC) $(RV_CFLAGS) -Ttext 0x200 sw/hello.S -o $@;

# $(BINDIR)/hello: sw/crt0.S sw/hello.c $(BINDIR)
# 	$(RV_CC) $(RV_CFLAGS) -T sw/fwu.ld sw/crt0.S sw/hello.c -o $@

clean:
	rm -rf work;
	rm -rf waves;
	rm -rf bins;