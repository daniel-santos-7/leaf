#ifndef SIGNATURE_WORDS
#define SIGNATURE_WORDS 4
#endif

.section .signature, "aw", @progbits
.balign 4
.globl begin_signature
begin_signature:
    .rept SIGNATURE_WORDS
    .word 0
    .endr
.globl end_signature
end_signature:
