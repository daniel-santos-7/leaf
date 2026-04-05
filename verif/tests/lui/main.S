.altmacro

.set dump_offset, 0

.macro _lui_one r, val
    lui x\r, \val
.endm

.macro _sw_one r, val
    .if \r == 5
        csrw mscratch, x5
        csrw mepc, x31
        la x31, begin_dump + dump_offset
        csrr x5, mscratch
        sw x5, 0(x31)
        csrr x31, mepc
    .else
        csrw mscratch, x5
        la x5, begin_dump + dump_offset
        sw x\r, 0(x5)
        csrr x5, mscratch
    .endif

    .set dump_offset, dump_offset + 4
.endm

.macro lui_all val
    .set i, 0
    .rept 32
        _lui_one %i, \val
        _sw_one %i, \val
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
    call finish_test
