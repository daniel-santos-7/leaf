# Microarchitecture Reference

## RTL File Map

| File | Entity | Role |
|------|--------|------|
| `rtl/leaf.vhdl` | `leaf` | Top: instantiates core + counters, Wishbone passthrough, COP |
| `rtl/core.vhdl` | `core` | Pipeline wiring: IF + ID/EX |
| `rtl/if_stage.vhdl` | `if_stage` | Fetch FSM + pipeline regs, drives instruction Wishbone port |
| `rtl/id_stage.vhdl` | `id_stage` | Decode, reg file, CSRs, pipeline reg |
| `rtl/main_ctrl.vhdl` | `main_ctrl` | Decoder + immediate gen + ALU op decode |
| `rtl/trap_ctrl.vhdl` | `trap_ctrl` | Trap and interrupt decision, what the trap stacks (mcause, mtval, mepc), ecall/ebreak/mret/wfi qualification |
| `rtl/reg_file.vhdl` | `reg_file` | 32×32 register file (SIZE=16 or 32) |
| `rtl/csrs.vhdl` | `csrs` | Machine CSRs, interrupt operands, trap state commit |
| `rtl/ex_block.vhdl` | `ex_block` | ALU, branch, load/store, CSR write mux |
| `rtl/alu.vhdl` | `alu` | ALU datapath (bypass chain) |
| `rtl/br_detector.vhdl` | `br_detector` | Branch condition evaluation |
| `rtl/dmls_block.vhdl` | `dmls_block` | Data load/store FSM, drives data Wishbone port |
| `rtl/csrs_logic.vhdl` | `csrs_logic` | CSR write data mux (funct3-based) |
| `rtl/counters.vhdl` | `counters` | mcycle, time, instret |
| `rtl/wb_arbiter.vhdl` | `wb_arbiter` | Wishbone arbiter (used in testbench only) |
| `rtl/leaf_pkg.vhdl` | `leaf_pkg` | ISA constants, opcodes, ALU ops |

---

## Architecture Overview

Leaf implements a two-stage pipeline (IF → ID/EX) with separate Wishbone B4
master ports for instruction and data access.

```
leaf (top)
├── counters       mcycle, time, instret
└── core           IF + ID/EX pipeline
    ├── if_stage     Fetch FSM + pipeline regs → inst Wishbone
    ├── id_stage     Decode + reg file + CSRs + pipeline reg
    │   ├── main_ctrl   Decoder, immediate gen, ALU op decode
    │   ├── trap_ctrl   Trap/interrupt decision, mcause + mtval + mepc,
    │                   ecall/ebreak/mret/wfi
    │   ├── reg_file    32×XLEN register file
    │   └── csrs        Machine-mode CSRs, interrupt operands, trap commit
    └── ex_block     ALU, branch, load/store, CSR write mux
        ├── alu          ALU datapath (arith → comp → logic → shifter)
        ├── br_detector  Branch condition evaluation
        ├── dmls_block   Data load/store FSM → data Wishbone
        └── csrs_logic   CSR write data mux
```

### Pipeline Operation

IF stage drives Wishbone instruction port (`inst_*`) directly via its own FSM.
On acknowledge/error, the fetched instruction is captured in pipeline registers
(`pc_reg`, `adr_reg`, `inst_reg`, `valid_reg`, `inst_err_reg`).

The `id_stage` receives IF outputs and passes them through combinational decode
(`main_ctrl`, `reg_file`, `csrs`) into an internal pipeline register. The
pipeline register outputs feed `ex_block` combinatorially.

Stages handshake via `ready_i`/`ready_o`:
- `if_stage.ready_i` = `id_stage.ready_o` — IF advances when ID is ready
- `id_stage.ready_i` = `ex_block.ready_o` — ID advances when EX is done
  (WFI: `id_stage.ready_o` tied to interrupt, gated by `wfi` in trap_ctrl)

Branch/trap: `ex_block.taken_o` (combinatorial) loops back to `if_stage`,
redirecting the next PC. Taken branch costs 2 cycles (fetch + redirect).

Wishbone: each port is driven directly by the corresponding FSM.
`if_stage` drives `inst_cyc_o`, `inst_stb_o`, `inst_adr_o` with
`inst_stall_i` backpressure. `dmls_block` drives `data_cyc_o`, `data_stb_o`,
`data_adr_o`, `data_sel_o`, `data_we_o` with `data_stall_i` backpressure.
Both FSMs share the same `clk_i` — there is no clock gating.

