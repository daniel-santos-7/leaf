.include "defs.inc"

.altmacro

.set dump_offset, 0

.macro test_addi_case reg, addr_reg, src, imm, off
    li x\reg, \src
    addi x\reg, x\reg, \imm
    la x\addr_reg, begin_dump + \off
    sw x\reg, 0(x\addr_reg)
.endm

.macro test_addi_all_regs src, imm
    .set i, 0
    .rept 32
        .if i == 31
            test_addi_case %i, 1, \src, \imm, dump_offset
        .else
            test_addi_case %i, %(i + 1), \src, \imm, dump_offset
        .endif
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.macro test_addi_case_group src
    test_addi_all_regs \src, 0
    test_addi_all_regs \src, 1
    test_addi_all_regs \src, -1
    test_addi_all_regs \src, 0x7FF
    test_addi_all_regs \src, -2048
    test_addi_all_regs \src, 0x555
    test_addi_all_regs \src, -171
.endm

.globl _start
_start:
    test_addi_case_group 0x00000000
    test_addi_case_group 0xFFFFFFFF
    test_addi_case_group 0xAAAAAAAA
    test_addi_case_group 0x55555555
    test_addi_case_group 0x80000000
    test_addi_case_group 0x7FFFFFFF
    call finish_test
