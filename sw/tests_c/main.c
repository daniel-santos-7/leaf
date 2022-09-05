void uart_send_string(const char* str, const int len) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;
  
  for(int i = 0; i < len; i++) {
    while(((*flag) & 0x20) != 0x20);
    (*out) = str[i];
  }
}

void uart_send_char(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char2(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char3(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char4(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char5(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char6(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char7(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char8(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char9(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char10(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char11(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char12(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char13(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char14(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char15(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char16(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}


void uart_send_char17(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char18(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char19(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char20(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char21(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char22(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char23(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char24(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char25(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char26(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char27(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char28(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char29(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char30(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char31(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char32(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char33(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char34(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char35(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char36(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char37(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char38(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char39(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

void uart_send_char40(const char c) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;

  while(((*flag) & 0x20) != 0x20);
  (*out) = c;
}

int main() {
  while(1) {
    uart_send_string("Hello World!\n", 13);
  }
  return 0;
}