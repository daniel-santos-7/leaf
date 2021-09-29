CORE_SRC = $(wildcard rtl/core/rtl/*.vhdl)
RAM_SRC =  $(wildcard rtl/ram/*.vhdl)
ROM_SRC =  $(wildcard rtl/rom/*.vhdl)
UART_SRC = $(wildcard rtl/uart/*.vhdl)
CHIP_SRC = rtl/leaf_chip_pkg.vhdl rtl/leaf_chip.vhdl

RTL_SRC = $(CORE_SRC) $(RAM_SRC) $(ROM_SRC) $(UART_SRC) $(CHIP_SRC)

.PHONY: all clean

all: work/work-obj93.cf

work/work-obj93.cf: $(RTL_SRC)
	test -d work || mkdir work;
	ghdl -i --workdir=work $(RTL_SRC);

elab: work/work-obj93.cf
	ghdl -c --workdir=work -e leaf_chip;

# waves/uart_tx_tb.ghw: work/work-obj93.cf
# 	test -d waves || mkdir waves;
# 	ghdl -e --workdir=work uart_tx_tb;
# 	ghdl -r --workdir=work uart_tx_tb --wave=waves/uart_tx_tb.ghw;

clean:
	rm -rf work;
	rm -rf waves;