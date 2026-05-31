# Microarchitecture Reference

## RTL File Map

| File | Entity | Role |
|------|--------|------|
| `rtl/leaf.vhdl` | `leaf` | Top-level: Wishbone interface, clock gating, counters, COP interface passthrough |
| `rtl/wb_ctrl.vhdl` | `wb_ctrl` | Wishbone B4 master FSM |
| `rtl/clk_ctrl.vhdl` | `clk_ctrl` | Clock gating |
| `rtl/counters.vhdl` | `counters` | mcycle, time, instret counters |
| `rtl/core.vhdl` | `core` | Core integration: IF + ID/EX pipeline |
| `rtl/if_stage.vhdl` | `if_stage` | Instruction fetch, PC register, flush |
| `rtl/id_stage.vhdl` | `id_stage` | Decode, register file, CSRs |
| `rtl/main_ctrl.vhdl` | `main_ctrl` | Main control decoder and immediate generator |
| `rtl/reg_file.vhdl` | `reg_file` | 32×32 register file |
| `rtl/csrs.vhdl` | `csrs` | Machine CSRs and trap control |
| `rtl/ex_block.vhdl` | `ex_block` | ALU, branch, CSR logic, load/store |
| `rtl/alu_ctrl.vhdl` | `alu_ctrl` | ALU operation decoder |
| `rtl/alu.vhdl` | `alu` | ALU datapath |
| `rtl/br_detector.vhdl` | `br_detector` | Branch condition evaluation |
| `rtl/dmls_block.vhdl` | `dmls_block` | Data memory load/store alignment |
| `rtl/csrs_logic.vhdl` | `csrs_logic` | CSR write data muxing |
| `rtl/leaf_pkg.vhdl` | `leaf_pkg` | ISA constants, opcodes, ALU ops, component declarations |

---

## Architecture Overview

Leaf implements a two-stage pipeline with Wishbone B4 bus interface:

```
                    ┌──────────────────────────────────────┐
                    │              leaf (top)               │
                    │  ┌──────────┐  ┌──────────────────┐   │
  clk_i ────────────┼─▶│clk_ctrl  │─▶│     core          │   │
  rst_i ────────────┼─▶│          │  │  ┌─────────────┐  │   │
                    │  └──────────┘  │  │  IF Stage    │  │   │
                    │  ┌──────────┐  │  │ (if_stage)   │  │   │
  ack_i ────────────┼─▶│ wb_ctrl  │◀─┼──│ • PC fetch   │  │   │
  err_i ────────────┼─▶│ (FSM)    │──┼──│ • imem rd    │  │   │
  dat_i ◀───────────┼──│          │  │  │ • flush      │  │   │
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

### Module Hierarchy

```
leaf (top)
├── wb_ctrl       Wishbone B4 master FSM
├── clk_ctrl      Glitch-free clock gating
├── counters      cycle, time, instret counters
└── core          Core (IF + ID/EX pipeline)
    ├── if_stage    Instruction fetch (IF)
    ├── id_stage    Decode + register file + CSRs (ID)
    │   ├── main_ctrl   Instruction decoder and immediate generator
    │   ├── reg_file    32 × XLEN register file
    │   └── csrs        Machine-mode CSRs and trap logic
    └── ex_block    ALU + branch + load/store (EX)
        ├── alu_ctrl     ALU operation decoder
        ├── alu          ALU datapath (bypass chain)
        ├── br_detector  Branch condition evaluation
        ├── dmls_block   Data memory load/store alignment
        └── csrs_logic   CSR write data mux
