# Specifications

This directory contains the RISC-V ISA specification PDFs used as reference for the Leaf core implementation.

## Documents

| File | Description |
|------|-------------|
| [riscv-unprivileged.pdf](riscv-unprivileged.pdf) | RISC-V Unprivileged Specification — base ISA (RV32I) |
| [riscv-privileged.pdf](riscv-privileged.pdf) | RISC-V Privileged Specification — machine-level CSRs and trap handling |

## Privilege Mode

Leaf operates exclusively in **Machine Mode** (M-mode, privilege level 3). There is no support for Supervisor (S-mode) or User (U-mode). The `MPP` field in `mstatus` is hardwired to `2'b11` on reads.

## General-Purpose Registers

Leaf implements the standard RV32I register file with 32 × 32-bit registers (`x0`–`x31`).

| Register | ABI Name | Description |
|----------|----------|-------------|
| `x0` | `zero` | Hardwired to zero (writes are discarded) |
| `x1` | `ra` | Return address |
| `x2` | `sp` | Stack pointer |
| `x3` | `gp` | Global pointer |
| `x4` | `tp` | Thread pointer |
| `x5` | `t0` | Temporary / alternate link register |
| `x6`–`x7` | `t1`–`t2` | Temporaries |
| `x8` | `s0`/`fp` | Saved register / frame pointer |
| `x9` | `s1` | Saved register |
| `x10`–`x11` | `a0`–`a1` | Function arguments / return values |
| `x12`–`x17` | `a2`–`a7` | Function arguments |
| `x18`–`x27` | `s2`–`s11` | Saved registers |
| `x28`–`x31` | `t3`–`t6` | Temporaries |


## Implemented ISA: RV32I + Zicsr

Leaf implements the RV32I base integer instruction set with the Zicsr extension for CSR access.

### RV32I Instructions

| Instruction | Opcode | Type | funct3 | funct7 | Description |
|-------------|--------|------|--------|--------|-------------|
| ADD | `0x33` | RR | `000` | `0000000` | Add |
| SUB | `0x33` | RR | `000` | `0100000` | Subtract |
| SLL | `0x33` | RR | `001` | `0000000` | Shift left logical |
| SLT | `0x33` | RR | `010` | `0000000` | Set less than (signed) |
| SLTU | `0x33` | RR | `011` | `0000000` | Set less than (unsigned) |
| XOR | `0x33` | RR | `100` | `0000000` | Bitwise XOR |
| SRL | `0x33` | RR | `101` | `0000000` | Shift right logical |
| SRA | `0x33` | RR | `101` | `0100000` | Shift right arithmetic |
| OR | `0x33` | RR | `110` | `0000000` | Bitwise OR |
| AND | `0x33` | RR | `111` | `0000000` | Bitwise AND |
| ADDI | `0x13` | IMM | `000` | — | Add immediate |
| SLLI | `0x13` | IMM | `001` | `0000000` | Shift left logical immediate |
| SLTI | `0x13` | IMM | `010` | — | Set less than immediate (signed) |
| SLTIU | `0x13` | IMM | `011` | — | Set less than immediate (unsigned) |
| XORI | `0x13` | IMM | `100` | — | Bitwise XOR immediate |
| SRLI | `0x13` | IMM | `101` | `0000000` | Shift right logical immediate |
| SRAI | `0x13` | IMM | `101` | `0100000` | Shift right arithmetic immediate |
| ORI | `0x13` | IMM | `110` | — | Bitwise OR immediate |
| ANDI | `0x13` | IMM | `111` | — | Bitwise AND immediate |
| LB | `0x03` | LOAD | `000` | — | Load byte (sign-extended) |
| LH | `0x03` | LOAD | `001` | — | Load halfword (sign-extended) |
| LW | `0x03` | LOAD | `010` | — | Load word |
| LBU | `0x03` | LOAD | `100` | — | Load byte (zero-extended) |
| LHU | `0x03` | LOAD | `101` | — | Load halfword (zero-extended) |
| SB | `0x23` | STORE | `000` | — | Store byte |
| SH | `0x23` | STORE | `001` | — | Store halfword |
| SW | `0x23` | STORE | `010` | — | Store word |
| BEQ | `0x63` | BRANCH | `000` | — | Branch if `rs1 == rs2` |
| BNE | `0x63` | BRANCH | `001` | — | Branch if `rs1 != rs2` |
| BLT | `0x63` | BRANCH | `100` | — | Branch if signed(`rs1`) < signed(`rs2`) |
| BGE | `0x63` | BRANCH | `101` | — | Branch if signed(`rs1`) >= signed(`rs2`) |
| BLTU | `0x63` | BRANCH | `110` | — | Branch if unsigned(`rs1`) < unsigned(`rs2`) |
| BGEU | `0x63` | BRANCH | `111` | — | Branch if unsigned(`rs1`) >= unsigned(`rs2`) |
| LUI | `0x37` | MISC | — | — | Load upper immediate |
| AUIPC | `0x17` | MISC | — | — | Add upper immediate to PC |
| JAL | `0x6F` | MISC | — | — | Jump and link |
| JALR | `0x67` | MISC | `000` | — | Jump and link register |
| FENCE | `0x0F` | MISC | — | — | Fence (treated as NOP) |
| ECALL | `0x73` | SYSTEM | `000` | — | Environment call |
| EBREAK | `0x73` | SYSTEM | `000` | — | Breakpoint |
| MRET | `0x73` | SYSTEM | `000` | — | Machine-mode return from trap |
| WFI | `0x73` | SYSTEM | `000` | — | Wait for interrupt |

