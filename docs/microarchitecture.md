# Microarchitecture Reference

## Architecture Overview

Leaf implements a two-stage pipeline with Wishbone B4 bus interface:

```
                   ┌──────────────────────────────────────┐
                   │              leaf (top)               │
                   │  ┌──────────┐  ┌──────────────────┐   │
clk_i ─────────────┼─▶│clk_ctrl  │──▶│    core          │   │
rst_i ─────────────┼─▶│          │  │  ┌─────────────┐  │   │
                   │  └──────────┘  │  │  IF Stage    │  │   │
                   │  ┌──────────┐  │  │ (if_stage)   │  │   │
ack_i ─────────────┼─▶│ wb_ctrl  │◀─┼──│ • PC fetch   │  │   │
err_i ─────────────┼─▶│ (FSM)    │──┼──│ • imem rd    │  │   │
dat_i ◀────────────┼──│          │  │  │ • flush      │  │   │
                   │  └──────────┘  │  └──────┬──────┘  │   │
                   │                │         │pipeline  │   │
                   │  ┌──────────┐  │  ┌──────▼──────┐  │   │
                   │  │ counters │  │  │  ID/EX      │  │   │
                   │  │ (cycle,  │  │  │ (id_stage + │  │   │
                   │  │  time,   │  │  │  ex_block)  │  │   │
                   │  │  instret)│  │  │ • decode    │  │   │
                   │  └──────────┘  │  │ • reg file  │  │   │
                   │                │  │ • CSR       │  │   │
                   │                │  │ • ALU       │  │   │
                   │                │  │ • branch    │  │   │
                   │                │  │ • load/store│  │   │
                   │                │  └─────────────┘  │   │
                   └──────────────────────────────────────┘
```

### Pipeline Operation

IF stage writes to pipeline registers on each clock; ID/EX operates combinatorially from those registers and writes results back in the same cycle. Both stages advance together — there is no independent stall per stage.

### Clock Domains

Two clock domains exist:

| Domain | Signal | Source | Consumers |
|--------|--------|--------|-----------|
| Free-running | `clk_i` | External input | `wb_ctrl`, `counters`, `clk_ctrl` |
| Gated | `clk` | `clk_ctrl(clk_i, clk_en)` | `core` (pipeline) |

The `clk_ctrl` module generates a glitch-free gated clock using a transparent latch (enable sampled on falling edge) + AND gate. The `clk_en` is asserted when the Wishbone FSM is in `START`, `EXECUTE`, or `ERROR` states — meaning the core clock is **stopped** during bus transactions and **running** when the pipeline has work to do.

```
clk_i   ─┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──
clk_en  ─┐    └──────┐    └──────┐    └──────┐    └──
en_latch ─┐    └──────┐    └──────┐    └──────┐    └──
clk      ─┐──┐  └──┐──┐  └──┐──┐  └──┐──┐  └──┐──┐
         FETCH EXEC FETCH EXEC FETCH EXEC FETCH EXEC
```

### Reset Architecture

Three different reset behaviors:

| Component | Reset Signal | Source | Deassertion |
|-----------|-------------|--------|-------------|
| `wb_ctrl` | `rst_i` | External | Immediate after `rst_i` |
| `clk_ctrl` | `rst_i` | External | Immediate (clock forced on during reset) |
| `counters` | `rst_i` | External | Immediate after `rst_i` |
| `core` | `reset` | `wb_ctrl` | 1 cycle after `rst_i` (when FSM exits START) |

The core's `reset` is derived from the Wishbone FSM START state, introducing a 1-cycle skew relative to `rst_i`.

## Top-Level Interface

### Ports (`rtl/leaf.vhdl`)

