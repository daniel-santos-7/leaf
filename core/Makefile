RTL_SRC=$(wildcard ./rtl/*.vhdl)
TBS=$(wildcard ./tbs/*.vhdl)

all: design testbenchs

design: $(RTL_SRC)
	test -d ./work || mkdir ./work
	ghdl -i --workdir=work $(RTL_SRC)

testbenchs: rtl $(RTL_SRC) $(TBS)
	test -d ./work || mkdir ./work
	ghdl -i --workdir=work $(TBS)

clean: ./work
	ghdl --remove --workdir=work
	rmdir work

