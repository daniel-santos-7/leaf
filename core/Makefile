RTL_SRC=$(wildcard ./rtl/*.vhdl)

TBS_PKG=./tbs/tbs_pkg.vhdl
TBS=$(wildcard ./tbs/*_tb.vhdl)

all: design-sim testbenchs waves

design-sim: $(RTL_SRC)
	test -d ./work || mkdir ./work
	ghdl -i --workdir=work $(RTL_SRC)
	ghdl -m --workdir=work core

testbenchs: design-sim $(TBS)
	test -d ./work || mkdir ./work
	ghdl -a --ieee=synopsys --workdir=work $(TBS_PKG)
	ghdl -a --ieee=synopsys --workdir=work $(TBS)

waves: testbenchs
	test -d ./waves || mkdir ./waves
	for tb in $(basename $(notdir $(TBS))); do \
		[ $$tb != core_tb ] && { ghdl -r --workdir=work $$tb --wave=./waves/$$tb.ghw; }; \
	done

clean: ./work
	ghdl --remove --workdir=work
	rm -rf ./work
	rm -rf ./waves