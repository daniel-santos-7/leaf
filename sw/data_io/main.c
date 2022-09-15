#include <stdio.h>

void main() {
    int str[10];
    int n;
    printf("Enter a string: ");
    scanf("%s", &str);
    printf("Enter an integer: ");
    scanf("%d", &n);

    printf("String = %s\n", str);
    printf("Number = %d\n", n);

    char *halt = (char *) 0x10;
    *halt = 0x1;
}