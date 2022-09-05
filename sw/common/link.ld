OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    IOP (rw)  : ORIGIN = 0x00000000, LENGTH = 0x00000010
	ROM (rx)  : ORIGIN = 0x00000100, LENGTH = 0x00000100
    MEM (rwx) : ORIGIN = 0x00010000, LENGTH = 0x00010000
}

SECTIONS
{
	.text :
	{
		__text_begin = .;
		*(.init)
		*(.text*)
		. = ALIGN(4);
		__text_end = .;
	} > MEM

	.rodata :
	{
        __rodata_begin = .;
		*(.rodata*)
		. = ALIGN(4);
		__rodata_end = .;
	} > MEM

	.data :
	{
		__data_begin = .;
		*(.data*)
		*(.eh_frame*)
		. = ALIGN(4);
		__data_end = .;
	} > MEM

	.bss :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss*)
		. = ALIGN(4);
		__bss_end = .;
	} > MEM

	__stack_top = 0x00020000;
	__end = .;

	/DISCARD/ :
	{
		*(.comment)
	}
}