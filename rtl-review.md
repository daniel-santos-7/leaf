# RTL Review

## Findings

1. `mret` is implemented as an exception instead of an exception return.

   In [rtl/csrs.vhdl](rtl/csrs.vhdl), `exc_taken` includes `mret` (`line 95`), so the CSR update logic enters the exception path before the return path in `mstatus`, `mepc`, `mcause`, and `mtval` handling (`lines 126, 181, 199, 242`). Practical effect: `mstatus` does not restore `MIE/MPIE`, `mepc/mcause/mtval` can be overwritten on handler exit, and `trap_taken` is asserted again on `mret` (`line 270`). This breaks the normal trap return flow and should fail the `ecall` path.

2. Load-fault signaling is miswired into the CSR block.

   In [rtl/id_stage.vhdl](rtl/id_stage.vhdl), the CSR instance connects `dmld_fault => dmst_fault` (`line 126`). This means a real load access fault is not reported correctly to the trap logic, while a store fault can be misclassified as a load fault due to the exception priority in [rtl/csrs.vhdl](rtl/csrs.vhdl) (`lines 218-225`). This is a functional exception-handling bug.

3. The control logic injects `'-'` values into the datapath during flush/invalid-opcode cases.

   In [rtl/main_ctrl.vhdl](rtl/main_ctrl.vhdl), the immediate generator drives don’t-care values on flush and unknown opcodes (`lines 50-63, 77`). Those values can propagate into ALU and shifter inputs and then into `numeric_std` conversions, producing repeated metavalue warnings and unstable simulation behavior. This matches the observed `addi` simulation behavior, which did not converge and emitted continuous `numeric_std` warnings.

4. Invalid CSR accesses do not raise traps.

   The project guide states invalid CSR addresses should trap, but the RTL currently treats all `SYSTEM_OPCODE` instructions as valid in [rtl/main_ctrl.vhdl](rtl/main_ctrl.vhdl) (`line 148`), and the CSR read path returns zero for unknown addresses in [rtl/csrs.vhdl](rtl/csrs.vhdl) (`line 116`). This masks illegal CSR accesses and deviates from expected ISA behavior.

## Validation Notes

- `make run` currently fails because the default target depends on `verif/tests/dump/out.bin`, which is not present in the repository state used for this review.
- `make -C verif/tests/addi run` compiles, but the simulation does not complete and emits a long stream of `numeric_std` metavalue warnings, consistent with the datapath contamination described above.
- The documented command `make -C verif/tests run TEST=...` does not match the current Makefile layout; the per-test invocation is `make -C verif/tests/<test> run`.