| Port | Direction | Description |
|------|-----------|-------------|
| `clk_i` | in | Master clock (50 MHz, 20 ns) |
| `rst_i` | in | Asynchronous reset (active high) |
| `ex_irq` | in | External interrupt (level-sensitive) |
| `sw_irq` | in | Software interrupt (level-sensitive) |
| `tm_irq` | in | Timer interrupt (level-sensitive) |
| `ack_i` | in | Wishbone acknowledge |
| `err_i` | in | Wishbone error |
| `dat_i` | in | Wishbone read data bus |
| `cop_dat_i` | in | Coprocessor read data (default 0) |
| `cop_adr_o` | out | Coprocessor address (6 bits, CSR address offset) |
| `cop_dat_o` | out | Coprocessor write data |
| `cop_we_o` | out | Coprocessor write strobe |
| `cyc_o` | out | Wishbone cycle |
| `stb_o` | out | Wishbone strobe |
| `we_o` | out | Wishbone write enable |
| `sel_o` | out | Wishbone byte selects |
| `adr_o` | out | Wishbone address |
| `dat_o` | out | Wishbone write data |

### Data Flow

```
                leaf.vhdl
    ┌────────────────────────────────────┐
    │                                    │
    │  ┌──────────────┐                  │
    │  │   wb_ctrl    │ ◀── imrd_en      │
    │  │              │ ◀── dmrd_en      │◀── core
    │  │              │ ◀── dmwr_en      │
    │  │              │ ◀── imrd_addr ───│
    │  │  (arbitrates)│ ◀── dmrw_addr ───│
    │  │              │ ◀── dmwr_data ───│
    │  │              │ ◀── dmwr_be ─────│
    │  │              │                  │
    │  │  ──▶ imrd_err ────▶ core        │
    │  │  ──▶ dmrd_err ────▶ core        │
    │  │  ──▶ dmwr_err ────▶ core        │
    │  │  ──▶ imrd_data ──▶ core        │
    │  │  ──▶ dmrd_data ──▶ core        │
    │  │  ──▶ clk_en ──▶ clk_ctrl       │
    │  │  ──▶ reset ──▶ core            │
    │  └──────────────┘                  │
    │                                    │
    │  ┌──────────────┐                  │
    │  │  clk_ctrl    │ ──▶ clk ──▶ core│
    │  └──────────────┘                  │
    │                                    │
    │  ┌──────────────┐                  │
    │  │  counters    │ ──▶ cycle ──▶ core
    │  │              │ ──▶ timer ──▶ core
    │  │              │ ──▶ instret ─▶ core
    │  └──────────────┘                  │
    │                                    │
    │  cop_adr_o ◀────── core (direct)   │
    │  cop_dat_o ◀────── core (direct)   │
    │  cop_we_o  ◀────── core (direct)   │
    │  cop_dat_i ──────▶ core (direct)   │
    └────────────────────────────────────┘
```

The COP interface bypasses `wb_ctrl` — it is a private channel between core and external coprocessor. No bus arbitration or error handling is performed on this path.

### Error Flow

1. `wb_ctrl` receives `err_i` from Wishbone slave
2. FSM transitions to `ERROR` state
3. Combinatorial logic asserts `imrd_err`, `dmrd_err`, or `dmwr_err` based on current enable signals
4. Error signals propagate to `core`:
   - `imrd_err` → `if_stage` → sets `imrd_fault` in pipeline register
   - `dmrd_err`/`dmwr_err` → `ex_block` → sets `dmld_fault`/`dmst_fault`
5. `id_stage` detects fault in decode → `csrs` triggers exception
6. FSM returns to `IDLE` on next clock

## Pipeline Stages

### IF Stage (`if_stage.vhdl`)

#### Interface

| Porta | Direção | Largura | Descrição |
|-------|---------|---------|-----------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset síncrono (active high) |
| `pcwr_en_i` | in | 1 | Pipeline advance enable |
| `imrd_err_i` | in | 1 | Instruction memory bus error |
| `taken_i` | in | 1 | Branch/jump taken (from ex_block) |
| `target_i` | in | XLEN | Branch/jump target address |
| `imrd_data_i` | in | XLEN | Instruction data from Wishbone |
| `imrd_en_o` | out | 1 | Instruction fetch request (to wb_ctrl) |
| `imrd_fault_o` | out | 1 | Instruction bus fault (to pipeline register) |
| `flush_o` | out | 1 | Discard current pipeline instruction |
| `retire_o` | out | 1 | Instruction retire pulse (= `pcwr_en_i and not flush_reg`) |
| `imrd_addr_o` | out | XLEN | Fetch address (to wb_ctrl) |
| `pc_o` | out | XLEN | Current PC (to ID/EX) |
| `next_pc_o` | out | XLEN | PC + 4 (to ID/EX) |
| `instr_o` | out | XLEN | Fetched instruction (to ID/EX) |

