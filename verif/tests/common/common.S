.include "defs.inc"

.section .text
.globl set_dump_pointers
.globl halt

set_dump_pointers:
    li t0, DUMP_START_ADDR
    sw a0, 0x0(a0)
    li t0, DUMP_STOP_ADDR
    sw a1, 0x0(t0)
    ret

halt:
    li t0, HALT_CMD_ADDR
    li t1, HALT_CMD_DATA
    sw t1, 0x0(t0)
    ret
