# Microarchitecture Reference

## RTL File Map

| File | Entity | Role |
|------|--------|------|
| `rtl/leaf.vhdl` | `leaf` | Top: instantiates core + counters, Wishbone passthrough, COP |
| `rtl/core.vhdl` | `core` | Pipeline wiring: IF → ID → EX |
| `rtl/if_stage.vhdl` | `if_stage` | Fetch through two FIFOs, drives the instruction Wishbone port |
| `rtl/fifo_buffer.vhdl` | `fifo_buffer` | 3-deep valid/ready FIFO (address and instruction buffers) |
| `rtl/id_stage.vhdl` | `id_stage` | Decode + reg file + CSRs; pure structure, no process |
| `rtl/main_ctrl.vhdl` | `main_ctrl` | Decoder, immediate gen, ALU op decode, ID-time trap decode, park register, pipeline advance |
| `rtl/reg_file.vhdl` | `reg_file` | 32×XLEN register file (SIZE = 16 or 32), registered read ports |
| `rtl/csrs.vhdl` | `csrs` | Machine CSRs, interrupt arm, trap state commit, COP window |
| `rtl/ex_block.vhdl` | `ex_block` | ALU, branch, load/store, trap decision |
| `rtl/alu.vhdl` | `alu` | ALU datapath (bypass chain) + pc+4 incrementer |
| `rtl/br_detector.vhdl` | `br_detector` | Branch condition evaluation + the held redirect |
| `rtl/dmls_block.vhdl` | `dmls_block` | Data load/store FSM, drives the data Wishbone port |
| `rtl/trap_ctrl.vhdl` | `trap_ctrl` | EX-time trap decision: priority, mcause/mtval/mepc, redirect, write inhibits, retire gating, CSR write data mux |
| `rtl/counters.vhdl` | `counters` | mcycle, time, instret |
| `rtl/leaf_pkg.vhdl` | `leaf_pkg` | ISA constants, opcodes, ALU op encoding, component declarations |

There is no bus arbiter in the repo: each Wishbone port is driven directly by
its owning entity.

---

## Architecture Overview

Leaf implements a three-stage pipeline (IF → ID → EX) with separate Wishbone B4
master ports for instruction and data access.

```
leaf (top)
├── counters       mcycle + time free-running on clk_i; instret counts
│                  core.retire_o (trap_ctrl's gated pulse)
└── core           pipeline
    ├── if_stage     Fetch: 2 × fifo_buffer → inst Wishbone
    ├── id_stage     Decode + CSR/exception logic (no process of its own)
    │   ├── main_ctrl   Decoder, immediate gen, ALU op decode, ID-time trap
    │   │               decode, park register, pipeline advance
    │   ├── reg_file    32×XLEN register file
    │   └── csrs        Machine-mode CSRs, interrupt arm, trap commit, COP
    └── ex_block     Execute
        ├── alu          ALU datapath (arith → comp → logic → shifter)
        ├── br_detector  Branch condition evaluation + held redirect
        ├── dmls_block   Data load/store FSM → data Wishbone
        └── trap_ctrl    EX-time trap decision + CSR write data mux
```

### The pipeline boundaries

The IF/ID boundary is the pair of FIFOs in `if_stage`.

The ID/EX boundary is **distributed**. `id_stage` contains no process at all —
just three instantiations and the output assignments — and each submodule
registers its own share of the boundary:

- `main_ctrl` registers its decode outputs and the whole ID-time cause set
- `reg_file` registers its read ports (`re_i => pipe_en`)
- `csrs` registers the pc, the two redirect candidates and the three
  interrupt arms

There is no `pipeline_reg` process in `id_stage` and no pipeline-register
entity. `ex_block` is purely combinational apart from the DMLS FSM and
`br_detector`'s redirect hold.

### Handshakes

Stages advance together, not with independent per-stage stalls:

- `if_stage.ready_i` = `id_stage.ready_o` = `main_ctrl`'s `pipe_en`
  (`ready_i and not parked_reg`, so a parked WFI holds it low)
- `id_stage.ready_i` = `ex_block.ready_o` = `dmls_block.dmls_ready_o`

### Redirect

`ex_block.taken_o`/`target_o` loop back into `if_stage` (`taken_i`/`target_i`),
and the same `ex_block.taken_o` feeds `id_stage.flush_i` — one wire, fanned out
in `core` — squashing the in-flight instruction behind the redirect. A taken
branch costs 2 cycles.

The redirect is **held**, not a single-cycle pulse. `br_detector` latches
`taken`/`target` into `taken_reg`/`target_reg` and keeps them asserted until
`if_stage` drives `redirect_ack_o` — the cycle its next fetch address is
accepted by the bus (`if_adr_buf_ready and not inst_stall_i`). The same
`redirect_ack` gates `epoch_reg` and `adr_reg` in `if_stage`, so the hold, the
epoch toggle and the address update move together and the bus may defer
acceptance for any number of cycles.

### Stale fetches

`epoch_reg` toggles on every acknowledged redirect; the fetch's epoch travels
with its address through `if_adr_buf`, and a mismatch against the current
`epoch_reg` drives `stale_o`. That covers entries already in flight; the window
from the redirect resolving until the fetch accepts it is covered by `flush_i`.
`main_ctrl` builds

```vhdl
id_valid <= valid_i and not stale_i and not flush_i;
```

and suppresses decode when it is low, so neither a stale nor a flushed fetch
commits state.

### The trap unit, split at the boundary

`main_ctrl` (in `id_stage`) names and qualifies the cause at ID time —
ecall/ebreak/mret/wfi, the illegal instruction, the fetch fault — beside the
rest of the decode, registers that cause set onto ID/EX, and drives the
pipeline advance.

The interrupt is armed in `csrs`, also at ID. `csrs` ANDs each write-forwarded
`mie` bit with its `mip` bit into `exi/tmi/swi_pend`, ORs those into `int_pend`
(the WFI wake, which the spec makes unaffected by the global enable), adds
`mstatus.MIE` for `int_taken` (the decode squash it exports to `main_ctrl`), and
registers the three arms onto ID/EX. `trap_ctrl` ORs those three into the
interrupt bit `csrs` stores in `mcause`, so the bit and the code ranked beside
it come from the same three signals.

The `mie` and `mstatus` lines are **write-forwarded** inside `csrs`: the arm
reads them one slot ahead of the instruction whose CSR write is committing in
that same cycle, so without the bypass a `csrs mstatus, 8` followed by
`csrc mstatus, 8` would take the trap with MIE already clear.  `mip` needs no
bypass — it is not writable by software.

Arming at ID is also what keeps the interrupted instruction annullable: it is
squashed in the decode and never reaches EX, so a store never gets to raise
`cyc`/`stb` and then have its own pc stacked.

`trap_ctrl` (in `ex_block`) is purely combinational. It ranks the registered
ID-time set against the five faults raised beside it in
`br_detector`/`dmls_block`, names `mcause`, picks `mtval` and `mepc`, and gates
the register-file and CSR write enables with `exc_fault` (the OR of those five
faults). Those results cross back into `id_stage` for `csrs` and the register
file; the five faults never leave `ex_block`. The redirect is whole in
`trap_ctrl`: it decides `taken` and names `target` with the same `mret`, both
entering `br_detector` as `trap_taken_i`/`trap_target_i`. `csrs` exports the two
candidates it registers onto ID/EX (`mepc_reg_o`, `mtvec_reg_o`) rather than a
resolved target.

