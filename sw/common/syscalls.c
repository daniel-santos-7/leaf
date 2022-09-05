#include <stdio.h>
#include <errno.h>
#include <sys/stat.h>

#undef errno
extern int errno;

// #define OUTPUT_ADDR 0xC
// #define HALT_ADDR 0x00000000

void _exit(int n) {
  // int volatile *halt = (int *) HALT_ADDR;
  // (*halt) = 1;
  // _exit(n);
}

int _close(int file) {
  return -1;
}

char *__env[1] = { 0 };
char **environ = __env;

int _execve(char *name, char **argv, char **env) {
  errno = ENOMEM;
  return -1;
}

int _fork(void) {
  errno = EAGAIN;
  return -1;
}

int _fstat(int file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}

int _getpid(void) {
  return 1;
}

int _isatty(int file) {
  return 1;
}

int _kill(int pid, int sig) {
  return EINVAL;
  return -1;
}

int _link(char *old, char *new) {
  errno = EMLINK;
  return -1;
}

int _lseek(int file, int ptr, int dir) {
  return 0;
}

int _open(const char *name, int flags, int mode) {
  return -1;
}

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

int _stat(char *file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}

int _times(struct tms *buf) {
  return -1;
}

int _unlink(char *name) {
  errno = ENOENT;
  return -1; 
}

int _wait(int *status) {
  errno = ECHILD;
  return -1;
}

int _write(int file, char *ptr, int len) {
  int todo;

  // if ((file != 1) && (file != 2) && (file != 3)) {
  //   return -1;
  // }
  
  // char volatile *out = (char *) OUTPUT_ADDR;

  // for (todo = 0; todo < len; todo++) {
  //   (*out) = *ptr++;
  // }

  char volatile *flag = (char *) 0x0;
  char volatile *out = (char *) 0xC;
  
  for(todo = 0; todo < len; todo++) {
    while(((*flag) & 0x20) != 0x20);
    (*out) = *ptr++;
  }

  return len;
}