#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
** Código reconstruido (reverse) para el binario: level3
** Arquitectura: ELF 64-bit x86-64 (PIE)
**
** Puntos principales:
**  - Lee hasta 23 caracteres con scanf
**  - Comprobaciones de prefijo: buf[0]=='4', buf[1]=='2'
**  - Construye result[0..7] empezando con '*' (42) y rellena desde grupos de 3 chars
**  - Compara con "********" y decide: solo strcmp == 0 -> éxito
**
** Contraseña: 42042042042042042042042
*/

static void syscall_malloc_fail(void)
{
    puts("Nope.");
    exit(1);
}

static void syscall_malloc_ok(void)
{
    puts("Good job.");
}

int main(void)
{
    char    buf[24];
    char    result[9];
    int     ret;
    long    index;
    int     i;
    char    tmp[4];
    int     cmp_result;

    printf("Please enter key: ");
    ret = scanf("%23s", buf);
    if (ret != 1)
        syscall_malloc_fail();

    if (buf[1] != '2')
        syscall_malloc_fail();
    if (buf[0] != '4')
        syscall_malloc_fail();

    memset(result, 0, 9);
    result[0] = '*';

    index = 2;
    i     = 1;
    while (strlen(result) < 8 && (size_t)index < strlen(buf))
    {
        tmp[0] = buf[index];
        tmp[1] = buf[index + 1];
        tmp[2] = buf[index + 2];
        tmp[3] = '\0';

        result[i] = (char)atoi(tmp);

        index += 3;
        i     += 1;
    }
    result[i] = '\0';

    cmp_result = strcmp(result, "********");
    if (cmp_result == 0)
        syscall_malloc_ok();
    else
        syscall_malloc_fail();

    return 0;
}
