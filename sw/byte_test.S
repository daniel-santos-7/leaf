.globl _start

_start:
	
	li t0, 0x78		# 'A'
	li t1, 0xFF		# uart write enable flag
	li t2, 0x0		
	sw t0, 0xC(x0)	# uart write address

	wait:
		lw t2, 0x0(x0)
		srli t2, t2, 8
		bne t1, t2, wait

inf_loop: 
	j inf_loop