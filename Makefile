CORE_SRC = $(wildcard rtl/core/rtl/*.vhdl)
RAM_SRC =  $(wildcard rtl/ram/*.vhdl)
ROM_SRC =  $(wildcard rtl/rom/*.vhdl)
UART_SRC = $(wildcard rtl/uart/*.vhdl)
CHIP_SRC = $(wildcard rtl/*.vhdl)

RTL_SRC = $(CORE_SRC) $(RAM_SRC) $(ROM_SRC) $(UART_SRC) $(CHIP_SRC)

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

clean:
	rm -rf work;
	rm -rf waves;