```

### Clock Domains

| Domain | Signal | Source | Consumers |
|--------|--------|--------|-----------|
| Free-running | `clk_i` | External input | `wb_ctrl`, `counters`, `clk_ctrl` |
| Gated | `clk` | `clk_ctrl(clk_i, clk_en)` | `core` (pipeline) |

### Reset Architecture

| Component | Reset Signal | Source | Deassertion |
|-----------|-------------|--------|-------------|
| `wb_ctrl` | `rst_i` | External | Immediate after `rst_i` |
| `clk_ctrl` | `rst_i` | External | Immediate (clock forced on during reset) |
| `counters` | `rst_i` | External | Immediate after `rst_i` |
| `core` | `reset` | `wb_ctrl` | 1 cycle after `rst_i` (when FSM exits START) |

The core's `reset` is derived from the Wishbone FSM START state, introducing a 1-cycle skew relative to `rst_i`.

---

## Module Interfaces

### 1. `leaf` (top-level)

File: `rtl/leaf.vhdl`

#### Generics

| Generic | Default | Description |
|---------|---------|-------------|
| `RESET_ADDR` | `0x00000000` | Reset vector address |
| `CSRS_MHART_ID` | `0x00000000` | Machine hart ID (mhartid CSR) |
| `REG_FILE_SIZE` | 32 | Register file size (16 or 32) |

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Master clock (50 MHz, 20 ns) |
| `rst_i` | in | 1 | Asynchronous reset (active high) |
| `ex_irq_i` | in | 1 | External interrupt (level-sensitive) |
| `sw_irq_i` | in | 1 | Software interrupt (level-sensitive) |
| `tm_irq_i` | in | 1 | Timer interrupt (level-sensitive) |
| `ack_i` | in | 1 | Wishbone acknowledge |
| `err_i` | in | 1 | Wishbone error |
| `dat_i` | in | XLEN | Wishbone read data bus |
| `cop_dat_i` | in | XLEN | Coprocessor read data (default 0) |
| `cop_adr_o` | out | 6 | Coprocessor address (CSR address offset) |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write strobe |
| `cyc_o` | out | 1 | Wishbone cycle |
| `stb_o` | out | 1 | Wishbone strobe |
| `we_o` | out | 1 | Wishbone write enable |
| `sel_o` | out | 4 | Wishbone byte selects |
| `adr_o` | out | XLEN | Wishbone address |
| `dat_o` | out | XLEN | Wishbone write data |

#### Block Diagram

```
     ┌─────────────────────────────────────────────────────────────────┐
     │  leaf                                                            │
     │                                                                  │
     │  clk_i ──▶ clk_ctrl ──clk──┐                                   │
     │  rst_i ──▶ clk_ctrl         │                                   │
     │                        ┌────┴────┐                              │
     │  ack_i ──┐             │         │                              │
     │  err_i ──┤  ┌───────┐  │ core    │                              │
     │  dat_i ◀─┼──┤wb_ctrl├─┘  IF      │                              │
     │          │  │ B4    │◀─── ID+CSR │                              │
     │  cyc_o ──┤  │ FSM   │───▶ EX     │                              │
     │  stb_o ──┤  └───────┘   │        │                              │
     │  we_o ───┤               │        │                              │
     │  adr_o ──┤            ┌──┴────────┘                              │
     │  dat_o ──┘            │  retire                                 │
     │                ┌──────▼─────┐                                   │
     │                │ counters   │                                   │
     │                │ cycle ─────┼──▶ core                           │
     │                │ timer ─────┼──▶ core                           │
     │                │ instret ───┼──▶ core                           │
     │                └────────────┘                                   │
     │                                                                  │
     │  cop_dat_i ──▶ core    cop_adr_o ◀── core                      │
     │  cop_dat_o ◀── core    cop_we_o  ◀── core                      │
     └─────────────────────────────────────────────────────────────────┘
```

#### Internal Data Flow

```
                 leaf.vhdl
    ┌────────────────────────────────────┐
    │                                    │
    │  ┌──────────────┐                  │
    │  │   wb_ctrl    │ ◀── imrd_en      │
    │  │              │ ◀── dmrd_en      │
    │  │              │ ◀── dmwr_en      │
    │  │              │ ◀── imrd_addr    │
    │  │  (arbitrates)│ ◀── dmrw_addr    │
    │  │              │ ◀── dmwr_data    │
    │  │              │ ◀── dmwr_be      │
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
    │  │  counters    │ ──▶ cycle ──▶ core│
    │  │              │ ──▶ timer ──▶ core│
    │  │              │ ──▶ instret ─▶ core│
    │  └──────────────┘                  │
    │                                    │
    │  cop_adr_o ◀────── core (direct)   │
    │  cop_dat_o ◀────── core (direct)   │
    │  cop_we_o  ◀────── core (direct)   │
    │  cop_dat_i ──────▶ core (direct)   │
    └────────────────────────────────────┘