### Wishbone

Each port is driven directly by its owning entity, with no arbitration.
`if_stage` drives `inst_cyc_o`, `inst_stb_o`, `inst_adr_o` under `inst_stall_i`
backpressure; `dmls_block` drives `data_cyc_o`, `data_stb_o`, `data_adr_o`,
`data_sel_o`, `data_we_o`, `data_dat_o` under `data_stall_i`. Both share
`clk_i` — there is no clock gating.

### Counter timing

`counters` is a separate entity at the `leaf` level. `mcycle` and `time` are
free-running on `clk_i`; `instret` counts the `retire_i` pulse, which comes from
`core.retire_o` = `trap_ctrl.retire_o`:

```vhdl
retire_o <= retire_i and pipe_en_i and not exc_taken;
```

`retire_i` there is `main_ctrl`'s registered `id_valid`. The `pipe_en` term is
what keeps a parked WFI from counting the instruction ahead of it once per
parked cycle.

### Naming

Every internal signal in `core.vhdl` is named
`<driver entity>_<the driver's output port minus its _o>`: `if_stage_pc` ←
`if_stage.pc_o`, `id_stage_imm` ← `id_stage.imm_o`, `ex_block_taken` ←
`ex_block.taken_o`. The ID→EX bundle is `id_stage_*` even though it is consumed
in EX — the name identifies the driver, not the stage the value lives in. A
signal with no sub-component driver gets a plain descriptive name (`pc_full`,
`taken_int`); a gated copy of another signal takes the `gtd_` prefix
(`gtd_opd0`/`gtd_opd1` in `alu`).

Nothing drives an output port directly: sequential processes write `*_reg`
signals, instantiated components write their own `<entity>_<port>` signal, and
every `*_o <= ...` is a concurrent assignment in one block at the end of the
architecture.

---

## Module Interfaces

### 1. `leaf` — Top Level

File: `rtl/leaf.vhdl`

#### Generics

| Generic | Default | Description |
|---------|---------|-------------|
| `RESET_ADDR` | `0x00000000` | Reset vector address |
| `CSRS_MHART_ID` | `0x00000000` | Machine hart ID (mhartid CSR) |
| `REG_FILE_SIZE` | 32 | Register file size (16 or 32) |

The testbench overrides `RESET_ADDR` to `0x80000000` (`tbs/leaf_tb_pkg.vhdl`).

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `rst_i` | in | 1 | Reset (active high) |
| `ex_irq_i` | in | 1 | External interrupt (level-sensitive) |
| `sw_irq_i` | in | 1 | Software interrupt (level-sensitive) |
| `tm_irq_i` | in | 1 | Timer interrupt (level-sensitive) |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address (CSR addr offset) |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write strobe |
| `inst_cyc_o` | out | 1 | Instruction Wishbone cycle |
| `inst_stb_o` | out | 1 | Instruction Wishbone strobe |
| `inst_adr_o` | out | XLEN-1:2 | Instruction Wishbone address |
| `inst_dat_i` | in | XLEN | Instruction Wishbone read data |
| `inst_ack_i` | in | 1 | Instruction Wishbone acknowledge |
| `inst_err_i` | in | 1 | Instruction Wishbone error |
| `inst_stall_i` | in | 1 | Instruction Wishbone stall |
| `data_cyc_o` | out | 1 | Data Wishbone cycle |
| `data_stb_o` | out | 1 | Data Wishbone strobe |
| `data_we_o` | out | 1 | Data Wishbone write enable |
| `data_sel_o` | out | 4 | Data Wishbone byte selects |
| `data_adr_o` | out | XLEN-1:2 | Data Wishbone address |
| `data_dat_o` | out | XLEN | Data Wishbone write data |
| `data_dat_i` | in | XLEN | Data Wishbone read data |
| `data_ack_i` | in | 1 | Data Wishbone acknowledge |
| `data_err_i` | in | 1 | Data Wishbone error |
| `data_stall_i` | in | 1 | Data Wishbone stall |

#### Block Diagram

```
                        leaf.vhdl

    clk_i ──┬──▶ counters ──── cycle, timer, instret ──┐
    rst_i ──┤        ▲                                 │
            │        └──────────── retire ─────────┐   │
            │                                      │   ▼
            │      ┌──────────────────────────────────────┐
            └─────▶│                 core                 │
                   │                                      │
    inst_dat_i ───▶│  if_stage  ──▶ inst_cyc_o/stb_o/adr_o│
    inst_ack_i ───▶│                                      │
    inst_err_i ───▶│  id_stage  ──▶ cop_adr_o/dat_o/we_o  │
    inst_stall_i ─▶│                                      │
                   │  ex_block  ──▶ data_cyc_o/stb_o/we_o │
    cop_dat_i ────▶│            ──▶ data_sel_o/adr_o/dat_o│
    ex_irq_i ─────▶│                                      │
    sw_irq_i ─────▶│                                      │
    tm_irq_i ─────▶│                                      │
    data_dat_i ───▶│                                      │
    data_ack_i ───▶│                                      │
    data_err_i ───▶│                                      │
    data_stall_i ─▶│                                      │
                   └──────────────────────────────────────┘
```

The COP interface is a private passthrough between core and an external
coprocessor via CSR address window `0x7C0`–`0x7FF`. No Wishbone arbitration.

### 1.1 `counters` — Cycle, Time, Instret

File: `rtl/counters.vhdl`

Three 64-bit counters, each in its own process, all reset by `reset_i`:

| Counter | CSR (low) | CSR (high) | Behavior |
|---------|-----------|------------|----------|
| `mcycle` | `0xC00` | `0xC80` | Increments every `clk_i` cycle |
| `time` | `0xC01` | `0xC81` | Increments every `clk_i` cycle |
| `minstret` | `0xC02` | `0xC82` | Increments on `retire_i` |

`time` increments on `clk_i`, not on a divided RTC — the testbench's `wb_clint`
keeps its own prescaled `mtime` separately.

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `retire_i` | in | 1 | Instruction retire pulse (from `core`) |
| `cycle_o` | out | 64 | Cycle counter value |
| `timer_o` | out | 64 | Timer value |
| `instret_o` | out | 64 | Instructions retired |

### 1.2 `core` — Core Pipeline

File: `rtl/core.vhdl`

Wires `if_stage` → `id_stage` → `ex_block` and closes the two loops back from
EX: the redirect (`ex_block_taken`/`ex_block_target` into `if_stage.taken_i`/
`target_i` and `id_stage.flush_i`) and the commit bundle (`ex_block_exc_taken`,
`mcause_exc`, `mcause_int`, `mtval`, `mepc`, `regwr_en`, `csrwr_en` back into
`id_stage`).

#### Generics

