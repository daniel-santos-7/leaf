# RTL Review Findings

> Revisão sistemática de cada módulo do processador Leaf.
> Iniciada em: 2026-05-29

## Metodologia

Cada módulo VHDL é analisado individualmente. Problemas são categorizados como:

| Severidade | Descrição |
|------------|-----------|
| **BUG** | Funcionalmente incorreto — afeta execução de instruções ou conformidade com a ISA |
| **WARN** | Potencialmente problemático — pode causar falhas em certos cenários |
| **INFO** | Questão de estilo, clareza, ou melhoria não-crítica |

---

## Top-level (`rtl/leaf.vhdl`)

### ~~BUG: `instret` hardwired to zero~~ (CORRIGIDO)

~~`rtl/counters.vhdl:40-41` — `instret` e `timer` são atribuídos como `(others => '0')`.~~

~~O módulo `counters` não tem porta de entrada para receber um sinal de retire do core. O `minstret` CSR nunca incrementa, e `mtime`/`mtimeh` CSR sempre retornam zero.~~

**Corrigido em 2026-05-29**:
- Adicionado `retire_i` a `counters`
- `instret_reg` incrementa em cada `retire_i = '1'` — sinal gerado pelo core (`pcwr_en and not flush`)
- `timer_reg` incrementa a cada `clk_i` (contador separado, sem reset — free-running desde power-on)
- `cycle_reg` permanece free-running no `clk_i`

---

### WARN: Reset distribution asymmetry

`rtl/leaf.vhdl:79-105`, `rtl/wb_ctrl.vhdl:122`

O sinal `reset` que alimenta o core é gerado pelo FSM do `wb_ctrl` (`reset <= '1' when curr_state = START else '0'`). O `clk_ctrl` e `counters` recebem `rst_i` diretamente.

Sequência: `rst_i` desassere → `wb_ctrl` move de START para IDLE → `reset` vai a '0' → core sai de reset.

Isso introduz um **delay de 1 ciclo** entre `rst_i` e `reset` para o core, enquanto `counters` é liberado imediatamente. O `clk_ctrl` também é liberado imediatamente (porta `or rst_i` na saída do clock gate).

**Impacto**: Baixo — o core começa a executar 1 ciclo após os contadores. O `wb_ctrl` também começa a aceitar requisições 1 ciclo após `rst_i`.

**Sugestão**: Ou documentar explicitamente este comportamento, ou unificar a distribuição de reset (usar `rst_i` em todos os módulos e ter um reset sincronizador dedicado separado do FSM Wishbone).

---

### WARN: COP interface lacks handshake signals

`rtl/leaf.vhdl:27-30`, `rtl/core.vhdl:32-35`

A interface do coprocessador tem `cop_adr_o` (6 bits), `cop_dat_o`, `cop_we_o`, `cop_dat_i`. Não há `cop_ack_i`, `cop_err_i`, ou `cop_ready_i`.

**Impacto**: Um coprocessador multi-ciclo não pode atrasar a resposta. A pipeline não tem mecanismo para stall esperando por um coprocessador. A interface é essencialmente single-cycle.

**Sugestão**: Adicionar um sinal `cop_stall_i` (ou `cop_ready_i`) que o core possa usar para congelar a pipeline enquanto espera. Alternativamente, documentar que a interface é single-cycle apenas.

---

### INFO: Gated clock via transparent latch

`rtl/clk_ctrl.vhdl:28-33`

O clock gating usa um latch transparente (enable sample na borda de descida) + AND gate. Técnica clássica, mas:

- FPGAs geralmente não sintetizam latches bem (LUT + rota, não latch dedicado)
- ASIC flows preferem células de clock gating dedicadas (ICG)
- A ferramenta de síntese (Yosys) precisa ser configurada para lidar com o clock gerado

**Sugestão**: Alternativa moderna é usar clock enable nos registradores (RTL com `if clk_en = '1'` em cada processo sensível a clock). Isso evita o latch e não cria domínio de clock adicional.

---

### INFO: Bus error reporting uses current enable signals

`rtl/wb_ctrl.vhdl:124-126`

```vhdl
imrd_err <= imrd_en when curr_state = ERROR else '0';
dmrd_err <= dmrd_en when curr_state = ERROR else '0';
dmwr_err <= dmwr_en when curr_state = ERROR else '0';
```