```

The COP interface bypasses `wb_ctrl` — it is a private channel between core and external coprocessor. No bus arbitration or error handling is performed on this path.

#### Error Flow

1. `wb_ctrl` receives `err_i` from Wishbone slave
2. FSM transitions to `ERROR` state
3. Combinatorial logic asserts `imrd_err`, `dmrd_err`, or `dmwr_err` based on current enable signals
4. Error signals propagate to `core`:
   - `imrd_err` → `if_stage` → sets `imrd_fault` in pipeline register
   - `dmrd_err`/`dmwr_err` → `ex_block` → sets `dmld_fault`/`dmst_fault`
5. `id_stage` detects fault in decode → `csrs` triggers exception
6. FSM returns to `IDLE` on next clock

---

#### 1.1 `wb_ctrl` — Wishbone Controller

File: `rtl/wb_ctrl.vhdl`

Implements a Wishbone B4-compatible master with a single-cycle arbitration FSM.

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock (free-running) |
| `rst_i` | in | 1 | Asynchronous reset (active high) |
| `imrd_en_i` | in | 1 | Instruction fetch enable (from core) |
| `dmrd_en_i` | in | 1 | Data read enable (from core) |
| `dmwr_en_i` | in | 1 | Data write enable (from core) |
| `ack_i` | in | 1 | Wishbone acknowledge |
| `err_i` | in | 1 | Wishbone error |
| `dat_i` | in | XLEN | Wishbone read data |
| `dmwr_be_i` | in | 4 | Data write byte enables (from core) |
| `imrd_addr_i` | in | XLEN | Instruction fetch address (from core) |
| `dmrw_addr_i` | in | XLEN | Data memory address (from core) |
| `dmwr_data_i` | in | XLEN | Data write data (from core) |
| `cyc_o` | out | 1 | Wishbone cycle |
| `stb_o` | out | 1 | Wishbone strobe |
| `we_o` | out | 1 | Wishbone write enable |
| `clk_en_o` | out | 1 | Clock enable (to clk_ctrl) |
| `reset_o` | out | 1 | Core reset (to core) |
| `imrd_err_o` | out | 1 | Instruction fetch bus error (to core) |
| `dmrd_err_o` | out | 1 | Data read bus error (to core) |
| `dmwr_err_o` | out | 1 | Data write bus error (to core) |
| `sel_o` | out | 4 | Wishbone byte selects |
| `adr_o` | out | XLEN | Wishbone address |
| `dat_o` | out | XLEN | Wishbone write data |
| `imrd_data_o` | out | XLEN | Instruction data (to core) |
| `dmrd_data_o` | out | XLEN | Read data (to core) |

##### FSM States

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

##### Bus Arbitration

Read-modify-write is used for stores: the FSM goes `READ_INSTR → RMW_CYCLE → WRITE_DATA → EXECUTE`, ensuring the bus is acquired for the full memory operation.

---

#### 1.2 `clk_ctrl` — Clock Gating

File: `rtl/clk_ctrl.vhdl`

Generates a glitch-free gated clock using a transparent latch (enable sampled on falling edge) + AND gate.

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Master clock |
| `rst_i` | in | 1 | Reset (forces clock on during reset) |
| `clk_en` | in | 1 | Clock enable (from wb_ctrl) |
| `clk` | out | 1 | Gated clock (to core) |

The `clk_en` is asserted when the Wishbone FSM is in `START`, `EXECUTE`, or `ERROR` states — meaning the core clock is **stopped** during bus transactions and **running** when the pipeline has work to do.

```
clk_i   ─┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──
clk_en  ─┐    └──────┐    └──────┐    └──────┐    └──
en_latch ─┐    └──────┐    └──────┐    └──────┐    └──
clk      ─┐──┐  └──┐──┐  └──┐──┐  └──┐──┐  └──┐──┐
         FETCH EXEC FETCH EXEC FETCH EXEC FETCH EXEC
