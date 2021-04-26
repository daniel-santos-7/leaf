# Leaf

Um pequeno núcleo RISC-V 32b de baixo consumo.

![RTL](/.github/rtl.png)

## Recursos

- Suporte a especificação base RISC-V (RV32I)
- Pipeline de 2 estágios (IF/ID & EX)

## Simulação

Execução dos testbench's ([GHDL](https://github.com/ghdl/ghdl) necessário):

```bash

$ mkdir work waves

$ ./scripts.sh test

```

Visualizar formas de ondas dos testes ([GTKWave](http://gtkwave.sourceforge.net/) necessário):

```bash

$ ./scripts.sh -w testbench

```