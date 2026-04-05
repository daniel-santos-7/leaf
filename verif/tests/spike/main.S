.section .text
.globl _start

_start:
    la   t0, begin_signature
    li   t1, 0x00000001
    sw   t1, 0(t0)
    li   t1, 0xABCD1234
    sw   t1, 4(t0)
    li   t1, 0xCAFEBABE
    sw   t1, 8(t0)
    li   t1, 0xFFFFFFFF
    sw   t1, 12(t0)

    jal  ra, spike_finish

done:
    j    done
