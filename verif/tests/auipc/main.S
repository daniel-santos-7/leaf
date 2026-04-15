.include "defs.inc"

.altmacro

.set dump_offset, 0

.macro test_auipc_case reg, addr_reg, val, off
    auipc x\reg, \val
    la x\addr_reg, begin_dump + \off
    sw x\reg, 0(x\addr_reg)
.endm

.macro test_auipc_all_regs val
    .set i, 0
    .rept 32
        .if i == 31
            test_auipc_case %i, 1, \val, dump_offset
        .else
            test_auipc_case %i, %(i + 1), \val, dump_offset
        .endif
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.macro test_auipc_basic_patterns
    test_auipc_all_regs 0x00000
    test_auipc_all_regs 0xFFFFF
    test_auipc_all_regs 0xAAAAA
    test_auipc_all_regs 0x55555
.endm

.macro test_auipc_walking_ones
    .set bit, 0x80000
    .rept 20
        test_auipc_all_regs %bit
        .set bit, bit >> 1
    .endr
.endm

.macro test_auipc_walking_zeros
    .set bit, 0x80000
    .rept 20
        test_auipc_all_regs %(0xFFFFF ^ bit)
        .set bit, bit >> 1
    .endr
.endm

.globl _start
_start:
    test_auipc_basic_patterns
    test_auipc_walking_ones
    test_auipc_walking_zeros
    call finish_test
