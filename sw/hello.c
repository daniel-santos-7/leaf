#include <string.h>

void uart_send_char(const char c);

char* UART_TX_ADDRESS = (char*)0x00000000;

int main() {

    uart_send_char('H');
    uart_send_char('E');
    uart_send_char('L');
    uart_send_char('L');
    uart_send_char('O');

    return 0;
}

void uart_send_char(const char c) {
    while((*UART_TX_ADDRESS) != 255);

    (*UART_TX_ADDRESS) = c;
}