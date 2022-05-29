#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>
#undef errno

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

int _close(int file) {
  return -1;
}

// char *__env[1] = { 0 };
// char **environ = __env;

// extern int errno;

// int _execve(char *name, char **argv, char **env) {
//   errno = ENOMEM;
//   return -1;
// }

// int _fork(void) {
//   errno = EAGAIN;
//   return -1;
// }

int _fstat(int file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}

// int _getpid(void) {
//   return 1;
// }

int _isatty(int file) {
  return 1;
}

// int _kill(int pid, int sig) {
//   errno = EINVAL;
//   return -1;
// }

// int _link(char *old, char *new) {
//   errno = EMLINK;
//   return -1;
// }

int _lseek(int file, int ptr, int dir) {
  return 0;
}

// int _open(const char *name, int flags, int mode) {
//   return -1;
// }

int _read(int file, char *ptr, int len) {
  return 0;
}

caddr_t _sbrk(int incr) {
  extern char __end;
  static char *heap_end;
  char *prev_heap_end;
 
  if (heap_end == 0) {
    heap_end = &__end;
  }
  prev_heap_end = heap_end;

  heap_end += incr;
  return (caddr_t) prev_heap_end;
}

// int _stat(char *file, struct stat *st) {
//   st->st_mode = S_IFCHR;
//   return 0;
// }

// int _times(struct tms *buf) {
//   return -1;
// }

// int _unlink(char *name) {
//   errno = ENOENT;
//   return -1; 
// }

// int _wait(int *status) {
//   errno = ECHILD;
//   return -1;
// }

int _write(int file, char *ptr, int len) {
  int todo;

  for (todo = 0; todo < len; todo++) {
    send_char(*ptr++);
  }
  return len;
}