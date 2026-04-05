.section .text
.globl _start

_start:
    la   t0, begin_signature
    li   t1, 0x00000001
    sw   t1, 0(t0)
    call halt
