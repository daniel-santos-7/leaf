# Every register-register ALU op over twelve operand pairs picked for the
# edges: shift amounts 0/1/30/31, the signed/unsigned boundary that separates
# slt from sltu, and the carry-out of bit 31.
#
# The alu had no directed coverage at all -- add/sub/sll/slt/... are empty
# stub directories -- so any change to it could only be checked with RISCOF.

.include "defs.inc"

.set dump_offset, 0

.macro alu_case a, b
    li   x5, \a
    li   x6, \b
    la   x7, begin_dump + dump_offset
    add  x8, x5, x6
    sw   x8,  0(x7)
    sub  x8, x5, x6
    sw   x8,  4(x7)
    sll  x8, x5, x6
    sw   x8,  8(x7)
    slt  x8, x5, x6
    sw   x8, 12(x7)
    sltu x8, x5, x6
    sw   x8, 16(x7)
    xor  x8, x5, x6
    sw   x8, 20(x7)
    srl  x8, x5, x6
    sw   x8, 24(x7)
    sra  x8, x5, x6
    sw   x8, 28(x7)
    or   x8, x5, x6
    sw   x8, 32(x7)
    and  x8, x5, x6
    sw   x8, 36(x7)
    .set dump_offset, dump_offset + 40
.endm

.globl _start
_start:
    alu_case 0x00000000, 0x00000000
    alu_case 0xFFFFFFFF, 0x00000001
    alu_case 0x7FFFFFFF, 0x00000001
    alu_case 0x80000000, 0x00000001
    alu_case 0x80000000, 0x0000001F
    alu_case 0xAAAAAAAA, 0x00000005
    alu_case 0x55555555, 0x0000001E
    alu_case 0xFFFFFFFF, 0xFFFFFFFF
    alu_case 0x00000001, 0x80000000
    alu_case 0x12345678, 0x00000010
    alu_case 0x80000000, 0x80000000
    alu_case 0xDEADBEEF, 0x0000000C
    call finish_test
1:  j      1b
