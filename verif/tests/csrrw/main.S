.include "defs.inc"

# csrrw on mscratch, the one machine CSR with no side effect of its own.
# Each case records two words: the value csrrw returned in rd, and the value
# left in the CSR read straight back. Covers the swap: rd gets the old value
# and rs1 lands whole.
#
# Two shapes: rd and rs1 rotating over all 32 registers for three
# initial/operand pairs, then a chain of four ops on one CSR.
#
# rd = x0 drops the read half but must still do the write half; rs1 = x0 is a
# write of zero for csrrw.

.altmacro

.set dump_offset, 0

.macro test_csrrw_case rd, rs1, addr, tmp, init, val, off
    li    x\tmp, \init
    csrw  mscratch, x\tmp
    li    x\rs1, \val
    la    x\addr, begin_dump + \off
    csrrw x\rd, mscratch, x\rs1
    sw    x\rd, 0(x\addr)
    csrr  x\tmp, mscratch
    sw    x\tmp, 4(x\addr)
.endm

.macro test_csrrw_all_regs init, val
    .set i, 0
    .rept 32
        test_csrrw_case %i, %((i + 1) % 32), %(((i + 3) % 31) + 1), \
                       %(((i + 6) % 31) + 1), \init, \val, dump_offset
        .set dump_offset, dump_offset + 8
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_csrrw_all_regs 0x00000000, 0xFFFFFFFF
    test_csrrw_all_regs 0xFFFFFFFF, 0x0F0F0F0F
    test_csrrw_all_regs 0xA5A5A5A5, 0x5A5A5A5A

    # A chain from a cleared CSR: every op sees what the one before it left.
    csrw  mscratch, x0
    li    x5, 0x0000FF00
    csrrw x6, mscratch, x5
    li    x5, 0x00FF0000
    csrrw x7, mscratch, x5
    li    x5, 0x0000F000
    csrrw x8, mscratch, x5
    li    x5, 0xFF000000
    csrrw x9, mscratch, x5
    csrr  x10, mscratch
    la    x11, begin_dump + dump_offset
    sw    x6,  0(x11)
    sw    x7,  4(x11)
    sw    x8,  8(x11)
    sw    x9,  12(x11)
    sw    x10, 16(x11)
    .set dump_offset, dump_offset + 20

    call finish_test
1:  j     1b
