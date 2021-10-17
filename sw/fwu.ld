ENTRY(_start)

MEMORY
{
    IOP (rwx): ORIGIN = 0x00000000, LENGTH = 0x00000100
    ROM (rx) : ORIGIN = 0x00000100, LENGTH = 0x00000200
	RAM (rwx): ORIGIN = 0x00000200, LENGTH = 0x00000300
}

SECTIONS
{
	.text :
	{
		*(.init)
		__text_begin = .;
		*(.text*)
		__text_end = .;
	} > RAM

	.rodata :
	{
        __rodata_begin = .;
		*(.rodata*)
		__rodata_end = .;
	} > RAM

	.data :
	{
		__data_begin = .;
		*(.data*)
		*(.eh_frame*)
		__data_end = .;
	} > RAM

	.bss ALIGN(4) :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss*)
		__bss_end = ALIGN(4);
	} > RAM

	__stack_top = 0x00000300;

	/DISCARD/ :
	{
		*(.comment)
	}
}