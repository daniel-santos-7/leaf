.equ MEM_SIZE, 0x1000

.equ DUMP_START_ADDR, MEM_SIZE - 0xC
.equ DUMP_LENGTH_ADDR, MEM_SIZE - 0x8
.equ HALT_CMD_ADDR, MEM_SIZE - 0x4

.equ HALT_CMD_DATA, 0xDEADBEEF

.globl _start
_start:
    li t0, MEM_SIZE

    li t1, 0xCAFEBABE
    sw t1, -16(t0)

    li t1, 0xFF0
    sw t1, -12(t0)

    li t1, 0xFFF
    sw t1, -8(t0)

    li t1, HALT_CMD_DATA
    sw t1, -4(t0)
