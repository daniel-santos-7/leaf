# Specifications

This directory contains the RISC-V ISA specification PDFs used as reference for the Leaf core implementation.

## Documents

| File | Description |
|------|-------------|
| [riscv-unprivileged.pdf](riscv-unprivileged.pdf) | RISC-V Unprivileged Specification — base ISA (RV32I) |
| [riscv-privileged.pdf](riscv-privileged.pdf) | RISC-V Privileged Specification — machine-level CSRs and trap handling |

## Implemented ISA: RV32I

Leaf implements the RV32I base integer instruction set. The table below lists every instruction supported.

### ALU Register-Register (opcode `0x33`)

| Instruction | funct3 | funct7 | ALU Op | Description |
|-------------|--------|--------|--------|-------------|
| ADD | `000` | `0000000` | ADD | Add |
| SUB | `000` | `0100000` | SUB | Subtract |
| SLL | `001` | `0000000` | SLL | Shift left logical |
| SLT | `010` | `0000000` | SLT | Set less than (signed) |
| SLTU | `011` | `0000000` | SLTU | Set less than (unsigned) |
| XOR | `100` | `0000000` | XOR | Bitwise XOR |
| SRL | `101` | `0000000` | SRL | Shift right logical |
| SRA | `101` | `0100000` | SRA | Shift right arithmetic |
| OR | `110` | `0000000` | OR | Bitwise OR |
| AND | `111` | `0000000` | AND | Bitwise AND |

### ALU Immediate (opcode `0x13`)

| Instruction | funct3 | funct7 | ALU Op | Description |
|-------------|--------|--------|--------|-------------|
| ADDI | `000` | — | ADD | Add immediate |
| SLLI | `001` | `0000000` | SLL | Shift left logical immediate |
| SLTI | `010` | — | SLT | Set less than immediate (signed) |
| SLTIU | `011` | — | SLTU | Set less than immediate (unsigned) |
| XORI | `100` | — | XOR | Bitwise XOR immediate |
| SRLI | `101` | `0000000` | SRL | Shift right logical immediate |
| SRAI | `101` | `0100000` | SRA | Shift right arithmetic immediate |
| ORI | `110` | — | OR | Bitwise OR immediate |
| ANDI | `111` | — | AND | Bitwise AND immediate |

### Branches (opcode `0x63`)

| Instruction | funct3 | Condition | Description |
|-------------|--------|-----------|-------------|
| BEQ | `000` | `rs1 == rs2` | Branch equal |
| BNE | `001` | `rs1 != rs2` | Branch not equal |
| BLT | `100` | `signed(rs1) < signed(rs2)` | Branch less than (signed) |
| BGE | `101` | `signed(rs1) >= signed(rs2)` | Branch greater or equal (signed) |
| BLTU | `110` | `unsigned(rs1) < unsigned(rs2)` | Branch less than (unsigned) |
| BGEU | `111` | `unsigned(rs1) >= unsigned(rs2)` | Branch greater or equal (unsigned) |

### Loads (opcode `0x03`)

| Instruction | funct3 | Description |
|-------------|--------|-------------|
| LB | `000` | Load byte (sign-extended) |
| LH | `001` | Load halfword (sign-extended) |
| LW | `010` | Load word |
| LBU | `100` | Load byte (zero-extended) |
| LHU | `101` | Load halfword (zero-extended) |

### Stores (opcode `0x23`)

| Instruction | funct3 | Description |
|-------------|--------|-------------|
| SB | `000` | Store byte |
| SH | `001` | Store halfword |
| SW | `010` | Store word |

### Other Instructions

| Instruction | Opcode | Description |
|-------------|--------|-------------|
| LUI | `0x37` | Load upper immediate |
| AUIPC | `0x17` | Add upper immediate to PC |
| JAL | `0x6F` | Jump and link |
| JALR | `0x67` | Jump and link register |
| FENCE | `0x0F` | Fence (treated as NOP) |

### System Instructions (opcode `0x73`)

| Instruction | funct3 | Address | Description |
|-------------|--------|---------|-------------|
| ECALL | `000` | `0x000` | Environment call |
| EBREAK | `000` | `0x001` | Breakpoint |
| MRET | `000` | `0x302` | Machine-mode return from trap |
| WFI | `000` | `0x105` | Wait for interrupt |
| CSRRW | `001` | — | CSR read/write |
| CSRRS | `010` | — | CSR read and set bits |
| CSRRC | `011` | — | CSR read and clear bits |
| CSRRWI | `101` | — | CSR read/write immediate |
| CSRRSI | `110` | — | CSR read and set bits immediate |
| CSRRCI | `111` | — | CSR read and clear bits immediate |

## Privilege Mode

