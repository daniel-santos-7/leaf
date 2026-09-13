.include "defs.inc"

# csrrwi on mscratch, the one machine CSR with no side effect of its own.
# Each case records two words: the value csrrwi returned in rd, and the value
# left in the CSR read straight back. Covers the swap: rd gets the old value
# and the zero-extended uimm lands whole.
#
# Two shapes: rd and the 5-bit uimm advancing together, so every
# immediate 0..31 is used once per initial value, then a chain of four ops.
#
# rd = x0 drops the read half but must still do the write half; uimm = 0 is a
# write of zero for csrrwi.

.altmacro

.set dump_offset, 0

.macro test_csrrwi_case rd, addr, tmp, init, uimm, off
    li     x\tmp, \init
    csrw   mscratch, x\tmp
    la     x\addr, begin_dump + \off
    csrrwi x\rd, mscratch, \uimm
    sw     x\rd, 0(x\addr)
    csrr   x\tmp, mscratch
    sw     x\tmp, 4(x\addr)
.endm

.macro test_csrrwi_all_regs init
    .set i, 0
    .rept 32
        test_csrrwi_case %i, %(((i + 3) % 31) + 1), %(((i + 6) % 31) + 1), \
                       \init, %i, dump_offset
        .set dump_offset, dump_offset + 8
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_csrrwi_all_regs 0x00000000
    test_csrrwi_all_regs 0xFFFFFFFF
    test_csrrwi_all_regs 0xA5A5A5A5

    # A chain from a cleared CSR: every op sees what the one before it left.
    csrw   mscratch, x0
    csrrwi x6, mscratch, 0x1F
    csrrwi x7, mscratch, 0x15
    csrrwi x8, mscratch, 0x0A
    csrrwi x9, mscratch, 0x01
    csrr   x10, mscratch
    la     x11, begin_dump + dump_offset
    sw     x6,  0(x11)
    sw     x7,  4(x11)
    sw     x8,  8(x11)
    sw     x9,  12(x11)
    sw     x10, 16(x11)
    .set dump_offset, dump_offset + 20

    call finish_test
1:  j      1b