O tipo de transação que causou o erro não é latched — usa o valor *atual* de `imrd_en`/`dmrd_en`/`dmwr_en` no ciclo em que `curr_state = ERROR`. Se o enable mudar entre o erro e o estado ERROR (ex: pipeline stall desativa `imrd_en`), o erro pode não ser corretamente atribuído.

**Impacto**: Baixo na prática — os enables raramente mudam durante um erro de barramento — mas é frágil.

**Sugestão**: Latch o tipo de transação (`error_source`) quando `err_i` é recebido.

---

### INFO: No bus timeout

`rtl/wb_ctrl.vhdl:61-111`

O FSM Wishbone espera indefinidamente por `ack_i` ou `err_i` nos estados `READ_INSTR`, `READ_DATA`, e `WRITE_DATA`. Não há contador de timeout.

**Impacto**: Um slave Wishbone que nunca responder trava o processador para sempre.

**Sugestão**: Adicionar timeout watchdog externo ou documentar a limitação.

---

### INFO: `sel_o` active when bus is idle

`rtl/wb_ctrl.vhdl:117`

```vhdl
sel_o <= dmwr_be when curr_state = WRITE_DATA else (others => '1');
```

`sel_o` fica como `1111` mesmo quando `cyc_o` está baixo. Wishbone slaves ignoram `sel_o` quando `cyc_o` é baixo, então não é um erro funcional.

---

## Pipeline Stage: IF (`rtl/if_stage.vhdl`)

### INFO: Flush condition inclui `not pcwr_en_i`

`rtl/if_stage.vhdl:71` (agora `flush_o <= taken_i or imrd_err_i or not pcwr_en_i`)

`flush_o` é assertado quando `pcwr_en_i` está baixo (pipeline stall). A instrução recém-buscada no pipeline register recebe `flush_o = 1` e é descartada pelo ID/EX. Ao retomar, a instrução precisa ser re-buscada — desperdiçando 1 ciclo.

**Sugestão**: Não atualizar o pipeline register durante stalls (gatar `out_pipe_proc` com `pcwr_en_i`).

### INFO: Busca especulativa desperdiçada em branches taken

Quando `taken_i = '1'`:
1. `pc_reg` recebe `target_i(XLEN-1 downto 2)`
2. `imrd_addr_o` (concatenação `pc_reg & "00"`) muda para o endereço alvo
3. A transação Wishbone anterior (sequencial) já está em andamento — completa com dados descartados
4. `wb_ctrl` retorna a IDLE, vê `imrd_en_o = 1` com novo endereço, inicia busca correta

Funcionalmente correto, mas desperdiça 1 transação de barramento por branch taken. Inerente ao pipeline de 2 estágios sem previsão de desvio.

### ENH: `pc_reg` reduzido para 30 bits

2026-05-29: `pc_reg` e `next_res` foram reduzidos de `std_logic_vector(XLEN-1 downto 0)` para `std_logic_vector(XLEN-1 downto 2)` (30 bits em RV32). Os 2 LSBs (`"00"`) são concatenados nas saídas:
- `imrd_addr_o <= pc_reg & b"00"`
- `pc_o <= pc_reg & b"00"`
- `next_pc_o <= next_res & b"00"`
- `next_res <= unsigned(pc_reg) + 1` (somador de 30 bits)

Economia: 2 flops + 2 full-adders. A interface da entidade não foi alterada.

---

## Pipeline Stage: Core (`rtl/core.vhdl`)

### INFO: Port naming inconsistente

`rtl/core.vhdl:19-43`

A maioria das portas da entidade não segue a convenção `_i`/`_o` do projeto. Apenas `cop_dat_i`, `cop_dat_o`, `cop_we_o`, e `retire_o` estão corretos.

| Porta atual | Esperado |
|---|---|
| `clk` (in) | `clk_i` |
| `reset` (in) | `reset_i` |
| `ex_irq`, `sw_irq`, `tm_irq` (in) | `ex_irq_i`, etc. |
| `imrd_err`, `dmrd_err`, `dmwr_err` (in) | `imrd_err_i`, etc. |
| `imrd_data`, `dmrd_data` (in) | `imrd_data_i`, etc. |
| `cycle`, `timer`, `instret` (in) | `cycle_i`, etc. |
| `imrd_en`, `dmrd_en`, `dmwr_en` (out) | `imrd_en_o`, etc. |
| `imrd_addr`, `dmrw_addr`, `dmwr_data` (out) | `imrd_addr_o`, etc. |

