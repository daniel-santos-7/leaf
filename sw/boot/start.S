.equ WM_CMD,    0x31
.equ UART_BRDV, 0x1458
.equ RAM_BASE,  0x10000
.equ RAM_SIZE,  0x10000

.text
.globl _start
_start:
1:
	li t0, 0x0			# clear t0
	li t1, 0x0			# clear t1
	li t2, 0x0			# clear t2
	li t3, 0x0			# clear t3

	li t0, UART_BRDV	# baud rate divisor
	sh t0, 0x8(zero)	# uart setup
2:	
	li t0, 0xFF			# debug value
	sb t0, 0x10(zero)	# debug register
	li t0, WM_CMD		# write memory command
3:
	call uart_read		# read uart
	bne t0, a0, 3b		# verify write memory command
	li t0, 0x0F			# debug value
	sb t0, 0x10(zero)	# debug register
4:
	li t0, RAM_BASE		# t0 = ram base address
	li t1, RAM_SIZE		# t1 = ram size
	add t1, t1, t0		# t1 = t0 (ram size) + t1 (ram base address)
5:
	call uart_read		# read uart
	sb a0, 0x0(t0)		# store byte
	addi t0, t0, 0x1	# t0 = t0 + 1
	bne t0, t1, 5b		# loop if t0 !== t1
	li t0, 0x0			# debug value
	sb t0, 0x10(zero)	# debug register
	j RAM_BASE			# jump to program
	
uart_read:
	li t2, 0			# clear t2
	li t3, 0x4			# read enable flag
1:
	lbu t2, 0x0(zero)	# load enable flag from uart
	andi t2, t2, 0x4	# bit mask 
	bne t2, t3, 1b		# loop if enable flag is not 0xFF
	lb a0, 0xC(zero)	# a0 receive byte from uart
	ret					# return