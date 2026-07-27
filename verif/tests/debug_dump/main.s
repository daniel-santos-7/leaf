.include "defs.inc"

.globl _start
_start:
    li   sp, MEM_BASE + MEM_SIZE

    li   t0, DUMP_START_ADDR
    li   t1, 0x00000080
    sw   t1, 0(t0)

    li   t0, DUMP_STOP_ADDR
    li   t1, 0x00000090
    sw   t1, 0(t0)

    li   t0, HALT_CMD_ADDR
    li   t1, HALT_CMD_DATA
    sw   t1, 0(t0)
