# Developer Guide

## Coding Style

### Naming Conventions

- **Port suffixes**: `_i` (input), `_o` (output), `_io` (bidirectional)
- **Internal signals**: `lowercase_snake_case`
- **Constants**: `UPPERCASE_SNAKE_CASE`
- **Generics**: `UPPERCASE_SNAKE_CASE`

### Conventions

- **Instantiation**: named association only: `signal_i => local_signal`
- **Case statements**: always include `when others =>`
- **Use constants from `leaf_pkg`** rather than literal values:
  - Opcodes: `RR_OPCODE`, `IMM_OPCODE`, `LOAD_OPCODE`, etc.
  - ALU ops: `ALU_ADD`, `ALU_SUB`, `ALU_SLL`, etc.
  - CSR addresses: `CSR_ADDR_MSTATUS`, `CSR_ADDR_MEPC`, etc.
  - Immediate types: `IMM_I_TYPE`, `IMM_S_TYPE`, etc.
  - Branch modes: `EQ_BD_MODE`, `LT_BD_MODE`, etc.
  - LSU types: `LSU_BYTE`, `LSU_HALF`, `LSU_WORD`

### LSP Support

`vhdl_ls.toml` lists only `leaf_pkg.vhdl` in the `work` library. Add new files there for LSP support.

## Project Structure

```
rtl/     VHDL RTL (17 files)
  leaf.vhdl         — top-level with Wishbone interface
  core.vhdl         — CPU core integration
  if_stage.vhdl     — instruction fetch
  id_stage.vhdl     — decode, regfile, CSRs
  ex_block.vhdl     — ALU, branch, CSR write, LSU
  alu.vhdl          — ALU datapath
  alu_ctrl.vhdl     — ALU control decoder
  br_detector.vhdl  — branch condition evaluation
  dmls_block.vhdl   — load/store alignment
  csrs.vhdl         — machine CSR and trap control
  csrs_logic.vhdl   — CSR read muxing
  counters.vhdl     — mcycle, minstret, time
  clk_ctrl.vhdl     — clock gating
  reg_file.vhdl     — 32×32 register file
  wb_ctrl.vhdl      — Wishbone B4 master FSM
  leaf_pkg.vhdl     — constants and component declarations
  main_ctrl.vhdl    — control decoder and immediate generator
tbs/     Testbench (3 files)
  leaf_tb.vhdl
  leaf_tb_pkg.vhdl
  wb_ram.vhdl
verif/   Verification and tests
  tests/<name>/    — per-test assembly programs
  riscof/          — RISC-V compliance framework
  common/          — shared test support files
tcl/     GTKWave helper TCL scripts
docs/    Documentation and RISC-V ISA PDFs
syn/     Synthesis scripts
  leaf_analysis.ys    — Yosys synthesis script
waves/   Waveform outputs (gitignored)
work/    Build artifacts (gitignored)
```

## Known RTL Issues

See [rtl-review.md](../rtl-review.md) for legacy findings and [review.md](review.md) for the ongoing systematic review.

### Legacy Issues (rtl-review.md)

1. `mret` is implemented as an exception instead of exception return — breaks trap return flow
2. Load-fault signal miswired (`dmld_fault => dmst_fault`) in `id_stage.vhdl`
3. Don't-care values (`'-'`) propagate from main_ctrl into ALU during flush/unknown opcodes
4. Invalid CSR accesses do not raise traps

### Review Findings (docs/review.md)

| ID | Severity | Component | Description |
|----|----------|-----------|-------------|
| R1 | BUG | `counters` | `instret` and `timer` hardwired to zero |
| R2 | WARN | `leaf` | Reset distribution asymmetry (core vs counters) |
| R3 | WARN | `leaf` | COP interface lacks handshake signals |
| R4 | INFO | `clk_ctrl` | Gated clock via transparent latch |
| R5 | INFO | `wb_ctrl` | Error reporting uses current enable, not latched source |
| R6 | INFO | `wb_ctrl` | No bus timeout mechanism |

## Adding a New Test

1. Create `verif/tests/<name>/main.s` with your assembly program
2. The program should end by writing `0xDEADBEEF` to `HALT_CMD_ADDR`
3. Use `store_regs` from `common.S` to dump register state for comparison
4. Run: `make -C verif/tests/<name> run`

## Adding a New RTL File

1. Create the VHDL file in `rtl/`
2. Add the component declaration to `rtl/leaf_pkg.vhdl`
3. Add the file to `vhdl_ls.toml` if using VHDL LSP
4. No Makefile changes needed — the wildcard `$(wildcard rtl/*.vhdl)` picks up new files automatically

## Tool Versions

| Tool | Purpose |
|------|---------|
| GHDL | VHDL simulation and synthesis |
| Yosys | Logic synthesis and netlist generation |
| ABC | Technology mapping (via Yosys) |
| Spike | RISC-V ISA reference simulator |
| RISC-V GCC | Test program compilation |
| RISCOF | Architectural test framework |

## Simulation Details

- GHDL flags: `--ieee=synopsys --workdir=work`
- Clock period: 20 ns (50 MHz)
- Reset address: `0x80000000`
- Memory: 4 MiB at base `0x80000000`

## HALF Mechanism

A test program halts the simulation by writing `0xDEADBEEF` to the last word of RAM (`HALT_CMD_ADDR = 0x803FFFFC`). The testbench detects this write and stops the clock via `clk_ctrl`, ending the simulation.
