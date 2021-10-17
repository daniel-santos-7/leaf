.section .init

.global _start
_start:

.hidden clear_bss
clear_bss:
	la x1, __bss_begin
	la x2, __bss_end
	beq x1, x2, 2f

1:
	sw x0, (x1)
	addi x1, x1, 4
	bne x1, x2, 1b
2:

.hidden init_stack
init_stack:
	la sp, __stack_top

.hidden call_main
call_main:
	call main

1:
	j 1b