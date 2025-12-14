.globl _start

_start:
    li t0, 0xFFC

    li t1, 0xFFFFFFFF
    sw t1, 0x0(t0)

    li t1, 0xFFFF0000
    sw t1, 0x0(t0)

    li t1, 0x0000FFFF
    sw t1, 0x0(t0)

    li t1, 0xDEADBEEF
    sw t1, 0x0(t0)
