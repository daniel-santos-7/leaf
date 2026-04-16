OUTPUT_ARCH(riscv)
ENTRY(_start)

DUMP_SIZE = DEFINED(DUMP_SIZE) ? DUMP_SIZE : 128;
SIGNATURE_SIZE = DUMP_SIZE;

SECTIONS
{
    . = 0x80000000;

    .text : { *(.text) }
    .rodata : { *(.rodata) *(.rodata.*) }
    .data : { *(.data) *(.data.*) }
    .bss : { *(.bss) *(.bss.*) *(COMMON) }

    . = ALIGN(16);
    .signature :
    {
        begin_signature = .;
        . += SIGNATURE_SIZE;
        end_signature = .;
        begin_dump = begin_signature;
        end_dump = end_signature;
    }

    . = ALIGN(64);
    .tohost :
    {
        tohost = .;
        . += 8;
        fromhost = .;
        . += 8;
    }
}