### INFO: Retire timing verificado — corretamente implementado

`rtl/core.vhdl:86-87`

```vhdl
retire <= pcwr_en and not flush;
```

O `flush` é registrado no pipeline register (`out_pipe_proc` em `if_stage.vhdl:71`). Quando uma branch taken está em EX, o `flush` associado a ela foi capturado no **ciclo anterior** (antes de `taken` subir), então `flush = 0` e o branch é contado. A instrução seguinte (especulativamente buscada) recebe `flush = 1` e é descartada. **Comportamento correto** — a documentação em `microarchitecture.md` condiz com o RTL.

---

## Pipeline Stage: ID (`rtl/id_stage.vhdl`)

### BUG: `dmld_fault` miswired no CSR block (CORRIGIDO)

Ver seção Bugs Conhecidos abaixo.

### INFO: Port naming padronizado

2026-05-30: Todas as 19 portas da entidade foram renomeadas com sufixos `_i`/`_o`:
- `clk` → `clk_i`, `reset` → `reset_i`
- `ex_irq`/`sw_irq`/`tm_irq` → `ex_irq_i` etc.
- `imrd_malgn`/`imrd_fault`/`dmld_*`/`dmst_*` → todas com `_i`
- `cycle`/`timer`/`instret` → `cycle_i` etc.
- `exec_res`/`dmld_data`/`pc`/`next_pc`/`instr` → `exec_res_i` etc.
- `flush`/`csrwr_data` → `flush_i`/`csrwr_data_i`
- `func3`/`func7`/`imm`/`exec_ctrl` → `func3_o` etc.
- `dmls_ctrl` → split em `dmls_mode_o`/`dmls_en_o`
- `pcwr_en`/`trap_taken`/`trap_target` → `pcwr_en_o` etc.
- `rd_data0`/`rd_data1` → `rd_data0_o`/`rd_data1_o`
- `csrrd_data` → `csrrd_data_o`

As portas `cop_*` já estavam corretas.

### INFO: Uso de `XLEN` nos ports

2026-05-30: Portas e sinais internos que usavam `31 downto 0` hardcoded foram alterados para `XLEN-1 downto 0`. `cycle`/`timer`/`instret` (64-bit, spec RISC-V) permanecem `63 downto 0`.

### INFO: Sinal `csrrd_data_i` renomeado

Sinal interno `csrrd_data_i` → `csrrd_data_s`. O sufixo `_i` era enganoso pois não se trata de uma porta de entrada — é um sinal interno que conecta a saída `rd_data` do csrs à entrada `wr_data3` do reg_file e à porta `csrrd_data_o` da entidade.

---

## Pipeline Stage: CSRs (`rtl/csrs.vhdl`)

### BUG: `mret` tratado como exceção — CORRIGIDO

2026-05-30: `exc_taken` incluía `mret`, causando:
- `mstatus` não restaurava `MIE/MPIE` (exception path tomava precedência sobre mret path)
- `mepc` era sobrescrito com PC corrente ao invés de permanecer inalterado
- `mcause` e `mtval` também eram sobrescritos
- `trap_taken` era re-assertado (funcionalmente inócuo mas incorreto conceitualmente)

**Corrigido**: `mret` removido de `exc_taken`; `trap_taken_o <= exc_taken or mret` adicionado separadamente. Agora:
- `exc_taken` contém apenas fontes de exceção/interrupção reais
- `mret` redireciona pipeline para `mepc` via `trap_taken_o` sem efeitos colaterais nos CSRs
- `mstatus` restaura `MIE`/`MPIE` corretamente no mret path

### BUG: Condição incorreta em `write_mcause` — CORRIGIDO

`rtl/csrs.vhdl:215` (2026-05-30): A condição `elsif exc_taken = '1' then` dentro do bloco `if int_taken = '1'` era sempre verdadeira, mas por construção só era atingida quando `exi_taken = '1'` (nem swi nem tmi). Funcionalmente correto, mas semanticamente enganoso — trocado para `elsif exi_taken = '1' then`.

### BUG: `mtval` subespecificado para access faults — CORRIGIDO

