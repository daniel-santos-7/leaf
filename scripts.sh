#!/usr/bin/env bash

set -e

core_tbs=$(basename -s .vhdl ./core/tbs/*_tb.vhdl);

testbench() {

    make -s -C ./core testbenchs;

    for tb in $core_tbs; do

        echo -n $tb;
        ghdl -e --workdir=./core/work $tb;
        ghdl -r --workdir=./core/work $tb --ieee-asserts=disable-at-0;
        echo -e " \e[1;92m[ok]\e[0m";

    done

    exit 0;

}

wave() {

    if [ -z "$1" ] 
        then

        echo "testbenchs:" $core_tbs;
        exit 1;

    fi

    make -s -C ./core waves;
    gtkwave ./core/waves/$1.ghw;
    exit 0;

}

arch_test() {

    test -d $1 || exit 1;
    make -s -C ./core testbenchs;
    at_dir=$(pwd)/arch-test
    make -s -C $1 TARGETDIR=$at_dir XLEN=32 RISCV_TARGET=leaf clean build compile simulate
    # make -s -C $1 TARGETDIR=$at_dir XLEN=32 RISCV_TARGET=leaf RISCV_TEST=add-01 clean build compile simulate

    # make -s -C ./core testbenchs;
    # ghdl -e --ieee=synopsys --workdir=./core/work core_tb;
    # ghdl -r --ieee=synopsys --workdir=./core/work core_tb -gBIN_FILE=$1/work/rv32i_m/I/add-01.elf.bin --wave=./core/waves/core_tb.ghw;

}

while [ $# -gt 0 ]; do
    
    case "$1" in

        testbench | -tb)
            testbench;;

        wave | -w)
            wave $2;;

        arch-test | -at)
            arch_test $2;
            exit 0;;

        *)  
            echo "Comandos válidos:";
            echo "testbench | -tb: executar testbenchs";
            echo "wave | -w [tb]: visualizar formas de ondas"; 
            echo "arch-test | -at [path]: realizar teste de conformidade"; 
            exit 1;;

    esac

    shift

done