#### Funcionamento

- `pc_reg` mantém o PC atual, atualizado a cada `clk_i` via `pc_reg_proc`
- `next_res` é PC+4 (combinatorial)
- `flush_val` é o valor combinatorial de flush (`taken_i or imrd_err_i or not pcwr_en_i`)
- `flush_reg` captura `flush_val` no pipeline register — representa a validade da instrução corrente
- Pipeline register (`out_pipe_proc`) captura `pc_o`, `next_pc_o`, `instr_o`, `flush_reg`, `imrd_fault_o` na borda de subida do clock
- `imrd_en_o = pcwr_en_i` — fetch ativo sempre que pipeline avança
- `imrd_addr_o = pc_reg` — endereço de fetch sempre reflete o PC atual
- `retire_o = pcwr_en_i and not flush_reg` — pulso de retire, indica instrução válida completada

#### Prioridade de atualização do PC

1. **Reset**: `pc_reg <= RESET_ADDR`
2. **Branch taken** (`taken_i = '1'`): `pc_reg <= target_i`
3. **Pipeline advance** (`pcwr_en_i = '1'`): `pc_reg <= next_res`
4. **Stall** (nenhuma condição acima): `pc_reg` mantém valor

### ID/EX Stage (`id_stage.vhdl`)

#### Interface

| Porta | Direção | Largura | Descrição |
|-------|---------|---------|-----------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset síncrono (active high) |
| `ex_irq_i` | in | 1 | External interrupt |
| `sw_irq_i` | in | 1 | Software interrupt |
| `tm_irq_i` | in | 1 | Timer interrupt |
| `imrd_malgn_i` | in | 1 | Instruction fetch misaligned |
| `imrd_fault_i` | in | 1 | Instruction fetch bus fault |
| `dmld_malgn_i` | in | 1 | Data load misaligned |
| `dmld_fault_i` | in | 1 | Data load bus fault |
| `dmst_malgn_i` | in | 1 | Data store misaligned |
| `dmst_fault_i` | in | 1 | Data store bus fault |
| `cycle_i` | in | 64 | Cycle counter value |
| `timer_i` | in | 64 | Timer value |
| `instret_i` | in | 64 | Instruction retired counter |
| `exec_res_i` | in | XLEN | ALU execution result |
| `dmld_data_i` | in | XLEN | Data load result (from dmls_block) |
| `pc_i` | in | XLEN | Current PC (from if_stage) |
| `next_pc_i` | in | XLEN | PC + 4 (from if_stage) |
| `instr_i` | in | XLEN | Fetched instruction |
| `flush_i` | in | 1 | Flush — discard current instruction |
| `csrwr_data_i` | in | XLEN | CSR write data (from csrs_logic) |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `func3_o` | out | 3 | funct3 field |
| `func7_o` | out | 7 | funct7 field |
| `imm_o` | out | XLEN | Decoded immediate |
| `jmp_o` | out | 1 | Jump (JAL/JALR) |
| `br_en_o` | out | 1 | Branch enable |
| `opd0_src_sel_o` | out | 1 | Select PC vs reg0 as ALU operand 0 |
| `opd1_src_sel_o` | out | 1 | Select imm vs reg1 as ALU operand 1 |
| `opd0_pass_o` | out | 1 | Gate ALU operand 0 |
| `opd1_pass_o` | out | 1 | Gate ALU operand 1 |
| `ftype_o` | out | 1 | Instruction type for ALU control |
| `op_en_o` | out | 1 | ALU operation enable |
| `dmls_mode_o` | out | 1 | Data memory mode (0=load, 1=store) |
| `dmls_en_o` | out | 1 | Data memory enable |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |
| `pcwr_en_o` | out | 1 | Pipeline advance enable (to if_stage) |
| `trap_taken_o` | out | 1 | Trap taken |
| `trap_target_o` | out | XLEN | Trap handler address |
| `rd_data0_o` | out | XLEN | Register file read port 0 |
| `rd_data1_o` | out | XLEN | Register file read port 1 |
| `csrrd_data_o` | out | XLEN | CSR read data |