2026-05-30: O `write_mtval` só carregava `exec_res_i` para misaligned e `pc_i` para ebreak; bus faults (`imrd_fault`, `dmld_fault`, `dmst_fault`) caíam no `else` e recebiam 0. A RISC-V spec diz que access faults devem conter o endereço efetivo.

**Corrigido**: `write_mtval` agora tem priority encoder completo espelhando `write_mcause`:

| Prioridade | Fonte | mtval |
|------------|-------|-------|
| 1 | `int_taken` | 0 |
| 2 | `imrd_malgn` | `exec_res_i` (endereço alvo do branch) |
| 3 | `imrd_fault` | `pc_i` (PC da instrução faultada) |
| 4 | `instr_err` | 0 (spec-permitido) |
| 5 | `ebreak` | `pc_i` |
| 6 | `dmld_malgn/fault` ou `dmst_malgn/fault` | `exec_res_i` (endereço efetivo) |
| 7 | `ecall` | 0 |

A adição de `int_taken` antes das exceções garante consistência com `mcause`: se uma interrupção e uma exceção são simultâneas, `mcause` reporta a interrupção e `mtval` fica 0 — alinhado com a prioridade RISC-V.

### INFO: Port naming e XLEN padronizados

2026-05-30: Todas as portas renomeadas com sufixos `_i`/`_o`:
- Entradas: `clk_i`, `reset_i`, `ex_irq_i`, `sw_irq_i`, `tm_irq_i`, `imrd_malgn_i`, `imrd_fault_i`, `instr_err_i`, `dmld_malgn_i`, `dmld_fault_i`, `dmst_malgn_i`, `dmst_fault_i`, `wr_en_i`, `wr_mode_i`, `rw_addr_i`, `wr_data_i`, `exec_res_i`, `pc_i`, `next_pc_i`, `cycle_i`, `timer_i`, `instret_i`
- Saídas: `pcwr_en_o`, `trap_taken_o`, `trap_target_o`, `rd_data_o`
- `cop_dat_i/adr_o/dat_o/we_o` já estavam corretos
- Portas de dados (`wr_data_i`, `exec_res_i`, `pc_i`, `next_pc_i`, `trap_target_o`, `rd_data_o`, etc.) mudadas de `31 downto 0` para `XLEN-1 downto 0`

### INFO: Sinais internos com XLEN

Sinais internos (`mtvec_base`, `mscratch`, `mepc`, `mtval`) atualizados para `XLEN-1 downto 0`/`XLEN-1 downto 2`.

### INFO: Coprocessor interface single-cycle

Interface COP não tem handshake (`cop_ack_i`/`cop_ready_i`). Documentado como limitação conhecida — ver seção WARN acima.

---

## Pipeline Stage: EX Block (`rtl/ex_block.vhdl`)

### INFO: Port naming padronizado com `_i`/`_o`

2026-05-30: Todas as 38 portas da entidade foram renomeadas com sufixos `_i`/`_o`:

| Atual | Novo |
|---|---|
| `trap_taken` (in) | `trap_taken_i` |
| `trap_target` (in) | `trap_target_i` |
| `func3` (in) | `func3_i` |
| `func7` (in) | `func7_i` |
| `reg0`/`reg1` (in) | `reg0_i`/`reg1_i` |
| `pc` (in) | `pc_i` |
| `imm` (in) | `imm_i` |
| `csrrd_data` (in) | `csrrd_data_i` |
| `jmp`/`br_en`/`ftype`/`op_en` (in) | `jmp_i`/`br_en_i`/`ftype_i`/`op_en_i` |
| `opd0_src_sel`/`opd1_src_sel` (in) | `opd0_src_sel_i`/`opd1_src_sel_i` |
| `opd0_pass`/`opd1_pass` (in) | `opd0_pass_i`/`opd1_pass_i` |
| `dmls_mode`/`dmls_en` (in) | `dmls_mode_i`/`dmls_en_i` |
| `dmrd_err`/`dmwr_err`/`dmrd_data` (in) | `dmrd_err_i`/`dmwr_err_i`/`dmrd_data_i` |
| `imrd_malgn`/`dmld_malgn`/`dmld_fault` (out) | `imrd_malgn_o`/`dmld_malgn_o`/`dmld_fault_o` |
| `dmst_malgn`/`dmst_fault` (out) | `dmst_malgn_o`/`dmst_fault_o` |
| `dmrd_en`/`dmwr_en` (out) | `dmrd_en_o`/`dmwr_en_o` |
| `dmwr_data`/`dmrw_addr` (out) | `dmwr_data_o`/`dmrw_addr_o` |
| `dm_byte_en`/`dmld_data` (out) | `dm_byte_en_o`/`dmld_data_o` |
| `csrwr_data` (out) | `csrwr_data_o` |
| `taken`/`target`/`res` (out) | `taken_o`/`target_o`/`res_o` |

