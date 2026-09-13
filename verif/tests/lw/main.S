.include "defs.inc"

# lw against four data words written at the head of the dump region, so the
# source bytes are part of the dumped output and both models see the same
# memory without relying on a loaded .data section.
#
#   begin_dump+0  0x8F7F0180    begin_dump+8  0xDEADBEEF
#   begin_dump+4  0x00FF7F80    begin_dump+12 0x12345678
#
# Three shapes: rd and the base register rotating over all 32 registers, a
# sweep of every 4 element in the block, and four immediate offsets including
# negative ones. Covers the whole word, with no extension to do.

.altmacro

.set dump_offset, 0

.macro test_lw_case rd, base, addr, elem, off
    la  x\base, begin_dump
    lw x\rd, \elem(x\base)
    la  x\addr, begin_dump + \off
    sw  x\rd, 0(x\addr)
.endm

.macro test_lw_all_regs elem
    .set i, 0
    .rept 32
        test_lw_case %i, %(((i + 1) % 31) + 1), %(((i + 3) % 31) + 1), \
                      \elem, dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.macro test_lw_at base_off, imm
    la  x5, begin_dump + \base_off
    lw x6, \imm(x5)
    la  x7, begin_dump + dump_offset
    sw  x6, 0(x7)
    .set dump_offset, dump_offset + 4
.endm

.globl _start
_start:
    # The data block, and the first four words of the dump.
    la   x5, begin_dump
    li   x6, 0x8F7F0180
    sw   x6, 0(x5)
    li   x6, 0x00FF7F80
    sw   x6, 4(x5)
    li   x6, 0xDEADBEEF
    sw   x6, 8(x5)
    li   x6, 0x12345678
    sw   x6, 12(x5)
    .set dump_offset, 16

    # rd and the base register rotate; the element stays put.
    test_lw_all_regs 0

    # every element in the block
    test_lw_at 0, 0
    test_lw_at 0, 4
    test_lw_at 0, 8
    test_lw_at 0, 12

    # immediate offsets, forward and back
    test_lw_at 16, -16
    test_lw_at 16, -4
    test_lw_at 0, 4
    test_lw_at 0, 8

    call finish_test
1:  j    1b