| Generic | Default | Description |
|---------|---------|-------------|
| `RESET_ADDR` | `0x00000000` | Reset vector address |
| `CSRS_MHART_ID` | `0x00000000` | Machine hart ID |
| `REG_FILE_SIZE` | 32 | Register file size |

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `ex_irq_i` | in | 1 | External interrupt |
| `sw_irq_i` | in | 1 | Software interrupt |
| `tm_irq_i` | in | 1 | Timer interrupt |
| `cycle_i` | in | 64 | Cycle counter |
| `timer_i` | in | 64 | Timer value |
| `instret_i` | in | 64 | Instructions retired |
| `retire_o` | out | 1 | Retire pulse (from `ex_block`) |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |
| `inst_cyc_o` | out | 1 | Instruction Wishbone cycle |
| `inst_stb_o` | out | 1 | Instruction Wishbone strobe |
| `inst_adr_o` | out | XLEN-1:2 | Instruction Wishbone address |
| `inst_dat_i` | in | XLEN | Instruction Wishbone read data |
| `inst_ack_i` | in | 1 | Instruction Wishbone acknowledge |
| `inst_err_i` | in | 1 | Instruction Wishbone error |
| `inst_stall_i` | in | 1 | Instruction Wishbone stall |
| `data_cyc_o` | out | 1 | Data Wishbone cycle |
| `data_stb_o` | out | 1 | Data Wishbone strobe |
| `data_we_o` | out | 1 | Data Wishbone write enable |
| `data_sel_o` | out | 4 | Data Wishbone byte selects |
| `data_adr_o` | out | XLEN-1:2 | Data Wishbone address |
| `data_dat_o` | out | XLEN | Data Wishbone write data |
| `data_dat_i` | in | XLEN | Data Wishbone read data |
| `data_ack_i` | in | 1 | Data Wishbone acknowledge |
| `data_err_i` | in | 1 | Data Wishbone error |
| `data_stall_i` | in | 1 | Data Wishbone stall |

#### Pipeline Flow

```
                              core.vhdl

   inst_* ──▶ if_stage ── pc, inst, inst_err, valid, stale ──▶ id_stage
                  ▲                                               │
                  │                        ┌── ID/EX boundary ────┴────┐
                  │                        │ main_ctrl: func3,         │
                  │                        │   branch_op, alu_op,      │
                  │                        │   dmls_ctrl, imm,         │
                  │                        │   opd_src_sel, opd_pass,  │
                  │                        │   regwr_en, csrwr_en,     │
                  │                        │   instr_err, fetch_fault, │
                  │                        │   ecall, ebreak, mret,    │
                  │                        │   wfi, retire             │
                  │                        │ reg_file: rd_data0/1      │
                  │                        │ csrs: pc_full, csrrd_data,│
                  │                        │   mepc_reg, mtvec_reg,    │
                  │                        │   exi/tmi/swi_trap        │
                  │                        └────────────┬─────────────┘
                  │                                     ▼
                  │  taken_i/target_i ◀──────────── ex_block ──▶ data_*
                  │  (also id_stage.flush_i)            │     ──▶ res,
                  │  redirect_ack_o ───────────────────▶│         pc_next,
                  │                                     │         dmld_data
                  │  ready_i ◀── id_stage.ready_o ◀── ready_o
                  │
                  └── commit back into id_stage: exc_taken, mcause_exc,
                      mcause_int, mtval, mepc, regwr_en, csrwr_en
```

### 1.3 `if_stage` — Instruction Fetch

File: `rtl/if_stage.vhdl`

No fetch FSM: two 3-deep FIFOs (`fifo_buffer`) plus an address register and an
epoch bit.

- `if_adr_buf` holds the in-flight fetch addresses, each tagged with the epoch
  bit (`adr_data <= epoch_reg & adr_reg`)
- `if_inst_buf` holds the returned instructions, each tagged with the bus error
  bit (`inst_data <= inst_err_i & inst_dat_i`)

Flow control:

```vhdl
adr_valid  <= not inst_stall_i;                  -- push an address per bus slot
adr_ready  <= if_inst_buf_valid and ready_i;     -- pop when ID consumes a pair
inst_valid <= (inst_ack_i or inst_err_i) and if_adr_buf_valid;
```

Bus signalling is direct from the FIFO status: `inst_cyc_o` is the instruction
FIFO's `ready_o` (room for a reply), `inst_stb_o` the address FIFO's (room for
a request), `inst_adr_o` is `adr_reg`.

`redirect_ack <= if_adr_buf_ready and not inst_stall_i` is the single condition
that consumes a redirect, toggles `epoch_reg` and updates `adr_reg`; it is
exported as `redirect_ack_o` so `br_detector` can release its hold.

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Synchronous reset (active high) |
| `ready_i` | in | 1 | Pipeline advance enable (from `id_stage`) |
| `inst_ack_i` | in | 1 | Wishbone acknowledge |
| `inst_err_i` | in | 1 | Wishbone bus error |
| `inst_stall_i` | in | 1 | Wishbone stall |
| `taken_i` | in | 1 | Redirect taken (held, from `ex_block`) |
| `target_i` | in | XLEN | Redirect target address |
| `inst_dat_i` | in | XLEN | Instruction data from Wishbone |
| `inst_err_o` | out | 1 | Bus error flag of the head instruction |
| `inst_cyc_o` | out | 1 | Wishbone cycle |
| `inst_stb_o` | out | 1 | Wishbone strobe |
| `valid_o` | out | 1 | Head address and instruction both present |
| `stale_o` | out | 1 | Head fetch belongs to the previous epoch |
| `redirect_ack_o` | out | 1 | Redirect consumed this cycle |
| `inst_adr_o` | out | XLEN-1:2 | Fetch address |
| `pc_o` | out | XLEN-1:2 | PC of the head instruction |
| `inst_o` | out | XLEN | Head instruction |

#### PC Update

`adr_reg` and `epoch_reg` only move on `redirect_ack`:

| Condition | `adr_reg` next | `epoch_reg` next |
|-----------|----------------|------------------|
| Reset | `RESET_ADDR(XLEN-1 downto 2)` | `'0'` |
| `redirect_ack` and `taken_i` | `target_i(XLEN-1 downto 2)` | toggles |
| `redirect_ack` and not `taken_i` | `adr_reg + 1` | hold |
| Otherwise | hold | hold |

#### 1.3.1 `fifo_buffer` — Valid/Ready FIFO

File: `rtl/fifo_buffer.vhdl`

`FIFO_DEPTH = 3`, `ADDR_WIDTH = 2`, `DATA_WIDTH` generic. The storage array has
its own process so it infers a RAM; `empty_reg`/`full_reg` are kept by the
pointers alone, with no fill counter (a simultaneous push and pop leaves the
distance unchanged). `valid_o = not empty_reg`, `ready_o = not full_reg`.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `valid_i` | in | 1 | Write data valid |
| `ready_i` | in | 1 | Reader consumes the head |
| `data_i` | in | DATA_WIDTH | Write data |
| `valid_o` | out | 1 | Not empty |
| `ready_o` | out | 1 | Not full |
| `data_o` | out | DATA_WIDTH | Head data |

### 1.4 `id_stage` — Instruction Decode

File: `rtl/id_stage.vhdl`

Structure only: three instantiations and the output assignments. Every output
except `ready_o` and the COP lines comes out of a submodule's own ID/EX
register.

