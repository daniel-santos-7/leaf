# Leaf RISC-V Core

Leaf is a compact 32-bit RISC-V processor core (RV32I) written in VHDL with a two-stage pipeline and Wishbone B4-compatible bus interface.

## Features

- RV32I base integer ISA
- Two-stage pipeline (IF + ID/EX)
- Wishbone B4-compatible master interface
- Machine-mode CSR support (mtvec, mepc, mcause, mstatus, mie, mip, mscratch, mtval)
- Machine counters (mcycle, minstret, mtime)
- External, software, and timer interrupt support
- Coprocessor interface via custom CSR window (0x7C0-0x7FF)
- GHDL simulation and synthesis flow
- RISC-V architectural test compliance via RISCOF
- Verification by Spike ISA simulator comparison

## Documentation

| Section | Description |
|---------|-------------|
| [User Guide](user-guide.md) | Build, simulate, test, and synthesize |
| [Microarchitecture](microarchitecture.md) | Architecture, pipeline, modules, Wishbone bus |
| [Developer Guide](developer.md) | Coding style, contributing, project structure |
| [Review](review.md) | RTL review findings and known bugs |

## Repository Layout

```
rtl/     VHDL RTL (17 files)
tbs/     Testbench (3 files)
verif/   Tests and RISCOF compliance
tcl/     GTKWave helper scripts
docs/    Documentation and RISC-V ISA PDFs
syn/     Synthesis scripts
waves/   Waveform outputs (gitignored)
work/    GHDL build artifacts (gitignored)
```

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

## Quick Start

```bash
# Build and run a test
make -C verif/tests/addi run

# Run with custom program
make run PROGRAM=/path/to/prog.bin DUMP_FILE=/path/to/out.dump

# Synthesize
make synthesis

# View waveform
gtkwave leaf_tb.ghw
```
