# Leaf

Leaf is a compact 32-bit RISC-V processor core designed for resource-constrained systems where area and simplicity matter more than raw throughput. The core is implemented in VHDL and targets RV32I-compatible software.

## Features

- RV32I base ISA support
- Two-stage pipeline (fetch / decode+execute)
- Wishbone B4-compatible bus interface

## Project Structure

Directory | Description
--------- | -----------
`docs/`   | Documentation and design notes
`ip/`     | Auxiliary or third-party IP blocks
`py/`     | Python tooling and utilities
`rtl/`    | VHDL RTL source files
`steps/`  | Build artifacts from simulation steps
`tbs/`    | VHDL testbenches
`tcl/`    | TCL scripts for tool automation
`verif/`  | Verification collateral, tests, and binaries
`waves/`  | Waveform outputs (`.ghw`)
`work/`   | GHDL work library

## Requirements

- GHDL (VHDL simulator)
- GNU Make
- GTKWave (optional, for waveform viewing)

On Debian/Ubuntu:

```bash
sudo apt install ghdl gtkwave make
```

## Quick Start (Simulation)

Run the default testbench:

```bash
make run
```

By default the simulation is configured to read `verif/tests/dump/out.bin` and write `verif/tests/dump/out.dump` while producing a waveform at `waves/leaf_tb.ghw`. See `Makefile` for the exact simulation flags.

Clean generated artifacts:

```bash
make clean
```
