.section .text
.globl _start

_start:
    la   t0, begin_signature
    li   t1, 0x00000001
    sw   t1, 0(t0)
    la   t0, tohost
    li   t1, 1
    sw   t1, 0(t0)
    sw   zero, 4(t0)
