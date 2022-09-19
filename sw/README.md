# Ferramentas de software

Este diretório apresenta alguns exemplos de softwares desenvolvidos para o processador Leaf.

## Lista de softwares testados

Pasta       | Descrição
----------- | ------
array_sort  | algoritmo básico para ordenar vetor
boot        | simples bootloader
coremak     | benchmark coremark
data_io 3   | teste de entrada e saída de dados
factorial   | algoritmo para o cálculo de 10! 
fibonacci   | algoritmo para gerar primeiros termos da serie de Fibonacci
tests_asm   | testes em assembly
tests_c 4   | testes em linguagem c

## Como desenvolver um programa em C

Para desenvolver um novo programa para o processador Leaf é necessário ter instalado na sua máquina o [conjunto de ferramentas de compilação](https://github.com/riscv-collab/riscv-gnu-toolchain) para a arquitetura RISC-V. A instalação dessas ferramentas no sistema operaciona Ubuntu pode ser realizada como se segue:

Clonar repositório do projeto:
```bash
git clone https://github.com/riscv-collab/riscv-gnu-toolchain
```

Instalar pacotes adicionais:
```bash
$ sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
```

Compilar e instalar ferramentas:
```bash
./configure --prefix=/opt/riscv --with-abi=ilp32 --with-arch=rv32i
make
```

Com as ferramentas de compilaçao instaladas no seu computador, crie uma nova pasta para armazenar o código fonte do programa a ser desenvolvido.

```bash
mkdir my_software
```

Nessa pasta, adicione os arquivos de códigos.

```c
// main.c
#include <stdio.h>

void main() {
	printf("Hello!\n");
}
```

Para facilitar a compilação, pode ser interessante criar um arquivo Makefile na pasta do novo programa. Esse arquivo pode incluir um [template padrão](/sw/common/common.mk) disponível na pasta [common](/sw/common/), nesse caso o Makefile pode ser criado rapidamente sobrescrevendo as variáveis definidas nesse template:

```Makefile
# variável com o nome do programa
APP_EXE  = my_software
include ../common/common.mk
```

O próximo passo é instalar a ferramenta [GNU Make](https://www.gnu.org/software/make/) e compilar o programa:

```bash
# para o Ubuntu
sudo apt install make
```

```bash
make all
```

Se nenhum problema for notificado, serão gerados arquivos com as extenções .elf .bin e .debug.

Finalmente, na raiz desse repositório, pode-se executar o programa desenvolvido por meio do simulador do sistema, especificando o arquivo .bin gerado.

```bash
make leaf_sim PROGRAM=sw/my_software/my_software.bin
```