UART_DSG = uart/uart_tx.vhdl uart/uart_rx.vhdl uart/uart_pkg.vhdl uart/uart.vhdl
UART_TBS = uart/uart_tx_tb.vhdl uart/uart_rx_tb.vhdl

DSG_SRC = $(UART_DSG)
TBS_SRC = $(UART_TBS)

.PHONY: all clean

all: work/work-obj93.cf waves/uart_tx_tb.ghw waves/uart_rx_tb.ghw

work/work-obj93.cf: $(DSG_SRC)
	test -d work || mkdir work;
	ghdl -a --workdir=work $(DSG_SRC) $(TBS_SRC);

waves/uart_tx_tb.ghw: work/work-obj93.cf
	test -d waves || mkdir waves;
	ghdl -e --workdir=work uart_tx_tb;
	ghdl -r --workdir=work uart_tx_tb --wave=waves/uart_tx_tb.ghw;

waves/uart_rx_tb.ghw: work/work-obj93.cf
	test -d waves || mkdir waves;
	ghdl -e --workdir=work uart_rx_tb;
	ghdl -r --workdir=work uart_rx_tb --wave=waves/uart_rx_tb.ghw;

clean:
	rm -rf work;
	rm -rf waves;