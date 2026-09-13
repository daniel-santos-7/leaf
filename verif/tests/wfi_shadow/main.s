.include "defs.inc"

# WFI sitting in the shadow of a taken jump must never execute.
# If it does, the core waits for an interrupt that never comes (the
# testbench ties all IRQ inputs low) and the simulation never halts.

.globl _start
_start:
    j    skip
    wfi                     # speculatively fetched, must be squashed

skip:
    li   a0, 0x600D600D
    la   t1, begin_dump
    sw   a0, 0(t1)
    call finish_test
1:  j    1b