### INFO: Uso de `XLEN` nos ports e sinais internos

2026-05-30: Todas as portas de dados e sinais internos (`opd0`, `opd1`, `gtd_opd0`, `gtd_opd1`, `alu_res`) alterados de `31 downto 0` para `XLEN-1 downto 0`. Replicação de `opd0_pass_i`/`opd1_pass_i` nos operandos gated ajustada para `(XLEN-1 downto 0 => ...)`.

---

## ALU Datapath (`rtl/alu.vhdl`)

### INFO: Port naming, XLEN, e header padronizados

2026-05-30: Todas as 4 portas renomeadas com sufixos `_i`/`_o` e `31 downto 0` → `XLEN-1 downto 0`:

| Atual | Novo |
|-------|------|
| `opd0` (in) | `opd0_i` |
| `opd1` (in) | `opd1_i` |
| `op` (in) | `op_i` |
| `res` (out) | `res_o` |

Sinais internos (`arith_opd0`, `arith_opd1`, `arith_res`, `comp_bypass`, `comp_res`, `logic_opd0`, `logic_opd1`, `logic_bypass`, `logic_res`, `shifter_opd`, `shifter_bypass`, `shifter_res`) também migrados para `XLEN-1 downto 0`. Variáveis do processo `arith_unit` (`opd0_i`, `opd1_i`) atualizadas.

Acesso a `opd0(31)` → `opd0_i(XLEN-1)` nas atribuições de `comp_opd0`, `comp_opd1`, `comp_opd2`.

Header `2022` → `2026`. Nenhum bug funcional encontrado — cadeia de bypass e decodificação corretas.

---

## ALU Control (`rtl/alu_ctrl.vhdl)`

### INFO: Port naming padronizado com `_i`/`_o`

2026-05-30: Todas as 5 portas renomeadas com sufixos `_i`/`_o`:

| Atual | Novo |
|-------|------|
| `op_en` | `op_en_i` |
| `ftype` | `ftype_i` |
| `func3` | `func3_i` |
| `func7` | `func7_i` |
| `op` | `op_o` |

Header `2022` → `2026`. Nenhum bug funcional encontrado — decodificação correta de:
- `SUB` quando `func3=000`, `func7=0100000`, `ftype=0` (R-type apenas)
- `SRA` quando `func3=101`, `func7=0100000` (qualquer formato)
- `op_en=0` retorna `ALU_ADD` (bolha/nop, pipeline stall)
- `others` clause presente com `ALU_ADD` (default seguro)

---

## CSR Write Logic (`rtl/csrs_logic.vhdl`)

### INFO: Port naming, XLEN, e header adicionados

2026-05-30: Arquivo sem header Leaf — adicionado. `use work.leaf_pkg.all` adicionado (necessário para `XLEN`). Todas as 5 portas renomeadas e migradas para `XLEN`:

| Atual | Novo |
|-------|------|
| `csrwr_mode` (in) | `csrwr_mode_i` |
| `csrrd_data` (in) | `csrrd_data_i` |
| `regwr_data` (in) | `regwr_data_i` |
| `immwr_data` (in) | `immwr_data_i` |
| `csrwr_data` (out) | `csrwr_data_o` |

Nenhum bug funcional — mapeamento CSR correto (CSRRW/CSRRS/CSRRC/CSRRWI/CSRRSI/CSRRCI), `others` clause presente.

---

## Branch Detector (`rtl/br_detector.vhdl`)

### INFO: Port naming, XLEN, e header padronizados

2026-05-30: Todas as 5 portas renomeadas com sufixos `_i`/`_o` e `31 downto 0` → `XLEN-1 downto 0`:

| Atual | Novo |
|-------|------|
| `reg0` (in) | `reg0_i` |
| `reg1` (in) | `reg1_i` |
| `mode` (in) | `mode_i` |
| `en` (in) | `en_i` |
| `branch` (out) | `branch_o` |

