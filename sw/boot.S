# ----------------------------------------------------------------------
# Leaf project
# boot program
# developed by: Daniel Santos
# 2021
# ----------------------------------------------------------------------

.equ LOAD_CMD, 0x00000077
.equ RAM_BASE, 0x200
.equ RAM_SIZE, 0x100

_start:
	
	li t0, 0	# clear t0
	li t1, 0	# clear t1
	li t2, 0	# clear t2
	li t3, 0	# clear t3

	load_program_begin:
		li t0, LOAD_CMD					# load command
		call uart_read					# read uart
		bne t0, a0, load_program_begin	# verify load command

	program_size:			
		call uart_read 				# get program size
		mv t0, a0	      			# save program size
		li t1, RAM_SIZE				# max program size
		bleu t0, t1, load_program	# continue if program size <= max program size 

	out_of_memory:
		j load_program_begin

	load_program:
		li t1, 0

		load_loop:
			call uart_read			# read instruction
			sw a0, RAM_BASE(t1)		# store instruction in address + RAM_BASE
			addi t1, t1, 4			# t1 = instruction address
			bltu t1, t0, load_loop 	# load if t1 < program size

	load_end:
		li	x1,  0
		li	x2,  0
		li	x3,  0
		li	x4,  0
		li	x5,  0
		li	x6,  0
		li	x7,  0
		li	x8,  0
		li	x9,  0
		li	x10, 0
		li	x11, 0
		li	x12, 0
		li	x13, 0
		li	x14, 0
		li	x15, 0
		li	x16, 0
		li	x17, 0
		li	x18, 0
		li	x19, 0
		li	x20, 0
		li	x21, 0
		li	x22, 0
		li	x23, 0
		li	x24, 0
		li	x25, 0
		li	x26, 0
		li	x27, 0
		li	x28, 0
		li	x29, 0
		li	x30, 0
		li	x31, 0
		j RAM_BASE

	uart_read:
		li t2, 0
		li t3, 0xF
		wait:
			lw t2, 0x0(x0)
			and t2, t2, t3
			bne t2, t3, wait

	lw a0, 0x8(x0)
	ret