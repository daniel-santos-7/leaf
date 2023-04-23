#include "leaf.h"

char volatile *iostatus = (char *) 0x0;
char volatile *iodata = (char *) 0xC;

void int2string(int num, char *str) {
    int i = 0;
    int isNegative = 0;
    char tempStr[20]; // Tamanho máximo da string

    // Verifica se o número é negativo
    if (num < 0) {
        isNegative = 1;
        num = -num;
    }

    // Lida com o caso especial de 0
    if (num == 0) {
        str[i++] = '0';
        str[i] = '\0';
        return;
    }

    // Converte cada dígito em um caractere
    while (num != 0) {
        int digit = num % 10;
        tempStr[i++] = digit + '0';
        num = num / 10;
    }

    // Adiciona o sinal de negativo, se necessário
    if (isNegative) {
        tempStr[i++] = '-';
    }

    // Inverte a string
    int j;
    for (j = 0; j < i; j++) {
        str[j] = tempStr[i - 1 - j];
    }
    str[i] = '\0'; // Adiciona o caractere nulo para terminar a string
}

int string2int(char *str) {
    int resultado = 0; // Variável para armazenar o resultado da conversão
    int sinal = 1; // Variável para armazenar o sinal do número (1 para positivo, -1 para negativo)
    int i = 0; // Variável de iteração para percorrer a string

    // Ignora espaços em branco iniciais
    while (str[i] == ' ') {
        i++;
    }

    // Verifica o sinal do número
    if (str[i] == '-') {
        sinal = -1;
        i++;
    } else if (str[i] == '+') {
        i++;
    }

    // Percorre a string e acumula o valor numérico
    while (str[i] != '\0' && str[i] >= '0' && str[i] <= '9') {
        resultado = resultado * 10 + (str[i] - '0');
        i++;
    }

    return resultado * sinal;
}

void uart_receive_string(char *str) {
  for (int i = 0; str[i] != '\0'; i++) {  
    while((*iostatus & 0x4) != 0x4);
    str[i] = *iodata;
    if (str[i] == '\n') {
        str[i] = '\0';
        break;
    }
  }
}

void uart_send_string(char *str) {
  for(int i = 0; str[i] != '\0'; i++) {
    while((*iostatus & 0x20) != 0x20);
    *iodata = str[i];
  }
}

void uart_send_integer(int num) {
    char str[20];
    int2string(num, str);
    uart_send_string(str);
}

int uart_receive_integer() {
    char str[20];
    uart_receive_string(str);
    return string2int(str);
}