```
                          id_stage.vhdl

    instr_i ──┬──▶ main_ctrl ── func3, branch_op, alu_op, dmls_ctrl, imm,
              │                 opd_src_sel, opd_pass, regwr_en/sel/addr,
              │                 csrwr_en, csrs_addr
              │              ── instr_err, fetch_fault, ecall, ebreak,
              │                 mret, wfi, retire
              │              ── pipe_en (= ready_o), id_valid
              │
              ├──▶ reg_file ── rd_data0_o, rd_data1_o (registered on pipe_en)
              │                wr_data mux: ALU res / dmld / pc+4 / csrrd
              │
              └──▶ csrs ────── csrrd_data, pc (full), mepc_reg, mtvec_reg,
                               exi/tmi/swi_trap, int_pend, int_taken,
                               cop_adr_o, cop_dat_o, cop_we_o
```

`main_ctrl.id_valid_o` qualifies the interrupt arm inside `csrs`;
`csrs.int_pend_o`/`int_taken_o` come back into `main_ctrl` as the WFI wake and
the decode squash.

#### Generics

| Generic | Default | Description |
|---------|---------|-------------|
| `REG_FILE_SIZE` | 32 | Register file size |
| `CSRS_MHART_ID` | `0x00000000` | Machine hart ID |

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `ex_irq_i` | in | 1 | External interrupt |
| `sw_irq_i` | in | 1 | Software interrupt |
| `tm_irq_i` | in | 1 | Timer interrupt |
| `cycle_i` | in | 64 | Cycle counter |
| `timer_i` | in | 64 | Timer |
| `instret_i` | in | 64 | Instructions retired |
| `pc_i` | in | XLEN-1:2 | PC of the fetched instruction |
| `instr_i` | in | XLEN | Instruction word |
| `fault_i` | in | 1 | Instruction fetch bus fault |
| `valid_i` | in | 1 | Instruction valid |
| `stale_i` | in | 1 | Fetch belongs to the previous epoch |
| `exc_taken_i` | in | 1 | Trap commits (from `ex_block`) |
| `mcause_exc_i` | in | 5 | mcause code field |
| `mcause_int_i` | in | 1 | mcause interrupt bit |
| `mtval_i` | in | XLEN | mtval to stack |
| `mepc_i` | in | XLEN-1:2 | PC to stack |
| `regwr_en_i` | in | 1 | Register write enable (fault-gated, from EX) |
| `csrwr_en_i` | in | 1 | CSR write enable (fault-gated, from EX) |
| `exec_res_i` | in | XLEN | ALU result (write-back) |
| `pc_next_i` | in | XLEN | pc+4 (JAL/JALR link) |
| `dmld_data_i` | in | XLEN | Data load result |
| `csrwr_data_i` | in | XLEN | CSR write data (from `trap_ctrl`) |
| `flush_i` | in | 1 | Squash the in-flight slot (= `ex_block.taken_o`) |
| `ready_i` | in | 1 | EX stage ready |
| `ready_o` | out | 1 | Pipeline advance (`main_ctrl.pipe_en`) |
| `func3_o` | out | 3 | funct3 field |
| `branch_op_o` | out | 2 | Branch operation (BR_NONE/BR_BRANCH/BR_JUMP) |
| `alu_op_o` | out | 5 | ALU operation code |
| `dmls_ctrl_o` | out | 2 | Data memory control (DMLS_IDLE/LOAD/STORE) |
| `mepc_reg_o` | out | XLEN-1:2 | mepc read back (mret redirect candidate) |
| `mtvec_reg_o` | out | XLEN-1:2 | mtvec base (trap redirect candidate) |
| `instr_err_o` | out | 1 | Illegal instruction |
| `fetch_fault_o` | out | 1 | Instruction access fault |
| `ecall_o` | out | 1 | ECALL |
| `ebreak_o` | out | 1 | EBREAK |
| `mret_o` | out | 1 | MRET |
| `wfi_o` | out | 1 | WFI |
| `exi_trap_o` | out | 1 | External interrupt armed |
| `tmi_trap_o` | out | 1 | Timer interrupt armed |
| `swi_trap_o` | out | 1 | Software interrupt armed |
| `regwr_en_o` | out | 1 | Register write enable (ungated) |
| `csrwr_en_o` | out | 1 | CSR write enable (ungated) |
| `rd_data0_o` | out | XLEN | Register read port 0 |
| `rd_data1_o` | out | XLEN | Register read port 1 |
| `csrrd_data_o` | out | XLEN | CSR read data |
| `imm_o` | out | XLEN | Decoded immediate |
| `opd_src_sel_o` | out | 2 | ALU operand source select (bit 0 → opd0) |
| `opd_pass_o` | out | 2 | ALU operand gates (bit 0 → opd0) |
| `pc_full_o` | out | XLEN | Full PC, EX-aligned |
| `retire_o` | out | 1 | Registered `id_valid` (ungated retire) |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |

#### 1.4.1 `main_ctrl` — Decoder

File: `rtl/main_ctrl.vhdl`

Decodes the opcode into every control signal, the immediate and the ALU op, and
owns the ID-time half of the trap unit plus the pipeline advance.

##### Decoding

- **Opcode-based**: R-type, I-type, loads, stores, branches, JAL/JALR, LUI,
  AUIPC, SYSTEM (ECALL/EBREAK/MRET/WFI/CSR), FENCE; anything else raises
  `instr_err`
- **Decode suppression**: the whole control set falls to its idle encoding when
  `id_valid = '0'`, when `imrd_fault_i = '1'` (garbage `instr_i`) or when
  `int_taken_i = '1'` (the interrupt squashes the slot it arms against)
- **Immediate types**: I, S, B, U, J, Z (CSR uimm)
- **CSR write suppression**: `csrrs`/`csrrc` and their immediate forms do not
  write when rs1/uimm is zero — the write is a no-op on the value but hits the
  read bypass in `csrs` and would freeze the next read of a live counter.
  `funct3(1 downto 0) = "01"` is the `csrrw` pair, which always writes.

##### The four SYSTEM instructions

`sys_ctrl` marks `funct3 = 000`; the four are then equality comparisons on
funct12 (`0x000` ecall, `0x001` ebreak, `0x302` mret, `0x105` wfi) rather than a
case over a sparse field.

The fetch fault is `imrd_fault_i and id_valid` — only `id_valid` annuls it, not
a pending interrupt, or a fetch fault taken in an interrupt's shadow would be
silently dropped.

##### The park

```vhdl
pipe_en <= ready_i and not parked_reg;
```

`parked_reg` sets on the registered `wfi_reg` and clears on `int_pend_i` — the
wake ignores `mstatus.MIE` per the spec, which is why `csrs` exports both
`int_pend` and `int_taken`. `ready_i` survives the park: dropping it there would
advance the ID/EX register over an instruction still occupying EX.

##### ALU Op Decode

Decoded here, not in a separate entity, into the 5-bit field word `alu` reads
directly (see §3):

