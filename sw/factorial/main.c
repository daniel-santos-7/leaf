#include <stdio.h>

void main() {
    int n = 10;
    printf("%d! = ", n);

    int result = n;

    if (n == 0) {
        result = 1;
    }

    while(n>1) {
        result *= --n;
    }

    printf("%d\n", result);
}