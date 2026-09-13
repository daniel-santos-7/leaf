.include "defs.inc"

# srli over every shift amount 0..31 for each of 6 source patterns.
# The shift amount and rd advance together, so each shamt is also a different
# destination register; rs1 and the address register rotate with them.
# Covers the logical right shift, which must not replicate the sign.

.altmacro

.set dump_offset, 0

.macro test_srli_case rd, rs1, addr, src, sh, off
    li x\rs1, \src
    srli x\rd, x\rs1, \sh
    la x\addr, begin_dump + \off
    sw x\rd, 0(x\addr)
.endm

.macro test_srli_all_shamts src
    .set i, 0
    .rept 32
        test_srli_case %i, %((i + 1) % 32), %(((i + 3) % 31) + 1), \
                       \src, %i, dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_srli_all_shamts 0x00000000
    test_srli_all_shamts 0xFFFFFFFF
    test_srli_all_shamts 0x80000000
    test_srli_all_shamts 0x7FFFFFFF
    test_srli_all_shamts 0xAAAAAAAA
    test_srli_all_shamts 0x12345678
    call finish_test
1:  j    1b