### Zicsr Instructions

| Instruction | Opcode | funct3 | Description |
|-------------|--------|--------|-------------|
| CSRRW | `0x73` | `001` | CSR read/write |
| CSRRS | `0x73` | `010` | CSR read and set bits |
| CSRRC | `0x73` | `011` | CSR read and clear bits |
| CSRRWI | `0x73` | `101` | CSR read/write immediate |
| CSRRSI | `0x73` | `110` | CSR read and set bits immediate |
| CSRRCI | `0x73` | `111` | CSR read and clear bits immediate |

## Machine CSRs

All CSRs are 32-bit (XLEN = 32). Counter CSRs are 64-bit, read as two 32-bit halves (low at `0xCxx`, high at `0xC8x`).

### Standard Machine CSRs

| Address | Register | R/W | Description |
|---------|----------|-----|-------------|
| `0x300` | `mstatus` | R/W | Machine status (MIE, MPIE, MPP) |
| `0x301` | `misa` | RO | ISA and extensions — reports RV32I (`0x40000100`) |
| `0x304` | `mie` | R/W | Interrupt enable (MEIE, MTIE, MSIE) |
| `0x305` | `mtvec` | R/W | Trap vector base address (direct mode only) |
| `0x340` | `mscratch` | R/W | Machine scratchpad register |
| `0x341` | `mepc` | R/W | Exception program counter |
| `0x342` | `mcause` | R/W | Trap cause (interrupt bit + exception code) |
| `0x343` | `mtval` | R/W | Trap value (faulting address or PC) |
| `0x344` | `mip` | RO | Interrupt pending (MEIP, MTIP, MSIP) |
| `0xC00` | `cycle` | RO | Cycle counter (low 32 bits) |
| `0xC01` | `time` | RO | Timer (low 32 bits) |
| `0xC02` | `instret` | RO | Instructions retired (low 32 bits) |
| `0xC80` | `cycleh` | RO | Cycle counter (high 32 bits) |
| `0xC81` | `timeh` | RO | Timer (high 32 bits) |
| `0xC82` | `instreth` | RO | Instructions retired (high 32 bits) |
| `0x7C0`–`0x7FF` | Coprocessor window | R/W | Forwarded to external coprocessor (64 entries) |
| `0xF14` | `mhartid` | RO | Hart ID (configurable via generic, default 0) |

Note: `time` and `timeh` are identical to `cycle`/`cycleh` — Leaf has no dedicated wall-clock timer input; `timer` counts every cycle from reset, same as `cycle`.

### CSR Field Layout

#### `mstatus` (0x300)

| Bits | Field | Reset | Description |
|------|-------|-------|-------------|
| 3 | MIE | 0 | Machine interrupt enable |
| 7 | MPIE | 1 | Machine previous interrupt enable |
| 12:11 | MPP | 11 | Machine previous privilege mode (hardwired to M-mode) |
| 31:13, 10:8, 6:4, 2:0 | WPRI | 0 | Reserved (ignored on write, reads as 0) |

#### `misa` (0x301)

| Bits | Field | Value | Description |
|------|-------|-------|-------------|
| 31:30 | MXL | `01` | Machine XLEN (01 = 32-bit) |
| 25:0 | Extensions | `0x00100` | ISA extensions bitmap — bit 8 ('I') set for RV32I |

