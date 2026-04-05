.section .signature, "aw", @progbits
.balign 4
.globl begin_signature
begin_signature:
    .word 0
    .word 0
    .word 0
    .word 0
.globl end_signature
end_signature:

.section .tohost, "aw", @progbits
.balign 8
.globl tohost
tohost:
    .dword 0
.globl fromhost
fromhost:
    .dword 0
