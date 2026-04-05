.include "defs.inc"

.altmacro

.macro _li_one r, val
    li x\r, \val
.endm

.macro li_all val
    .set i, 0
    .rept 32
        _li_one %i, \val
        .set i, i + 1
    .endr
.endm

.macro li_walking_ones
    .set bit, 0x80000000
    .rept 32
        li_all %bit
        .set bit, bit >> 1
    .endr
.endm

.macro li_walking_zeros
    .set bit, 0x80000000
    .rept 32
        li_all %(0xFFFFF - bit)
        .set bit, bit >> 1
    .endr
.endm

.globl _start

_start:
    li_all 0x00000000
    li_all 0xFFFFFFFF
    li_all 0xAAAAAAAA
    li_all 0x55555555
    li_walking_ones
    li_walking_zeros
    csrw mcause, x1
    csrw mscratch, x10
    li a0, 0
    call store_regs
    call finish_test
