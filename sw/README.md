# :computer: Ferramentas de programação

Este diretório apresenta recursos para programação do processador Leaf e alguns exemplos de softwares já desenvolvidos com a linguagem de programação C e Assembly.

## Lista de softwares testados

Diretório   					| Descrição
------------------------------- | -------------------------------
[array_sort](/sw/array_sort/)  	| Algoritmo básico para ordenar um vetor
[boot](/sw/boot/)        		| Simples bootloader
[coremak](/sw/coremark/)     	| Benchmark coremark
[data_io](/sw/data_io/)   		| Teste de entrada e saída de dados
[factorial](/sw/factorial)   	| Algoritmo para o cálculo de 10!
[fibonacci](/sw/fibonacci/)   	| Algoritmo para gerar primeiros termos da serie de Fibonacci
[tests_asm](/sw/tests_asm/)   	| Testes em assembly
[tests_c](/sw/tests_c/)   		| Testes em linguagem c

## Desenvolvimento de um programa em C

Para desenvolver um novo programa para o processador Leaf, é necessário ter instalado na sua máquina o [conjunto de ferramentas de compilação para a arquitetura RISC-V](https://github.com/riscv-collab/riscv-gnu-toolchain). A instalação dessas ferramentas em um sistema operacional Linux pode ser realizada como se segue:

```bash
# clonar repositório das ferramentas
git clone https://github.com/riscv-collab/riscv-gnu-toolchain
```

```bash
# instalar pacotes adicionais necessários
sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
```

```bash
# acessar diretório do repositório
cd ./riscv-gnu-toolchain
```

```bash
# compilar e instalar ferramentas
./configure --prefix=/opt/riscv --with-abi=ilp32 --with-arch=rv32i
make
```

Com as ferramentas de compilaçao instaladas no seu computador, crie uma nova pasta para armazenar o código fonte do programa a ser desenvolvido.

```bash
mkdir my_software && cd my_software
```

Nessa pasta, adicione os arquivos de códigos.

```bash
touch main.c
```

```c
// main.c
#include <stdio.h>

void main() {
	printf("Hello!\n");
}
```

Para facilitar a compilação, pode ser interessante criar um arquivo [Makefile](https://www.gnu.org/software/make/manual/make.html) na pasta do novo programa. Esse arquivo pode incluir um [template padrão](/sw/common/common.mk) disponível na pasta [common](/sw/common/), nesse caso, o Makefile pode ser desenvolvido rapidamente sobrescrevendo as variáveis já definidas nesse template.

```Makefile
# variável com o nome do programa
APP_EXE  = my_software

# incluir template
include ../common/common.mk
```

Abaixo estão as variáveis com valores pré-definidos no arquivo [common.mk](/sw/common/common.mk):

```Makefile

# arquivo CRT0 com rotinas básicas para suportar programas desenvolvidos em linguagem C
STARTUP  ?= ../common/crt0.S

# implementação de funções básicas, necessárias para o funcionamento da biblioteca padrão (NewLib)
SYSCALLS ?= ../common/syscalls.c

# script de linker para compilação
LDSCRIPT ?= ../common/sim.ld

# nome do programa
APP_EXE  ?= out

# código fonte do programa
APP_SRC  ?= $(wildcard ./*.c) $(wildcard ./*.cpp) $(wildcard ./*.s) $(wildcard ./*.S) $(STARTUP) $(SYSCALLS)

```

Vale salientar que se torna necessária a ferramenta [GNU Make](https://www.gnu.org/software/make/) para compilar o programa por meio de um Makefile.

```bash
# instalação da ferramenta Make via apt
sudo apt install make
```

Para compilar o programa, pode-se executar o seguinte comando:
```bash
# compilar programa
make all
```

Se o arquivo [common.mk](/sw/common/common.mk) for utilizado, após a compilação, serão gerados arquivos com as extenções .elf .bin e .debug.

## Execução de um programa

É possivel executar um programa por meio de simulação. Nesse caso, não é preciso sintetizar o processador em um FPGA, entretanto, o software [GHDL](https://github.com/ghdl/ghdl) é necessário para simular o funcionamento do sistema digital.

```bash
# instalar simulador GHDL via opt
sudo apt install ghdl
```

A execução por meio de simulação é lenta, desse modo, softwares complexos e que envolvam muitas operações numéricas podem demorar a obter resultados.

Para iniciar a execução de um programa, execute o seguinte comando na raiz do repositório, especificando a localização do arquivo .bin, gerado após a compilação do software.

```bash
# executar programa
make leaf_sim PROGRAM=sw/my_software/my_software.bin
```

Se um dispositivo FPGA estiver disponível, pode-se realizar a sintese lógica do simples [SoC](/soc/) disponível neste repositório. 

Esse sistema inclui, além do processador Leaf, uma memória de leitura e escrita (64kB), uma interface serial (UART) e uma memória de somente leitura que armazena um pequeno firmware. Esse firmware se trata de um simples [bootloader](/sw/boot/), o qual permite a programação do dispositivo por meio do módulo UART.

Os procedimentos para desenvolver um programa que será executado em hardware, são idênticos aos já apresentados. Todavia, durante a compilação, o script [soc.ld](/sw/common/soc.ld) deve ser especificado, isso possibilita que o compilador conheça o limite de memória disponível (apenas 64kB).

```Makefile
# variável com o nome do programa
APP_EXE  = my_software

# deve-se espeficiar o script adequado para o SoC
LDSCRIPT = ../common/soc.ld

# incluir template
include ../common/common.mk

```

Após compilar o programa, deve-se enviar o arquivo .bin gerado por meio da interface serial do dispotivo. Um [conversor USB para Serial TTL](https://shopee.com.br/Conversor-Usb-Serial-Rs232-Ttl-Pl2303hx-i.326746528.8939099476) pode ser conveniente para esse propósito.

No diretório [utils](/sw/utils/) podem ser encontrados scripts utilitários que facilitam a programação de um software via serial.

No Windows, pode-se executar o script [upload.ps1](/sw/utils/upload.ps1) especificando o binário que será enviado, conforme o exemplo:

```bash
# enviar programa via serial
.\upload.ps1 .\my_software.bin
```

Para distros Linux, recomenda-se utilizar o script [upload.py](/sw/utils/upload.py) para programação. Esse script tem por requisito o pacote [pyserial](https://pypi.org/project/pyserial/), o qual pode ser instalado por meio do gerenciador de pacotes do python:

```bash
# instalar dependência por meio do pip
pip install pyserial
```

após a instalação, é necessário configurar as permissões de leitura e escrita da porta serial:

```bash
# configurar permissões
sudo chmod 777 /dev/ttyUSB0
```

por fim, basta executar o script especificando o software a ser enviado:
```bash
# enviar programa
./upload.py ./my_software.bin
```
