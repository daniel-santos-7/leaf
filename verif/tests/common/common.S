.section .text
.globl store_regs

store_regs:
    csrw mscratch, x31
    la x31, begin_dump

    sw x0, 0(x31)
    sw x1, 4(x31)
    sw x2, 8(x31)
    sw x3, 12(x31)
    sw x4, 16(x31)
    sw x5, 20(x31)
    sw x6, 24(x31)
    sw x7, 28(x31)
    sw x8, 32(x31)
    sw x9, 36(x31)
    sw x10, 40(x31)
    sw x11, 44(x31)
    sw x12, 48(x31)
    sw x13, 52(x31)
    sw x14, 56(x31)
    sw x15, 60(x31)
    sw x16, 64(x31)
    sw x17, 68(x31)
    sw x18, 72(x31)
    sw x19, 76(x31)
    sw x20, 80(x31)
    sw x21, 84(x31)
    sw x22, 88(x31)
    sw x23, 92(x31)
    sw x24, 96(x31)
    sw x25, 100(x31)
    sw x26, 104(x31)
    sw x27, 108(x31)
    sw x28, 112(x31)
    sw x29, 116(x31)
    sw x30, 120(x31)

    csrr x30, mscratch
    sw x30, 124(x31)
    ret
