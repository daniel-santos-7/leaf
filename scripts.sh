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

while [ $# -gt 0 ]; do
    
    case "$1" in

        testbench | -tb)
            testbench;;

        wave | -w)
            wave $2;;

        *)  
            echo "";
            echo "Comandos válidos:";
            echo "testbench | -tb: executar testbenchs (GHDL necessário)";
            echo "wave | -w [tb]: visualizar formas de ondas (GTKWave necessário)"; 
            echo "";
            exit 1;;

    esac

    shift

done