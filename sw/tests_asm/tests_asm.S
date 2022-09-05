.globl _start
_start:
    
loop:
    li a0, 'L'
    call uart_write
    li a0, 'e'
    call uart_write
    li a0, 'a'
    call uart_write
    li a0, 'f'
    call uart_write    
    li a0, '\n'
    call uart_write
    j loop

uart_write:
    li t2, 0x0
    li t3, 0x20
wait:
    lbu t2, 0x0(x0)
    andi t2, t2, 0x20
    bne t2, t3, wait
    sb a0, 0xC(x0)
    ret