#!/bin/bash

RV_ARCH_TEST_DIR=$1

[ ! -d "$RV_ARCH_TEST_DIR" ] && exit 1;

export TARGETDIR=$PWD/../arch-test
export XLEN=32
export RISCV_TARGET=leaf

# make -C $RV_ARCH_TEST_DIR clean;
make -C $RV_ARCH_TEST_DIR compile RISCV_DEVICE=I;
make -C $RV_ARCH_TEST_DIR compile RISCV_DEVICE=privilege;

bins=$(find $RV_ARCH_TEST_DIR/work/rv32i_m/ -name "*.bin");

for bin in $bins; do
    test=$(basename -s .elf.bin $bin);
    dir=$(dirname $bin);
    echo "running test: $test";
    case $test in 
        misalign-jal-01 | misalign2-jalr-01) continue;;
        misalign-beq-01 | misalign-bge-01 | misalign-bgeu-01 | misalign-blt-01 | misalign-bltu-01 | misalign-bne-01) continue;;
        *) make -sC ../../ leaf_sim PROGRAM=$bin | xxd -c 4 -p > $dir/$test.signature.output;;
    esac
done

make -C $RV_ARCH_TEST_DIR verify RISCV_DEVICE=I;
make -C $RV_ARCH_TEST_DIR verify RISCV_DEVICE=privilege;