```

---

#### 1.3 `counters` — Cycle, Time, Instret Counters

File: `rtl/counters.vhdl`

Tracks three 64-bit values: `mcycle` (free-running, resettable), `time` (free-running, no reset), `minstret` (increments on instruction retire).

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock (free-running, not gated) |
| `reset_i` | in | 1 | Reset |
| `retire_i` | in | 1 | Instruction retire pulse (from core) |
| `cycle_o` | out | 64 | Cycle counter value (CSR 0xC00/0xC80) |
| `timer_o` | out | 64 | Timer value (CSR 0xC01/0xC81) |
| `instret_o` | out | 64 | Instruction retired counter (CSR 0xC02/0xC82) |

| Counter | CSR (low) | CSR (high) | Reset | Behavior |
|---------|-----------|-------------|-------|----------|
| `mcycle` | `0xC00` | `0xC80` | Yes | Increments every `clk_i` cycle (free-running) |
| `time` | `0xC01` | `0xC81` | No | Increments every `clk_i` cycle (free-running, separate register) |
| `minstret` | `0xC02` | `0xC82` | Yes | Increments on instruction retire (`retire_i`) |

The `time` counter has no reset — it counts continuously from power-on as a free-running real-time clock, independent of the core's operating state.

##### Retire Signal

The `retire` pulse is generated in `if_stage.vhdl` as:

```vhdl
retire_o <= pcwr_en_i and not flush_reg;
```

`flush_reg` is the registered version of flush (captured in the pipeline register). Since `flush_reg` reflects the flush from the previous cycle (when the instruction was fetched), a current taken branch has `flush_reg = 0` and is counted. The speculatively fetched instruction after the branch has `flush_reg = 1` and is not counted.

This counts one instruction per valid pipeline advance:
- **Normal instructions**: counted on each pipeline cycle
- **Taken branches**: branch is counted, next instruction (flushed) is not
- **Traps**: trap-causing instruction (ecall/ebreak) is counted
- **Stalls**: no count when pipeline is stalled (pcwr_en = '0')
- **Bus errors**: faulted instruction is not counted (flush = '1')

---

#### 1.4 `core` — Core Pipeline

File: `rtl/core.vhdl`

Integrates IF stage, ID stage, and execution block into a two-stage pipeline.

```
                   core.vhdl (pipeline flow →)

    imem          ┌──────────┐  pc, next_pc    ┌──────────┐  control    ┌──────────┐
    ─────────────▶│ if_stage │  instr, flush   │ id_stage │  signals    │ ex_block │
    imrd_data_i   │          │────────────────▶│          │────────────▶│          │
                  │  pc_reg  │  imrd_fault     │ main_ctrl│  func3/7    │ alu_ctrl │──▶ alu_res
                  │  flush   │────────────────▶│ reg_file │  imm/jmp    │ alu      │──▶ dmld_data
                  │  retire  │◀────────────────│ csrs     │◀────────────│ dmls     │──▶ csrwr_data
                  └──────────┘  pcwr_en        └──────────┘  res/dmld   │ br_det   │──▶ taken
                       ▲                           ▲                    └──────────┘──▶ target
                       │                           │
                       └─── taken, target ──────────┘
```

##### Generics

| Generic | Default | Description |
|---------|---------|-------------|
| `RESET_ADDR` | `0x00000000` | Reset vector address |
| `CSRS_MHART_ID` | `0x00000000` | Machine hart ID |
| `REG_FILE_SIZE` | 32 | Register file size (16 or 32) |

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Gated clock (from clk_ctrl) |
| `reset_i` | in | 1 | Core reset (from wb_ctrl, 1 cycle after rst_i) |
| `ex_irq_i` | in | 1 | External interrupt |
| `sw_irq_i` | in | 1 | Software interrupt |
| `tm_irq_i` | in | 1 | Timer interrupt |
| `imrd_err_i` | in | 1 | Instruction memory bus error |
| `dmrd_err_i` | in | 1 | Data read bus error |
| `dmwr_err_i` | in | 1 | Data write bus error |
| `imrd_data_i` | in | XLEN | Instruction data from Wishbone |
| `dmrd_data_i` | in | XLEN | Data read data from Wishbone |
| `cycle_i` | in | 64 | Cycle counter value |
| `timer_i` | in | 64 | Timer value |
| `instret_i` | in | 64 | Instruction retired counter value |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |
| `retire_o` | out | 1 | Instruction retire pulse |
| `imrd_en_o` | out | 1 | Instruction fetch enable |
| `dmrd_en_o` | out | 1 | Data read enable |
| `dmwr_en_o` | out | 1 | Data write enable |
| `dmwr_be_o` | out | 4 | Data write byte enables |
| `imrd_addr_o` | out | XLEN | Instruction fetch address |
| `dmrw_addr_o` | out | XLEN | Data memory address |
| `dmwr_data_o` | out | XLEN | Data write data |

---

##### 1.4.1 `if_stage` — Instruction Fetch

File: `rtl/if_stage.vhdl`

Manages the program counter, instruction fetch request, and pipeline flush logic.

```
                         if_stage.vhdl (flow →)

              taken ───┐
              target ──┼─────┐
              pcwr_en ─┤     │   ┌──────────────────┐
              imrd_err ┤     ├───▶   pc_reg_proc    │──── pc_reg ──▶ imrd_addr_o
              reset_i ─┤     │   │  MUX(0:RESET,    │       │
                       │     │   │      1:target,   │       │
                       │     │   │      2:next_res, │       ├──────▶ next_res (PC+4)
                       │     │   │      3:hold)     │       │
                       │     │   └──────────────────┘       │
                       │     │                              ├──────▶ imrd_en_o
                       │     │   ┌──────────────────┐       │
                       └─────┼───▶   flush_val      │       │
                             │   │  taken or err    │───────┼──────▶ flush_reg ──▶ flush_o
                             │   │  or not pcwr_en  │       │
                             │   └──────────────────┘       │
                             │                              │
    imrd_data_i ─────────────┼──────────────────────────────┘
                             │   ┌──────────────────┐
                             └───▶  out_pipe_proc   │──── pc_o
                                 │  (pipeline reg)  │──── next_pc_o
                                 │                  │──── instr_o
                                 │                  │──── imrd_fault_o
                                 └──────────────────┘

    retire_o <= pcwr_en_i and not flush_reg
