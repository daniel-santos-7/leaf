# Leaf

Leaf is a compact 32-bit RISC-V core (RV32I) written in VHDL with a two-stage pipeline and Wishbone B4 bus interface.

## Features

- RV32I base integer ISA
- Two-stage pipeline (IF + ID/EX)
- Wishbone B4-compatible master interface
- Machine-mode CSR support (mtvec, mepc, mcause, mstatus, mie, mip, mscratch, mtval)
- Machine counters (mcycle, minstret, mtime)
- External, software, and timer interrupt support
- Coprocessor interface via custom CSR window (0x7C0-0x7FF)
- GHDL simulation and synthesis flow
- Verification by Spike ISA simulator comparison

## Quick Start

```bash
# Build and run a test
make -C verif/tests/addi run

# Run with custom program
make run PROGRAM=/path/to/prog.bin DUMP_FILE=/path/to/out.dump

# Synthesize (GHDL + Yosys)
make synthesis

# View waveform
gtkwave leaf_tb.ghw
```

## Build and Simulate

The top-level Makefile compiles all VHDL sources and runs the testbench:

```bash
make run PROGRAM=/abs/path/to/program.bin DUMP_FILE=/abs/path/to/result.dump
```

The default `PROGRAM` and `DUMP_FILE` point to `verif/tests/dump/out.bin` and `verif/tests/dump/out.dump`, which do not exist by default — you must provide a program binary.

Key Make variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PROGRAM` | `verif/tests/dump/out.bin` | Program binary to load into RAM |
| `DUMP_FILE` | `verif/tests/dump/out.dump` | Output register dump file |
| `WAVEFORM` | `leaf_tb.ghw` | GHDL waveform output |
| `REG_FILE` | 32 | Register file size override for synthesis |

A test program **halts** by writing `0xDEADBEEF` to `HALT_CMD_ADDR` (last word of RAM). The testbench detects this write and stops the clock via `clk_ctrl`, ending the simulation.

```bash
make clean
```

## Synthesis

Leaf supports GHDL-based VHDL-to-Verilog synthesis followed by Yosys/ABC for area and timing estimation:

```bash
make synthesis
```

This produces:

| Output | Description |
|--------|-------------|
| `work/leaf.v` | Synthesized Verilog netlist |
| `work/leaf.rpt` | Yosys area/timing report |
| `work/leaf_netlist.v` | Post-synthesis gate-level netlist |

Edit the `abc -D 20` command in `syn/leaf_analysis.ys` to change the timing constraint.

## Running Tests

Tests are organized per directory under `verif/tests/`. Each test is a standalone assembly program:

```bash
# List all tests
make -C verif/tests list

# Run a single test (Leaf + Spike)
make -C verif/tests/addi run

# Run all tests
make -C verif/tests run
```

Per-test targets:

| Target | Description |
|--------|-------------|
| `run` | Build and run both Leaf and Spike |
| `run-leaf` | Build and run Leaf only |
| `run-spike` | Build and run Spike only |
| `compare` | Compare Leaf dump vs Spike signature |
| `clean` | Clean test artifacts |

### Verification Strategy

Each test runs the same program on both Leaf and Spike, then compares register dumps. Spike serves as the golden reference model.

## RISCOF Compliance

Set up and run the RISC-V architectural test suite:

```bash
make -C verif/riscof riscv-arch-test    # First-time setup (clones arch test v3.9.1)
make -C verif/riscof run                # Run compliance (requires Python venv)
```

## Waveforms

The default waveform is written to `leaf_tb.ghw` in the project root:

```bash
gtkwave leaf_tb.ghw
```

GTKWave helper scripts are in `tcl/`:

- `add-signals.tcl` — add common signal groups
- `gen-trace.tcl` — generate trace output
- `gtkwave.tcl` — general-purpose helper

## Microarchitecture

See [rtl/README.md](rtl/README.md) for the full microarchitecture reference, including:

- Pipeline stage descriptions and interfaces
- CSR register map and trap handling
- Wishbone bus FSM and arbitration
- Counter architecture and retire logic
- RTL file map

## Requirements

- `ghdl` — VHDL simulator
- `make` — build automation
- `riscv32-unknown-elf-gcc` — RISC-V GCC toolchain
- `riscv32-unknown-elf-objcopy` — binary generation
- `riscv32-unknown-elf-objdump` — disassembly
- `spike` — ISA simulator for comparison verification
- `gtkwave` — waveform viewer (optional)

## Key Parameters

| Generic | Default | Description |
|---------|---------|-------------|
| `RESET_ADDR` | `0x80000000` | Reset vector address |
| `REG_FILE_SIZE` | 32 | Number of integer registers |
| `CSRS_MHART_ID` | 0 | Hardware thread ID |

## Project Structure

```
rtl/     VHDL RTL (17 files)
  leaf.vhdl           — top-level with Wishbone interface
  core.vhdl           — CPU core integration
  if_stage.vhdl       — instruction fetch
  id_stage.vhdl       — decode, regfile, CSRs
  ex_block.vhdl       — ALU, branch, CSR write, LSU
  alu.vhdl            — ALU datapath
  alu_ctrl.vhdl       — ALU control decoder
  br_detector.vhdl    — branch condition evaluation
  dmls_block.vhdl     — load/store alignment
  csrs.vhdl           — machine CSR and trap control
  csrs_logic.vhdl     — CSR read muxing
  counters.vhdl       — mcycle, minstret, time
  clk_ctrl.vhdl       — clock gating
  reg_file.vhdl       — 32x32 register file
  wb_ctrl.vhdl        — Wishbone B4 master FSM
  leaf_pkg.vhdl       — constants and component declarations
  main_ctrl.vhdl      — control decoder and immediate generator
tbs/     Testbench (3 files)
  leaf_tb.vhdl
  leaf_tb_pkg.vhdl
  wb_ram.vhdl
verif/   Verification and tests
  tests/<name>/    — per-test assembly programs
  riscof/          — RISC-V compliance framework
  common/          — shared test support files
tcl/     GTKWave helper TCL scripts
specs/   RISC-V ISA specification PDFs
syn/     Synthesis scripts
  leaf_analysis.ys    — Yosys synthesis script
waves/   Waveform outputs (gitignored)
work/    Build artifacts (gitignored)
```

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

## Simulation Details

- GHDL flags: `--ieee=synopsys --workdir=work`
- Clock period: 20 ns (50 MHz)
- Reset address: `0x80000000`
- Memory: 4 MiB at base `0x80000000`

## Tool Versions

| Tool | Purpose |
|------|---------|
| GHDL | VHDL simulation and synthesis |
| Yosys | Logic synthesis and netlist generation |
| ABC | Technology mapping (via Yosys) |
| Spike | RISC-V ISA reference simulator |
| RISC-V GCC | Test program compilation |
| RISCOF | Architectural test framework |

## Known Issues

See [issues.md](issues.md) for documented RTL issues and planned improvements.
