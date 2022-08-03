#include <stdio.h>

int main() {
    int a = 0;
    int b = 1;
    int c = 0;

    int n = 10;

    for(int i=0; i<n; i++) {
        printf("%d ", a);

        c = a + b;
        a = b;
        b = c;
    }

    printf("\n");
    return 0;
}