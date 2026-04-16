# :leaves: Leaf

Leaf is a compact 32-bit RISC-V core written in VHDL. It implements the RV32I base ISA with a two-stage pipeline and a Wishbone B4-compatible master interface.

## Features

- RV32I base integer ISA
- Two-stage pipeline (`IF` + `ID/EX`)
- Wishbone B4-compatible bus interface
- Machine-mode CSR support
- GHDL simulation flow
- GHDL-based VHDL-to-Verilog synthesis flow

## Repository Layout

Directory | Description
--------- | -----------
`docs/`   | Documentation and design notes
`ip/`     | Third-party or auxiliary IP
`py/`     | Python utilities
`rtl/`    | VHDL RTL source files
`tbs/`    | Testbenches and testbench packages
`tcl/`    | Tool automation scripts
`verif/`  | Verification assets, tests, and RISCOF setup
`waves/`  | Waveform outputs
`work/`   | GHDL work library

## Requirements

- `ghdl`
- `make`
- `riscv32-unknown-elf-gcc`
- `riscv32-unknown-elf-objcopy`
- `riscv32-unknown-elf-objdump`
- `spike` for Spike-based comparison flows
- `gtkwave` optional

Example for Debian/Ubuntu:

```bash
sudo apt install ghdl gtkwave make
```

RISC-V GNU toolchain and Spike installation depend on your environment and package source.

## Build And Simulation

Run the top-level simulation with an explicit program image:

```bash
make run PROGRAM=/abs/path/to/program.bin DUMP_FILE=/abs/path/to/result.dump
```

The top-level `Makefile` defaults to:

```bash
PROGRAM=verif/tests/dump/out.bin
DUMP_FILE=verif/tests/dump/out.dump
```

That default binary is not currently present in the repository, so `make run` without overrides will fail unless you generate or provide that file first.

Clean build artifacts:

```bash
make clean
```

Generate synthesized Verilog with GHDL:

```bash
make synthesis
```

Output is written to `syn/leaf.v`.

## Running Tests

Tests are organized per directory under `verif/tests/`. Run them from each test directory:

```bash
make -C verif/tests/addi run
make -C verif/tests/ecall run
make -C verif/tests/li run
make -C verif/tests/lui run
```

Each test flow can build:

- a Leaf ELF/binary/debug image
- a Spike ELF/binary/debug image
- a Leaf dump
- a Spike signature

Useful targets inside a test directory:

```bash
make -C verif/tests/addi run
make -C verif/tests/addi run-leaf
make -C verif/tests/addi run-spike
make -C verif/tests/addi compare
make -C verif/tests/addi clean
```

## RISCOF

Set up and run the compliance flow with:

```bash
make -C verif/riscof riscv-arch-test
make -C verif/riscof run
```

## Utilities

Parse a GHDL CSV trace:

```bash
python3 py/trace.py <csv_file>
```

Parse a Spike trace log:

```bash
python3 py/spike-trace-parser.py <log>
```

Open the main waveform:

```bash
gtkwave leaf_tb.ghw
```

## Main RTL Files

File | Description
---- | -----------
`rtl/leaf.vhdl` | Top-level core wrapper with Wishbone interface
`rtl/core.vhdl` | CPU core integration
`rtl/if_stage.vhdl` | Instruction fetch stage
`rtl/id_stage.vhdl` | Decode stage, register file, and CSR integration
`rtl/ex_block.vhdl` | ALU, branch, CSR write, and load/store execution block
`rtl/csrs.vhdl` | Machine CSR implementation and trap control
`rtl/wb_ctrl.vhdl` | Wishbone master FSM

## Review Notes

Static RTL review notes are available in [rtl-review.md](rtl-review.md).
