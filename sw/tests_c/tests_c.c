#include <string.h>

#define OUTPUT_ADDR 0x00200000
#define HALT_ADDR 0x00200004

void send_string(const char* str) {
  char volatile *out = (char *) OUTPUT_ADDR;
  int n = strlen(str);
  for(int i=0; i<n; i++) {
    (*out) = str[i];
  }
}

void send_char(const char c) {
  char volatile *out = (char *) OUTPUT_ADDR;
  (*out) = c;
}

int main() {
  char * name = "Leaf";
  send_string(name);
  return 0;
}