void uart_send_string(const char* str, const int len) {
  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;
  
  for(int i = 0; i < len; i++) {
    while(((*flag) & 0x20) != 0x20);
    (*out) = str[i];
  }
}

int main() {
  while(1) {
    uart_send_string("Hello World!\n", 13);
  }
  return 0;
}