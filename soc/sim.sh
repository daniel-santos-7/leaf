#!/bin/bash

set -e

CORE_SRC=../core/rtl/*.vhdl
RTL_SRC=./rtl/*.vhdl
TBS_SRC=./tbs/*.vhdl

test -d ../work/ || mkdir ../work;

test -d ../waves/ || mkdir ../waves;

ghdl -i --ieee=synopsys --workdir=../work/ $CORE_PKG $CORE_SRC $RTL_SRC $TBS_SRC;

for TB in $TBS_SRC; do

    TB_NAME=$(basename -s .vhdl $TB);

    echo "running testbench: $TB_NAME";

    ghdl -m --ieee=synopsys --workdir=../work/ $TB_NAME;
    ghdl -r --ieee=synopsys --workdir=../work $TB_NAME --wave=../waves/$TB_NAME.ghw --ieee-asserts=disable;

done;