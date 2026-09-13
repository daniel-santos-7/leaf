.include "defs.inc"

# srl over 16 operand pairs, each replayed across all 32 registers:
# rd, rs1, rs2 and the address register all rotate, so every register is
# exercised in every role. Covers the logical right shift, with the shift
# amount masked to rs2(4:0).
#
# x0 lands in each role in turn: as rd the result is dropped, as a source it
# reads zero.

.altmacro

.set dump_offset, 0

.macro test_srl_case rd, rs1, rs2, addr, a, b, off
    li x\rs1, \a
    li x\rs2, \b
    srl x\rd, x\rs1, x\rs2
    la x\addr, begin_dump + \off
    sw x\rd, 0(x\addr)
.endm

.macro test_srl_all_regs a, b
    .set i, 0
    .rept 32
        test_srl_case %i, %((i + 1) % 32), %((i + 2) % 32), \
                       %(((i + 3) % 31) + 1), \a, \b, dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_srl_all_regs 0xFFFFFFFF, 0x00000000
    test_srl_all_regs 0xFFFFFFFF, 0x00000001
    test_srl_all_regs 0xFFFFFFFF, 0x0000001F
    test_srl_all_regs 0x80000000, 0x00000001
    test_srl_all_regs 0x80000000, 0x0000001F
    test_srl_all_regs 0x7FFFFFFF, 0x00000001
    test_srl_all_regs 0xAAAAAAAA, 0x00000004
    test_srl_all_regs 0x55555555, 0x00000011
    test_srl_all_regs 0x12345678, 0x00000008
    test_srl_all_regs 0xDEADBEEF, 0x00000010
    test_srl_all_regs 0x00000001, 0x0000001F
    test_srl_all_regs 0x00000001, 0x0000001E
    test_srl_all_regs 0xFFFFFFFF, 0x00000020
    test_srl_all_regs 0xFFFFFFFF, 0x00000021
    test_srl_all_regs 0x80000000, 0xFFFFFFFF
    test_srl_all_regs 0x12345678, 0x000000E0
    call finish_test
1:  j    1b
