.include "defs.inc"

# sh writing straight into the dump region, so what the dump shows is the
# memory the store left behind -- no read-back path in the way. Every slot is
# pre-filled with 0xFFFFFFFF first, so a store that writes too much or too
# little is visible as a stray 0xFF or a surviving one. Covers that exactly one
# half of the word moves and the upper 16 bits of
# the source are dropped.
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

.macro test_sh_case src, base, val, elem, off
    la   x\base, begin_dump + \off
    li   x\src, -1
    sw   x\src, 0(x\base)
    li   x\src, \val
    sh   x\src, \elem(x\base)
.endm

.macro test_sh_all_regs
    .set i, 0
    .rept 32
        test_sh_case %i, %(((i + 1) % 31) + 1), %(0xAABBCC00 + i * 7), \
                      %((i % 2) * 2) , dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    fill_slot dump_offset
    li   x6, 0x12345678
    sh   x6, 0(x5)              # -> 0xFFFF5678
    .set dump_offset, dump_offset + 4
    fill_slot dump_offset
    li   x6, 0x12345678
    sh   x6, 2(x5)              # -> 0x5678FFFF
    .set dump_offset, dump_offset + 4

    # src and base rotate over all 32 registers
    test_sh_all_regs

    # negative immediates off a base pointing past the slots
    fill_slot dump_offset
    fill_slot %(dump_offset + 4)
    la   x5, begin_dump + dump_offset + 8
    li   x6, 0x0BADF00D
    sh   x6, -8(x5)             # -> 0xFFFFF00D
    li   x6, 0x0BADF00D
    sh   x6, -2(x5)             # -> 0xF00DFFFF
    .set dump_offset, dump_offset + 8

    call finish_test
1:  j    1b
