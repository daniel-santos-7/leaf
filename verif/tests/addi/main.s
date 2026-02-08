.macro set_all_regs val
    .irp r, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20, x21, x22, x23, x24, x25, x26, x27, x28, x29, x30, x31
        addi \r, x0, \val
    .endr
.endm

.globl _start

_start:
    set_all_regs 0x0FF
