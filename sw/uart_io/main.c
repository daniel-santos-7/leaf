#include "../common/leaf.h"

void main() {
    char name[20];
    int age;

    uart_send_string("Qual seu nome?\n");
    uart_receive_string(name);
    uart_send_string("Olá ");
    uart_send_string(name);
    uart_send_string("\n");

    uart_send_string("Qual sua idade?\n");
    age = uart_receive_integer();
    uart_send_string("Você tem ");
    uart_send_integer(age);
    uart_send_string(" anos\n");

    if (age >= 18) {
        uart_send_string("Você já de maior");
    } else {
        uart_send_string("Você ainda é de menor");
    }
}