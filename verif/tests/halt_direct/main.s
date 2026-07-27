.include "defs.inc"

.globl _start
_start:
    li x1, HALT_CMD_DATA
    li x2, HALT_CMD_ADDR
    sw x1, 0(x2)