```

###### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Synchronous reset (active high) |
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

###### Operation

- `pc_reg` holds the current PC, updated every `clk_i` via `pc_reg_proc`
- `next_res` is PC+4 (combinatorial)
- `flush_val` is the combinatorial flush value (`taken_i or imrd_err_i or not pcwr_en_i`)
- `flush_reg` captures `flush_val` in the pipeline register — represents the validity of the current instruction
- Pipeline register (`out_pipe_proc`) captures `pc_o`, `next_pc_o`, `instr_o`, `flush_reg`, `imrd_fault_o` on the rising clock edge
- `imrd_en_o = pcwr_en_i` — fetch active whenever pipeline advances
- `imrd_addr_o = pc_reg` — fetch address always reflects the current PC
- `retire_o = pcwr_en_i and not flush_reg` — retire pulse, indicates valid instruction completed

###### PC Update Priority

1. **Reset**: `pc_reg <= RESET_ADDR`
2. **Branch taken** (`taken_i = '1'`): `pc_reg <= target_i`
3. **Pipeline advance** (`pcwr_en_i = '1'`): `pc_reg <= next_res`
4. **Stall** (no condition above): `pc_reg` holds value

---

##### 1.4.2 `id_stage` — Instruction Decode

File: `rtl/id_stage.vhdl`

Combines instruction decode, register file read, and CSR access. Passes decoded control signals to `ex_block`.

```
                         id_stage.vhdl (flow →)

    instr_i ──▶  field extraction
                 ├── func3(14:12) ──▶ func3_o
                 ├── func7(31:25) ──▶ func7_o
                 ├── rs1(19:15) ──▶ reg_file.rd_addr0
                 ├── rs2(24:20) ──▶ reg_file.rd_addr1
                 ├── rd(11:7)   ──▶ reg_file.wr_addr
                 └── csr(31:20) ──▶ csrs.rw_addr

    instr_i ──▶  main_ctrl ──▶ imm_o, jmp_o, br_en_o,
                 opcode decode   opd_src_sel, pass,
                 imm gen         ftype, op_en,
                                 dmls_mode, dmls_en

    ┌─────────── reg_file (32 × XLEN) ────────────┐
    │  rd_addr0 ◀── rs1       rd_data0 ──▶ rd_data0_o
    │  rd_addr1 ◀── rs2       rd_data1 ──▶ rd_data1_o
    │  wr_addr  ◀── rd                             │
    │  wr_data0 ◀── exec_res (from ex_block)      │
    │  wr_data1 ◀── dmld_data (from ex_block)     │
    │  wr_data2 ◀── next_pc (from if_stage)        │
    │  wr_data3 ◀── csrrd_data (from csrs)        │
    └──────────────────────────────────────────────┘

    csrs (CSR registers + trap logic)
    ├── wr_data ◀── csrwr_data_i (from ex_block)
    ├── rw_addr ◀── instr(31:20)
    ├── rd_data ──▶ csrrd_data_o
    ├── trap_taken_o, trap_target_o ──▶ ex_block
    ├── pcwr_en_o ────────────────────▶ if_stage (pipeline advance)
    ├── cop_adr_o, cop_dat_o, cop_we_o ──▶ external COP
    └── faults/irqs ──▶ exception decode ──▶ mepc, mcause, mtval
