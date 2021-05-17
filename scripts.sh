#!/usr/bin/env bash

set -e

RTL_SRC=./rtl/*.vhdl;
RTL_TOP=core;

TBS_PKG_SRC=./tbs/tbs_pkg.vhdl;
TBS_SRC=./tbs/*_tb.vhdl;
TBS_TOP=core_tb;

arch_test() {

    ARCH_TEST_DIR=$1;
    LOCAL_TARGETDIR=$(pwd)/arch-test/;

    test -d $ARCH_TEST_DIR || exit 1;

    make -s -C $1 TARGETDIR=$LOCAL_TARGETDIR XLEN=32 RISCV_TARGET=leaf clean build;

    test -d ./work/ || mkdir ./work;

    ghdl -i --workdir=./work/ $RTL_SRC;
    ghdl -m --workdir=./work/ $RTL_TOP;

    TBS_TOP_SRC=./tbs/$TBS_TOP.vhdl;

    ghdl -i --ieee=synopsys --workdir=./work/ $TBS_PKG_SRC $TBS_TOP_SRC;
    ghdl -m --ieee=synopsys --workdir=./work/ $TBS_TOP;

    BIN_FILES_DIR=$ARCH_TEST_DIR/work/rv32i_m/I/;
    BIN_FILES=$(find $BIN_FILES_DIR -name *.bin);

    for BIN in $BIN_FILES; do

        TEST_NAME=$(basename -s .elf.bin $BIN);

        case $TEST_NAME in jalr-01 | jal-01) continue;; esac;

        echo "running test: $TEST_NAME";

        ghdl -r --ieee=synopsys --workdir=./work/ $TBS_TOP --ieee-asserts=disable -gPROGRAM_FILE=$BIN -gDUMP_FILE=$BIN_FILES_DIR/$TEST_NAME.signature.output -gMEM_SIZE=2097152;

    done;

    make -s -C $1 TARGETDIR=$LOCAL_TARGETDIR XLEN=32 RISCV_TARGET=leaf verify;

    ghdl --remove --workdir=./work/;

    rmdir ./work/;

}

testbench() {

	ghdl -i --ieee=synopsys --workdir=./work/ $TBS_PKG_SRC $TBS_SRC;

    for TB in $TBS_SRC; do

        TB_NAME=$(basename -s .vhdl $TB);

        if [ $TB_NAME == $TBS_TOP ]; then continue; fi

        echo "running testbench: $TB_NAME";

        ghdl -m --ieee=synopsys --workdir=./work/ $TB_NAME;

        ghdl -r --ieee=synopsys --workdir=./work $TB_NAME;

    done;

    ghdl --remove --workdir=./work/;

    rmdir ./work/;

}

while [ $# -gt 0 ]; do
    
    case $1 in

        arch-test | -at)
            arch_test $2;
            exit 0;;

        testbench | -tb)
            testbench;
            exit 0;;

        *)  
            echo "Valid commands:";
            echo "arch-test | -at [path]: perform compliance test";
            echo "testbench | -tb: run hardware tests";
            exit 1;;

    esac

    shift

done
