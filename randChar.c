/* Program to generate random characters */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void)
{
    char randChar;
    int i;
    int n;

    scanf("%d", &n);

    srand(time(NULL));
    for (i = 0; i < n; i++)
    {
        randChar = rand();

        randChar %= 0x7F;

        if (randChar == 0x09 || randChar == 0x0A || (randChar > 0x20 && randChar < 0x7E))
            printf("%c", randChar);
    }
    printf("\n");
    return 0;
}