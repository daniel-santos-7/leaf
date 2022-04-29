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

#define RVMODEL_HALT                    \
  la t0, begin_signature;               \
  li t1, TESTUTIL_ADDR_BEGIN_SIGNATURE; \
  sw t0, 0(t1);                         \
  la t0, end_signature;                 \
  li t1, TESTUTIL_ADDR_END_SIGNATURE;   \
  sw t0, 0(t1);                         \
  li t0, 1;                             \
  li t1, TESTUTIL_ADDR_HALT;            \
  sw t0, 0(t1);                         \
  self_loop:  j self_loop;

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