.include "defs.inc"

.section .text
.globl finish_test

finish_test:
    la a0, begin_dump
    la a1, end_dump
    li t0, DUMP_START_ADDR
    sw a0, 0(t0)
    li t0, DUMP_STOP_ADDR
    sw a1, 0(t0)
    li t0, HALT_CMD_ADDR
    li t1, HALT_CMD_DATA
    sw t1, 0x0(t0)
    ret