Combines decode, register file read, and CSR access:

- **main_ctrl** decodes the instruction: opcode, funct3, funct7 → control signals and immediate
- **reg_file** reads two source registers (combinatorial read)
- **csrs** handles CSR read/write and trap/exception logic
- Passes decoded signals to `ex_block`

#### Register File (`reg_file.vhdl`)

32 × XLEN register file with combinatorial read, synchronous write. Register x0 is hardwired to zero.

| Porta | Direção | Largura | Descrição |
|-------|---------|---------|-----------|
| `clk_i` | in | 1 | Clock |
| `we_i` | in | 1 | Write enable |
| `wr_sel_i` | in | 2 | Write data mux select (0=ALU, 1=dmem, 2=next_pc, 3=CSR) |
| `wr_addr_i` | in | 5 | Write destination register address |
| `wr_data0_i` | in | XLEN | Write data from ALU result |
| `wr_data1_i` | in | XLEN | Write data from data load |
| `wr_data2_i` | in | XLEN | Write data from next PC |
| `wr_data3_i` | in | XLEN | Write data from CSR read |
| `rd_addr0_i` | in | 5 | Read port 0 address |
| `rd_addr1_i` | in | 5 | Read port 1 address |
| `rd_data0_o` | out | XLEN | Read port 0 data |
| `rd_data1_o` | out | XLEN | Read port 1 data |

Dual-implementation: `SIZE=16` selects `small_reg_file` (4-bit addressing), `SIZE=32` selects `large_reg_file` (5-bit). Default is 32.

### Execution Block (`ex_block.vhdl`)

#### Interface

| Porta | Direção | Largura | Descrição |
|-------|---------|---------|-----------|
| `trap_taken_i` | in | 1 | Trap taken (from csrs) |
| `trap_target_i` | in | XLEN | Trap handler PC |
| `func3_i` | in | 3 | funct3 field |
| `func7_i` | in | 7 | funct7 field |
| `reg0_i` | in | XLEN | Register file read port 0 |
| `reg1_i` | in | XLEN | Register file read port 1 |
| `pc_i` | in | XLEN | Current PC |
| `imm_i` | in | XLEN | Decoded immediate |
| `csrrd_data_i` | in | XLEN | CSR read data |
| `jmp_i` | in | 1 | Jump (JAL/JALR) |
| `br_en_i` | in | 1 | Branch enable |
| `opd0_src_sel_i` | in | 1 | Select PC vs reg0 as ALU operand 0 |
| `opd1_src_sel_i` | in | 1 | Select imm vs reg1 as ALU operand 1 |
| `opd0_pass_i` | in | 1 | Gate ALU operand 0 |
| `opd1_pass_i` | in | 1 | Gate ALU operand 1 |
| `ftype_i` | in | 1 | Instruction type for ALU control |
| `op_en_i` | in | 1 | ALU operation enable |
| `dmls_mode_i` | in | 1 | Data memory mode (0=load, 1=store) |
| `dmls_en_i` | in | 1 | Data memory enable |
| `dmrd_err_i` | in | 1 | Data read bus error |
| `dmwr_err_i` | in | 1 | Data write bus error |
| `dmrd_data_i` | in | XLEN | Data read data (from Wishbone) |
| `imrd_malgn_o` | out | 1 | Instruction fetch misaligned |
| `dmld_malgn_o` | out | 1 | Data load misaligned |
| `dmld_fault_o` | out | 1 | Data load bus fault |
| `dmst_malgn_o` | out | 1 | Data store misaligned |
| `dmst_fault_o` | out | 1 | Data store bus fault |
| `dmrd_en_o` | out | 1 | Data read request (to wb_ctrl) |
| `dmwr_en_o` | out | 1 | Data write request (to wb_ctrl) |
| `dmwr_data_o` | out | XLEN | Data write data |
| `dmrw_addr_o` | out | XLEN | Data memory address |
| `dm_byte_en_o` | out | 4 | Data byte enables |
| `dmld_data_o` | out | XLEN | Data load result (aligned/sextended) |
| `csrwr_data_o` | out | XLEN | CSR write data (from csrs_logic) |
| `taken_o` | out | 1 | Branch/jump/trap taken |
| `target_o` | out | XLEN | Branch/jump/trap target address |
| `res_o` | out | XLEN | ALU result |

