# User Guide

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

### Clean

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

Each test runs the same program on both Leaf and Spike, then compares register dumps. Spike serves as the golden reference model. A test program halts by writing `0xDEADBEEF` to `HALT_CMD_ADDR` (last word of RAM), which stops the clock in the testbench.

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

## Utilities

```bash
# Parse GHDL CSV trace
python3 py/trace.py <csv_file>

# Parse Spike trace log
python3 py/spike-trace-parser.py <log>
```