### Counter Timing

`counters` is a separate entity at the `leaf` level. All counters increment on
`clk_i` (free-running `clk_i`, not pipelined clock). `retire` pulse from
`if_stage` gates `instret`:

```vhdl
retire_o <= valid_reg and ready_i;
```

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

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `rst_i` | in | 1 | Asynchronous reset (active high) |
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

    clk_i ──────▶ counters ── cycle, timer, instret ──▶ core
    rst_i ──────▶ counters                                │
    rst_i ──────▶ core                                    │
                                                          │
    inst_dat_i ──┐                                        │
    inst_ack_i ──┤                                        │
    inst_err_i ──┤                                        │
    inst_stall_i ─┤  ┌──────────┐                         │
                  ├──│   core   │──▶ inst_cyc_o           │
    cop_dat_i ────┤   │         │──▶ inst_stb_o           │
                  │   │  if_stage│──▶ inst_adr_o           │
    ex_irq_i ─────┤   │  (fetch) │                         │
    sw_irq_i ─────┤   │         │                         │
    tm_irq_i ─────┘   │  id_stage│──▶ cop_adr_o           │
                      │  (decode)│──▶ cop_dat_o           │
    data_dat_i ──────▶│  + regs  │──▶ cop_we_o            │
    data_ack_i ──────▶│  + CSRs) │                         │
    data_err_i ──────▶│         │                         │
    data_stall_i ────▶│  ex_block│──▶ data_cyc_o          │
                      │  (exec)  │──▶ data_stb_o          │
                      │         │──▶ data_we_o            │
                      │         │──▶ data_sel_o           │
                      │         │──▶ data_adr_o           │
                      │         │──▶ data_dat_o           │
                      └──────────┘                         │
```

The COP interface is a private passthrough between core and an external
coprocessor via CSR address window `0x7C0`–`0x7FF`. No Wishbone arbitration.

### 1.1 `counters` — Cycle, Time, Instret

File: `rtl/counters.vhdl`

Tracks three 64-bit values on `clk_i`:

| Counter | CSR (low) | CSR (high) | Reset | Behavior |
|---------|-----------|-------------|-------|----------|
| `mcycle` | `0xC00` | `0xC80` | Yes | Increments every `clk_i` cycle |
| `time` | `0xC01` | `0xC81` | Yes | Increments every `clk_i` cycle |
| `minstret` | `0xC02` | `0xC82` | Yes | Increments on `retire_i` pulse |

`time` is reset on `rst_i` (unlike the stale doc claim). `minstret` counts
only when `retire_i = valid_reg and ready_i` is asserted from `if_stage`.

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `retire_i` | in | 1 | Instruction retire pulse |
| `cycle_o` | out | 64 | Cycle counter value |
| `timer_o` | out | 64 | Timer value |
| `instret_o` | out | 64 | Instruction retired counter |

### 1.2 `core` — Core Pipeline

File: `rtl/core.vhdl`

Wires `if_stage` → `id_stage` → `ex_block`. Internal signals use `ex_*`
prefix for decode outputs to execution and `if_*` for fetch outputs.

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
| `inst_err_i` | in | 1 | Instruction Wishbone error |
| `inst_ack_i` | in | 1 | Instruction Wishbone acknowledge |
| `inst_stall_i` | in | 1 | Instruction Wishbone stall |
| `inst_dat_i` | in | XLEN | Instruction Wishbone read data |
| `inst_cyc_o` | out | 1 | Instruction Wishbone cycle |
| `inst_stb_o` | out | 1 | Instruction Wishbone strobe |
| `inst_adr_o` | out | XLEN-1:2 | Instruction Wishbone address |
| `data_dat_i` | in | XLEN | Data Wishbone read data |
| `data_ack_i` | in | 1 | Data Wishbone acknowledge |
| `data_err_i` | in | 1 | Data Wishbone error |
| `data_stall_i` | in | 1 | Data Wishbone stall |
| `cycle_i` | in | 64 | Cycle counter |
| `timer_i` | in | 64 | Timer value |
| `instret_i` | in | 64 | Instruction retired counter |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |
| `retire_o` | out | 1 | Instruction retire pulse |
| `data_cyc_o` | out | 1 | Data Wishbone cycle |
| `data_stb_o` | out | 1 | Data Wishbone strobe |
| `data_we_o` | out | 1 | Data Wishbone write enable |
| `data_sel_o` | out | 4 | Data Wishbone byte selects |
| `data_adr_o` | out | XLEN-1:2 | Data Wishbone address |
| `data_dat_o` | out | XLEN | Data Wishbone write data |

#### Pipeline Flow

```
                 core.vhdl

    inst_dat_i ───▶ if_stage ── pc, next_pc, instr, imrd_fault ──▶ id_stage
    inst_ack_i ───▶ (fetch)    ─────────────────────────────────▶ (decode)
    inst_err_i ───▶            valid                              │
    inst_stall_i ──▶            retire                            │
                       ▲         │                                │
                       │         │  ┌─── pipeline reg ──┐         │
                       │         │  │ func3, branch_op, │         │
                       │         │  │ alu_op, dmls_ctrl,│         │
                       │         │  │ rd0, rd1,         │         │
                       │         │  │ csrrd_data, imm,  │         │
                       │         │  │ opd0/1_src_sel,   │         │
                       │         │  │ opd0/1_pass,      │         │
                       │         │  │ exc_taken, mret,  │         │
                       │         │  │ mepc, mtvec_base, │         │
                       │         │  │ pc_full,          │         │
                       │         │  │ regwr_en, csrwr_en│         │
                       │         │  └───────────────────┘         │
                       │         │                                │
                       │         └──────────────▶ ex_block ────▶ taken_o
                       │  taken_i, target_i ◀──── (exec)    ────▶ target_o
                       │                            ────▶ data_*
                       │                            ────▶ res_o
                       │  ready_i (id_ready) ◀────── ready_o
