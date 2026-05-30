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
1. `pc_reg` recebe `target_i`
2. `imrd_addr_o` muda para o endereço alvo
3. A transação Wishbone anterior (sequencial) já está em andamento — completa com dados descartados
4. `wb_ctrl` retorna a IDLE, vê `imrd_en_o = 1` com novo endereço, inicia busca correta

Funcionalmente correto, mas desperdiça 1 transação de barramento por branch taken. Inerente ao pipeline de 2 estágios sem previsão de desvio.

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

## Bugs Conhecidos (de `rtl-review.md`)

### BUG: `mret` tratado como exceção, não como retorno de exceção

`rtl/csrs.vhdl:95, 270`

`exc_taken` inclui `mret` — o CSR update logic entra no path de exceção antes do path de retorno nos processos de `mstatus`, `mepc`, `mcause`, `mtval`. Efeito prático:
- `mstatus` não restaura `MIE/MPIE`
- `mepc`/`mcause`/`mtval` podem ser sobrescritos no handler exit
- `trap_taken` é re-assertado em `mret`

Isso quebra o fluxo normal de trap return.

---

### BUG: Load-fault miswired no CSR block

`rtl/id_stage.vhdl:126`

A instância do csrs conecta `dmld_fault => dmst_fault`. Um load access fault real não é reportado corretamente à lógica de trap, enquanto um store fault pode ser classificado erroneamente como load fault devido à prioridade de excessão em `rtl/csrs.vhdl:218-225`.

---

### BUG: Don't-care values no datapath durante flush/opcode inválido

`rtl/main_ctrl.vhdl:50-63, 77`

O immediate generator injeta valores don't-care (`'-'`) durante flush e opcodes desconhecidos. Esses valores propagam para entradas da ALU e shifter, chegando a conversões `numeric_std` — produzindo warnings de metavalue e comportamento de simulação instável. O teste `addi` não converge por causa disto.

---

### BUG: Invalid CSR accesses não geram traps

`rtl/main_ctrl.vhdl:148`, `rtl/csrs.vhdl:116`

O projeto especifica que endereços CSR inválidos devem gerar trap, mas:
- `main_ctrl` trata todo `SYSTEM_OPCODE` como válido
- O read path do csrs retorna zero para endereços desconhecidos

Isso mascara acessos CSR ilegais e desvia do comportamento ISA esperado.

---

## Validation Notes

- `make run` falha porque o target default depende de `verif/tests/dump/out.bin`, que não existe no repositório.
- `make -C verif/tests/addi run` compila mas a simulação não converge — emite warnings contínuos de `numeric_std` metavalue, consistente com a contaminação do datapath descrita acima.
- `make -C verif/tests run TEST=...` não corresponde ao Makefile atual; a invocação correta é `make -C verif/tests/<test> run`.

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

## Próximas Revisões

- [x] ~~`rtl/core.vhdl` — integração do pipeline~~ (revisado)
- [ ] `rtl/id_stage.vhdl` — decodificação, regfile, CSRs
- [ ] `rtl/ex_block.vhdl` — ALU, branch, load/store
- [ ] `rtl/main_ctrl.vhdl` — decodificador de controle
- [ ] `rtl/alu.vhdl` — datapath da ULA
- [ ] `rtl/alu_ctrl.vhdl` — decodificador de operação da ULA
- [ ] `rtl/br_detector.vhdl` — detecção de desvio
- [ ] `rtl/dmls_block.vhdl` — load/store alignment
- [ ] `rtl/csrs.vhdl` — CSRs e traps
- [ ] `rtl/csrs_logic.vhdl` — multiplexação CSR
- [ ] `rtl/reg_file.vhdl` — banco de registradores
- [ ] `rtl/leaf_pkg.vhdl` — constantes e declarações
