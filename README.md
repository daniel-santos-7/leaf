# :leaves: Leaf

Um pequeno núcleo RISC-V 32-bit de baixo consumo.

![RTL](/.github/rtl.png)

## Recursos

- Suporte a especificação base RISC-V (RV32I)
- Pipeline de 2 estágios IF / ID & EX

## Teste de conformidade

### Requisitos:

- [GHDL](https://github.com/ghdl/ghdl)
- [RISC-V GNU Compiler Toolchain (32 bits)](https://github.com/riscv/riscv-gnu-toolchain)

### Instruções:

Para a execução dos testes de conformidade, os seguintes procedimentos devem ser seguidos:

- Clone o [repositório](https://github.com/riscv/riscv-arch-test) com o conjunto de testes disponibilizado pela comunidade RISC-V:

```bash

$ git clone https://github.com/riscv/riscv-arch-test

```

- Clone o repositório deste projeto e execute o arquivo **scripts.sh** especificando o local em que o conjunto de testes foi armazenado:

```bash

$ ./scripts.sh arch-test ../riscv-arch-test/

```

---

<p align="center">2021</p>