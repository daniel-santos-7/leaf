addi x0, x0, 0

addi x11, x0, 0x48
jal x1, spi_write

addi x11, x0, 0x45
jal x1, spi_write

addi x11, x0, 0x4C
jal x1, spi_write

addi x11, x0, 0x4C
jal x1, spi_write

addi x11, x0, 0x4F
jal x1, spi_write

spi_write:
	
	sw x11, 0x8(x0)
	li x28, 0xFFFFFFFF
	
	wait:
		lw x29, 0x4(x0)
	 	bne x29, x28, wait
	
	lw x10, 0x8(x0)
	jalr x0, x1, 0