COMMON_SRC = $(wildcard rtl/common/*.vhdl)

CORE_SRC = $(wildcard rtl/core/rtl/*.vhdl)
RAM_SRC =  $(wildcard rtl/ram/*.vhdl)
ROM_SRC =  $(wildcard rtl/rom/*.vhdl)
UART_SRC = $(wildcard rtl/uart/*.vhdl)
CHIP_SRC = $(wildcard rtl/*.vhdl)

RTL_SRC = $(CORE_SRC) $(RAM_SRC) $(ROM_SRC) $(UART_SRC) $(CHIP_SRC) $(COMMON_SRC)

RV_CC = riscv32-unknown-elf-gcc
RV_CFLAGS = -nostartfiles

.PHONY: all clean

all: work/work-obj93.cf waves/leaf_chip_tb.ghw

work/work-obj93.cf: $(RTL_SRC)
	test -d work || mkdir work;
	ghdl -i --workdir=work $(RTL_SRC);
	ghdl -m --workdir=work leaf_chip;

waves/leaf_chip_tb.ghw: work/work-obj93.cf
	test -d waves || mkdir waves;
	ghdl -m --workdir=work leaf_chip_tb;
	ghdl -r --workdir=work leaf_chip_tb --ieee-asserts=disable --wave=waves/leaf_chip_tb.ghw;

waves/fifo_tb.ghw: work/work-obj93.cf
	test -d waves || mkdir waves;
	ghdl -m --workdir=work fifo_tb;
	ghdl -r --workdir=work fifo_tb --ieee-asserts=disable --wave=waves/fifo_tb.ghw;

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