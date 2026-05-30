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

Combines decode, register file read, and CSR access:

- **main_ctrl** decodes the instruction: opcode, funct3, funct7 → control signals and immediate
- **reg_file** reads two source registers (combinatorial read)
- **csrs** handles CSR read/write and trap/exception logic
- Passes decoded signals to `ex_block`

### Execution Block (`ex_block.vhdl`)

Contains all datapath execution logic:

- **alu_ctrl** — decodes ALU operation from funct3/funct7
- **alu** — performs the selected operation (add, sub, sll, slt, etc.)
- **br_detector** — evaluates branch conditions (eq, ne, lt, ge, ltu, geu)
- **dmls_block** — load/store alignment and sign-extension
- **csrs_logic** — CSR write data muxing (reg, immediate, or RS1-based modes)

### Control Signals (`exec_ctrl`)

8-bit control word from main_ctrl:

| Bit | Signal | Description |
|-----|--------|-------------|
| 7 | `jmp` | Jump (JAL/JALR) |
| 6 | `br_en` | Branch enable |
| 5 | `opd0_src_sel` | Select PC vs reg0 as ALU operand 0 |
| 4 | `opd1_src_sel` | Select imm vs reg1 as ALU operand 1 |
| 3 | `opd0_pass` | Gate ALU operand 0 |
| 2 | `opd1_pass` | Gate ALU operand 1 |
| 1 | `ftype` | Instruction type for ALU control |
| 0 | `op_en` | ALU operation enable |

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

## CSRs

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

### Custom Coprocessor Window

CSR addresses `0x7C0` to `0x7FF` are reserved for coprocessor attachment. Reads are forwarded to `cop_dat_i`, writes to `cop_dat_o` with `cop_we_o` strobe.

## Exception and Trap Handling

Exception sources and their `mcause` codes:

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