- `op_en = '0'` → `ALU_ADD` (bubble / non-ALU instruction)
- `funct3 = 000`, `funct7 = 0100000`, R-type → `ALU_SUB`
- `funct3 = 101`, `funct7 = 0100000` → `ALU_SRA`
- otherwise `funct3` maps to ADD, SLL, SLT, SLTU, XOR, SRL, OR, AND

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `imrd_fault_i` | in | 1 | Instruction fetch bus fault |
| `instr_i` | in | XLEN | Instruction word |
| `valid_i` | in | 1 | Fetch valid |
| `stale_i` | in | 1 | Fetch from the previous epoch |
| `flush_i` | in | 1 | Redirect squash |
| `int_pend_i` | in | 1 | Interrupt pending (WFI wake, no MIE) |
| `int_taken_i` | in | 1 | Interrupt taken (decode squash, with MIE) |
| `exc_taken_i` | in | 1 | Trap commits |
| `ready_i` | in | 1 | EX ready |
| `pipe_en_o` | out | 1 | Pipeline advance |
| `id_valid_o` | out | 1 | ID slot holds a real instruction |
| `instr_err_o` | out | 1 | Illegal instruction (registered) |
| `fetch_fault_o` | out | 1 | Instruction access fault (registered) |
| `ecall_o` / `ebreak_o` / `mret_o` / `wfi_o` | out | 1 | SYSTEM causes (registered) |
| `retire_o` | out | 1 | Registered `id_valid` |
| `func3_o` | out | 3 | funct3 |
| `branch_op_o` | out | 2 | Branch operation |
| `alu_op_o` | out | 5 | ALU operation code |
| `dmls_ctrl_o` | out | 2 | Data memory control |
| `imm_o` | out | XLEN | Immediate |
| `opd_src_sel_o` | out | 2 | ALU operand source select |
| `opd_pass_o` | out | 2 | ALU operand gates |
| `regwr_en_o` | out | 1 | Register write enable |
| `regwr_sel_o` | out | 2 | Register write-back source select |
| `regwr_addr_o` | out | 5 | Register write address (rd) |
| `csrwr_en_o` | out | 1 | CSR write enable |
| `csrs_addr_o` | out | 12 | CSR write address |

#### 1.4.2 `reg_file` — Register File

File: `rtl/reg_file.vhdl`

32 × XLEN, x0 hardwired to zero. `SIZE = 16` selects the embedded variant
(4-bit addressing), `SIZE = 32` the full one; the choice is a `generate`, not a
runtime mux.

The write data mux is 4:1 on `wr_sel_i`:

| `wr_sel_i` | Source |
|------------|--------|
| `00` | `wr_data0_i` — ALU result |
| `01` | `wr_data1_i` — data load result |
| `10` | `wr_data2_i` — pc+4 (JAL/JALR link) |
| `11` | `wr_data3_i` — CSR read data |

Reads are combinational with write forwarding (write data bypasses to a read
port whose address matches and is not x0), then **registered** onto ID/EX by
`re_i` — which `id_stage` ties to `main_ctrl`'s `pipe_en`. This registration is
`reg_file`'s share of the distributed pipeline boundary.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `we_i` | in | 1 | Write enable (fault-gated, from EX) |
| `wr_sel_i` | in | 2 | Write data source select |
| `wr_addr_i` | in | 5 | Write address |
| `wr_data0_i` … `wr_data3_i` | in | XLEN | Write data sources |
| `rd_addr0_i` | in | 5 | Read address 0 (rs1) |
| `rd_addr1_i` | in | 5 | Read address 1 (rs2) |
| `re_i` | in | 1 | Read register enable (= `pipe_en`) |
| `rd_data0_o` | out | XLEN | Read port 0 (registered) |
| `rd_data1_o` | out | XLEN | Read port 1 (registered) |

#### 1.4.3 `csrs` — Control and Status Registers

File: `rtl/csrs.vhdl`

The machine-mode CSRs, the interrupt arm, and the trap state commit. Each
register has its own write process; `exc_taken_i` takes priority over a software
write in `mstatus`, `mepc`, `mcause` and `mtval`.

`csrs` decides no trap. The cause code (`mcause_exc_i`), the interrupt bit
(`mcause_int_i`), `mtval_i` and `mepc_i` all arrive from `trap_ctrl` and are
only registered here. Likewise the redirect: `mepc_reg_o` and `mtvec_reg_o`
leave as two candidates, and `trap_ctrl` picks between them with the same `mret`
it drives `taken_o` from. `mret` stacks no cause; it only redirects and unstacks
`mstatus`.

##### Machine-Mode CSRs

| Address | Register | Description |
|---------|----------|-------------|
| `0x300` | `mstatus` | MIE (bit 3), MPIE (bit 7); MPP reads `11` |
| `0x301` | `misa` | RV32I, hardwired (MXL = 1, bit 8 = I) |
| `0x304` | `mie` | MEIE (11), MTIE (7), MSIE (3) |
| `0x305` | `mtvec` | Trap vector base address |
| `0x340` | `mscratch` | Machine scratchpad |
| `0x341` | `mepc` | Exception program counter |
| `0x342` | `mcause` | Trap cause (bit 31 interrupt, bits 4:0 code) |
| `0x343` | `mtval` | Trap value |
| `0x344` | `mip` | MEIP (11), MTIP (7), MSIP (3) — read-only, sampled from the irq pins |
| `0xF14` | `mhartid` | Hart ID (read-only, from the `MHART_ID` generic) |

##### Read-Only Counters

| Address | Register | Address | Register |
|---------|----------|---------|----------|
| `0xC00` | `cycle` | `0xC80` | `cycleh` |
| `0xC01` | `time` | `0xC81` | `timeh` |
| `0xC02` | `instret` | `0xC82` | `instreth` |

##### Read bypass and write forwarding

`rd_data_bypassed` returns the write data when a write to the same address
commits in the same cycle. Separately, `mie`, `mstatus.MIE`, `mepc` and
`mtvec_base` each have a write-forwarded copy, so the values registered onto
ID/EX — and the interrupt arm built from them — see a CSR write in the cycle it
commits rather than one cycle later. `mip` has none: software cannot write it.

##### The interrupt arm

```vhdl
exi_pend <= mie_meie_bypassed and mip_meip;   -- likewise tmi, swi
int_pend <= exi_pend or tmi_pend or swi_pend; -- wfi wake, no mstatus.MIE
irq_arm  <= mstatus_mie_bypassed and not exc_taken_i and id_valid_i;
exi_trap <= exi_pend and irq_arm;             -- registered onto ID/EX
int_taken_o <= int_pend and mstatus_mie_bypassed;
```

- `not exc_taken_i` is the one-shot: `mstatus.MIE` only clears at the edge the
  trap commits, so without it the same interrupt would commit twice
  (`verif/tests/wfi_timer`)
- `id_valid_i` keeps the arm off a stale or flushed slot, whose registered pc
  would stack a wrong-path `mepc` (`verif/tests/int_mret_shadow`)
- nothing is ranked or ORed here — `trap_ctrl` does both, so the code and
  mcause's interrupt bit come from the same three signals

##### Coprocessor Window

