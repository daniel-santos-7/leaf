.include "defs.inc"

# sw writing straight into the dump region, so what the dump shows is the
# memory the store left behind -- no read-back path in the way. Every slot is
# pre-filled with 0xFFFFFFFF first, so a store that writes too much or too
# little is visible as a stray 0xFF or a surviving one. Covers the whole word,
# with nothing of the previous contents left.
#
# Three shapes: the explicit offsets with their expected words spelled out
# below, the source and base registers rotating over all 32 registers, and a
# pair of negative immediates off a shifted base.

.altmacro

.set dump_offset, 0

.macro fill_slot off
    la   x5, begin_dump + \off
    li   x6, -1
    sw   x6, 0(x5)
.endm

.macro test_sw_case src, base, val, elem, off
    la   x\base, begin_dump + \off
    li   x\src, -1
    sw   x\src, 0(x\base)
    li   x\src, \val
    sw   x\src, \elem(x\base)
.endm

.macro test_sw_all_regs
    .set i, 0
    .rept 32
        test_sw_case %i, %(((i + 1) % 31) + 1), %(0xAABBCC00 + i * 7), \
                      0, dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    fill_slot dump_offset
    li   x6, 0x12345678
    sw   x6, 0(x5)              # -> 0x12345678
    .set dump_offset, dump_offset + 4
    fill_slot dump_offset
    sw   x0, 0(x5)              # -> 0x00000000
    .set dump_offset, dump_offset + 4

    # src and base rotate over all 32 registers
    test_sw_all_regs

    # negative immediates off a base pointing past the slots
    fill_slot dump_offset
    fill_slot %(dump_offset + 4)
    la   x5, begin_dump + dump_offset + 8
    li   x6, 0x0BADF00D
    sw   x6, -8(x5)             # -> 0x0BADF00D
    li   x6, 0x0BADF00D
    sw   x6, -4(x5)             # -> 0x0BADF00D
    .set dump_offset, dump_offset + 8

    call finish_test
1:  j    1b