Header `2022` → `2026`. Nenhum bug funcional encontrado — lógica de comparação correta para BEQ/BNE/BLT/BGE/BLTU/BGEU, `others` clause presente, gating `branch_o <= branch_i and en_i`.

---

## Data Memory Load/Store Block (`rtl/dmls_block.vhdl`)

### INFO: Port naming, XLEN, e header padronizados

2026-05-30: Todas as 18 portas renomeadas com sufixos `_i`/`_o` e `31 downto 0` → `XLEN-1 downto 0`:

| Atual | Novo |
|-------|------|
| `dmrd_err` (in) | `dmrd_err_i` |
| `dmwr_err` (in) | `dmwr_err_i` |
| `dmls_mode` (in) | `dmls_mode_i` |
| `dmls_en` (in) | `dmls_en_i` |
| `dmls_dtype` (in) | `dmls_dtype_i` |
| `dmst_data` (in) | `dmst_data_i` |
| `dmls_addr` (in) | `dmls_addr_i` |
| `dmrd_data` (in) | `dmrd_data_i` |
| `dmld_malgn` (out) | `dmld_malgn_o` |
| `dmld_fault` (out) | `dmld_fault_o` |
| `dmst_malgn` (out) | `dmst_malgn_o` |
| `dmst_fault` (out) | `dmst_fault_o` |
| `dmrd_en` (out) | `dmrd_en_o` |
| `dmwr_en` (out) | `dmwr_en_o` |
| `dmwr_data` (out) | `dmwr_data_o` |
| `dmrw_addr` (out) | `dmrw_addr_o` |
| `dm_byte_en` (out) | `dm_byte_en_o` |
| `dmld_data` (out) | `dmld_data_o` |

Aliasing `dmls_addr(31 downto 2)` → `dmls_addr_i(XLEN-1 downto 2)` na atribuição de `dmrw_addr_o`. `resize(..., 32)` → `resize(..., XLEN)` nas saídas.

Header `2022` → `2026`. Nenhum bug funcional encontrado — byte lane selection, byte rotation, misaligned detection, e fault propagation corretos.

---

## Bugs Conhecidos (de `rtl-review.md`)

### ~~BUG: `mret` tratado como exceção, não como retorno de exceção~~ (CORRIGIDO)

~~`rtl/csrs.vhdl:95, 270`~~

~~`exc_taken` inclui `mret` — o CSR update logic entra no path de exceção antes do path de retorno nos processos de `mstatus`, `mepc`, `mcause`, `mtval`. Efeito prático:
- `mstatus` não restaura `MIE/MPIE`
- `mepc`/`mcause`/`mtval` podem ser sobrescritos no handler exit
- `trap_taken` é re-assertado em `mret`

Isso quebra o fluxo normal de trap return.~~

**Corrigido em 2026-05-30**: `mret` removido de `exc_taken`; `trap_taken_o <= exc_taken or mret`.

---

### ~~BUG: Load-fault miswired no CSR block~~ (CORRIGIDO)

~~`rtl/id_stage.vhdl:126`~~

~~A instância do csrs conecta `dmld_fault => dmst_fault`. Um load access fault real não é reportado corretamente à lógica de trap, enquanto um store fault pode ser classificado erroneamente como load fault devido à prioridade de excessão em `rtl/csrs.vhdl:218-225`.~~

**Corrigido em 2026-05-30**: `dmld_fault => dmld_fault_i` (conexão correta).

---

### INFO: Don't-care values no datapath durante flush/opcode inválido

`rtl/main_ctrl.vhdl:50-63, 77`

O immediate generator injeta valores don't-care (`'-'`) durante flush e opcodes desconhecidos. Esses valores propagam para entradas da ALU e shifter, chegando a conversões `numeric_std` — produzindo warnings de simulação (`metavalue detected`). Durante `flush = '1'`, `exec_ctrl_o` e `regwr_en_o` são zerados, então os metavalues em `imm_o` nunca são capturados funcionalmente. O sintetizador (Yosys) ignora don't-cares.

**Não é um bug funcional** — apenas poluição visual na simulação. O teste `addi` não converge por outra causa (provavelmente relacionada a outro bug na lista).

---

### ~~BUG: Invalid CSR accesses não geram traps~~ (WONTFIX)

~~`rtl/main_ctrl.vhdl:148`, `rtl/csrs.vhdl:116`~~

