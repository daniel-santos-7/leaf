# ----------------------------------------------------------------------
# Leaf project
# boot program
# developed by: Daniel Santos
# 2021
# ----------------------------------------------------------------------

.equ LOAD_CMD, 0x77
.equ RAM_BASE, 0x200
.equ RAM_SIZE, 0x100

.globl _start

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
			sb a0, RAM_BASE(t1)		# store instruction in address + RAM_BASE
			addi t1, t1, 1			# t1 = instruction address
			bltu t1, t0, load_loop 	# load if t1 < program size

	load_end:
		j RAM_BASE

	uart_read:
		li t2, 0				# clear t2
		li t3, 0xFF				# read enable flag
		wait:
			lbu t2, 0x0(x0)		# load enable flag from uart
			bne t2, t3, wait	# loop if enable flag is not 0xFF

	lw a0, 0x8(x0)				# a0 receive byte from uart
	ret							# return