# :leaves: Leaf

Leaf é um pequeno processador RISC-V de 32 bits adequado para aplicações que tenham como principal requisito a economia de recursos, em detrimento de elevado poder de processamento, como as aplicações em Internet das Coisas (IoT).

## :star: Recursos

- Suporte a especificação base RISC-V (RV32I)
- Pipeline de 2 estágios (busca de instruções / decodificação e execução)
- Interface compatível com o protocolo Wishbone B4

## :file_folder: Diretórios

Este repositório apresenta a seguinte estrutura de diretórios:

Diretório        | Descrição
---------------- | ----------------
[cpu](/cpu/)     | Projeto do processador Leaf
[soc](/soc/)     | Exemplo de um simples (*System On Chip*) sintetizável em FPGA com o processador Leaf
[sim](/sim/)     | Exemplo de um sistema não sintetizável (simulador) com um processador Leaf
[uart](/uart/)   | Projeto de um módulo UART (interface serial)
[sw](/sw)        | Exemplos de programas e recursos para programação

## :computer: Ambiente de desenvolvimento

Este projeto tem sido desenvolvido com o auxílio das seguintes ferramentas:

- [GHDL v0.37](https://github.com/ghdl/ghdl): ferramenta *open-source* para interpretação e simulação de projetos desenvolvidos com VHDL.
- [GtkWave](http://gtkwave.sourceforge.net/): software para visualização de formatos de ondas digitais.
- [GNU Make](https://www.gnu.org/software/make/): interpretador de Makefiles, utilizado para execução de scripts e compilações.

Em qualquer sistema operacional baseado no linux, essas ferramentas podem ser instaladas com facilidade por meio de um gerenciador de pacotes.

```bash
# apt é o gerenciador de pacotes padrão de distros beseadas no Debian, como o Ubuntu
sudo apt install ghdl gtkwave make
```

---

<p align="center">2022</p>