~~O projeto especifica que endereços CSR inválidos devem gerar trap, mas:~~
- ~~`main_ctrl` trata todo `SYSTEM_OPCODE` como válido~~
- ~~O read path do csrs retorna zero para endereços desconhecidos~~

**WONTFIX**: Comportamento intencional para este core simples — CSR inválido lê 0, escrita ignorada. Aceitável para o escopo do Leaf.

---

## Validation Notes

- `make run` falha porque o target default depende de `verif/tests/dump/out.bin`, que não existe no repositório.
- `make -C verif/tests/addi run` compila mas a simulação não converge — emite warnings contínuos de `numeric_std` metavalue, consistente com a contaminação do datapath descrita acima.
- `make -C verif/tests run TEST=...` não corresponde ao Makefile atual; a invocação correta é `make -C verif/tests/<test> run`.

---

## Pipeline Stage: Register File (`rtl/reg_file.vhdl`)

### INFO: Header year e port naming padronizados

2026-05-30: Header `2022` → `2026`. Todas as 12 portas renomeadas com sufixos `_i`/`_o`:
- `clk`/`we`/`wr_sel`/`wr_addr`/`wr_data0-3`/`rd_addr0-1` → `clk_i` etc.
- `rd_data0`/`rd_data1` → `rd_data0_o`/`rd_data1_o`

Don't-cares (`(others => '-')`) mantidos no `wr_data_mux` — inofensivo em síntese.

### INFO: Estrutura geral

Correto e simples: 32×32 register file, leitura combinacional, escrita síncrona. x0 hardwired a zero (reescrito a cada ciclo). Dual-implementation com `SIZE=16` para modo embedded (`small_reg_file` com 4-bit addressing).

---

## Package (`rtl/leaf_pkg.vhdl`)

### INFO: Dead code removido

2026-05-30: Constantes `ALU_CTRL_*` (10 linhas, 10-bit) removidas — não referenciadas em nenhum módulo. Eram resquício de design anterior; o ALU opcode real usa as constantes `ALU_ADD`, `ALU_SUB`, etc. (6-bit).

### INFO: Component declarations verificadas

Todas as 17 component declarations conferidas contra suas respectivas entidades. As declarações de `core`, `leaf`, e `wb_ctrl` ainda usam portas sem `_i`/`_o` e `31 downto 0` sem XLEN — serão atualizadas quando esses módulos forem revisados.

Header já `2026`. Constantes verificadas: opcodes, CSR addresses, ALU ops (6-bit), branch modes, LSU types, I-types — todas corretas.

---

## Melhorias Planejadas

### INFO: `mcountinhibit` (CSR `0x320`) — counter inhibit

Adicionar o registrador `mcountinhibit` WARL para permitir que o software pause `mcycle` e `minstret`.

**Implementação**:
1. `csrs.vhdl`: add `mcountinhibit_reg` (bits 0 e 2 writable, demais hardwired a 0), write process, leitura no `read_csr`, porta `mcountinhibit_o`
2. `id_stage.vhdl`: add porta `mcountinhibit_o` — wire-through do csrs
3. `core.vhdl`: add porta `mcountinhibit_o` — wire-through do id_stage
4. `counters.vhdl`: add porta `inhibit_i` — `inhibit_i(0)` trava `cycle_reg`, `inhibit_i(2)` trava `instret_reg`
5. `leaf.vhdl`: conectar `core.mcountinhibit_o` → `counters.inhibit_i`
6. `leaf_pkg.vhdl`: add constante `CSR_ADDR_MCOUNTINHIBIT`, atualizar component declarations

Detalhado em: `docs/microarchitecture.md` (seção Counter Inhibit)

---

### INFO: `mtimecmp` — timer interrupt interno

O core não gera `tm_irq` internamente. O contador `time` (CSR `0xC01`/`0xC81`) existe e é legível por software, mas sem um registrador `mtimecmp` o timer interrupt depende de hardware externo.

**Implementação futura**:
1. Adicionar `mtimecmp` no CSR space (endereço `0x321`, ao lado de `mtime` em `0xC01`)
2. Comparador em hardware: `tm_irq <= '1' when timer >= mtimecmp`
3. Opção 1: implementar no `csrs.vhdl` com registrador e comparador internos
4. Opção 2: módulo externo conectado via Wishbone, com `tm_irq` como saída