Contains all datapath execution logic:

- **alu_ctrl** — decodes ALU operation from funct3/funct7
- **alu** — performs the selected operation (add, sub, sll, slt, etc.)
- **br_detector** — evaluates branch conditions (eq, ne, lt, ge, ltu, geu)
- **dmls_block** — load/store alignment and sign-extension
- **csrs_logic** — CSR write data muxing (reg, immediate, or RS1-based modes)

### Control Signals

Individual ports from `main_ctrl`, passed through `id_stage` to `ex_block`:

| Porta | Descrição |
|-------|-----------|
| `jmp_i` | Jump (JAL/JALR) |
| `br_en_i` | Branch enable |
| `opd0_src_sel_i` | Select PC vs reg0 as ALU operand 0 |
| `opd1_src_sel_i` | Select imm vs reg1 as ALU operand 1 |
| `opd0_pass_i` | Gate ALU operand 0 |
| `opd1_pass_i` | Gate ALU operand 1 |
| `ftype_i` | Instruction type for ALU control |
| `op_en_i` | ALU operation enable |

## Wishbone Bus Interface

`wb_ctrl.vhdl` implements a Wishbone B4-compatible master with a single-cycle arbitration FSM:

### States

| State | Description |
|-------|-------------|
| `START` | Initial reset state, asserts internal reset |
| `IDLE` | Waits for imem request (`imrd_en`) |
| `READ_INSTR` | Instruction fetch cycle, waits for `ack_i` or `err_i` |
| `BRD_CYCLE` | Transition to data read |
| `READ_DATA` | Data read cycle, waits for `ack_i` or `err_i` |
| `RMW_CYCLE` | Transition to data write |
| `WRITE_DATA` | Data write cycle, waits for `ack_i` or `err_i` |
| `EXECUTE` | Single-cycle execute — clock gating enabled, bus released |
| `ERROR` | Bus error response — signals error to core |

### Bus Arbitration

Read-modify-write is used for stores: the FSM goes `READ_INSTR → RMW_CYCLE → WRITE_DATA → EXECUTE`, ensuring the bus is acquired for the full memory operation.

## CSRs (`csrs.vhdl`)

### Interface

| Porta | Direção | Largura | Descrição |
|-------|---------|---------|-----------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset síncrono |
| `ex_irq_i` | in | 1 | External interrupt |
| `sw_irq_i` | in | 1 | Software interrupt |
| `tm_irq_i` | in | 1 | Timer interrupt |
| `imrd_malgn_i` | in | 1 | Instruction fetch misaligned |
| `imrd_fault_i` | in | 1 | Instruction fetch fault |
| `instr_err_i` | in | 1 | Illegal instruction |
| `dmld_malgn_i` | in | 1 | Data load misaligned |
| `dmld_fault_i` | in | 1 | Data load fault |
| `dmst_malgn_i` | in | 1 | Data store misaligned |
| `dmst_fault_i` | in | 1 | Data store fault |
| `wr_en_i` | in | 1 | CSR write enable |
| `wr_mode_i` | in | 3 | CSR write mode (funct3) |
| `rw_addr_i` | in | 12 | CSR address |
| `wr_data_i` | in | XLEN | CSR write data |
| `exec_res_i` | in | XLEN | ALU result (for mtval on misaligned) |
| `pc_i` | in | XLEN | Current PC (for mepc/mtval on ebreak) |
| `next_pc_i` | in | XLEN | Next PC (for mepc on WFI) |
| `cycle_i` | in | 64 | Cycle counter |
| `timer_i` | in | 64 | Timer value |
| `instret_i` | in | 64 | Instruction retired counter |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |
| `pcwr_en_o` | out | 1 | Pipeline advance (0 during WFI until interrupt) |
| `trap_taken_o` | out | 1 | Exception/interrupt/mret taken |
| `trap_target_o` | out | XLEN | Trap handler or return address |
| `rd_data_o` | out | XLEN | CSR read data |