```

### 1.3 `if_stage` — Instruction Fetch

File: `rtl/if_stage.vhdl`

Fetch FSM with states `REQUEST`, `WFETCH`, `IDLE`. Drives the instruction
Wishbone master port directly. Pipeline registers capture fetched instruction,
address, and valid/error flags.

#### FSM States

| State | Description |
|-------|-------------|
| `REQUEST` | Cycle + Strobe asserted. On acknowledge/error, capture data if ready |
| `WFETCH` | Strobe deasserted (wait-state). On acknowledge/error, capture data |
| `IDLE` | Bus released. On ready, re-assert cycle/strobe |

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Synchronous reset (active high) |
| `ready_i` | in | 1 | Pipeline advance enable (from id_stage) |
| `inst_ack_i` | in | 1 | Wishbone acknowledge |
| `inst_err_i` | in | 1 | Wishbone bus error |
| `inst_stall_i` | in | 1 | Wishbone stall (strobe gating) |
| `taken_i` | in | 1 | Branch/jump/trap taken (from ex_block) |
| `target_i` | in | XLEN | Branch/jump/trap target address |
| `inst_dat_i` | in | XLEN | Instruction data from Wishbone |
| `inst_cyc_o` | out | 1 | Wishbone cycle |
| `inst_stb_o` | out | 1 | Wishbone strobe |
| `inst_err_o` | out | 1 | Instruction bus error flag |
| `valid_o` | out | 1 | Instruction valid (not flushed) |
| `inst_adr_o` | out | XLEN-1:2 | Fetch address |
| `pc_o` | out | XLEN-1:2 | Current PC |
| `next_pc_o` | out | XLEN-1:2 | PC + 4 |
| `inst_o` | out | XLEN | Fetched instruction |
| `retire_o` | out | 1 | Retire pulse (= `valid_reg and ready_i`) |

#### Operation

- `pc_reg` updated on acknowledge: `pc_reg <= adr_reg` (holds fetched PC)
- `adr_reg` tracks next address: reset = `RESET_ADDR`, branch = `target`,
  advance = `adr_reg + 1`, hold otherwise
- `inst_reg` captures `inst_dat_i` on acknowledge/error
- `valid_reg` = '1' when a valid instruction was fetched (not flushed)
- `inst_err_reg` = '1' when `inst_err_i` was asserted
- `taken_reg` extends the `taken_i` pulse: combinatorial `taken = taken_i or taken_reg`
  so a taken branch that arrives during IDLE is not lost

Taken redirect takes priority: on acknowledge `taken_i` redirects to `target`
(vs next sequential). Retire counts only `valid_reg and ready_i`.

#### PC Update

| Condition | adr_reg next | pc_reg next |
|-----------|-------------|-------------|
| Reset | `RESET_ADDR` | 0 |
| Acknowledge + taken | `target` | `adr_reg` |
| Acknowledge + advance | `adr_reg + 1` | `adr_reg` |
| Acknowledge + IDLE | `target` or `adr_reg + 1` | `adr_reg` |
| Otherwise | hold | hold |

### 1.4 `id_stage` — Instruction Decode

File: `rtl/id_stage.vhdl`

Contains the decode logic (`main_ctrl`), register file (`reg_file`), CSRs
(`csrs`), and the ID/EX pipeline register. Combinatorial decode outputs are
latched into the pipeline register on `id_ready = '1'`.

```
                 id_stage.vhdl

    instr_i ──▶ field extraction ── func3, rs1, rs2, rd, csr addr
            │
            ├──▶ main_ctrl ── imm, branch_op, dmls_ctrl, alu_op,
            │    (decoder)      opd0/1_src_sel, opd0/1_pass,
            │                   exc_taken, mret, regwr_en, csrwr_en
            │                ── instr_err, ecall, ebreak, mret, wfi
            │                ── ready_o (pipeline advance)
            │
            ├──▶ reg_file ── rd_data0_o, rd_data1_o
            │    (32×XLEN)   wr_data: ALU / dmld / next_pc / CSR
            │
            └──▶ csrs ──── csrrd_data, mepc, mtvec_base, mie_*, mip_*
                 (trap     cop_adr_o, cop_dat_o, cop_we_o
                  logic)   mstatus_mie, mie_*, mip_*

    All decode outputs → pipeline_reg → ex_block
