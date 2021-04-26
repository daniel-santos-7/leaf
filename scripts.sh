#!/usr/bin/env bash

test() {

ghdl -i --workdir=work ./rtl/*.vhdl 

ghdl -i --workdir=work ./tbs/*.vhdl

for tb in $(basename -s .vhdl ./tbs/*_tb.vhdl); do
    
    echo -n $tb;

    ghdl -m --workdir=work $tb;

    ghdl -r --workdir=work $tb --wave=./waves/$tb.ghw --ieee-asserts=disable-at-0;

    echo -e " [ok]";

done

ghdl --remove --workdir=work

exit 0;

}

wave() {

if [ -z "$1" ] 

    then
    
    echo "testbenchs:"

    for tb in $(basename -s .vhdl ./tbs/*_tb.vhdl); do
    
    echo $tb;

    done

fi

gtkwave ./waves/$1.ghw;

exit 0;

}

while [ $# -gt 0 ]; do
    
    case "$1" in

        test | -t)
            test;;

        wave | -w)
            wave $2;;

        *)  
            echo "";
            echo "Comandos válidos:";
            echo "test | -t: executar testbenchs (GHDL necessário)";
            echo "wave [tb] | -w [tb]: visualizar formas de ondas (GTKWAVE necessário)"; 
            echo ""; 
            exit 1;;

    esac

    shift

done