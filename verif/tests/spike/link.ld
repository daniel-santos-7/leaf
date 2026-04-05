/* link.ld */
OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    . = 0x80000000;

    .text : { *(.text) }
    .data : { *(.data) }
    .bss : { *(.bss) }

    . = ALIGN(16);
    .signature : { *(.signature) }

    . = ALIGN(64);
    .tohost : { *(.tohost) }
}
