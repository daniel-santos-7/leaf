char volatile *iostatus = (char *) 0x0;
char volatile *iodata = (char *) 0xC;

void uart_send_string(char *str) {
  for(int i = 0; str[i] != '\0'; i++) {
    while((*iostatus & 0x20) != 0x20);
    *iodata = str[i];
  }
}

// void uart_receive_string(char *str) {
//   for (int i = 0; str[i] != '\0'; i++) {  
//     while((*iostatus & 0x4) != 0x4);
//     str[i] = *iodata;
//   }
// }

// void uart_send_char(char c) {
//   while((*iostatus & 0x20) != 0x20);
//   *iodata = c;
// }

// char uart_receive_char() {
//   while((*iostatus & 0x4) != 0x4);
//   return *iodata;
// }

void main() {
  while(1) {
    uart_send_string("Leaf\n");
  }
  // char *halt = (char *) 0x10;
  // *halt = 0x1;
}