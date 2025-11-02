# Testes de Conformidade da Arquitetura

## Testes de Conformidade

Para assegurar que o Leaf esteja operando conforme as especificações da arquitetura RISC-V, foram realizadas verificações utilizando [um conjunto de testes](https://github.com/riscv-non-isa/riscv-arch-test/tree/old-framework-2.x) de conformidade.

## Como Executar os Testes

Para executar os testes de conformidade, siga as instruções abaixo:

1. Primeiramente, deve-se clonar o repositório do conjunto de testes:

```bash
# Apenas a versão antiga (old-framework-2.x) é suportada por enquanto.
git clone https://github.com/riscv-non-isa/riscv-arch-test/ -b old-framework-2.x
```

2. Após baixar os testes em um diretório do seu computador, execute o script `run.sh` passando o diretório como argumento:
```bash
# <diretório> é o local para o qual o repostiório foi clonado.
./run.sh <diretório>/riscv-arch-test/
```

## Resultados Esperados

Resultados esperados para o conjunto básico de instruções:

```bash
Check add-01                    ... OK 
Check addi-01                   ... OK 
Check and-01                    ... OK 
Check andi-01                   ... OK 
Check auipc-01                  ... OK 
Check beq-01                    ... OK 
Check bge-01                    ... OK 
Check bgeu-01                   ... OK 
Check blt-01                    ... OK 
Check bltu-01                   ... OK 
Check bne-01                    ... OK 
Check fence-01                  ... OK 
Check jal-01                    ... OK 
Check jalr-01                   ... OK 
Check lb-align-01               ... OK 
Check lbu-align-01              ... OK 
Check lh-align-01               ... OK 
Check lhu-align-01              ... OK 
Check lui-01                    ... OK 
Check lw-align-01               ... OK 
Check or-01                     ... OK 
Check ori-01                    ... OK 
Check sb-align-01               ... OK 
Check sh-align-01               ... OK 
Check sll-01                    ... OK 
Check slli-01                   ... OK 
Check slt-01                    ... OK 
Check slti-01                   ... OK 
Check sltiu-01                  ... OK 
Check sltu-01                   ... OK 
Check sra-01                    ... OK 
Check srai-01                   ... OK 
Check srl-01                    ... OK 
Check srli-01                   ... OK 
Check sub-01                    ... OK 
Check sw-align-01               ... OK 
Check xor-01                    ... OK 
Check xori-01                   ... OK 
--------------------------------
 OK: 38/38 RISCV_TARGET=leaf RISCV_DEVICE=I XLEN=32
```

Resultados esperados para o conjunto de instruções privilegiado:

```bash
Check ebreak                    ... OK 
Check ecall                     ... OK 
Check misalign1-jalr-01         ... OK 
Check misalign2-jalr-01         ... IGNORE 
Check misalign-beq-01           ... IGNORE 
Check misalign-bge-01           ... IGNORE 
Check misalign-bgeu-01          ... IGNORE 
Check misalign-blt-01           ... IGNORE 
Check misalign-bltu-01          ... IGNORE 
Check misalign-bne-01           ... IGNORE 
Check misalign-jal-01           ... IGNORE 
Check misalign-lh-01            ... OK 
Check misalign-lhu-01           ... OK 
Check misalign-lw-01            ... OK 
Check misalign-sh-01            ... OK 
Check misalign-sw-01            ... OK 
--------------------------------
 OK: 16/16 RISCV_TARGET=leaf RISCV_DEVICE=privilege XLEN=32
```
