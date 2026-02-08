.include "defs.inc"

.globl _start
_start:
    la t0, trap_handler
    csrw mtvec, t0
    li a7, 1
    li a0, 10
    ecall
    li t0, HALT_CMD_ADDR
    li t1, HALT_CMD_DATA
    sw t1, 0x0(t0)

trap_handler:
    csrr t0, mepc
    addi t0, t0, 0x4
    csrw mepc, t0
    mret