CSR addresses `0x7C0`–`0x7FF` (`rw_addr_i(11 downto 6) = "011111"`) read from
`cop_dat_i` and write through `cop_dat_o` with `cop_we_o`. `cop_adr_o` carries
the write address's low 6 bits while a write commits, the read address's
otherwise.

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `ex_irq_i` / `sw_irq_i` / `tm_irq_i` | in | 1 | Interrupt pins (sampled into `mip`) |
| `mcause_exc_i` | in | 5 | mcause code field (from `trap_ctrl`) |
| `mcause_int_i` | in | 1 | mcause interrupt bit (from `trap_ctrl`) |
| `mtval_i` | in | XLEN | mtval to stack |
| `mepc_i` | in | XLEN-1:2 | PC to stack |
| `mret_i` | in | 1 | MRET (unstacks `mstatus`) |
| `exc_taken_i` | in | 1 | Trap commits |
| `id_valid_i` | in | 1 | ID slot holds a real instruction |
| `wr_en_i` | in | 1 | CSR write enable (fault-gated) |
| `wr_addr_i` | in | 12 | CSR write address (registered, EX-aligned) |
| `rw_addr_i` | in | 12 | CSR read address (live, from `instr_i`) |
| `wr_data_i` | in | XLEN | CSR write data |
| `pipe_en_i` | in | 1 | ID/EX register enable |
| `pc_i` | in | XLEN-1:2 | PC of the ID slot |
| `cycle_i` / `timer_i` / `instret_i` | in | 64 | Counter values |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |
| `int_pend_o` | out | 1 | Interrupt pending (WFI wake) |
| `int_taken_o` | out | 1 | Interrupt taken (decode squash) |
| `exi_trap_o` / `tmi_trap_o` / `swi_trap_o` | out | 1 | Armed interrupt, registered onto ID/EX |
| `mepc_reg_o` | out | XLEN-1:2 | mepc read back, EX-aligned |
| `mtvec_reg_o` | out | XLEN-1:2 | mtvec base, EX-aligned |
| `csrrd_data_o` | out | XLEN | CSR read data, EX-aligned |
| `pc_o` | out | XLEN | Full PC, EX-aligned |

### 1.5 `ex_block` — Execution Block

File: `rtl/ex_block.vhdl`

Structure plus the two pieces of state in EX: `dmls_block`'s FSM and
`br_detector`'s redirect hold. Everything else — the ALU, the trap decision, the
CSR write data mux — is combinational.

```
                            ex_block.vhdl

    reg0_i ─┐                                    ┌── res_o (ALU result)
    pc_i ───┼─▶ MUX ─▶ AND ─┐                    ├── arith_res (internal)
            │   src_sel(0)  │                    └── pc_next_o (pc+4)
            │   pass(0)     ├──▶ alu ────────────┘
    reg1_i ─┐               │
    imm_i ──┼─▶ MUX ─▶ AND ─┘
            │   src_sel(1)
                pass(1)

    br_detector ◀── reg0, reg1, func3, branch_op, arith_res,
                    trap_taken/trap_target, redirect_ack_i
        └──▶ taken_o, target_o, imrd_malgn

    dmls_block ◀── arith_res, reg1, func3, dmls_ctrl, data_*
        ├──▶ data_cyc_o/stb_o/we_o/sel_o/adr_o/dat_o
        ├──▶ dmld_data_o, dmls_ready (= ready_o)
        └──▶ dmld/dmst malgn + fault

    trap_ctrl ◀── the ID-time cause set, the five EX faults,
                  mepc_reg/mtvec_reg, func3/csrrd/reg0/imm
        ├──▶ trap_taken/trap_target → br_detector
        ├──▶ exc_taken, mcause_exc, mcause_int, mtval, mepc
        ├──▶ regwr_en_o, csrwr_en_o, csrwr_data_o
        └──▶ retire_o
```

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `mepc_reg_i` | in | XLEN-1:2 | mret redirect candidate |
| `mtvec_reg_i` | in | XLEN-1:2 | Trap redirect candidate |
| `func3_i` | in | 3 | funct3 (branch mode, load/store type, CSR mode) |
| `reg0_i` | in | XLEN | Register read port 0 |
| `reg1_i` | in | XLEN | Register read port 1 |
| `pc_i` | in | XLEN | Full PC |
| `immwr_data_i` | in | XLEN | Immediate |
| `csrrd_data_i` | in | XLEN | CSR read data |
| `opd_src_sel_i` | in | 2 | ALU operand source select |
| `opd_pass_i` | in | 2 | ALU operand gates |
| `branch_op_i` | in | 2 | Branch operation (bit 0 = enable, bit 1 = jump) |
| `alu_op_i` | in | 5 | ALU operation code |
| `dmls_ctrl_i` | in | 2 | Data memory control |
| `redirect_ack_i` | in | 1 | Fetch consumed the redirect (releases the hold) |
| `instr_err_i` | in | 1 | Illegal instruction |
| `fetch_fault_i` | in | 1 | Instruction access fault |
| `ecall_i` / `ebreak_i` / `mret_i` / `wfi_i` | in | 1 | SYSTEM causes |
| `retire_i` | in | 1 | Ungated retire bit |
| `pipe_en_i` | in | 1 | ID/EX advance (gates the retire pulse) |
| `exi_trap_i` / `tmi_trap_i` / `swi_trap_i` | in | 1 | Armed interrupts |
| `regwr_en_i` | in | 1 | Register write enable (ungated) |
| `csrwr_en_i` | in | 1 | CSR write enable (ungated) |
| `data_dat_i` | in | XLEN | Data Wishbone read data |
| `data_ack_i` | in | 1 | Data Wishbone acknowledge |
| `data_err_i` | in | 1 | Data Wishbone error |
| `data_stall_i` | in | 1 | Data Wishbone stall |
| `ready_o` | out | 1 | EX ready (= `dmls_ready`) |
| `taken_o` | out | 1 | Redirect taken (held) |
| `target_o` | out | XLEN | Redirect target |
| `res_o` | out | XLEN | ALU result |
| `pc_next_o` | out | XLEN | pc+4 |
| `csrwr_data_o` | out | XLEN | CSR write data |
| `dmld_data_o` | out | XLEN | Load result |
| `exc_taken_o` | out | 1 | Trap commits |
| `mcause_int_o` | out | 1 | mcause interrupt bit |
| `mcause_exc_o` | out | 5 | mcause code field |
| `mtval_o` | out | XLEN | mtval |
| `mepc_o` | out | XLEN-1:2 | PC to stack |
| `regwr_en_o` | out | 1 | Register write enable (fault-gated) |
| `csrwr_en_o` | out | 1 | CSR write enable (fault-gated) |
| `retire_o` | out | 1 | Retire pulse |
| `data_cyc_o` | out | 1 | Data Wishbone cycle |
| `data_stb_o` | out | 1 | Data Wishbone strobe |
| `data_we_o` | out | 1 | Data Wishbone write enable |
| `data_sel_o` | out | 4 | Data Wishbone byte selects |
| `data_adr_o` | out | XLEN-1:2 | Data Wishbone address |
| `data_dat_o` | out | XLEN | Data Wishbone write data |

#### 1.5.1 `alu` — ALU Datapath

File: `rtl/alu.vhdl`

Combinational, organized as a bypass chain: `arith → comp → logic → shifter`,
with a 4:1 result mux on `op_i(4 downto 3)`.

##### Sub-blocks

- **arith_unit**: ADD/SUB as `opd0 + (opd1 xor sign) + cin`, the ones'
  complement plus a carry-in of one