Read-only, returns `0x40000100`.

#### `mtvec` (0x305)

| Bits | Field | Reset | Description |
|------|-------|-------|-------------|
| 31:2 | BASE | 0 | Trap vector base address (word-aligned) |
| 1:0 | MODE | `00` | Vector mode (00 = Direct, hardwired) |

Only Direct mode is supported — all traps jump to `BASE`. The low 2 bits are hardwired to `00` (reads always return 0; writes are ignored).

#### `mepc` (0x341)

| Bits | Field | Description |
|------|-------|-------------|
| 31:2 | ADDR | Exception program counter (word-aligned) |
| 1:0 | — | Hardwired to `00` on writes |

Stores the PC of the trapped instruction. Updated automatically on trap, readable and writable by software.

#### `mcause` (0x342)

| Bits | Field | Description |
|------|-------|-------------|
| 31 | Interrupt | `1` for interrupt, `0` for exception |
| 30:0 | Exception Code | Identifies the trap source (see table below) |

#### `mtval` (0x343)

| Bits | Field | Description |
|------|-------|-------------|
| 31:0 | VAL | Trap-specific value (faulting address, PC, or 0) |

#### `mie` (0x304) and `mip` (0x344)

| Bit | mie Field | mip Field | Description |
|-----|-----------|-----------|-------------|
| 3 | MSIE | MSIP | Software interrupt |
| 7 | MTIE | MTIP | Timer interrupt |
| 11 | MEIE | MEIP | External interrupt |

`mie` is read/write. `mip` is read-only — its bits reflect the current state of the external interrupt pins (MEI, MTI, MSI). Interrupts are level-sensitive.

#### `mscratch` (0x340)

Simple 32-bit scratch register. No field layout — software can use it freely.

#### Coprocessor Window (`0x7C0`–`0x7FF`)

CSR addresses `0x7C0`–`0x7FF` are reserved for an external coprocessor. Writes are forwarded to the coprocessor with a write strobe; reads return coprocessor data.

## Traps and Interrupts

### Trap Flow

**On exception or interrupt**:
1. `mepc` ← current PC
2. `mstatus.MPIE` ← `mstatus.MIE`; `mstatus.MIE` ← 0
3. `mcause` ← cause code (interrupt bit set for interrupts)
4. `mtval` ← address or PC (per table below)
5. Next PC ← `mtvec` (direct mode)
6. Pipeline redirects to handler

**On MRET**:
1. `mstatus.MIE` ← `mstatus.MPIE`; `mstatus.MPIE` ← 1
2. Next PC ← `mepc`
3. Pipeline redirects to return address

### Interrupt Priority

All interrupts are gated by `mstatus.MIE`. When multiple interrupts are pending, the highest priority is served first:

| Priority | Interrupt | mcause code |
|----------|-----------|-------------|
| 1 (highest) | MSI (software) | 3 |
| 2 | MTI (timer) | 7 |
| 3 (lowest) | MEI (external) | 11 |

### Exception Codes

| mcause code | Exception | Description |
|-------------|-----------|-------------|
| 0 | Instruction address misaligned | Branch/jump target not word-aligned |
| 1 | Instruction access fault | Bus error during instruction fetch |
| 2 | Illegal instruction | Unrecognized opcode |
| 3 | Breakpoint | EBREAK instruction executed |
| 4 | Load address misaligned | Load access not word-aligned |
| 5 | Load access fault | Bus error during data load |
| 6 | Store address misaligned | Store access not word-aligned |
| 7 | Store access fault | Bus error during data store |
| 11 | Environment call from M-mode | ECALL instruction executed |

### `mtval` Assignment

| Exception | mtval |
|-----------|-------|
| Instruction address misaligned | Target address (from ALU result) |
| Instruction access fault | PC of faulted instruction |
| Illegal instruction | 0 |
| Breakpoint | PC of breakpoint instruction |
| Load/store address misaligned | Effective address (from ALU result) |
| Load/store access fault | Effective address (from ALU result) |
| Environment call | 0 |
| Interrupt | 0 |

## Future CSRs

| Address | Register | Status |
|---------|----------|--------|
| `0x320` | `mcountinhibit` | Planned — counter inhibit (WARL, bits 0=CY, 2=IR) |
| `0x321` | `mhpmevent3` | Not implemented |
| `0x323`–`0x32F` | `mhpmevent4`–`31` | Not implemented |
