//TestDll.c 

#include <stdio.h>

int hello()
{
    printf ("Hello from DLL\n");
}

int SumNumbers(int a, int b)
{
    int c;
    c=a+b;
    return c;
}