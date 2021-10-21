.equ UART_BRDV, 0x1B2

.globl _start
_start:
    li t0, 0	# clear t0
    li t1, 0
    li t2, 0
    li t3, 0

uart_setup:
    li t0, UART_BRDV
    sh t0, 0x8(x0)

msg:

    li a0, 0
    call uart_write

    li a0, 'H'
    call uart_write

    li a0, 'E'
    call uart_write

    li a0, 'L'
    call uart_write

    li a0, 'L'
    call uart_write

    li a0, 'O'
    call uart_write

    li t0, 0
    li t1, 0x17D7840

    li a0, '\n'
    call uart_write

    delay:
        addi t0, t0, 1
        bne t0, t1, delay

    j msg

uart_write:
    li t2, 0
    li t3, 0x20

    wait:
        lbu t2, 0x0(x0)
        andi t2, t2, 0x20
        bne t2, t3, wait

    sb a0, 0xC(x0)
    ret
