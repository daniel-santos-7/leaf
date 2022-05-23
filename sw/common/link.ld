OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    MEM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00200000
    IOP (w)   : ORIGIN = 0x00200000, LENGTH = 0x00000008
}

SECTIONS
{
	.text :
	{
		*(.init)
		__text_begin = .;
		*(.text*)
		__text_end = .;
	} > MEM

	.rodata :
	{
        __rodata_begin = .;
		*(.rodata*)
		__rodata_end = .;
	} > MEM

	.data :
	{
		__data_begin = .;
		*(.data*)
		*(.eh_frame*)
		__data_end = .;
	} > MEM

	.bss ALIGN(4) :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss*)
		__bss_end = ALIGN(4);
	} > MEM

	__stack_top = 0x00200000;

	/DISCARD/ :
	{
		*(.comment)
	}
}