```

###### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Synchronous reset (active high) |
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
| `csrwr_data_i` | in | XLEN | CSR write data (from csrs_logic in ex_block) |
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

Sub-blocks instantiated within `id_stage`:

###### 1.4.2.1 `main_ctrl` — Main Control Decoder

File: `rtl/main_ctrl.vhdl`

Decodes the instruction opcode to generate control signals and the appropriate immediate value.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `imrd_malgn_i` | in | 1 | Instruction fetch misaligned |
| `dmld_malgn_i` | in | 1 | Data load misaligned |
| `dmld_fault_i` | in | 1 | Data load fault |
| `flush_i` | in | 1 | Pipeline flush |
| `instr_i` | in | XLEN | Instruction word |
| `instr_err_o` | out | 1 | Illegal instruction |
| `csrwr_en_o` | out | 1 | CSR write enable |
| `regwr_en_o` | out | 1 | Register file write enable |
| `regwr_sel_o` | out | 2 | Register write data select (0=ALU, 1=dmem, 2=next_pc, 3=CSR) |
| `dmls_mode_o` | out | 1 | Data memory mode (0=load, 1=store) |
| `dmls_en_o` | out | 1 | Data memory enable |
| `jmp_o` | out | 1 | Jump (JAL/JALR) |
| `br_en_o` | out | 1 | Branch enable |
| `opd0_src_sel_o` | out | 1 | Select PC vs reg0 as ALU operand 0 |
| `opd1_src_sel_o` | out | 1 | Select imm vs reg1 as ALU operand 1 |
| `opd0_pass_o` | out | 1 | Gate ALU operand 0 |
| `opd1_pass_o` | out | 1 | Gate ALU operand 1 |
| `ftype_o` | out | 1 | Instruction type for ALU control |
| `op_en_o` | out | 1 | ALU operation enable |
| `imm_o` | out | XLEN | Decoded immediate |

Immediate encoding per RISC-V specification: I-type, S-type, B-type, U-type, J-type, Z-type (shamt for CSR).

###### 1.4.2.2 `reg_file` — Register File

File: `rtl/reg_file.vhdl`

32 × XLEN register file with combinatorial read (dual-port) and synchronous write. Register x0 is hardwired to zero.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
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

###### 1.4.2.3 `csrs` — Control and Status Registers

File: `rtl/csrs.vhdl`

Implements machine-mode CSR registers and all trap/exception logic.

###### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Synchronous reset |
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

###### Operation

- **System calls**: `ecall`, `ebreak`, `mret`, `wfi` decoded from write enable + address
- **Interrupt pending**: `mip_meip`/`msip`/`mtip` directly wired from external IRQ inputs (level-sensitive)
- **Exception vector**: `exc_taken` combines all fault signals, ecall, ebreak, and interrupts
- **Trap taken**: `trap_taken_o <= exc_taken or mret` — redirects pipeline for both traps and MRET
- **mstatus**: MIE/MPIE updated on entry (save+disable) and MRET (restore)
- **mepc**: Saves PC on trap; `next_pc` on WFI (return after wakeup); writable via CSR
- **mcause**: Priority encoder for exception source; interrupt bit = `int_taken`
- **mtval**: Address for misaligned access faults; PC for ebreak; zero otherwise
- **Coprocessor window**: CSR addresses `0x7C0`–`0x7FF` forwarded to `cop_dat_o` with `cop_we_o` strobe

###### Machine-Mode CSRs

| Address | Register | Description |
|---------|----------|-------------|
| `0x300` | `mstatus` | Machine status (MIE, MPIE) |
| `0x301` | `misa` | ISA and extensions (RV32I) |
| `0x304` | `mie` | Interrupt enable (MEIE, MTIE, MSIE) |
| `0x305` | `mtvec` | Trap vector base address |
| `0x320` | `mcountinhibit` | Machine counter inhibit (WARL) — *not implemented* |
| `0x321` | `mhpmevent3` | Hardware performance event select (future) |
| `0x323`–`0x32F` | `mhpmevent4–31` | Hardware performance event select (future) |
| `0x340` | `mscratch` | Machine scratchpad |
| `0x341` | `mepc` | Exception program counter |
| `0x342` | `mcause` | Trap cause |
| `0x343` | `mtval` | Trap value |
| `0x344` | `mip` | Interrupt pending |

###### Read-Only Counters

| Address | Register | Description |
|---------|----------|-------------|
| `0xC00` | `cycle` | Cycle counter (low) |
| `0xC01` | `time` | Timer (low) |
| `0xC02` | `instret` | Instruction retired (low) |
| `0xC80` | `cycleh` | Cycle counter (high) |
| `0xC81` | `timeh` | Timer (high) |
| `0xC82` | `instreth` | Instruction retired (high) |

###### Counter Inhibit (`mcountinhibit`)

`mcountinhibit` (CSR `0x320`) is a WARL register that allows software to selectively pause performance counters:

| Bit | Field | Control |
|-----|-------|----------|
| 0 | CY | `mcycle` — 1 = inhibit increment |
| 2 | IR | `minstret` — 1 = inhibit increment |
| others | — | Hardwired to 0 (reserved) |

When a bit is `1`, the respective counter stops incrementing. Bit 1 (TM for `time`) is hardwired to 0 — `time` is an independent wall-clock timer and should not be inhibited.

**Note**: `mcountinhibit` is **not yet implemented** in Leaf. Future implementation requires:

1. Add `mcountinhibit_reg` in `csrs.vhdl` (bits 0 and 2 writable WARL, others hardwired to 0)
2. Add `mcountinhibit_o` ports in `csrs` → `id_stage` → `core`
3. Add `inhibit_i` port in `counters` — gating on increments (`inhibit_i(0)` locks `cycle`, `inhibit_i(2)` locks `instret`)
4. Connect `core.mcountinhibit_o` → `counters.inhibit_i` in `leaf.vhdl`

###### Timer Interrupt (`tm_irq`)

`tm_irq` is an external core input — Leaf does not generate it internally. The `time` counter (CSR `0xC01`/`0xC81`) increments every `clk_i` cycle and is readable by software, but there is no `mtimecmp` register to compare the timer and generate the IRQ automatically.

To use timer interrupts, external hardware must:
- Program a comparison value via memory-mapped register or coprocessor CSR
- Compare against `time` or its own counter
- Assert `tm_irq` when the condition is met

Implementation of `mtimecmp` per the RISC-V Privileged Spec (section 3.1.11) is a future improvement.

###### Custom Coprocessor Window

CSR addresses `0x7C0` to `0x7FF` are reserved for coprocessor attachment. Reads are forwarded to `cop_dat_i`, writes to `cop_dat_o` with `cop_we_o` strobe.

###### Exception and Trap Handling

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

Interrupt codes (mcause bit 31 = 1):

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

---

##### 1.4.3 `ex_block` — Execution Block

File: `rtl/ex_block.vhdl`

Contains all datapath execution logic: ALU, branch detection, load/store alignment, and CSR write data muxing.

```
                         ex_block.vhdl (flow →)

    Operand selection:
    reg0_i ─────┐                    gtd_opd0
    pc_i ───────┼──▶ MUX ──▶ AND ───┐    (gated)
    opd0_src_sel┘       opd0_pass ▲        │
                                       │    │
    reg1_i ─────┐                    │    │
    imm_i ──────┼──▶ MUX ──▶ AND ───┐    │    │
    opd1_src_sel┘       opd1_pass ▲    │    │
                                      │    │
    ALU:                              │    │
    ┌──────────┐    ┌──────────┐      │    │
    │ alu_ctrl │───▶│   alu    │◀─────┘    │
    │ op_en_i  │    │arith→comp│◀──────────┘
    │ ftype_i  │    │→logic→shf│──── alu_res
    │ func3/7  │    └──────────┘       │
    └──────────┘                       │
                                       │
    Branch:                            │
    ┌─────────────────────┐            │
    │ br_detector         │            │
    │ compare(reg0, reg1) │──── branch─┼──▶ taken_o
    │ mode = func3        │            │   (branch or jmp or trap)
    └─────────────────────┘            │
                                       │
    Load/Store:                        │
    ┌────────────────────────────┐     │
    │ dmls_block                 │     │
    │ alu_res ──▶ addr align     │◀────┘
    │ func3 ────▶ dtype decode   │──── dmld_data_o
    │ reg1 ─────▶ store data rot │──── dmwr_data_o
    │ dmrd_data  ▶ load align    │──── dm_byte_en_o
    │ dmrd/wr_err▶ fault detect  │──── dmrd/wr_en_o
    │            ▶ misalign det  │──── dmld/st_malgn/fault_o
    └────────────────────────────┘

    CSR write data:
    ┌──────────────────────┐
    │ csrs_logic           │
    │ mode = func3         │──── csrwr_data_o
    │ csrrd_data_i         │
    │ reg0_i / imm_i       │
    └──────────────────────┘

    Target: target_o <= trap_target when trap_taken else alu_res & 0
