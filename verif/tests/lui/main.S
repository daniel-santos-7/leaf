.altmacro

.macro _lui_one r, val
    lui x\r, \val
.endm

.macro lui_all val
    .set i, 0
    .rept 32
        _lui_one %i, \val
        .set i, i + 1
    .endr
.endm

.macro lui_walking_ones
    .set bit, 0x80000
    .rept 20
        lui_all %bit
        .set bit, bit >> 1
    .endr
.endm

.macro lui_walking_zeros
    .set bit, 0x80000
    .rept 20
        lui_all %(0xFFFFF - bit)
        .set bit, bit >> 1
    .endr
.endm

.globl _start

_start:
    lui_all 0x00000
    lui_all 0xFFFFF
    lui_all 0xAAAAA
    lui_all 0x55555
    lui_walking_ones
    lui_walking_zeros
    call store_regs
    call finish_test