```

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Synchronous reset |
| `ex_irq_i` | in | 1 | External interrupt |
| `sw_irq_i` | in | 1 | Software interrupt |
| `tm_irq_i` | in | 1 | Timer interrupt |
| `imrd_malgn_i` | in | 1 | Instruction fetch misaligned |
| `dmld_malgn_i` | in | 1 | Data load misaligned |
| `dmld_fault_i` | in | 1 | Data load bus fault |
| `dmst_malgn_i` | in | 1 | Data store misaligned |
| `dmst_fault_i` | in | 1 | Data store bus fault |
| `cycle_i` | in | 64 | Cycle counter |
| `timer_i` | in | 64 | Timer |
| `instret_i` | in | 64 | Instruction retired counter |
| `exec_res_i` | in | XLEN | ALU result (write-back) |
| `dmld_data_i` | in | XLEN | Data load result |
| `pc_i` | in | XLEN-1:2 | Current PC |
| `next_pc_i` | in | XLEN-1:2 | PC + 4 |
| `instr_i` | in | XLEN | Instruction word |
| `fault_i` | in | 1 | Instruction fetch bus fault |
| `valid_i` | in | 1 | Instruction valid |
| `cop_dat_i` | in | XLEN | Coprocessor read data |
| `cop_adr_o` | out | 6 | Coprocessor address |
| `cop_dat_o` | out | XLEN | Coprocessor write data |
| `cop_we_o` | out | 1 | Coprocessor write enable |
| `csr_wr_data_i` | in | XLEN | CSR write data (from ex_block) |
| `ready_i` | in | 1 | EX stage ready |
| `exc_fault_i` | in | 1 | EX-stage fault (suppress writes) |
| `rf_we_i` | in | 1 | Register file write enable (from ex_block) |
| `csr_we_i` | in | 1 | CSR write enable (from ex_block) |
| `ready_o` | out | 1 | ID stage ready (pipeline advance) |
| `func3_o` | out | 3 | funct3 field |
| `branch_op_o` | out | 2 | Branch operation (BR_NONE/BR_BRANCH/BR_JUMP) |
| `alu_op_o` | out | 6 | ALU operation code |
| `dmls_ctrl_o` | out | 2 | Data memory control (DMLS_IDLE/DMLS_LOAD/DMLS_STORE) |
| `exc_taken_o` | out | 1 | Exception taken |
| `mret_o` | out | 1 | MRET instruction |
| `mepc_o` | out | XLEN-1:2 | Exception PC (from csrs) |
| `mtvec_base_o` | out | XLEN-1:2 | Trap vector base |
| `rd_data0_o` | out | XLEN | Register read port 0 |
| `rd_data1_o` | out | XLEN | Register read port 1 |
| `csrrd_data_o` | out | XLEN | CSR read data |
| `imm_o` | out | XLEN | Decoded immediate |
| `opd0_src_sel_o` | out | 1 | Select PC vs reg0 as ALU opd0 |
| `opd1_src_sel_o` | out | 1 | Select imm vs reg1 as ALU opd1 |
| `opd0_pass_o` | out | 1 | Gate ALU operand 0 |
| `opd1_pass_o` | out | 1 | Gate ALU operand 1 |
| `pc_full_o` | out | XLEN | Full PC (pc_i & "00") |
| `ex_regwr_en_o` | out | 1 | Register write enable (pipelined) |
| `ex_csrwr_en_o` | out | 1 | CSR write enable (pipelined) |

All outputs except `ready_o`, `cop_adr_o`, `cop_dat_o`, `cop_we_o` come from
the pipeline register (registered on `id_ready`).

#### 1.4.1 `main_ctrl` — Decoder

File: `rtl/main_ctrl.vhdl`

Decodes opcode to generate all control signals, immediate and ALU opcode. The
trap side — ecall/ebreak/mret/wfi, the fetch fault and the interrupt — is
decided in `trap_ctrl`; main_ctrl only reports the illegal instruction.

##### Decoding Logic

- **Opcode-based**: R-type, I-type, loads, stores, branches, JAL/JALR,
  LUI, AUIPC, system (ECALL/EBREAK/MRET/WFI/CSR), FENCE
- **Trap inhibit**: gates control outputs when `imrd_fault` or an interrupt is
  taken (prevents decode-triggered error loops)
- **WFI**: parks the pipeline from `trap_ctrl`, not from here
- **Immediate types**: I, S, B, U, J, Z (CSR uimm)

##### ALU Op Decode

ALU op decode is inside `main_ctrl` (not a separate entity):

- `op_en = 0` → `ALU_ADD` (pipeline bubble / non-ALU instruction)
- `func3 = 000`, `func7(5) = 1`, R-type → `ALU_SUB`
- `func3 = 101`, `func7(5) = 1` → `ALU_SRA`
- Otherwise maps `func3` → ALU op (ADD, SLL, SLT, SLTU, XOR, SRL, OR, AND)

##### Interrupt Logic

Interrupts are taken when `mstatus_MIE = 1` and the corresponding `mie` and
`mip` bits are set:

- `exi_taken = mie_meie and mip_meip`
- `tmi_taken = mie_mtie and mip_mtip`
- `swi_taken = mie_msie and mip_msip`
- `int_taken = (exi or tmi or swi) and mstatus_mie`

#### 1.4.2 `reg_file` — Register File

File: `rtl/reg_file.vhdl`

32 × XLEN register file. Register x0 is hardwired to zero. Dual-implementation:
`SIZE = 16` selects 4-bit addressing (16 registers), `SIZE = 32` selects 5-bit
(32 registers). Default is 32.

Write data mux selects from ALU result, data load, next PC, or CSR read data
(via `wr_sel_i`). Combinatorial read with forwarding: read data bypasses from
write data when write address matches read address and write is active.

#### 1.4.3 `csrs` — Control and Status Registers

File: `rtl/csrs.vhdl`

Implements the machine-mode CSR registers and the trap state commit. Every trap
decision lives in `trap_ctrl`: whether an interrupt is taken, out of the four
write-bypassed operands exported from here (`exi_taken_o`, `tmi_taken_o`,
`swi_taken_o`, `mstatus_mie_o`), and what the trap stacks — cause, `mtval` and
`mepc` alike — out of those plus the fault set `trap_ctrl` owns. The results
come back as `int_taken_i`, `mcause_exc_i`, `mtval_i` and `mepc_i`, and the
three writes here only register them.

##### Machine-Mode CSRs

| Address | Register | Description |
|---------|----------|-------------|
| `0x300` | `mstatus` | Machine status (MIE, MPIE) |
| `0x301` | `misa` | ISA (RV32I, hardwired) |
| `0x304` | `mie` | Interrupt enable (MEIE, MTIE, MSIE) |
| `0x305` | `mtvec` | Trap vector base address |
| `0x340` | `mscratch` | Machine scratchpad |
| `0x341` | `mepc` | Exception program counter |
| `0x342` | `mcause` | Trap cause |
| `0x343` | `mtval` | Trap value |
| `0x344` | `mip` | Interrupt pending |
| `0xF14` | `mhartid` | Hart ID (read-only) |

##### Read-Only Counters

| Address | Register | Description |
|---------|----------|-------------|
| `0xC00` | `cycle` | Cycle counter (low) |
| `0xC01` | `time` | Timer (low) |
| `0xC02` | `instret` | Instret counter (low) |
| `0xC80` | `cycleh` | Cycle counter (high) |
| `0xC81` | `timeh` | Timer (high) |
| `0xC82` | `instreth` | Instret counter (high) |

##### Modes

| funct3 | Mode | Operation |
|--------|------|-----------|
| `001` | CSRRW | Atomic read+write |
| `010` | CSRRS | Atomic read+set |
| `011` | CSRRC | Atomic read+clear |
| `101` | CSRRWI | Atomic read+write immediate |
| `110` | CSRRSI | Atomic read+set immediate |
| `111` | CSRRCI | Atomic read+clear immediate |

##### Trap/Exception Handling

Exception sources and `mcause` codes. The two columns are two processes in
`trap_ctrl` -- `encode_mcause` and `select_mtval` -- walking the same causes in
the same priority order, interrupts first; `csrs` only registers what comes
out. The `mtval` is picked off the cause rather than decoded back out of the
code because the two numberings collide: 3, 7 and 11 appear in both halves.

| Code | Source | mtval |
|------|--------|-------|
| 0 | Instruction address misaligned | Target address |
| 1 | Instruction access fault | PC of faulted instruction |
| 2 | Illegal instruction | 0 |
| 3 | Breakpoint (ebreak) | PC of breakpoint |
| 4 | Load address misaligned | Effective address |
| 5 | Load access fault | Effective address |
| 6 | Store address misaligned | Effective address |
| 7 | Store access fault | Effective address |
| 11 | Environment call (ecall) | 0 |

Interrupt codes (mcause bit 31 = 1):

| Code | Source |
|------|--------|
| 3 | Machine software interrupt |
| 7 | Machine timer interrupt |
| 11 | Machine external interrupt |

Trap flow:
1. `trap_ctrl` picks the PC to stack — the EX-aligned PC of the trapping
   instruction, or the word past it when the trap releases a parked WFI — and
   `csrs` registers it into `mepc`
2. `mstatus.MIE` saved to `mstatus.MPIE`, then `MIE` cleared
3. `mcause` and `mtval` set
4. PC jumps to `mtvec` (via `ex_block` combinatorial mux)

##### Coprocessor Window

CSR addresses `0x7C0`–`0x7FF` are forwarded to `cop_dat_o` with `cop_we_o`
strobe on writes, and `cop_dat_i` is read on reads. Write address
(5:0) and read address (5:0) are output on `cop_adr_o`.

### 1.5 `ex_block` — Execution Block

File: `rtl/ex_block.vhdl`

Contains the ALU, branch detector, data load/store FSM, and CSR write data
mux. Drives the data Wishbone master port.

```
                 ex_block.vhdl

    reg0_i ─────┐
    pc_i ───────┼──▶ MUX ──▶ AND ──┐
    opd0_src_sel┘       opd0_pass   │
                                    ├──▶ ALU ── res_o
    reg1_i ─────┐                   │
    imm_i ──────┼──▶ MUX ──▶ AND ──┘
    opd1_src_sel┘       opd1_pass

    br_detector ◀── reg0, reg1, func3, arith_res
        └── taken_o, target_o

    dmls_block ◀── arith_res, reg1, func3, data_*, dmls_ctrl
        ├── data_cyc_o, data_stb_o, data_we_o, data_sel_o
        ├── data_adr_o, data_dat_o
        └── dmld_data_o

    csrs_logic ◀── func3, csrrd_data, reg0, imm
        └── csrwr_data_o

    Target MUX: target_o = trap_target when trap_taken else arith_res & 0
