# :leaves: Leaf

Leaf is a compact 32-bit RISC-V core (RV32I) written in VHDL with a two-stage pipeline and Wishbone B4 bus interface.

## Documentation

| Section | Description |
|---------|-------------|
| [User Guide](docs/user-guide.md) | Build, simulate, test, synthesize |
| [Reference](docs/reference.md) | Architecture, pipeline, modules, bus |
| [Developer Guide](docs/developer.md) | Coding style, contributing, known issues |

## Quick Start

```bash
# Run a test
make -C verif/tests/addi run

# Run custom program
make run PROGRAM=/path/to/prog.bin DUMP_FILE=/path/to/out.dump

# Synthesize (GHDL + Yosys + IHP SG13G2)
make synthesis

# View waveform
gtkwave leaf_tb.ghw
```

## Requirements

- `ghdl`, `make`
- `riscv32-unknown-elf-gcc`, `objcopy`, `objdump`
- `spike` (for comparison verification)
- `gtkwave` (optional)

## Known Issues

See [rtl-review.md](rtl-review.md) for documented RTL bugs.
