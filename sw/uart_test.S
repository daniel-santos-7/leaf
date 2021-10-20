.globl _start

_start:
	
	li t0, 0x41		# 'A'
	li t1, 0x20		# uart write enable flag
	li t2, 0x0		
	sw t0, 0xC(x0)	# uart write address

	wait:
		lw t2, 0xC(x0)
		andi t2, t2, 0x20
		bne t1, t2, wait

inf_loop: 
	j inf_loop