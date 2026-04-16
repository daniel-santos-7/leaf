OUTPUT_ARCH(riscv)
ENTRY(_start)

DUMP_SIZE = DEFINED(DUMP_SIZE) ? DUMP_SIZE : 128;

SECTIONS
{
    . = 0x80000000;

    .text : { *(.text) }
    .rodata : { *(.rodata) *(.rodata.*) }
    .data : { *(.data) *(.data.*) }
    .bss : { *(.bss) *(.bss.*) *(COMMON) }

    . = ALIGN(16);
    .dump :
    {
        begin_dump = .;
        . += DUMP_SIZE;
        end_dump = .;
    }
}
