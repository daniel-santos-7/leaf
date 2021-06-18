addi x0, x0, 0

load_start:
	li x5, 0xFFFFFFFF
	jal x1, spi_read
	bne x5, x10, load_start
	li x6, 0x0

load:
	li x7, 0x400
	beq x6, x7, load_end
	jal x1, spi_read
	li x7, 0xFFFFFFFF
	beq x10, x7, load_end
	sw x10, 0x400(x6)
	addi x6, x6, 0x4
	jal x0, load

spi_read:
	
	li x28, 0x0
	sw x28, 0x8(x0)
	li x28, 0xFFFFFFFF
	li x29, 0x0
	
	wait:
		lw x29, 0x4(x0) 
		bne x29, x28, wait

	lw x10, 0x8(x0)
	jalr x0, x1, 0

load_end:
	li	x1,  0x00000000
	li	x2,  0x00000000
	li	x3,  0x00000000
	li	x4,  0x00000000
	li	x5,  0x00000000
	li	x6,  0x00000000
	li	x7,  0x00000000
	li	x8,  0x00000000
	li	x9,  0x00000000
	li	x10, 0x00000000
	li	x11, 0x00000000
	li	x12, 0x00000000
	li	x13, 0x00000000
	li	x14, 0x00000000
	li	x15, 0x00000000
	li	x16, 0x00000000
	li	x17, 0x00000000
	li	x18, 0x00000000
	li	x19, 0x00000000
	li	x20, 0x00000000
	li	x21, 0x00000000
	li	x22, 0x00000000
	li	x23, 0x00000000
	li	x24, 0x00000000
	li	x25, 0x00000000
	li	x26, 0x00000000
	li	x27, 0x00000000
	li	x28, 0x00000000
	li	x29, 0x00000000
	li	x30, 0x00000000
	li	x31, 0x00000000
	j 0x400
