.include "defs.inc"

# csrrs/csrrc with rs1 = x0, and csrrsi/csrrci with uimm = 0, must not write the
# CSR; csrrw/csrrwi must write even with rs1 = x0 / uimm = 0.
#
# The bug this guards against is only value-visible on a CSR that changes on its
# own: the spurious write hits the read bypass in csrs and freezes the next read
# of cycle/instret. Spike reports 0 for both counters here, so that half cannot
# be diffed against it -- what is diffed is the write/no-write decode itself.

.globl _start
_start:
    la     x1, begin_dump

    # A real set/clear writes; the same op with rs1 = x0 / uimm = 0 does not.
    csrw   mscratch, x0
    li     x9, 0x0000F0F0
    csrrs  x10, mscratch, x9
    csrr   x11, mscratch
    sw     x10, 0(x1)
    sw     x11, 4(x1)

    li     x9, 0x00005050
    csrrc  x12, mscratch, x9
    csrr   x13, mscratch
    sw     x12, 8(x1)
    sw     x13, 12(x1)

    csrrsi x14, mscratch, 5
    csrr   x15, mscratch
    sw     x14, 16(x1)
    sw     x15, 20(x1)

    csrrci x16, mscratch, 4
    csrr   x17, mscratch
    sw     x16, 24(x1)
    sw     x17, 28(x1)

    csrrs  x18, mscratch, x0
    csrr   x19, mscratch
    sw     x18, 32(x1)
    sw     x19, 36(x1)

    csrrc  x20, mscratch, x0
    csrr   x21, mscratch
    sw     x20, 40(x1)
    sw     x21, 44(x1)

    csrrsi x22, mscratch, 0
    csrr   x23, mscratch
    sw     x22, 48(x1)
    sw     x23, 52(x1)

    csrrci x24, mscratch, 0
    csrr   x25, mscratch
    sw     x24, 56(x1)
    sw     x25, 60(x1)

    # csrrw/csrrwi write even with rs1 = x0 / uimm = 0.
    li     x26, 0x12345678
    csrw   mscratch, x26
    csrrw  x27, mscratch, x0
    csrr   x28, mscratch
    sw     x27, 64(x1)
    sw     x28, 68(x1)

    li     x26, 0x0BADF00D
    csrw   mscratch, x26
    csrrwi x29, mscratch, 0
    csrr   x30, mscratch
    sw     x29, 72(x1)
    sw     x30, 76(x1)

    call finish_test
1:  j      1b
