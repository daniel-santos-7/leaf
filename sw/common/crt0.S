.section .init

.global _start
_start:

.hidden clear_bss
clear_bss:
	la t0, __bss_begin
	la t1, __bss_end
	beq t0, t1, 2f
1:
	sw x0, 0x0(t0)
	addi t0, t0, 0x4
	bne t0, t1, 1b
2:

.hidden init_stack
init_stack:
	la sp, __stack_top

.hidden call_main
call_main:
	call main

.hidden halt
halt:
    li t0, 0x00000001
    li t1, 0x00200004   # halt simulation register address
    sw t0, 0x0(t1)

1:
	j 1b