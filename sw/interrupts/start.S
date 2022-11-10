.globl _start
_start:
    la t0, trap_handler
    csrw mtvec, t0
    li t0, 0xFFFFFFFF
    csrw mie, t0
    csrw mstatus, t0
    wfi

loop: 
    j loop

trap_handler:
    mret