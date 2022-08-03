_start:

    nop
    nop
    nop

    rdcycle t0
    rdcycle t0
    rdcycle t0

    # halt program
    li t0, 0x00000001
    li t1, 0x00200004   # halt simulation register address
    sw t0, 0x0(t1)