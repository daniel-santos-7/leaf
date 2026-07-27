.include "defs.inc"

.globl _start
_start:
    li   sp, MEM_BASE + MEM_SIZE
    la   x1, begin_dump

    li   x9, 0xDEADBEEF
    sw   x9, 0(x1)

    lui  x9, 0x12345
    addi x9, x9, 0x678
    sw   x9, 4(x1)

    li   x3, -1
    xori x3, x3, 0xFF
    sw   x3, 8(x1)

    li   x4, 42
    ori  x4, x4, 0xF0
    sw   x4, 12(x1)

    add  x5, x4, x9
    sw   x5, 16(x1)

    sub  x5, x9, x4
    sw   x5, 20(x1)

    li   x6, 0x80000000
    slti x6, x6, 0
    sw   x6, 24(x1)

    li   x7, 0xABCD
    srli x7, x7, 4
    sw   x7, 28(x1)

    li   x8, 0x80000000
    srai x8, x8, 16
    sw   x8, 32(x1)

    call finish_test
