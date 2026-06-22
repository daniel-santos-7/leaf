.include "defs.inc"

.globl _start
_start:
    la t0, trap_handler
    csrw mtvec, t0
    li a7, 1
    li a0, 10
    ecall
    call finish_test

trap_handler:
    csrr t0, mepc
    addi t0, t0, 0x4
    csrw mepc, t0
    mret