```

#### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `exc_taken_i` | in | 1 | Exception taken (from csrs) |
| `mret_i` | in | 1 | MRET |
| `mepc_i` | in | XLEN-1:2 | Exception PC |
| `mtvec_base_i` | in | XLEN-1:2 | Trap vector base |
| `func3_i` | in | 3 | funct3 field |
| `reg0_i` | in | XLEN | Register read port 0 |
| `reg1_i` | in | XLEN | Register read port 1 |
| `pc_i` | in | XLEN | Full PC |
| `opd0_src_sel_i` | in | 1 | Select PC vs reg0 |
| `opd1_src_sel_i` | in | 1 | Select imm vs reg1 |
| `opd0_pass_i` | in | 1 | Gate ALU operand 0 |
| `opd1_pass_i` | in | 1 | Gate ALU operand 1 |
| `branch_op_i` | in | 2 | Branch operation (BR_NONE/BR_BRANCH/BR_JUMP) |
| `alu_op_i` | in | 6 | ALU operation code |
| `dmls_ctrl_i` | in | 2 | Data memory control |
| `data_dat_i` | in | XLEN | Data Wishbone read data |
| `data_ack_i` | in | 1 | Data Wishbone acknowledge |
| `data_err_i` | in | 1 | Data Wishbone error |
| `data_stall_i` | in | 1 | Data Wishbone stall |
| `csrrd_data_i` | in | XLEN | CSR read data |
| `immwr_data_i` | in | XLEN | Immediate (for CSR ops) |
| `csrwr_data_o` | out | XLEN | CSR write data |
| `imrd_malgn_o` | out | 1 | Instruction fetch misaligned |
| `dmld_malgn_o` | out | 1 | Data load misaligned |
| `dmld_fault_o` | out | 1 | Data load bus fault |
| `dmst_malgn_o` | out | 1 | Data store misaligned |
| `dmst_fault_o` | out | 1 | Data store bus fault |
| `data_cyc_o` | out | 1 | Data Wishbone cycle |
| `data_stb_o` | out | 1 | Data Wishbone strobe |
| `data_dat_o` | out | XLEN | Data Wishbone write data |
| `data_adr_o` | out | XLEN-1:2 | Data Wishbone address |
| `data_sel_o` | out | 4 | Data Wishbone byte selects |
| `data_we_o` | out | 1 | Data Wishbone write enable |
| `dmld_data_o` | out | XLEN | Load result (aligned + sign-extended) |
| `taken_o` | out | 1 | Branch/jump/trap taken |
| `target_o` | out | XLEN | Branch/jump/trap target |
| `ready_o` | out | 1 | EX stage ready |
| `branch_o` | out | 1 | Branch condition met |
| `res_o` | out | XLEN | ALU result |
| `valid_i` | in | 1 | Instruction valid |
| `fault_i` | in | 1 | IF-stage fault |
| `regwr_en_i` | in | 1 | Register write enable |
| `csrwr_en_i` | in | 1 | CSR write enable |
| `exc_fault_o` | out | 1 | EX-stage fault (suppress write-back) |
| `rf_we_o` | out | 1 | Register file write (gated by exc_fault) |
| `csr_we_o` | out | 1 | CSR write (gated by exc_fault) |

#### 1.5.1 `alu` — ALU Datapath

File: `rtl/alu.vhdl`

Combinational datapath organized as a bypass chain: `arith → comp → logic →
shifter → res_o`. Each sub-block passes through the previous result when its
operation is not selected.

##### Sub-blocks

- **arith_unit**: ADD/SUB via `unsigned` addition with conditional 2's
  complement of opd1
- **comparator**: SLT/SLTU using MSB comparison with `arith_res(31)` for
  same-sign case
- **logic_unit**: XOR/OR/AND
- **shifter**: SLL/SRL/SRA via `numeric_std` shift functions (5-bit
  shift amount from opd1(4:0))

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `pc_i` | in | XLEN | PC (for AUIPC/JAL) |
| `reg0_i` | in | XLEN | Register value 0 |
| `reg1_i` | in | XLEN | Register value 1 |
| `immwr_data_i` | in | XLEN | Immediate |
| `opd0_src_sel_i` | in | 1 | Select PC vs reg0 |
| `opd1_src_sel_i` | in | 1 | Select imm vs reg1 |
| `opd0_pass_i` | in | 1 | Gate opd0 (0 = 0) |
| `opd1_pass_i` | in | 1 | Gate opd1 (0 = 0) |
| `op_i` | in | 6 | ALU operation code |
| `res_o` | out | XLEN | Final result |
| `arith_res_o` | out | XLEN | Arithmetic result (for branches) |

#### 1.5.2 `br_detector` — Branch Detector

File: `rtl/br_detector.vhdl`

Combinational comparator for branch condition evaluation. Detects
misaligned instruction fetch for taken branches.

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `reg0_i` | in | XLEN | RS1 value |
| `reg1_i` | in | XLEN | RS2 value |
| `mode_i` | in | 3 | Branch mode (funct3) |
| `en_i` | in | 1 | Branch enable |
| `jmp_i` | in | 1 | Jump (unconditional) |
| `arith_res_i` | in | XLEN | ALU arithmetic result (target) |
| `trap_taken_i` | in | 1 | Trap taken (override branch) |
| `trap_target_i` | in | XLEN | Trap target |
| `branch_o` | out | 1 | Branch condition met |
| `taken_o` | out | 1 | Taken (branch or jump or trap) |
| `target_o` | out | XLEN | Target address |
| `imrd_malgn_o` | out | 1 | Instruction fetch misaligned |

#### 1.5.3 `dmls_block` — Data Load/Store

File: `rtl/dmls_block.vhdl`

Handles data memory load/store alignment, byte enables, and sign-extension.
Contains a data Wishbone FSM with states `IDLE`, `REQUEST`, `WACCESS`, `DONE`.

##### FSM States

| State | Description |
|-------|-------------|
| `IDLE` | Waits for load/store request (`dmls_ctrl_i`) |
| `REQUEST` | Cycle + Strobe asserted. On acknowledge → DONE, on stall → WACCESS |
| `WACCESS` | Wait-state (strobe deasserted). On acknowledge/error → DONE |
| `DONE` | Single-cycle done, returns to IDLE |

##### Data Types

Handles all RV32I load/store types: LB, LBU, LH, LHU, LW, SB, SH, SW.
Misalignment is detected per type: byte accesses are never misaligned,
halfword requires `addr(0)=0`, word requires `addr(1:0)=00`.

##### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | in | 1 | Clock |
| `reset_i` | in | 1 | Reset |
| `dmls_ctrl_i` | in | 2 | Control (IDLE/LOAD/STORE) |
| `dmls_dtype_i` | in | 3 | Data type (func3: LB/LBU/LH/LHU/W/SB/SH/SW) |
| `dmst_data_i` | in | XLEN | Store data from reg1 |
| `arith_res_i` | in | XLEN | Address from ALU |
| `data_dat_i` | in | XLEN | Wishbone read data |
| `data_ack_i` | in | 1 | Wishbone acknowledge |
| `data_err_i` | in | 1 | Wishbone error |
| `data_stall_i` | in | 1 | Wishbone stall |
| `data_cyc_o` | out | 1 | Wishbone cycle |
| `data_stb_o` | out | 1 | Wishbone strobe |
| `data_dat_o` | out | XLEN | Wishbone write data |
| `data_adr_o` | out | XLEN-1:2 | Wishbone address |
| `data_sel_o` | out | 4 | Byte enables |
| `data_we_o` | out | 1 | Write enable |
| `dmls_ready_o` | out | 1 | Ready (pipeline gate) |
| `dmld_malgn_o` | out | 1 | Load misaligned |
| `dmld_fault_o` | out | 1 | Load bus fault |
| `dmst_malgn_o` | out | 1 | Store misaligned |
| `dmst_fault_o` | out | 1 | Store bus fault |
| `dmld_data_o` | out | XLEN | Load result (aligned + extended) |

#### 1.5.4 `csrs_logic` — CSR Write Data Mux

File: `rtl/csrs_logic.vhdl`

Combinational mux computing CSR write data from funct3:

| funct3 | Operation |
|--------|-----------|
| `001` | CSRRW: `regwr_data_i` |
| `010` | CSRRS: `csrrd_data_i or regwr_data_i` |
| `011` | CSRRC: `csrrd_data_i and not regwr_data_i` |
| `101` | CSRRWI: `immwr_data_i` |
| `110` | CSRRSI: `csrrd_data_i or immwr_data_i` |
| `111` | CSRRCI: `csrrd_data_i and not immwr_data_i` |
| others | 0 (ECALL/EBREAK/MRET/WFI) |

### 1.6 `wb_arbiter` — Wishbone Arbiter (Testbench Only)

File: `rtl/wb_arbiter.vhdl`

Simple round-robin arbiter that merges instruction and data Wishbone master
ports into a single shared bus. Used by the testbench; not part of the
`leaf` core.