Leaf operates exclusively in **Machine Mode** (M-mode, privilege level 3). There is no support for Supervisor (S-mode) or User (U-mode). The `MPP` field in `mstatus` is hardwired to `2'b11` on reads.

## Machine CSRs

All CSRs are 32-bit (XLEN = 32). Counter CSRs are 64-bit, read as two 32-bit halves (low at `0xCxx`, high at `0xC8x`).

### Standard Machine CSRs

| Address | Register | R/W | Description |
|---------|----------|-----|-------------|
| `0x300` | `mstatus` | R/W | Machine status (MIE, MPIE, MPP) |
| `0x301` | `misa` | RO | ISA and extensions — reports RV32I (`0x30000100`) |
| `0x304` | `mie` | R/W | Interrupt enable (MEIE, MTIE, MSIE) |
| `0x305` | `mtvec` | R/W | Trap vector base address (direct mode only) |
| `0x340` | `mscratch` | R/W | Machine scratchpad register |
| `0x341` | `mepc` | R/W | Exception program counter |
| `0x342` | `mcause` | R/W | Trap cause (interrupt bit + exception code) |
| `0x343` | `mtval` | R/W | Trap value (faulting address or PC) |
| `0x344` | `mip` | RO | Interrupt pending (MEIP, MTIP, MSIP) |
| `0xF14` | `mhartid` | RO | Hart ID (configurable via generic, default 0) |

### `mstatus` Fields

| Bits | Field | Reset | Description |
|------|-------|-------|-------------|
| 3 | MIE | 0 | Machine interrupt enable |
| 7 | MPIE | 1 | Machine previous interrupt enable |
| 12:11 | MPP | 11 | Machine previous privilege mode (hardwired to M-mode) |

### Counter CSRs

| Address | Register | Width | Description |
|---------|----------|-------|-------------|
| `0xC00` | `cycle` | 32 | Cycle counter (low 32 bits) |
| `0xC01` | `time` | 32 | Timer (low 32 bits) |
| `0xC02` | `instret` | 32 | Instructions retired (low 32 bits) |
| `0xC80` | `cycleh` | 32 | Cycle counter (high 32 bits) |
| `0xC81` | `timeh` | 32 | Timer (high 32 bits) |
| `0xC82` | `instreth` | 32 | Instructions retired (high 32 bits) |

**Counter behavior:**

| Counter | Reset | Increment condition |
|---------|-------|---------------------|
| `mcycle` | Yes (0) | Every clock cycle |
| `time` | No (free-running) | Every clock cycle |
| `minstret` | Yes (0) | Each retired instruction |

### Interrupts

**Pending (mip), directly wired from external pins:**

| mip bit | Signal | Pin |
|---------|--------|-----|
| MEIP (11) | Machine external interrupt pending | `ex_irq_i` |
| MTIP (7) | Machine timer interrupt pending | `tm_irq_i` |
| MSIP (3) | Machine software interrupt pending | `sw_irq_i` |

**Enable (mie):**

| mie bit | Signal | Description |
|---------|--------|-------------|
| MEIE (11) | External interrupt enable | Gates MEIP |
| MTIE (7) | Timer interrupt enable | Gates MTIP |
| MSIE (3) | Software interrupt enable | Gates MSIP |

All interrupts are **level-sensitive** and gated by `mstatus.MIE`. The interrupt with the highest priority wins when multiple are pending:

| Priority | Interrupt | mcause code |
|----------|-----------|-------------|
| 1 (highest) | MEI | 11 |
| 2 | MTI | 7 |
| 3 (lowest) | MSI | 3 |

### Exception Codes

| mcause | Exception | Description |
|--------|-----------|-------------|
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

## Trap Flow

**On exception/interrupt** (`exc_taken = 1`):
1. `mepc` ← current PC
2. `mstatus.MPIE` ← `mstatus.MIE`; `mstatus.MIE` ← 0
3. `mcause` ← cause code (interrupt bit set for interrupts)
4. `mtval` ← address or PC (per table above)
5. `trap_target` ← `mtvec` (direct mode)
6. Pipeline redirects to `trap_target`

**On MRET**:
1. `mstatus.MIE` ← `mstatus.MPIE`; `mstatus.MPIE` ← 1
2. `trap_target` ← `mepc`
3. Pipeline redirects to `trap_target`

## Coprocessor CSR Window

CSR addresses `0x7C0`–`0x7FF` are reserved for an external coprocessor. Writes are forwarded as `cop_dat_o` with `cop_we_o` strobe; reads return `cop_dat_i`.

## Future CSRs

| Address | Register | Status |
|---------|----------|--------|
| `0x320` | `mcountinhibit` | Planned — counter inhibit (WARL, bits 0=CY, 2=IR) |
| `0x321` | `mhpmevent3` | Not implemented |
| `0x323`–`0x32F` | `mhpmevent4`–`31` | Not implemented |