### Funcionamento

The CSRs module implements the machine-mode CSR registers and all trap/exception logic:

- **System calls**: `ecall`, `ebreak`, `mret`, `wfi` decoded from write enable + address
- **Interrupt pending**: `mip_meip/msip/mtip` directly wired from external IRQ inputs (level-sensitive)
- **Exception vector**: `exc_taken` combines all fault signals, ecall, ebreak, and interrupts
- **Trap taken**: `trap_taken_o <= exc_taken or mret` — redirects pipeline for both traps and MRET
- **mstatus**: MIE/MPIE updated on entry (save+disable) and MRET (restore)
- **mepc**: Saves PC on trap; `next_pc` on WFI (return after wakeup); writable via CSR
- **mcause**: Priority encoder for exception source; interrupt bit = `int_taken`
- **mtval**: Address for misaligned access faults; PC for ebreak; zero otherwise
- **Coprocessor window**: CSR addresses `0x7C0`–`0x7FF` forwarded to `cop_dat_o` with `cop_we_o` strobe

### Machine-Mode CSRs

| Address | Register | Description |
|---------|----------|-------------|
| `0x300` | `mstatus` | Machine status (MIE, MPIE) |
| `0x301` | `misa` | ISA and extensions (RV32I) |
| `0x304` | `mie` | Interrupt enable (MEIE, MTIE, MSIE) |
| `0x305` | `mtvec` | Trap vector base address |
| `0x320` | `mcountinhibit` | Machine counter inhibit (WARL) — *não implementado* |
| `0x321` | `mhpmevent3` | Hardware performance event select (future) |
| `0x323`–`0x32F` | `mhpmevent4–31` | Hardware performance event select (future) |
| `0x340` | `mscratch` | Machine scratchpad |
| `0x341` | `mepc` | Exception program counter |
| `0x342` | `mcause` | Trap cause |
| `0x343` | `mtval` | Trap value |
| `0x344` | `mip` | Interrupt pending |

### Read-Only Counters

| Address | Register | Description |
|---------|----------|-------------|
| `0xC00` | `cycle` | Cycle counter (low) |
| `0xC01` | `time` | Timer (low) |
| `0xC02` | `instret` | Instruction retired (low) |
| `0xC80` | `cycleh` | Cycle counter (high) |
| `0xC81` | `timeh` | Timer (high) |
| `0xC82` | `instreth` | Instruction retired (high) |

### Counter Inhibit (`mcountinhibit`)

`mcountinhibit` (CSR `0x320`) é um registrador WARL que permite ao software pausar seletivamente os contadores de performance:

| Bit | Campo | Controle |
|-----|-------|----------|
| 0 | CY | `mcycle` — 1 = inibe incremento |
| 2 | IR | `minstret` — 1 = inibe incremento |
| demais | — | Hardwired a 0 (reservados) |

Quando um bit é `1`, o respectivo contador para de incrementar. O bit 1 (TM para `time`) é hardwired a 0 — `time` é um timer wall-clock independente e não deve ser inibido.

**Nota**: `mcountinhibit` ainda **não está implementado** no Leaf. A implementação futura requer:

1. Adicionar registrador `mcountinhibit_reg` em `csrs.vhdl` (bits 0 e 2 writable WARL, demais hardwired a 0)
2. Adicionar portas `mcountinhibit_o` em `csrs` → `id_stage` → `core`
3. Adicionar porta `inhibit_i` em `counters` — gating nos incrementos (`inhibit_i(0)` trava `cycle`, `inhibit_i(2)` trava `instret`)
4. Conectar `core.mcountinhibit_o` → `counters.inhibit_i` em `leaf.vhdl`

