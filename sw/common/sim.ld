OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    IOP (rw)  : ORIGIN = 0x00000000, LENGTH = 0x00000010
    RAM (rwx) : ORIGIN = 0x00400000, LENGTH = 0x00400000
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
	} > RAM

	.rodata :
	{
        __rodata_begin = .;
		*(.rodata*)
		. = ALIGN(4);
		__rodata_end = .;
	} > RAM

	.data :
	{
		__data_begin = .;
		*(.data*)
		*(.eh_frame*)
		. = ALIGN(4);
		__data_end = .;
	} > RAM

	.bss :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss*)
		. = ALIGN(4);
		__bss_end = .;
	} > RAM

	.sdata : 
	{
		__sdata_begin = .;
		*(.sdata*)
		. = ALIGN(4);
		__sdata_end = .;
	} > RAM

	__stack_top = ORIGIN(RAM) + LENGTH(RAM);
	__end = .;

	/DISCARD/ :
	{
		*(.comment)
		*(.debug*)
		*(.riscv.attributes)
	}
}