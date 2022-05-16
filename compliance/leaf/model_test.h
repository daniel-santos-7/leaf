#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_DATA_SECTION                        \
  .pushsection .tohost,"aw",@progbits;              \
  .align 8; .global tohost; tohost: .dword 0;       \
  .align 8; .global fromhost; fromhost: .dword 0;   \
  .popsection;                                      \
  .align 8; .global begin_regstate; begin_regstate: \
  .word 128;                                        \
  .align 8; .global end_regstate; end_regstate:     \
  .word 4;

#define TESTUTIL_BASE 0x1FFFF3
#define TESTUTIL_ADDR_HALT (TESTUTIL_BASE + 0x0)
#define TESTUTIL_ADDR_BEGIN_SIGNATURE (TESTUTIL_BASE + 0x4)
#define TESTUTIL_ADDR_END_SIGNATURE (TESTUTIL_BASE + 0x8)

#define OUTPUT_ADDR 0x00200000
#define HALT_ADDR 0x00200004

#define RVMODEL_HALT        \
  li t0, OUTPUT_ADDR;       \
  li t1, HALT_ADDR;         \
  la t2, begin_signature;   \
  la t3, end_signature;     \
  write:                    \
    lw t4, 0x0(t2);         \
    sw t4, 0x0(t0);         \
    addi t2, t2, 0x4;       \
    blt t2, t3, write;      \
  li t5, 0x1;               \
  sw t5, 0x0(t1);           \
  self_loop : j self_loop;

#define RVMODEL_DATA_BEGIN \
  .align 4; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END                          \
  .align 4; .global end_signature; end_signature: \
  RVMODEL_DATA_SECTION

#define RVMODEL_BOOT
#define LOCAL_IO_WRITE_STR(_STR)
#define RVMODEL_IO_WRITE_STR(_SP, _STR)
#define RSIZE 4
#define LOCAL_IO_PUSH(_SP)
#define LOCAL_IO_POP(_SP)
#define RVMODEL_IO_ASSERT_GPR_EQ(_SP, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)
#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif