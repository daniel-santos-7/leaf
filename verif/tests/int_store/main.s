.include "defs.inc"

# An interrupt must not annul a store that already went to the bus.
#
# MTIP is pending from reset and MTIE is armed, so enabling mstatus.MIE takes
# the trap on the store below. The trap is decided in EX, against that very
# instruction, so three things have to hold for it to run exactly once:
# dmls_block must not leave IDLE under exc_taken (or cyc/stb are already out),
# main_ctrl must kill the EX slot on exc_taken (or the store issues the cycle
# after, once MIE clears and exc_taken drops -- pipe_en is low here, so the
# slot does not move on its own), and trap_ctrl must not arm while a
# transaction is in flight.
#
# The handler moves the destination on by one word, so a store that ran twice
# leaves both words set. The dump carries the count and the OR rather than the
# raw words, so it does not pin down which side of the trap the store ran on.

.equ CLINT_MTIMECMP, 0x02004000
.equ PATTERN,        0x5A5A5A5A

.globl _start
_start:
    la   t0, handler
    csrw mtvec, t0
    li   s3, 0

    li   t0, 0x80               # mie.MTIE; mstatus.MIE still 0
    csrs mie, t0

    la   s6, scratch
    li   s5, PATTERN

    li   t0, 8
    csrs mstatus, t0            # enable -> the trap belongs around the sw
store:
    sw   s5, 0(s6)

    # Exactly one of the two words must carry the pattern.
    la   t1, scratch
    lw   t2, 0(t1)
    lw   t3, 4(t1)
    snez t4, t2
    snez t5, t3
    add  s7, t4, t5             # 1 = stored once, 2 = stored twice
    or   s8, t2, t3             # the pattern, whichever word took it

    la   t1, begin_dump
    sw   s3, 0(t1)              # 1, one trap
    sw   s7, 4(t1)              # 1, one store
    sw   s8, 8(t1)              # PATTERN
    call finish_test
1:  j    1b

handler:
    li   t2, CLINT_MTIMECMP
    li   t3, -1
    sw   t3, 0(t2)
    sw   t3, 4(t2)
    addi s6, s6, 4              # move the destination: a store that already
    addi s3, s3, 1              # ran would leave the old word set too
    mret

.section .data
scratch:
    .word 0
    .word 0