```

###### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
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
| `dmld_data_o` | out | XLEN | Data load result (aligned/sign-extended) |
| `csrwr_data_o` | out | XLEN | CSR write data (from csrs_logic) |
| `taken_o` | out | 1 | Branch/jump/trap taken |
| `target_o` | out | XLEN | Branch/jump/trap target address |
| `res_o` | out | XLEN | ALU result |

Sub-blocks instantiated within `ex_block`:

###### 1.4.3.1 `alu_ctrl` — ALU Operation Decoder

File: `rtl/alu_ctrl.vhdl`

Combinational decoder that maps instruction fields to ALU operation codes.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `op_en_i` | in | 1 | ALU operation enable (0 = idle/ADD) |
| `ftype_i` | in | 1 | Format type (0 = R-type, 1 = I-type) |
| `func3_i` | in | 3 | funct3 field |
| `func7_i` | in | 7 | funct7 field |
| `op_o` | out | 6 | ALU operation code (ALU_ADD, ALU_SUB, etc.) |

Decoding logic:
- `op_en_i = 0` → `ALU_ADD` (pipeline bubble)
- `func3 = 000`, `func7 = 0100000`, `ftype = 0` → `ALU_SUB`
- `func3 = 101`, `func7 = 0100000` → `ALU_SRA`
- Otherwise maps `func3` to the corresponding ALU operation (ADD, SLL, SLT, SLTU, XOR, SRL, OR, AND)

###### 1.4.3.2 `alu` — ALU Datapath

File: `rtl/alu.vhdl`

Combinational datapath organized as a bypass chain: `arith → comp → logic → shifter → res_o`.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `opd0_i` | in | XLEN | Operand 0 |
| `opd1_i` | in | XLEN | Operand 1 |
| `op_i` | in | 6 | ALU operation code from alu_ctrl |
| `res_o` | out | XLEN | Result |

Sub-blocks:
- **arith_unit**: ADD/SUB via `unsigned` addition with conditional 2's complement of `opd1_i`
- **comparator**: SLT/SLTU using MSB comparison with `arith_res(31)` for same-sign case
- **logic_unit**: XOR/OR/AND with bypass
- **shifter**: SLL/SRL/SRA via `numeric_std` shift functions (5-bit shift amount from `opd1_i(4:0)`)

When a sub-block's operation is not selected, it passes through the previous result.

###### 1.4.3.3 `br_detector` — Branch Detector

File: `rtl/br_detector.vhdl`

Combinational comparator for branch condition evaluation.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `reg0_i` | in | XLEN | Register value 0 (RS1) |
| `reg1_i` | in | XLEN | Register value 1 (RS2) |
| `mode_i` | in | 3 | Branch mode (funct3: EQ/NE/LT/GE/LTU/GEU) |
| `en_i` | in | 1 | Branch enable (from br_en_i) |
| `branch_o` | out | 1 | Branch condition met |

Output is gated: `branch_o <= branch_i and en_i`.

###### 1.4.3.4 `dmls_block` — Data Memory Load/Store

File: `rtl/dmls_block.vhdl`

Handles data memory load/store alignment and sign-extension for all RISC-V load/store data types (byte, halfword, word, signed/unsigned).

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `dmrd_err_i` | in | 1 | Data read bus error |
| `dmwr_err_i` | in | 1 | Data write bus error |
| `dmls_mode_i` | in | 1 | Mode (0=load, 1=store) |
| `dmls_en_i` | in | 1 | Enable |
| `dmls_dtype_i` | in | 3 | Data type (LSU_BYTE, LSU_BYTEU, LSU_HALF, LSU_HALFU, LSU_WORD) |
| `dmst_data_i` | in | XLEN | Store data from register |
| `dmls_addr_i` | in | XLEN | Load/store address |
| `dmrd_data_i` | in | XLEN | Data read data from Wishbone |
| `dmld_malgn_o` | out | 1 | Load address misaligned |
| `dmld_fault_o` | out | 1 | Load bus fault |
| `dmst_malgn_o` | out | 1 | Store address misaligned |
| `dmst_fault_o` | out | 1 | Store bus fault |
| `dmrd_en_o` | out | 1 | Data read request |
| `dmwr_en_o` | out | 1 | Data write request |
| `dmwr_data_o` | out | XLEN | Data write data (byte-rotated to align with byte enables) |
| `dmrw_addr_o` | out | XLEN | Data memory address (word-aligned) |
| `dm_byte_en_o` | out | 4 | Byte enables |
| `dmld_data_o` | out | XLEN | Load data (aligned and sign/zero-extended) |

###### 1.4.3.5 `csrs_logic` — CSR Write Data Mux

File: `rtl/csrs_logic.vhdl`

Combinational mux that computes the CSR write data based on the instruction's `funct3` field.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `csrwr_mode_i` | in | 3 | CSR write mode (funct3) |
| `csrrd_data_i` | in | XLEN | Current CSR read data |
| `regwr_data_i` | in | XLEN | Register file read data (RS1) |
| `immwr_data_i` | in | XLEN | Zero-extended immediate (uimm) |
| `csrwr_data_o` | out | XLEN | CSR write data |

Modes: `001`=CSRRW, `010`=CSRRS, `011`=CSRRC, `101`=CSRRWI, `110`=CSRRSI, `111`=CSRRCI. `others` (incl. `000`) = 0 (ECALL/EBREAK/MRET/WFI).


