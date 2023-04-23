// leaf.h
#ifndef LEAF_H
#define LEAF_H

void int2string(int num, char *str);

void uart_send_string(char *str);
void uart_send_integer(int num);

void uart_receive_string(char *str);
int uart_receive_integer();

#endif // LEAF_H