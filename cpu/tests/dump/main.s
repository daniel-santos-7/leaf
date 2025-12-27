.equ HALT_CMD_ADDR, 0xFFC
.equ HALT_CMD_DATA, 0xDEADBEEF

.globl _start
_start:
    li t0, HALT_CMD_ADDR
    li t1, HALT_CMD_DATA
    sw t1, 0x0(t0)
