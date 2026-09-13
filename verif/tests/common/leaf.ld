OUTPUT_ARCH(riscv)
ENTRY(_start)

DUMP_SIZE = DEFINED(DUMP_SIZE) ? DUMP_SIZE : 128;

SECTIONS
{
    . = 0x80000000;

    .text : { *(.text) }
    .rodata : { *(.rodata) *(.rodata.*) }

    /* Page-align the read-only to writable transition. Permissions are
       page-granular, so any writable section sharing a page with .text
       forces a single RWX LOAD segment and ld warns. Everything below is
       writable and shares one segment. */
    . = ALIGN(0x1000);

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
