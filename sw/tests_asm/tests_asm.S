.globl _start
_start:
    call uart_read
    call uart_write
    li t0, 0x00000010
    li t1, 0x1
    sw t1, 0x0(t0)

uart_read:
	li t2, 0		 
	li t3, 0x4		 
1:
	lbu t2, 0x0(zero)
	andi t2, t2, 0x4 
	bne t2, t3, 1b	 
	lw a0, 0xC(zero) 
	ret				 

uart_write:
    li t2, 0x0
    li t3, 0x20
1:
    lbu t2, 0x0(x0)
    andi t2, t2, 0x20
    bne t2, t3, 1b
    sb a0, 0xC(zero)
    ret