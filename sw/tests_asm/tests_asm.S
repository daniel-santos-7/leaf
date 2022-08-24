.equ OUT_ADDR, 0x00000004

_start:

    li t0, 0xFFFFFFFF
    li t1, 0x00800000
    sw t0, -0x4(t1)
    lw t2, -0x4(t1)

    li t0, 'L'
    li t1, OUT_ADDR
    sw t0, 0x0(t1)

    # halt program
    li t0, 0x00000001
    li t1, 0x00000000
    sw t0, 0x0(t1)