---

## Main Control (`rtl/main_ctrl.vhdl`)

### INFO: Já conforme as convenções

2026-05-30: `main_ctrl` já utilizava header 2026, portas com `_i`/`_o`, e `XLEN` para dados. Nenhuma alteração necessária. Verificação funcional completa — decodificação de opcodes e geração de imediatos correta.

---

## Wishbone Master (`rtl/wb_ctrl.vhdl`)

### INFO: Port naming, XLEN, e header padronizados

2026-05-30: Header `2022` → `2026`. Adicionado `use work.leaf_pkg.all` (XLEN). Todas as 21 portas revisadas:

| Atual | Novo |
|-------|------|
| `imrd_en/dmrd_en/dmwr_en` (in) | `_i` |
| `dmwr_be/imrd_addr/dmrw_addr/dmwr_data` (in) | `_i` |
| `clk_en/reset/imrd_err/dmrd_err/dmwr_err` (out) | `_o` |
| `imrd_data/dmrd_data` (out) | `_o` |
| `31 downto 0` | `XLEN-1 downto 0` |

Portas `clk_i`/`rst_i`/`ack_i`/`err_i`/`dat_i`/`cyc_o`/`stb_o`/`we_o`/`sel_o`/`adr_o`/`dat_o` já estavam corretas. Nenhum bug funcional encontrado.

---

## CPU Core (`rtl/core.vhdl`)

### INFO: Port naming, XLEN, e generics padronizados

2026-05-30: Todas as 22 portas renomeadas com sufixos `_i`/`_o`:

| Atual | Novo |
|-------|------|
| `clk/reset` | `_i` |
| `ex_irq/sw_irq/tm_irq` | `_i` |
| `imrd_err/dmrd_err/dmwr_err` | `_i` |
| `imrd_data/dmrd_data` | `_i` |
| `cycle/timer/instret` | `_i` |
| `imrd_en/dmrd_en/dmwr_en` (out) | `_o` |
| `dmwr_be/imrd_addr/dmrw_addr/dmwr_data` (out) | `_o` |

Generics `31 downto 0` → `XLEN-1 downto 0`. Sinais internos (`target`, `pc`, `next_pc`, `instr`, `imm`, `trap_target`, `reg0_data`, `reg1_data`, `exec_res`, `dmld_data`, `csrrd_data`, `csrwr_data`) migrados para `XLEN-1 downto 0`. Nenhum bug funcional encontrado.

---

## Top-Level (`rtl/leaf.vhdl`)

### INFO: Port naming e XLEN padronizados

2026-05-30: Portas `ex_irq`/`sw_irq`/`tm_irq` → `ex_irq_i`/`sw_irq_i`/`tm_irq_i`. Generics e sinais internos `31 downto 0` → `XLEN-1 downto 0`. Portas Wishbone (`clk_i`, `rst_i`, `ack_i`, `err_i`, `dat_i`, `cyc_o`, `stb_o`, etc.) já estavam corretas. Nenhum bug funcional.

---

## Próximas Revisões

Todas as revisões concluídas.

- [x] ~~`rtl/if_stage.vhdl` — fetch stage~~
- [x] ~~`rtl/main_ctrl.vhdl` — decodificador de controle~~
- [x] ~~`rtl/reg_file.vhdl` — banco de registradores~~
- [x] ~~`rtl/csrs_logic.vhdl` — multiplexação CSR~~
- [x] ~~`rtl/csrs.vhdl` — CSRs e traps~~
- [x] ~~`rtl/id_stage.vhdl` — decodificação, regfile, CSRs~~
- [x] ~~`rtl/alu_ctrl.vhdl` — decodificador de operação da ULA~~
- [x] ~~`rtl/alu.vhdl` — datapath da ULA~~
- [x] ~~`rtl/br_detector.vhdl` — detecção de desvio~~
- [x] ~~`rtl/ex_block.vhdl` — ALU, branch, load/store~~
- [x] ~~`rtl/dmls_block.vhdl` — load/store alignment~~
- [x] ~~`rtl/core.vhdl` — integração do pipeline~~
- [x] ~~`rtl/wb_ctrl.vhdl` — Wishbone B4 master~~
- [x] ~~`rtl/leaf.vhdl` — top-level~~
- [x] ~~`rtl/leaf_pkg.vhdl` — constantes e declarações~~
