# instret is one of the unprivileged counters, and Spike only implements
# those with Zicntr. Without it csrr instret raises an illegal instruction,
# the test traps into its own handler and spins there forever. Leaf has the
# unprivileged counters and not the machine ones (see CSR_ADDR_INSTRET in
# rtl/leaf_pkg.vhdl), so instret is the name both models answer to.
SPIKE_ISA = rv32i_zicntr

include ../common/common.mk
