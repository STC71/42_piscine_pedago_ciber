#include <stdio.h>
#include <stdlib.h>
#include <string.h>


static void no(void)
{
    printf("Nope.\n");
    exit(1);
}

static void ok(void)
{
    printf("Good job.\n");
}

/*
** Código reconstruido (reverse) para el binario: level2
** Arquitectura: ELF 32-bit x86 (PIE)
**
** Método de análisis:
**   - objdump -d level2  -> desensamblado completo
**   - strings level2     -> identificó "delabere", "%23s", "Nope.", "Good job."
**   - Se trazó el algoritmo desde el desensamblado de main()
**
** Algoritmo:
**   1. Lee hasta 23 caracteres con scanf("%23s", buf).
**      Si scanf no devuelve 1 -> exit (no).
**   2. Valida que buf[0] == '0' y buf[1] == '0'.
**      Si alguna comprobación falla -> exit (no).
**   3. Construye un buffer result (9 bytes, inicializado a 0) con result[0] = 'd' (0x64).
**   4. Bucle: mientras strlen(result) < 8 Y loop_index < strlen(buf+1):
**        - Toma 3 caracteres de buf en [index],[index+1],[index+2]
**          empezando desde index=2 (buf[2..4], buf[5..7], ...)
**        - Llama a atoi() sobre esos 3 chars -> almacena el byte en result[i]
**        - index += 3, i += 1
**   5. strcmp(result, "delabere") == 0 -> "Good job." sino -> "Nope."
**
** La cadena objetivo "delabere" = {100,101,108,97,98,101,114,101} en decimal ASCII.
** result[0] = 'd' = 100 (hardcodeado).
** result[1..7] son rellenados por el bucle desde la entrada codificada.
**
** Construcción de la contraseña:
**   buf[0] = '0', buf[1] = '0'  (prefijo obligatorio)
**   Luego 7 grupos de códigos ASCII decimales de 3 dígitos:
**     'e'=101 -> "101"
**     'l'=108 -> "108"
**     'a'=97  -> "097"
**     'b'=98  -> "098"
**     'e'=101 -> "101"
**     'r'=114 -> "114"
**     'e'=101 -> "101"
**   Contraseña = "00" + "101" + "108" + "097" + "098" + "101" + "114" + "101"
**             = "00101108097098101114101"  (23 chars, exactamente %23s)
**
** Nota: existen otras contraseñas válidas, p.ej. atoi(" 97") = 97,
** por lo que espacios o ceros delante en los grupos de 3 chars también funcionan.
*/
        no();

    return 0;
}