- **comparator**: SLT/SLTU. Equal signs cannot overflow the subtraction, so
  `arith_res(31)` answers; differing signs make `opd0`'s sign the signed answer
  and its inverse the unsigned one
- **logic_unit**: XOR/OR/AND
- **shifter**: one right shifter serves all three. SLL reverses both the operand
  and the result, SRA fills from the sign bit through an extra top bit
  (`shifter_fill & shifter_src`), SRL fills zero. A `shift_left` beside it would
  cost a second barrel.

Operand selection happens here too: `opd0 = pc_i` when `opd_src_sel_i(0)` else
`reg0_i`; `opd1 = immwr_data_i` when `opd_src_sel_i(1)` else `reg1_i`; each is
then ANDed with its `opd_pass_i` bit (`gtd_opd0`/`gtd_opd1`).

`pc_next_o` is pc+4 from its own narrow incrementer on the word address — for
JAL/JALR the one adder is busy computing the jump target, and the same value is
the `mepc` a WFI trap stacks.

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `pc_i` | in | XLEN | PC (AUIPC/JAL/branches) |
| `reg0_i` | in | XLEN | Register value 0 |
| `reg1_i` | in | XLEN | Register value 1 |
| `immwr_data_i` | in | XLEN | Immediate |
| `opd_src_sel_i` | in | 2 | Operand source select (bit 0 → opd0) |
| `opd_pass_i` | in | 2 | Operand gates (bit 0 → opd0) |
| `op_i` | in | 5 | ALU operation code (see §3) |
| `res_o` | out | XLEN | Final result |
| `arith_res_o` | out | XLEN | Arithmetic result (branch/jump target, load/store address) |
| `pc_next_o` | out | XLEN | pc+4 |

#### 1.5.2 `br_detector` — Branch Detector

File: `rtl/br_detector.vhdl`

Branch condition evaluation, the misaligned-fetch check for taken redirects, and
the redirect hold.

```vhdl
taken_int  <= (branch and en_i) or jmp_i or trap_taken_i;
target_int <= trap_target_i when trap_taken_i = '1'
              else arith_res_i(XLEN-1 downto 1) & b"0";  -- JALR clears bit 0
imrd_malgn_o <= arith_res_i(1) and ((branch and en_i) or jmp_i);
```

`taken_reg`/`target_reg` hold the redirect until `redirect_ack_i`. Clearing on
the acknowledge takes priority over capturing: a redirect resolving in that same
cycle still drives `taken_o` combinationally through `taken_int`, so nothing is
lost.

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `reg0_i` | in | XLEN | rs1 value |
| `reg1_i` | in | XLEN | rs2 value |
| `mode_i` | in | 3 | Branch mode (funct3) |
| `en_i` | in | 1 | Branch enable (`branch_op(0)`) |
| `jmp_i` | in | 1 | Unconditional jump (`branch_op(1)`) |
| `arith_res_i` | in | XLEN | ALU arithmetic result (target) |
| `trap_taken_i` | in | 1 | Trap redirect (overrides the branch) |
| `trap_target_i` | in | XLEN | Trap redirect target |
| `redirect_ack_i` | in | 1 | Fetch consumed the redirect |
| `taken_o` | out | 1 | Redirect taken (held) |
| `target_o` | out | XLEN | Redirect target |
| `imrd_malgn_o` | out | 1 | Instruction address misaligned |

#### 1.5.3 `dmls_block` — Data Load/Store

File: `rtl/dmls_block.vhdl`

Load/store alignment, byte enables and sign-extension, plus the data Wishbone
FSM.

##### FSM States

| State | Description |
|-------|-------------|
| `IDLE` | Waits for `dmrd_en`/`dmwr_en`; latches address, data and selects on entry to REQUEST |
| `REQUEST` | Cycle + strobe asserted. Acknowledge → DONE; otherwise, once not stalled → WACCESS |
| `WACCESS` | Cycle held, strobe deasserted. Acknowledge or error → DONE |
| `DONE` | Single cycle, clears the request registers, returns to IDLE |

`dmls_ready_o` is `'1'` in DONE and in IDLE with no request pending — that is
`ex_block.ready_o`, so a load or store stalls the whole pipeline for the length
of the access.

##### Data Types

All RV32I load/store types: LB, LBU, LH, LHU, LW, SB, SH, SW. Misalignment is
per type — byte accesses never misalign, halfword requires `addr(0) = 0`, word
requires `addr(1:0) = 00` — and a misaligned access keeps `dmrd_en`/`dmwr_en`
low, so the bus cycle never starts. Store data is rotated to the selected lane;
loads are extracted from the lane and sign- or zero-extended. Bus faults are
`data_err_i` qualified by the direction (`dmld_fault_o`, `dmst_fault_o`).

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `dmls_ctrl_i` | in | 2 | Control (IDLE/LOAD/STORE) |
| `dmls_dtype_i` | in | 3 | Data type (funct3) |
| `dmst_data_i` | in | XLEN | Store data (rs2) |
| `arith_res_i` | in | XLEN | Address from the ALU |
| `data_dat_i` | in | XLEN | Wishbone read data |
| `data_ack_i` | in | 1 | Wishbone acknowledge |
| `data_err_i` | in | 1 | Wishbone error |
| `data_stall_i` | in | 1 | Wishbone stall |
| `dmls_ready_o` | out | 1 | Ready (pipeline gate) |
| `dmld_data_o` | out | XLEN | Load result (aligned + extended) |
| `dmld_malgn_o` | out | 1 | Load address misaligned |
| `dmld_fault_o` | out | 1 | Load bus fault |
| `dmst_malgn_o` | out | 1 | Store address misaligned |
| `dmst_fault_o` | out | 1 | Store bus fault |
| `data_cyc_o` | out | 1 | Wishbone cycle |
| `data_stb_o` | out | 1 | Wishbone strobe |
| `data_we_o` | out | 1 | Write enable |
| `data_sel_o` | out | 4 | Byte enables |
| `data_adr_o` | out | XLEN-1:2 | Wishbone address |
| `data_dat_o` | out | XLEN | Wishbone write data |

#### 1.5.4 `trap_ctrl` — Trap Decision

File: `rtl/trap_ctrl.vhdl`

Purely combinational. Ranks the registered ID-time cause set against the five
EX-time faults, names what the trap stacks, decides the redirect, gates the
write enables and the retire pulse, and muxes the CSR write data.

```vhdl
exc_fault <= imrd_malgn_i or dmld_malgn_i or dmld_fault_i or
             dmst_malgn_i or dmst_fault_i;
int_trap  <= exi_trap_i or tmi_trap_i or swi_trap_i;
exc_taken <= instr_err_i or fetch_fault_i or ecall_i or ebreak_i or
             int_trap or exc_fault;
taken_o   <= exc_taken or mret_i;
target_o  <= mepc_reg_i & "00" when mret_i = '1' else mtvec_reg_i & "00";
retire_o  <= retire_i and pipe_en_i and not exc_taken;
regwr_en_o <= regwr_en_i and not exc_fault;
csrwr_en_o <= csrwr_en_i and not exc_fault;
```

