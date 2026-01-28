.include "defs.inc"

.globl _start
_start:
    li t0, DUMP_START_ADDR
    li t1, 0x0
    sw t1, 0x0(t0)

    li t0, DUMP_STOP_ADDR
    li t1, 0x33
    sw t1, 0x0(t0)

    li t0, HALT_CMD_ADDR
    li t1, HALT_CMD_DATA
    sw t1, 0x0(t0)
