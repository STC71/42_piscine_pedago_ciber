#include <stdio.h>
#include <string.h>

/*
** Código reconstruido (reverse) para el binario: level1
** Arquitectura: ELF 32-bit x86 (PIE)
**
** Método de análisis:
**   - objdump -d level1  -> desensamblado de main()
**   - objdump -s -j .rodata level1  -> extraer datos de solo-lectura
**
** Cómo funciona:
**   El binario almacena una cadena de contraseña incrustada en .rodata
**   en el offset de fichero 0x2008 (dirección virtual 0x2008 en el mapeo PIE).
**   Antes de llamar a printf(), main() copia 14 bytes desde .rodata
**   a la pila (mediante instrucciones mov) para construir la referencia
**   "__stack_check\0".
**   Luego lee la entrada del usuario con scanf("%s", buf) y compara la
**   entrada con la referencia en pila usando strcmp().
**   Si strcmp() devuelve 0 -> "Good job." de lo contrario -> "Nope."
**
** Contraseña: __stack_check
**
** Nota: existen múltiples contraseñas posibles si el binario es parcheado,
** pero con este binario sin modificar solo "__stack_check" es válida.
*/

int main(void)
{
    /*
    ** The reference string is built on the stack from .rodata bytes.
    ** Equivalent to: char ref[] = "__stack_check";
    ** (the binary copies it word by word before scanf)
    */
    char ref[14];
    char input[100];

    ref[0]  = '_';
    ref[1]  = '_';
    ref[2]  = 's';
    ref[3]  = 't';
    ref[4]  = 'a';
    ref[5]  = 'c';
    ref[6]  = 'k';
    ref[7]  = '_';
    ref[8]  = 'c';
    ref[9]  = 'h';
    ref[10] = 'e';
    ref[11] = 'c';
    ref[12] = 'k';
    ref[13] = '\0';

    printf("Please enter key: ");
    scanf("%s", input);

    if (strcmp(input, ref) == 0)
        printf("Good job.\n");
    else
        printf("Nope.\n");

    return 0;
}
