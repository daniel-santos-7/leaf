.equ WM_CMD, 0x31
.equ UART_BRDV,0x1B2
.equ RAM_BASE, 0x10000
.equ RAM_SIZE, 0x10000

.text
.globl _start
_start:
	li t0, 0x0					# clear t0
	li t1, 0x0					# clear t1
	li t2, 0x0					# clear t2
	li t3, 0x0					# clear t3

	li t0, UART_BRDV			# baud rate divisor
	sh t0, 0x8(zero)			# uart setup

wait_write_cmd:
	li t0, WM_CMD				# write memory command

wait_cmd_loop:
	call uart_read				# read uart
	bne t0, a0, wait_cmd_loop	# verify write memory command

	li a1, 0x0
	call uart_write
	li a1, 0x79
	call uart_write

	li t0, 0x4					# program size loop counter

program_size:
	call uart_read 				# get program size
	slli t1, t1, 0x8			# shift byte to left
	add t1, t1, a0	      		# save program size
	addi t0, t0, -0x1			# counter = counter - 1
	bnez t0, program_size		# loop if counter > 0

out_of_memory:
	mv t0, t1					# program size
	li t1, RAM_SIZE				# max program size
	# bgtu t0, t1, wait_write_cmd	# loop if program size > max program size
	bleu t0, t1, load_program	# load program if program_size <= max program size

	li a1, 0x0
	call uart_write
	li a1, 0x1F
	call uart_write
	j wait_write_cmd

load_program:
	li a1, 0x0
	call uart_write
	li a1, 0x79
	call uart_write

	li t1, RAM_BASE				# ram base address
	add t0, t0, t1				# program size + ram base address

load_loop:
	call uart_read				# read instruction
	sb a0, 0x0(t1)				# store instruction in address + RAM_BASE
	addi t1, t1, 1				# t1 = instruction address
	bltu t1, t0, load_loop 		# load if t1 < program size

	li a1, 0x0
	call uart_write
	li a1, 0x79
	call uart_write

load_end:
	j RAM_BASE					# go to ram base address

uart_read:
	li t2, 0					# clear t2
	li t3, 0x4					# read enable flag
	
uart_read_wait:
	lbu t2, 0x0(zero)			# load enable flag from uart
	andi t2, t2, 0x4			# bit mask 
	bne t2, t3, uart_read_wait	# loop if enable flag is not 0xFF
	lw a0, 0xC(zero)			# a0 receive byte from uart
	ret							# return

uart_write:
    li t2, 0
    li t3, 0x20

uart_write_wait:
    lbu t2, 0x0(zero)
    andi t2, t2, 0x20
    bne t2, t3, uart_write_wait
    sb a1, 0xC(zero)
    ret