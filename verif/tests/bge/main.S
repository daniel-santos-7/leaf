.include "defs.inc"

# bge in three shapes, all recorded as the path that actually ran:
#   0x0A -> the branch was taken and skipped the instruction behind it
#   0xBA -> it fell through and that instruction ran
# Covers the signed greater-or-equal, where the pairs straddling 0x80000000
# answer the opposite way from bgeu.
#
# The three parts are 16 operand pairs on fixed registers, the same three
# pairs replayed with rs1/rs2 rotating over all 32 registers, and a backward
# branch closing a loop -- the accumulator says how many times the body ran.

.altmacro

.set dump_offset, 0

.macro test_bge_pair a, b, off
    li   x5, \a
    li   x6, \b
    li   x7, 0
    bge x5, x6, 1f
    addi x7, x7, 0xB0
1:  addi x7, x7, 0x0A
    la   x8, begin_dump + \off
    sw   x7, 0(x8)
.endm

.macro test_bge_reg_case rs1, rs2, res, addr, a, b, off
    li   x\rs1, \a
    li   x\rs2, \b
    li   x\res, 0
    bge x\rs1, x\rs2, 1f
    addi x\res, x\res, 0xB0
1:  addi x\res, x\res, 0x0A
    la   x\addr, begin_dump + \off
    sw   x\res, 0(x\addr)
.endm

.macro test_bge_all_regs a, b
    .set i, 0
    .rept 32
        test_bge_reg_case %i, %((i + 1) % 32), %((i + 2) % 32), \
                           %(((i + 3) % 31) + 1), \a, \b, dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_bge_pair 0x00000000, 0x00000000, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x00000000, 0x00000001, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x00000001, 0x00000000, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0xFFFFFFFF, 0x00000000, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x00000000, 0xFFFFFFFF, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0xFFFFFFFF, 0xFFFFFFFF, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x80000000, 0x7FFFFFFF, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x7FFFFFFF, 0x80000000, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x80000000, 0x80000000, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x7FFFFFFF, 0x7FFFFFFF, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0xAAAAAAAA, 0x55555555, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x55555555, 0xAAAAAAAA, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x80000000, 0xFFFFFFFF, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0xFFFFFFFF, 0x80000000, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x00000001, 0x7FFFFFFF, dump_offset
    .set dump_offset, dump_offset + 4
    test_bge_pair 0x12345678, 0x12345679, dump_offset
    .set dump_offset, dump_offset + 4

    test_bge_all_regs 0x00000005, 0x00000005
    test_bge_all_regs 0xFFFFFFFB, 0x00000005
    test_bge_all_regs 0x00000005, 0xFFFFFFFB

    # A backward branch closing a loop: loops while the limit is still at or
    # above the counter, so the
    # accumulator ends at three times the iteration count.
    li    x5, 1
    li    x6, 0
    li    x7, 8
1:  addi  x6, x6, 3
    addi  x5, x5, 1
    bge   x7, x5, 1b
    la    x8, begin_dump + dump_offset
    sw    x6, 0(x8)
    .set dump_offset, dump_offset + 4

    call finish_test
2:  j     2b
