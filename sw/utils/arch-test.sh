#!/bin/bash

RV_ARCH_TEST_DIR=$PWD/../../../riscv-arch-test/
export TARGETDIR=$PWD/../../compliance/
export XLEN=32
export RISCV_TARGET=leaf

make -C $RV_ARCH_TEST_DIR build;
ghdl -m --workdir=$PWD/../../work --ieee=synopsys leaf_sim;

bins=$(find $RV_ARCH_TEST_DIR/work/rv32i_m/I/ -name "*.bin");

for bin in $bins; do
    test=$(basename -s .elf.bin $bin);
    echo "running test: $test";
    ghdl -r --workdir=$PWD/../../work --ieee=synopsys leaf_sim --max-stack-alloc=0 --ieee-asserts=disable -gPROGRAM=$bin | xxd -c 4 -p > $RV_ARCH_TEST_DIR/work/rv32i_m/I/$test.signature.output;
done

make -C $RV_ARCH_TEST_DIR verify;