### Timer Interrupt (`tm_irq`)

`tm_irq` é uma entrada externa do core — o Leaf não a gera internamente. O contador `time` (CSR `0xC01`/`0xC81`) incrementa a cada ciclo de `clk_i` e é legível por software, mas não há registrador `mtimecmp` para comparar o timer e gerar a IRQ automaticamente.

Para usar timer interrupts, é necessário hardware externo que:
- Programe um valor de comparação via memory-mapped register ou CSR de coprocessador
- Compare contra `time` ou seu próprio contador
- Assevere `tm_irq` quando a condição for satisfeita

A implementação de `mtimecmp` conforme a RISC-V Privileged Spec (seção 3.1.11) é uma melhoria futura.

### Custom Coprocessor Window

CSR addresses `0x7C0` to `0x7FF` are reserved for coprocessor attachment. Reads are forwarded to `cop_dat_i`, writes to `cop_dat_o` with `cop_we_o` strobe.

## Exception and Trap Handling

Exception sources, their `mcause` codes, and `mtval` behavior:

| Code | Source | mtval |
|------|--------|-------|
| 0 | Instruction address misaligned | Target address (`exec_res`) |
| 1 | Instruction access fault | PC of faulted instruction |
| 2 | Illegal instruction | 0 |
| 3 | Breakpoint (ebreak) | PC of breakpoint instruction |
| 4 | Load address misaligned | Effective address (`exec_res`) |
| 5 | Load access fault | Effective address (`exec_res`) |
| 6 | Store address misaligned | Effective address (`exec_res`) |
| 7 | Store access fault | Effective address (`exec_res`) |
| 11 | Environment call (ecall) | 0 |

Interrupt codes (mscause bit 31 = 1):

| Code | Source |
|------|--------|
| 0 | Instruction address misaligned |
| 1 | Instruction access fault |
| 2 | Illegal instruction |
| 3 | Breakpoint (ebreak) |
| 4 | Load address misaligned |
| 5 | Load access fault |
| 6 | Store address misaligned |
| 7 | Store access fault |
| 11 | Environment call (ecall) |

Interrupt codes (mscause bit 31 = 1):

| Code | Source |
|------|--------|
| 3 | Machine software interrupt |
| 7 | Machine timer interrupt |
| 11 | Machine external interrupt |

Trap flow:
1. Current PC is saved to `mepc`
2. `mstatus.MIE` is saved to `mstatus.MPIE`, then `MIE` is cleared
3. `mcause` and `mtval` are set
4. PC jumps to `mtvec`

## Counters (`rtl/counters.vhdl`)

The counters module tracks three 64-bit values, all on the `clk_i` domain:

| Counter | CSR (low) | CSR (high) | Reset | Behavior |
|---------|-----------|-------------|-------|----------|
| `mcycle` | `0xC00` | `0xC80` | Yes | Increments every `clk_i` cycle (free-running) |
| `time` | `0xC01` | `0xC81` | No | Increments every `clk_i` cycle (free-running, separate register) |
| `minstret` | `0xC02` | `0xC82` | Yes | Increments on instruction retire (`retire_i`) |

The `time` counter has no reset — it counts continuously from power-on as a free-running real-time clock, independent of the core's operating state.

### Retire Signal

The `retire` pulse is generated in `if_stage.vhdl` as:

```vhdl
retire_o <= pcwr_en_i and not flush_reg;
```

`flush_reg` é a versão registrada do flush (capturada no pipeline register). Como `flush_reg` reflete o flush do ciclo anterior (quando a instrução foi buscada), uma branch taken corrente tem `flush_reg = 0` e é contada. A instrução especulativamente buscada após a branch recebe `flush_reg = 1` e não é contada.

O sinal atravessa `core.vhdl` como wire-through direto (`retire_o => retire_o`).

