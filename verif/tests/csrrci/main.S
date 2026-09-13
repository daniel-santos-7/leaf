.include "defs.inc"

# csrrci on mscratch, the one machine CSR with no side effect of its own.
# Each case records two words: the value csrrci returned in rd, and the value
# left in the CSR read straight back. Covers the clear: the bits of the
# zero-extended uimm are cleared.
#
# Two shapes: rd and the 5-bit uimm advancing together, so every
# immediate 0..31 is used once per initial value, then a chain of four ops.
#
# rd = x0 drops the read half but must still do the write half; uimm = 0 is the
# no-write case verif/tests/csr_rs1_zero pins down separately.

.altmacro

.set dump_offset, 0

.macro test_csrrci_case rd, addr, tmp, init, uimm, off
    li     x\tmp, \init
    csrw   mscratch, x\tmp
    la     x\addr, begin_dump + \off
    csrrci x\rd, mscratch, \uimm
    sw     x\rd, 0(x\addr)
    csrr   x\tmp, mscratch
    sw     x\tmp, 4(x\addr)
.endm

.macro test_csrrci_all_regs init
    .set i, 0
    .rept 32
        test_csrrci_case %i, %(((i + 3) % 31) + 1), %(((i + 6) % 31) + 1), \
                       \init, %i, dump_offset
        .set dump_offset, dump_offset + 8
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_csrrci_all_regs 0x00000000
    test_csrrci_all_regs 0xFFFFFFFF
    test_csrrci_all_regs 0xA5A5A5A5

    # A chain from a cleared CSR: every op sees what the one before it left.
    csrw   mscratch, x0
    csrrci x6, mscratch, 0x1F
    csrrci x7, mscratch, 0x15
    csrrci x8, mscratch, 0x0A
    csrrci x9, mscratch, 0x01
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
