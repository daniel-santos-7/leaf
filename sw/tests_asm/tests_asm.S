_start:
    nop

    li t0, 0x5
    li t1, 0x4
    sw t0, 0x0(t1)

    # halt program
    li t0, 0x00000001
    li t1, 0x00000000   # halt simulation register address
    sw t0, 0x0(t1)