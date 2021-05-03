#!/usr/bin/env bash

core_tbs=$(basename -s .vhdl ./core/tbs/*_tb.vhdl);

testbench() {

    make -C ./core
    test -d ./core/waves || mkdir ./core/waves

    for tb in $core_tbs; do

        echo -n $tb;
        ghdl -m --workdir=./core/work $tb;
        ghdl -r --workdir=./core/work $tb --wave=./core/waves/$tb.ghw --ieee-asserts=disable-at-0;
        echo -e " [ok]";

    done

    make -C ./core clean

    exit 0;

}

wave() {

    if [ -z "$1" ] 
        then

        echo "testbenchs:";
        
        for tb in $core_tbs; do
            echo $tb;
        done

    fi

    gtkwave ./core/waves/$1.ghw;

    exit 0;

}

while [ $# -gt 0 ]; do
    
    case "$1" in

        testbench | -tb)
            testbench $2;;

        wave | -w)
            wave $2;;

        *)  
            echo "";
            echo "Comandos válidos:";
            echo "testbench [tb]: executar testbench (GHDL necessário)";
            echo "wave [tb]: visualizar formas de ondas (GTKWAVE necessário)"; 
            echo "";
            exit 1;;

    esac

    shift

done