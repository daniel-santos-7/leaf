.include "defs.inc"

.section .text
.globl halt

halt:
    li t0, HALT_CMD_ADDR
    li t1, HALT_CMD_DATA
    sw t1, 0x0(t0)
    ret
