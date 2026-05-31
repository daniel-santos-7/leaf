# Leaf 🍃

Leaf is a compact 32-bit RISC-V processor core (RV32I) in VHDL with a two-stage pipeline and Wishbone B4-compatible bus interface.

## Features

- RV32I base integer ISA
- Two-stage pipeline (IF + ID/EX)
- Wishbone B4-compatible master interface
- Machine-mode CSR support (mtvec, mepc, mcause, mstatus, mie, mip, mscratch, mtval)
- Machine counters (mcycle, minstret, mtime)
- External, software, and timer interrupt support
- Custom CSR window (0x7C0-0x7FF) for coprocessor interface

## Project Structure

```
rtl/     VHDL RTL source files
tbs/     Testbench sources
verif/   Verification and test infrastructure
tcl/     GTKWave helper scripts
specs/   RISC-V ISA specification PDFs
syn/     Synthesis scripts
waves/   Waveform outputs (gitignored)
work/    Build artifacts (gitignored)
```

See [rtl/README.md](rtl/README.md) for the full microarchitecture reference.

## Build and Simulate

The top-level Makefile compiles all VHDL sources and runs the testbench with a user-supplied binary. Set `PROGRAM` to the `.bin` path and `DUMP_FILE` for register dump output:

| Variable | Default | Description |
|----------|---------|-------------|
| `PROGRAM` | `verif/tests/dump/out.bin` | Program binary loaded into RAM |
| `DUMP_FILE` | `verif/tests/dump/out.dump` | Register dump output path |
| `WAVEFORM` | `leaf_tb.ghw` | GHDL waveform file |
| `REG_FILE` | 32 | Register count override (synthesis only) |

Clock period is 20 ns (50 MHz). GHDL flags: `--ieee=synopsys --workdir=work`.

Waveforms are written to `leaf_tb.ghw` and viewed with `gtkwave`:

```bash
gtkwave leaf_tb.ghw
```

TCL helper scripts for GTKWave are in `tcl/`: `add-signals.tcl`, `gen-trace.tcl`, `gtkwave.tcl`.

### Requirements

- `ghdl` — VHDL simulator and synthesis front-end
- `make` — build automation
- `gtkwave` — waveform viewer (optional)

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

## Known Issues

See [issues.md](issues.md) for documented RTL issues and planned improvements.
