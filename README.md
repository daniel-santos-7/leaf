# Leaf 🍃

Leaf is a compact 32-bit RISC-V processor core (RV32I) in VHDL with a
three-stage pipeline and a Wishbone B4-compatible bus interface.

## Features

- RV32I base integer ISA
- Three-stage pipeline (IF → ID → EX)
- Two independent Wishbone B4-compatible master ports (instruction and data)
- FIFO-based instruction fetch with epoch tagging to discard stale fetches
- Machine-mode CSRs (mstatus, misa, mie, mtvec, mscratch, mepc, mcause,
  mtval, mip, mhartid)
- Read-only counters (cycle, time, instret, plus their high halves)
- External, software, and timer interrupt support
- Traps: ecall, ebreak, mret, wfi, illegal instruction, instruction/data
  access faults, misaligned address faults
- Custom CSR window (0x7C0–0x7FF) for a coprocessor interface

## Project Structure

```
rtl/     VHDL RTL source files
tbs/     Testbench sources
verif/   Verification: instruction-level tests and RISCOF
specs/   RISC-V ISA specification PDFs
syn/     Synthesis scripts
waves/   Waveform outputs (gitignored)
work/    Build artifacts (gitignored)
```

See [rtl/README.md](rtl/README.md) for the microarchitecture reference (block
diagrams and port tables). Note that it still describes the older FSM-based
`if_stage` and a two-stage pipeline; the RTL is authoritative where they
disagree.

## Build and Simulate

The top-level Makefile compiles all VHDL sources and runs the testbench with a
user-supplied binary. Set `PROGRAM` to the `.bin` path and `DUMP_FILE` for the
register dump output:

```bash
make run PROGRAM=/path/to/prog.bin
make run PROGRAM=/path/to/prog.bin DUMP_FILE=/path/to/out.dump
make clean
```

| Variable | Default | Description |
|----------|---------|-------------|
| `PROGRAM` | `verif/tests/dump/out.bin` | Program binary loaded into RAM |
| `DUMP_FILE` | `verif/tests/dump/out.dump` | Register dump output path |
| `WAVEFORM` | `leaf_tb.ghw` | GHDL waveform file |
| `SIMXOPTS` | `--ieee-asserts=disable --stop-time=1ms` | Extra GHDL run options |
| `REG_FILE` | `32` | Register file size (synthesis only) |

The default `PROGRAM` path does not exist in the repository — always pass
`PROGRAM` explicitly.

Testbench parameters live in `tbs/leaf_tb_pkg.vhdl`: clock period 10 ns
(100 MHz), reset address `0x80000000`, 4 MiB of RAM. GHDL flags:
`--ieee=synopsys --workdir=work`.

Waveforms are written to `$(WAVEFORM)` and viewed with `gtkwave`:

```bash
gtkwave leaf_tb.ghw
```

### Requirements

- `ghdl` — VHDL simulator and synthesis front-end
- `make` — build automation
- `gtkwave` — waveform viewer (optional)
- `yosys` — area/timing estimation (synthesis only)
- `riscv32-unknown-elf-gcc` and `spike` — verification only
- `python3` with `venv` — RISCOF only

## Verification

### Instruction-level tests

Each directory under `verif/tests/` holds a `main.s` and a one-line Makefile.
Every test is built twice — once for Leaf and once for Spike — and Leaf's
register dump is diffed against the Spike signature.

```bash
make -C verif/tests list             # list test names
make -C verif/tests/<test> run-leaf  # Leaf only (fastest)
make -C verif/tests/<test> run       # Leaf + Spike
make -C verif/tests/<test> compare   # run + diff
make -C verif/tests compare          # every test
```

To add a test, create `verif/tests/<name>/main.s` (include
`common/defs.inc`, define `_start`, end with `call finish_test`) and a
Makefile containing `include ../common/common.mk`; the aggregate Makefile
picks new directories up automatically.

Override the toolchain prefix with `RISCV_PREFIX` in
`verif/tests/common/common.mk`.

### RISCOF (official RISC-V architecture tests)

```bash
make -C verif/riscof run
```

This creates a virtualenv in `verif/riscof/venv` and fetches
`riscv-arch-test` v3.9.1. The simulation command used by the plugin is
hardcoded in `verif/riscof/leaf/riscof_leaf.py` — check its path and
`--stop-time` match your environment.

## Synthesis

Leaf supports GHDL-based VHDL-to-Verilog synthesis followed by Yosys/ABC for
area and timing estimation:

```bash
make synthesis
```

This produces:

| Output | Description |
|--------|-------------|
| `work/leaf.v` | Synthesized Verilog netlist |
| `work/leaf.rpt` | Yosys area/timing report |
| `work/leaf_netlist.v` | Post-synthesis gate-level netlist |

Edit the `abc -D 20` command in `syn/leaf_analysis.ys` to change the timing
constraint.

## License

Distributed under the [MIT License](LICENSE).
