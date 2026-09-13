.include "defs.inc"

# fence is architecturally a no-op on a single-hart core with no store buffer,
# so what there is to check is that it decodes as legal in every pred/succ
# spelling, leaves the register file alone, and does not upset the pipeline
# around it.
#
# fence.i is deliberately absent: it is Zifencei, not RV32I, and Spike at
# --isa=rv32i raises an illegal instruction on it while Leaf's decode accepts
# the whole FENCE opcode regardless of funct3.
#
# Three shapes: all 31 registers dumped across a battery of fence forms, a
# store/fence/load round trip, and fences sitting in and around a redirect.

.set dump_offset, 0

.globl _start
_start:
    li   x1, 0x5A5A0000 + 1
    li   x2, 0x5A5A0000 + 2
    li   x3, 0x5A5A0000 + 3
    li   x4, 0x5A5A0000 + 4
    li   x5, 0x5A5A0000 + 5
    li   x6, 0x5A5A0000 + 6
    li   x7, 0x5A5A0000 + 7
    li   x8, 0x5A5A0000 + 8
    li   x9, 0x5A5A0000 + 9
    li   x10, 0x5A5A0000 + 10
    li   x11, 0x5A5A0000 + 11
    li   x12, 0x5A5A0000 + 12
    li   x13, 0x5A5A0000 + 13
    li   x14, 0x5A5A0000 + 14
    li   x15, 0x5A5A0000 + 15
    li   x16, 0x5A5A0000 + 16
    li   x17, 0x5A5A0000 + 17
    li   x18, 0x5A5A0000 + 18
    li   x19, 0x5A5A0000 + 19
    li   x20, 0x5A5A0000 + 20
    li   x21, 0x5A5A0000 + 21
    li   x22, 0x5A5A0000 + 22
    li   x23, 0x5A5A0000 + 23
    li   x24, 0x5A5A0000 + 24
    li   x25, 0x5A5A0000 + 25
    li   x26, 0x5A5A0000 + 26
    li   x27, 0x5A5A0000 + 27
    li   x28, 0x5A5A0000 + 28
    li   x29, 0x5A5A0000 + 29
    li   x30, 0x5A5A0000 + 30
    li   x31, 0x5A5A0000 + 31

    fence
    fence rw, rw
    fence r, r
    fence w, w
    fence r, w
    fence w, r
    fence i, o
    fence o, i
    fence iorw, iorw
    fence ir, ow

    # x31 is the address register, so its own value goes through mscratch.
    csrw mscratch, x31
    la   x31, begin_dump
    sw   x1, 0(x31)
    sw   x2, 4(x31)
    sw   x3, 8(x31)
    sw   x4, 12(x31)
    sw   x5, 16(x31)
    sw   x6, 20(x31)
    sw   x7, 24(x31)
    sw   x8, 28(x31)
    sw   x9, 32(x31)
    sw   x10, 36(x31)
    sw   x11, 40(x31)
    sw   x12, 44(x31)
    sw   x13, 48(x31)
    sw   x14, 52(x31)
    sw   x15, 56(x31)
    sw   x16, 60(x31)
    sw   x17, 64(x31)
    sw   x18, 68(x31)
    sw   x19, 72(x31)
    sw   x20, 76(x31)
    sw   x21, 80(x31)
    sw   x22, 84(x31)
    sw   x23, 88(x31)
    sw   x24, 92(x31)
    sw   x25, 96(x31)
    sw   x26, 100(x31)
    sw   x27, 104(x31)
    sw   x28, 108(x31)
    sw   x29, 112(x31)
    sw   x30, 116(x31)
    csrr x30, mscratch
    sw   x30, 120(x31)
    .set dump_offset, 124

    # A store, a fence, then the load that must still see the stored word.
    la   x5, begin_dump + dump_offset
    li   x6, 0xCAFEBABE
    sw   x6, 0(x5)
    fence rw, rw
    lw   x7, 0(x5)
    sw   x7, 4(x5)
    li   x6, 0x0BADF00D
    sw   x6, 8(x5)
    fence w, r
    lw   x7, 8(x5)
    sw   x7, 12(x5)
    .set dump_offset, dump_offset + 16

    # A fence in the shadow of a taken branch must be squashed with the rest.
    li   x7, 0
    beq  x0, x0, 1f
    fence rw, rw
    addi x7, x7, 0xB0
1:  addi x7, x7, 0x0A
    la   x8, begin_dump + dump_offset
    sw   x7, 0(x8)              # -> 0x0A
    .set dump_offset, dump_offset + 4

    # A fence as the first instruction at a redirect target.
    li   x9, 0
    beq  x0, x0, 2f
    addi x9, x9, 0xB0
2:  fence
    addi x9, x9, 0x0C
    la   x8, begin_dump + dump_offset
    sw   x9, 0(x8)              # -> 0x0C
    .set dump_offset, dump_offset + 4

    # A fence refetched on every pass of a loop.
    li   x5, 4
    li   x6, 0
3:  fence rw, rw
    addi x6, x6, 5
    addi x5, x5, -1
    bne  x5, x0, 3b
    la   x8, begin_dump + dump_offset
    sw   x6, 0(x8)              # -> 0x14
    .set dump_offset, dump_offset + 4

    call finish_test
4:  j    4b
