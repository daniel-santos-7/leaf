.include "defs.inc"

# xor over 14 operand pairs, each replayed across all 32 registers:
# rd, rs1, rs2 and the address register all rotate, so every register is
# exercised in every role. Covers the bitwise xor.
#
# x0 lands in each role in turn: as rd the result is dropped, as a source it
# reads zero.

.altmacro

.set dump_offset, 0

.macro test_xor_case rd, rs1, rs2, addr, a, b, off
    li x\rs1, \a
    li x\rs2, \b
    xor x\rd, x\rs1, x\rs2
    la x\addr, begin_dump + \off
    sw x\rd, 0(x\addr)
.endm

.macro test_xor_all_regs a, b
    .set i, 0
    .rept 32
        test_xor_case %i, %((i + 1) % 32), %((i + 2) % 32), \
                       %(((i + 3) % 31) + 1), \a, \b, dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_xor_all_regs 0x00000000, 0x00000000
    test_xor_all_regs 0x00000000, 0x00000001
    test_xor_all_regs 0x00000001, 0x00000000
    test_xor_all_regs 0xFFFFFFFF, 0x00000001
    test_xor_all_regs 0x00000001, 0xFFFFFFFF
    test_xor_all_regs 0x7FFFFFFF, 0x00000001
    test_xor_all_regs 0x80000000, 0x00000001
    test_xor_all_regs 0x80000000, 0xFFFFFFFF
    test_xor_all_regs 0x7FFFFFFF, 0x80000000
    test_xor_all_regs 0xAAAAAAAA, 0x55555555
    test_xor_all_regs 0x55555555, 0xAAAAAAAA
    test_xor_all_regs 0xFFFFFFFF, 0xFFFFFFFF
    test_xor_all_regs 0x12345678, 0x9ABCDEF0
    test_xor_all_regs 0xDEADBEEF, 0x0BADF00D
    call finish_test
1:  j    1b