An `mret` redirects the fetch but commits nothing beyond the `mstatus`
unstacking in `csrs`, so it joins the redirect and not `exc_taken`.

##### Priority and what is stacked

`encode_trap` is one chain in the spec's priority order, interrupts first, and
picks `mcause` and `mtval` together — `mtval` is taken off the cause rather than
decoded back out of the code, because the two numberings collide at 3, 7 and 11.
An ecall is the only cause left once the eleven above it are ruled out, so it is
the `else`.

| Priority | Cause | mcause code | interrupt bit | mtval |
|---|-------|------|-----|-------|
| 1 | Machine software interrupt | 3 | 1 | 0 |
| 2 | Machine timer interrupt | 7 | 1 | 0 |
| 3 | Machine external interrupt | 11 | 1 | 0 |
| 4 | Instruction address misaligned | 0 | 0 | Target address (`exec_res_i`) |
| 5 | Instruction access fault | 1 | 0 | PC |
| 6 | Illegal instruction | 2 | 0 | 0 |
| 7 | Breakpoint (ebreak) | 3 | 0 | PC |
| 8 | Load address misaligned | 4 | 0 | Effective address |
| 9 | Load access fault | 5 | 0 | Effective address |
| 10 | Store address misaligned | 6 | 0 | Effective address |
| 11 | Store access fault | 7 | 0 | Effective address |
| 12 | Environment call (ecall) | 11 | 0 | 0 |

`mepc` is the EX-aligned PC of the trapping instruction, except under `wfi_i`,
where it is `pc_next_i` — a WFI released by an interrupt stacks the word past
itself, so the handler's `mret` does not fall back in and sleep again.

The trap then commits in `csrs`: `mepc`, `mcause` and `mtval` are registered,
`mstatus.MIE` is saved into `MPIE` and cleared, and the fetch is redirected to
`mtvec`.

##### CSR Write Data Mux

`csrwr_mode_i` is funct3:

| funct3 | Operation |
|--------|-----------|
| `001` | CSRRW: `regwr_data_i` |
| `010` | CSRRS: `csrrd_data_i or regwr_data_i` |
| `011` | CSRRC: `csrrd_data_i and not regwr_data_i` |
| `101` | CSRRWI: `immwr_data_i` |
| `110` | CSRRSI: `csrrd_data_i or immwr_data_i` |
| `111` | CSRRCI: `csrrd_data_i and not immwr_data_i` |
| others | 0 (ECALL/EBREAK/MRET/WFI) |

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `instr_err_i` | in | 1 | Illegal instruction |
| `fetch_fault_i` | in | 1 | Instruction access fault |
| `ecall_i` / `ebreak_i` / `mret_i` / `wfi_i` | in | 1 | SYSTEM causes |
| `mepc_reg_i` | in | XLEN-1:2 | mret redirect candidate |
| `mtvec_reg_i` | in | XLEN-1:2 | Trap redirect candidate |
| `retire_i` | in | 1 | Ungated retire bit |
| `pipe_en_i` | in | 1 | ID/EX advance |
| `exi_trap_i` / `tmi_trap_i` / `swi_trap_i` | in | 1 | Armed interrupts |
| `imrd_malgn_i` | in | 1 | Instruction address misaligned |
| `dmld_malgn_i` / `dmld_fault_i` | in | 1 | Load faults |
| `dmst_malgn_i` / `dmst_fault_i` | in | 1 | Store faults |
| `exec_res_i` | in | XLEN | ALU result (mtval for address causes) |
| `pc_i` | in | XLEN | Full PC |
| `pc_next_i` | in | XLEN-1:2 | pc+4 (mepc for a released WFI) |
| `regwr_en_i` | in | 1 | Register write enable (ungated) |
| `csrwr_en_i` | in | 1 | CSR write enable (ungated) |
| `csrwr_mode_i` | in | 3 | funct3 for the CSR write mux |
| `csrrd_data_i` | in | XLEN | CSR read data |
| `regwr_data_i` | in | XLEN | rs1 value |
| `immwr_data_i` | in | XLEN | Immediate (CSR uimm) |
| `exc_taken_o` | out | 1 | Trap commits |
| `mcause_int_o` | out | 1 | mcause interrupt bit |
| `taken_o` | out | 1 | Redirect taken |
| `target_o` | out | XLEN | Redirect target |
| `mcause_exc_o` | out | 5 | mcause code field |
| `mtval_o` | out | XLEN | mtval |
| `mepc_o` | out | XLEN-1:2 | PC to stack |
| `regwr_en_o` | out | 1 | Register write enable (fault-gated) |
| `csrwr_en_o` | out | 1 | CSR write enable (fault-gated) |
| `csrwr_data_o` | out | XLEN | CSR write data |
| `retire_o` | out | 1 | Retire pulse |

---

## 2. Control Encodings

From `rtl/leaf_pkg.vhdl`.

| Constant group | Values |
|----------------|--------|
| `BR_*` | `BR_NONE` `00`, `BR_BRANCH` `01`, `BR_JUMP` `10` — bit 0 is `en_i`, bit 1 is `jmp_i` |
| `DMLS_*` | `DMLS_IDLE` `00`, `DMLS_LOAD` `01`, `DMLS_STORE` `10` — bit 0 is read, bit 1 is write |
| `IMM_*_TYPE` | I `000`, S `001`, B `010`, U `011`, J `100`, Z `101` |
| `*_BD_MODE` | EQ `000`, NE `001`, LT `100`, GE `101`, LTU `110`, GEU `111` (funct3) |
| `LSU_*` | BYTE `000`, HALF `001`, WORD `010`, BYTEU `100`, HALFU `101` (funct3) |
| `CSR_ADDR_COP0_MIN/MAX` | `0x7C0` / `0x7FF` |

## 3. ALU Op Encoding

`alu_op` is 5 bits, read by `alu` as fields with no decoding of its own:

```
    op(4 downto 3)  res_sel     which unit answers
    op(2)           arith op    '0' plus, '1' minus
    op(1 downto 0)  unit op     comparator / logic / shifter
```

The comparator, the logic unit and the shifter never answer at the same time, so
they share the low field.

| Op | res_sel | arith | unit | Encoding |
|----|---------|-------|------|----------|
| `ALU_ADD` | ARITH `00` | PLUS | NONE `00` | `00000` |
| `ALU_SUB` | ARITH `00` | MINUS | NONE `00` | `00100` |
| `ALU_SLT` | COMP `01` | MINUS | SIGNED `00` | `01100` |
| `ALU_SLTU` | COMP `01` | MINUS | UNSIGNED `01` | `01101` |
| `ALU_XOR` | LOGIC `10` | PLUS | XOR `00` | `10000` |
| `ALU_OR` | LOGIC `10` | PLUS | OR `01` | `10001` |
| `ALU_AND` | LOGIC `10` | PLUS | AND `10` | `10010` |
| `ALU_SLL` | SHIFT `11` | PLUS | SLL `00` | `11000` |
| `ALU_SRL` | SHIFT `11` | PLUS | SRL `01` | `11001` |
| `ALU_SRA` | SHIFT `11` | PLUS | SRA `10` | `11010` |

SLT/SLTU set the arith field to MINUS because the comparator reads
`arith_res(31)` for the same-sign case.