Isso conta uma instrução por avanço válido do pipeline:
- **Normal instructions**: counted on each pipeline cycle
- **Taken branches**: branch is counted, next instruction (flushed) is not
- **Traps**: trap-causing instruction (ecall/ebreak) is counted
- **Stalls**: no count when pipeline is stalled (pcwr_en = '0')
- **Bus errors**: faulted instruction is not counted (flush = '1')

## Register File

The register file (`reg_file.vhdl`) has 32 × 32-bit registers with:

- 2 asynchronous read ports
- 1 synchronous write port with 4-way write mux (ALU result, load data, next PC, CSR read data)
- Register x0 is hardwired to zero (writes to x0 are discarded)

## Block Diagram

```
                  ┌──────────┐
  clk_i ─────────▶│clk_ctrl  │───▶ clk (gated)
  rst_i ─────────▶│          │
                  └──────────┘
                  ┌──────────┐
  ack_i ─────────▶│          │
  err_i ─────────▶│ wb_ctrl  │◀─── imrd_en, dmrd_en, dmwr_en
  dat_i ◀────────▶│          │───▶ cyc_o, stb_o, we_o, adr_o, dat_o
                  └──────────┘
                        │
               ┌────────┴────────┐
               │                 │
        ┌──────────────┐  ┌──────────────┐
        │   counters   │  │    core      │
        │ (cycle,time, │  │              │
        │  instret)    │  │ if_stage     │
        └──────────────┘  │ id_stage     │
                          │ ex_block     │
                          └──────────────┘
```

## RTL File Map

| File | Entity | Role |
|------|--------|------|
| `rtl/leaf.vhdl` | `leaf` | Top-level: Wishbone interface, clock gating, counters, COP interface passthrough |
| `rtl/core.vhdl` | `core` | Core integration: IF + ID/EX pipeline |
| `rtl/if_stage.vhdl` | `if_stage` | Instruction fetch, PC register, flush |
| `rtl/id_stage.vhdl` | `id_stage` | Decode, register file, CSRs |
| `rtl/ex_block.vhdl` | `ex_block` | ALU, branch, CSR logic, load/store |
| `rtl/alu.vhdl` | `alu` | ALU datapath |
| `rtl/alu_ctrl.vhdl` | `alu_ctrl` | ALU operation decoder |
| `rtl/br_detector.vhdl` | `br_detector` | Branch condition evaluation |
| `rtl/dmls_block.vhdl` | `dmls_block` | Data memory load/store alignment |
| `rtl/csrs.vhdl` | `csrs` | Machine CSRs and trap control |
| `rtl/csrs_logic.vhdl` | `csrs_logic` | CSR write data muxing |
| `rtl/counters.vhdl` | `counters` | mcycle, time, minstret counters |
| `rtl/clk_ctrl.vhdl` | `clk_ctrl` | Clock gating |
| `rtl/reg_file.vhdl` | `reg_file` | 32×32 register file |
| `rtl/wb_ctrl.vhdl` | `wb_ctrl` | Wishbone B4 master FSM |
| `rtl/leaf_pkg.vhdl` | `leaf_pkg` | ISA constants, opcodes, ALU ops, component declarations |
| `rtl/main_ctrl.vhdl` | `main_ctrl` | Main control decoder and immediate generator |

## Test Support Files

| File | Purpose |
|------|---------|
| `verif/tests/common/common.mk` | Build rules: .s → .elf → .bin → run/compare |
| `verif/tests/common/leaf.ld` | Leaf linker script |
| `verif/tests/common/spike.ld` | Spike linker script |
| `verif/tests/common/leaf.S` | Leaf HALT routine |
| `verif/tests/common/spike.S` | Spike finish routine |
| `verif/tests/common/common.S` | `store_regs` helper (dumps x0-x31 + CSRs) |
| `verif/tests/common/defs.inc` | Memory map constants |

## Key Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MEM_BASE` | `0x80000000` | Memory base address |
| `MEM_SIZE` | `0x400000` | Memory size (4 MiB) |
| `HALT_CMD_ADDR` | `0x803FFFFC` | HALT command address (last word) |
| `CLK_PERIOD` | 20 ns | Clock period (50 MHz) |
| `XLEN` | 32 | Register width |
