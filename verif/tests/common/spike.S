.section .text
.globl finish_test

finish_test:
    la t0, tohost
    li t1, 1
    sw t1, 0x0(t0)
    sw zero, 0x4(t0)
    ret
