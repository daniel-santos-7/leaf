.include "defs.inc"

.altmacro

.set dump_offset, 0

.macro test_li_case reg, addr_reg, val, off
    li x\reg, \val
    la x\addr_reg, begin_dump + \off
    sw x\reg, 0(x\addr_reg)
.endm

.macro test_li_all_regs val
    .set i, 0
    .rept 32
        .if i == 31
            test_li_case %i, 1, \val, dump_offset
        .else
            test_li_case %i, %(i + 1), \val, dump_offset
        .endif
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.macro test_li_basic_patterns
    test_li_all_regs 0x00000000
    test_li_all_regs 0xFFFFFFFF
    test_li_all_regs 0xAAAAAAAA
    test_li_all_regs 0x55555555
.endm

.macro test_li_walking_ones
    .set bit, 0x80000000
    .rept 32
        test_li_all_regs %bit
        .set bit, bit >> 1
    .endr
.endm

.macro test_li_walking_zeros
    .set bit, 0x80000000
    .rept 32
        test_li_all_regs %(0xFFFFFFFF ^ bit)
        .set bit, bit >> 1
    .endr
.endm

.globl _start
_start:
    test_li_basic_patterns
    test_li_walking_ones
    test_li_walking_zeros
    call finish_test
