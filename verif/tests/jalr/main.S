.include "defs.inc"

# jalr in four shapes: the link value for every rd, a nonzero offset in both
# directions, the mandatory clearing of target bit 0, and a real call/return
# pair. Every jump has a poisoned instruction directly behind it that must
# never run.
#
# rs1 is always a nonzero register: with rs1 = x0 the target would be the
# immediate itself, which is not a valid instruction address here.

.altmacro

.set dump_offset, 0

.macro test_jalr_case rd, rs1, addr, off
    la   x\rs1, 1f
    li   x\rd, 0xBAD
    jalr x\rd, x\rs1, 0
    li   x\rd, 0xDEAD
1:  la   x\addr, begin_dump + \off
    sw   x\rd, 0(x\addr)
.endm

.macro test_jalr_all_regs
    .set i, 0
    .rept 32
        test_jalr_case %i, %(((i + 1) % 31) + 1), \
                       %(((i + 3) % 31) + 1), dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_jalr_all_regs

    # A positive offset: base + 8 skips the first two words of the block.
    li   x7, 0
    la   x5, fwd_base
    jalr x6, x5, 8
fwd_base:
    addi x7, x7, 1
    addi x7, x7, 2
    addi x7, x7, 4
    addi x7, x7, 8
    la   x8, begin_dump + dump_offset
    sw   x7, 0(x8)              # 0x0C if only the last two words ran
    .set dump_offset, dump_offset + 4

    # A negative offset: base - 8 lands back on the first word of the block.
    li   x7, 0
    la   x5, back_base + 8
    jalr x6, x5, -8
back_base:
    addi x7, x7, 1
    addi x7, x7, 2
    beq  x0, x0, 2f
    addi x7, x7, 4
2:  la   x8, begin_dump + dump_offset
    sw   x7, 0(x8)              # 0x03 if the block ran from its first word
    .set dump_offset, dump_offset + 4

    # Bit 0 of the computed target is cleared, so +1 lands on the same word.
    li   x7, 0
    la   x5, 3f
    jalr x6, x5, 1
    li   x7, 0xDEAD
3:  addi x7, x7, 0x55
    la   x8, begin_dump + dump_offset
    sw   x7, 0(x8)              # 0x55 if the +1 was dropped
    .set dump_offset, dump_offset + 4

    # A call/return pair: jal links, jalr x0, ra, 0 returns.
    li   x7, 0
    jal  x1, adder
    jal  x1, adder
    la   x8, begin_dump + dump_offset
    sw   x7, 0(x8)              # 0x14 after two calls
    .set dump_offset, dump_offset + 4

    call finish_test
4:  j    4b

adder:
    addi x7, x7, 10
    jalr x0, x1, 0
