#!/usr/bin/env bash
###############################################################################
#                 Reverse me — TUTORIAL INTERACTIVO (mandatory + bonus)       #
#                                                                             #
#  Guía paso a paso para presentar y evaluar el proyecto Reverse_me. Siga en  #
#  una terminal y ejecute los comandos sugeridos en otra terminal cuando se    #
#  indique.                                                                    #
###############################################################################

set -o pipefail
set -u

# ==========================================================================
# COLORES
# ==========================================================================
readonly ROJO='\033[0;31m'
readonly VERDE='\033[0;32m'
readonly AMARILLO='\033[1;33m'
readonly AZUL='\033[0;34m'
readonly CIAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NEGRITA='\033[1m'
readonly RESET='\033[0m'

# ==========================================================================
# VARIABLES
# ==========================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TUTORIAL_DIR="$SCRIPT_DIR/tmp_tutorial_reverse"
PASO_ACTUAL=1
PASOS_TOTALES=10

# Modo no interactivo: exporta AUTO=1 o pasa --auto como primer argumento
AUTO=${AUTO:-0}
if [[ "${1:-}" == "--auto" ]]; then
    AUTO=1
fi

# ==========================================================================
# FUNCIONES AUX
# ==========================================================================
encabezado() {
    echo -e "\n${NEGRITA}${AZUL}════════════════════════════════════════════════════════════${RESET}"
    echo -e "${NEGRITA}${AZUL}$1${RESET}"
    echo -e "${NEGRITA}${AZUL}════════════════════════════════════════════════════════════${RESET}\n"
}

paso() {
    echo -e "${NEGRITA}${CIAN}🔄 PASO $PASO_ACTUAL/$PASOS_TOTALES: $1${RESET}"
    echo -e "${CIAN}─────────────────────────────────────────────────────────────${RESET}\n"
}

comando_usuario() {
    echo -e "${NEGRITA}En OTRA terminal, ejecuta:${RESET}\n"
    echo -e "  ${MAGENTA}$1${RESET}\n"
}

descripcion() {
    echo -e "${MAGENTA}📝 $1${RESET}\n"
}

esperado() {
    echo -e "${VERDE}✓ Se esperaba:${RESET} $1\n"
}

pausa() {
    if [[ "${AUTO:-0}" == "1" ]]; then
        echo -e "${AMARILLO}Auto mode: saltando pausa...${RESET}"
        return 0
    fi
    read -p "$(echo -e "${CIAN}Presiona Enter cuando hayas ejecutado los comandos...${RESET}")" -r
}

siguiente_paso() {
    PASO_ACTUAL=$((PASO_ACTUAL + 1))
    if [[ "${AUTO:-0}" == "1" ]]; then
        echo ""
        clear
        return 0
    fi
    echo ""
    read -p "$(echo -e "${CIAN}Presiona Enter para el siguiente paso...${RESET}")" -r
    clear
}

verificar_archivo() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo -e "  ${VERDE}✓${RESET} Encontrado: $path"
        return 0
    else
        echo -e "  ${ROJO}✗${RESET} NO encontrado: $path"
        return 1
    fi
}

# Helpers para verificación automática de bytes
hexdump_bytes() {
    # args: file offset len
    local file="$1"; local off="$2"; local len="$3"
    xxd -p -s "$off" -l "$len" "$file" 2>/dev/null | tr -d '\n'
}

check_bytes() {
    # args: file offset expected_hex
    local file="$1"; local off="$2"; local expected="$3"; local len=$(( ${#expected} / 2 ))
    local got=$(hexdump_bytes "$file" "$off" "$len")
    # Normaliza la representación del offset: si ya incluye '0x' no lo duplicamos.
    local off_str
    if [[ "$off" == 0x* ]]; then
        off_str="$off"
    else
        off_str="0x$off"
    fi
    echo "  file=$file offset=$off_str expected=$expected got=$got"
    if [[ "$got" == "$expected" ]]; then
        echo -e "  ${VERDE}✓ Bytes coinciden${RESET}"
        return 0
    else
        echo -e "  ${ROJO}✗ Bytes NO coinciden${RESET}"
        return 1
    fi
}

# ==========================================================================
# PREPARACIÓN
# ==========================================================================
preparacion() {
    mkdir -p "$TUTORIAL_DIR"
    echo -e "Directorio de trabajo: ${CIAN}$TUTORIAL_DIR${RESET}" 
}

limpiar() {
    rm -rf "$TUTORIAL_DIR"
}

trap limpiar EXIT

# ==========================================================================
# PASOS
# ==========================================================================

paso_1() {
    encabezado "Introducción y comprobaciones básicas"
    paso "Preparar entorno y comprobar binarios"
    descripcion "Verificamos formato y mostramos strings para localizar pistas."
    comando_usuario "cd $SCRIPT_DIR && file binary/* && strings binary/level1 | head -n 20"
    esperado "Verás que los binarios son ELF y strings como 'Please enter key', 'Good job.'"
    pausa

    echo -e "\nComprobando localmente..."
    file binary/level1 binary/level2 binary/level3 || true
    strings binary/level1 | egrep 'Please|Good|Nope|__stack_check' || true

    siguiente_paso
}

paso_2() {
    encabezado "Mandatory — Level1 (reversing y recreación)"
    paso "Encontrar la contraseña y verificar"
    descripcion "Usamos 'strings' para encontrar la contraseña y 'objdump' para confirmar la lógica."
    comando_usuario "strings binary/level1 | grep -E '__stack_check|Please|Good|Nope'\nobjdump -d binary/level1 | sed -n '1,220p' | grep -n -E 'strcmp|jne'"
    esperado "Contraseña encontrada: '__stack_check' y la comparación seguida de un 'jne'"
    echo -e "\n${MAGENTA}🔎 Explicación:${RESET}"
    echo -e "  - 'strings' lista cadenas embebidas; si aparece '__stack_check' es una pista muy fuerte de la contraseña esperada." 
    echo -e "  - 'objdump -d' muestra el código desensamblado: buscar 'strcmp' indica que el programa compara la entrada con una cadena almacenada." 
    echo -e "  - Las instrucciones 'jne' (jump if not equal) justo después de la comparación son la rama de fallo; si la comparación devuelve 0 (iguales) no se salta y se sigue la rama de éxito (p. ej. imprimir 'Good job.').\n"
    pausa

    echo -e "\nVerificando password level1..."
    printf "__stack_check\n" | ./binary/level1 || true

    siguiente_paso
}

paso_3() {
    encabezado "Mandatory — Level1: guía para recrear 'source.c'"
    paso "Mostrar ejemplo de 'source.c' representativo"
    descripcion "A continuación verás un ejemplo de código que replica la funcionalidad; puedes usarlo como referencia para tu 'source.c'."
    echo -e "\n${CIAN}Ejemplo (mostrar en pantalla):${RESET}\n"
    cat <<'EOF'
#include <stdio.h>
#include <string.h>
int main(void){char input[108]; const char expected[]="__stack_check"; printf("Please enter key: "); if(scanf("%107s", input)!=1){printf("Nope.\n");return 0;} if(strcmp(input, expected)==0) printf("Good job.\n"); else printf("Nope.\n");}
EOF

     descripcion "Pruebas reproducibles desde OTRA terminal (comandos y resultados esperados):"
     cat <<'OUT'

  1) Compilar el ejemplo:
      mkdir -p level1 && gcc -o level1/level1_recreated level1/source.c

  2) Ejecutar el binario original con la contraseña conocida:
      printf '__stack_check\n' | ./binary/level1
      # Expected output: 'Please enter key:' seguido de 'Good job.'

  3) Ejecutar el binario recreado para validar comportamiento:
      printf '__stack_check\n' | ./level1/level1_recreated
      # Expected: 'Please enter key:' seguido de 'Good job.'

OUT
     pausa
     siguiente_paso
}

paso_4() {
    encabezado "Mandatory — Level2 (reversing y derivación de contraseña)"
    paso "Analizar algoritmo y construir la contraseña"
    descripcion "Identificamos la validación '00' y el bucle que toma bloques de 3 dígitos para reconstruir la palabra objetivo ('delabere')."
    comando_usuario "strings binary/level2 | grep delabere\nobjdump -d binary/level2 | sed -n '1,300p' | grep -n -E 'atoi|strlen|strcmp|jne'"
    esperado "A continuación mostramos comandos para derivar la contraseña y la salida esperada."
    echo -e "\nExplicación breve de la salida:" 
    echo -e "  - 'strings' mostrará texto embebido en el binario; encontrar 'delabere' indica que esa cadena existe en el ejecutable y probablemente se usa como valor esperado en una comparación." 
    echo -e "  - El 'objdump | grep' busca instrucciones y llamadas clave: 'call ... strcmp@plt' muestra dónde el programa invoca 'strcmp' para comparar tu entrada con la cadena embebida." 
    echo -e "  - Las instrucciones 'jne' (jump if not equal) normalmente aparecen justo después de la comparación: si 'strcmp' devuelve distinto de 0 el flujo salta a la rama de fallo; si no salta, continúa por la rama de éxito." 
    echo -e "  - Para entender exactamente qué bytes/control de flujo se usan, busca la llamada a 'strcmp' y muestra unas líneas de assembly alrededor (por ejemplo, +/- 20 líneas) para ver el 'cmp/test' y el posterior 'jne'.\n"
    pausa

    echo -e "\nPasos detallados para derivar la contraseña (ejecuta en OTRA terminal):"
    echo -e "  1) Inspeccionar cadenas:\n     strings binary/level2 | grep delabere\n     # Expected: mostrará la cadena 'delabere' en el binario."
    echo -e "\n  2) Ver el flujo de validación con objdump (buscar atoi/strcmp/jne):\n     objdump -d binary/level2 | sed -n '1,300p' | grep -n -E 'atoi|strlen|strcmp|jne'\n     # Expected: verás llamadas a atoi y strcmp y varios 'jne' que condicionan el flujo."
    echo -e "\n  3) Uso de un script/one-liner para reconstruir la contraseña (ejemplo reproducible):\n     python3 - <<'PY'\nstr_digits = '00101108097098101114101'\nprint(str_digits)\nPY\n     # Expected: imprime la contraseña: 00101108097098101114101\n"
    echo -e "\n  4) Probar la contraseña en el binario original:\n     printf '00101108097098101114101\\n' | ./binary/level2\n     # Expected: 'Please enter key:' seguido de 'Good job.' si la contraseña es correcta."
    echo -e "\n  5) Recomendación: crear un 'source.c' que implemente la lógica (leer input, validar prefijo '00', procesar bloques de 3 dígitos con atoi, construir 'out' y strcmp con 'delabere') y probarlo localmente."

    echo -e "\nPara inspeccionar exactamente dónde se llama a 'strcmp' y ver el ensamblado alrededor, puedes usar este comando (localiza la línea con la llamada y muestra ±20 líneas):"
    echo -e "  match_line=\$(objdump -d binary/level2 | grep -n -E 'call\\s+.*strcmp@plt|strcmp@plt' | head -n1 | cut -d: -f1)"
    echo -e "  if [[ -n \"\$match_line\" ]]; then start=\$((match_line-20)); end=\$((match_line+20)); objdump -d binary/level2 | sed -n \"\${start},\${end}p\"; else echo 'No se encontró strcmp en el rango buscado'; fi"
    echo -e "\nQué buscar: una instrucción 'call   <strcmp@plt>' seguida (en las líneas siguientes) por las instrucciones que comprueban el resultado (por ejemplo 'test' o 'cmp') y un 'jne' que salta a la ruta de fallo. Ese 'jne' es el punto de control de flujo que normalmente parcheamos (reemplazando por NOPs) para forzar la rama de éxito."

    echo -e "\n¿Por qué la contraseña tiene esa forma numérica (ej: 00101108097098101114101)?"
    echo -e "  - Formato: '00' + concatenación de códigos ASCII en decimal, cada carácter codificado con 3 dígitos."
    echo -e "    Ejemplo: 'delabere' -> d=100 e=101 l=108 a=097 b=098 e=101 r=114 e=101 -> '100101108097098101114101' -> contraseña: '00' + eso."
    echo -e "  - Si ves una cadena con 7 grupos de 3 dígitos tras '00' (p. ej. 00101108097098101114101) eso decodifica a 'elabere' (faltaría el grupo '100' para la 'd'). Comprueba la longitud y agrupa en bloques de 3 para confirmar."
    echo -e "\nDecodificar/encodar (one-liners):"
    echo -e "  Decodificar:\n    python3 - <<'PY'\ns='00101108097098101114101'\ns=s[2:]\nprint([s[i:i+3] for i in range(0,len(s),3)])\nprint(''.join(chr(int(g)) for g in [s[i:i+3] for i in range(0,len(s),3)]))\nPY"
    echo -e "  Encodar (para 'delabere'):\n    python3 - <<'PY'\nword='delabere'\nprint('00'+''.join(f'{ord(c):03d}' for c in word))\nPY\n"

    echo -e "\nProbando contraseña level2 (automático):"
    printf "00101108097098101114101\n" | ./binary/level2 || true

    siguiente_paso
}

paso_5() {
    encabezado "Mandatory — Level2: guía para recrear 'source.c'"
    paso "Código ejemplo (resumen)"
    descripcion "Aquí hay instrucciones claras de prueba y un resumen de las comprobaciones que debes realizar desde OTRA terminal." 
    echo -e "\n${CIAN}Resumen de pruebas y verificación:${RESET}\n"
    echo -e "  - Comprobar que el binario original acepta la contraseña encontrada:"
    echo -e "      printf '00101108097098101114101\\n' | ./binary/level2\n      # Expected: 'Good job.'\n"
    echo -e "  - Comprobar que tu 'source.c' recreado produce la misma salida con la misma contraseña:\n      gcc -o level2/level2_recreated level2/source.c && printf '00101108097098101114101\\n' | ./level2/level2_recreated\n      # Expected: 'Good job.'\n"
    echo -e "  - Si quieres, instrumenta con objdump -d y comprueba las ramas condicionadas por 'jne' para justificar los parches en la parte bonus.\n"
    pausa
    echo -e "\nVerificando password level2..."
    if printf "00101108097098101114101\n" | ./binary/level2 | grep -q "Good job\."; then
        echo -e "  ${VERDE}✓${RESET} level2 acepta la contraseña\n"
    else
        echo -e "  ${ROJO}✗${RESET} level2 NO acepta la contraseña\n"
    fi

    siguiente_paso
}

paso_6() {
    encabezado "Preparación de la entrega (mandatory)"
    paso "Revisar estructura y archivos requeridos"
    descripcion "Cada nivel debe incluir: carpeta 'levelN', fichero 'password' con la contraseña encontrada y 'source.c' representativo."
    comando_usuario "ls -al level1 level2 level3 || true\nls -al level1/*.c level2/*.c || true"
    pausa
    siguiente_paso
}

paso_7() {
    encabezado "Bonus — Aplicar parches"
    paso 'Explicación y Generación de binarios con patch_all.py'
    
    local f_patch="$SCRIPT_DIR/patch_all.py"
    local line_func=$(grep -n "def patch_binary" "$f_patch" | head -n 1 | cut -d: -f1)
    local line_verify=$(grep -n "if actual != bytearray(original):" "$f_patch" | head -n 1 | cut -d: -f1)
    local line_level1=$(grep -n "Nivel 1:" "$f_patch" | head -n 1 | cut -d: -f1)

    descripcion "Antes de ejecutar, analicemos dinámicamente cómo funciona 'patch_all.py':"
    echo -e "${CIAN}1. Lógica Principal (patch_binary)${RESET}"
    echo -e "   Abre el archivo en modo binario modificado y aplica los bytes. Código en:"
    echo -e "   👉 ${NEGRITA}patch_all.py:${line_func}${RESET}\n"
    
    echo -e "${CIAN}2. Mecanismo de Seguridad${RESET}"
    echo -e "   Comprueba que los bytes en disco coinciden con los esperados antes de alterar"
    echo -e "   nada, previniendo corromper archivos incorrectos. Código en:"
    echo -e "   👉 ${NEGRITA}patch_all.py:${line_verify}${RESET}\n"
    
    echo -e "${CIAN}3. Estructura de Parches${RESET}"
    echo -e "   Cada nivel define su 'offset', 'originales', y 'reemplazo'."
    echo -e "   Ejemplo (NOPs sobre JNE en level1):"
    echo -e "   👉 ${NEGRITA}patch_all.py:${line_level1}${RESET}\n"

    descripcion "El script aplica parches en la sección .text para forzar la rama de éxito."
    comando_usuario "cd $SCRIPT_DIR && python3 patch_all.py"
    pausa

    echo -e "\nAplicando parches ahora..."
    python3 "$SCRIPT_DIR/patch_all.py" || true
    verificar_archivo "$SCRIPT_DIR/level1/level1_patched"
    verificar_archivo "$SCRIPT_DIR/level2/level2_patched"
    verificar_archivo "$SCRIPT_DIR/level3/level3_patched"
    echo -e "\nComprobando bytes parcheados (ejemplos):"
    # level1: expect NOPs at 0x1244
    check_bytes "$SCRIPT_DIR/level1/level1_patched" 0x1244 909090909090 || true
    # level2: expect NOPs at 0x146d and 0x13f3
    check_bytes "$SCRIPT_DIR/level2/level2_patched" 0x146d 909090909090 || true
    check_bytes "$SCRIPT_DIR/level2/level2_patched" 0x13f3 909090909090 || true
    # level3: expect xor at 0x14a5 (31c0) and NOPs at 0x1408
    check_bytes "$SCRIPT_DIR/level3/level3_patched" 0x14a5 31c00f84 || true
    check_bytes "$SCRIPT_DIR/level3/level3_patched" 0x1408 909090909090 || true
    siguiente_paso
}

paso_8() {
    encabezado "Bonus — Volcados (hexdump) antes / después"
    paso "Mostrar ejemplos reproducibles de hexdump"
    descripcion "Los patch_explanation.md contienen los volcados; aquí mostramos cómo reproducirlos localmente."
    comando_usuario "hexdump -C -s 0x1244 -n 16 binary/level1 && hexdump -C -s 0x1244 -n 16 level1/level1_patched\nxxd -p -s 0x1244 -l 6 binary/level1 && xxd -p -s 0x1244 -l 6 level1/level1_patched\npython3 - <<'PY'\nfrom pathlib import Path\nprint(Path('binary/level1').read_bytes()[0x1244:0x124a].hex())\nprint(Path('level1/level1_patched').read_bytes()[0x1244:0x124a].hex())\nPY"
    pausa

    echo -e "\nEjemplo (level1):"
    hexdump -C -s 0x1244 -n 16 binary/level1 || true
    echo -e "\n---> patched:\n"
    hexdump -C -s 0x1244 -n 16 level1/level1_patched || true
    echo -e "\nAlternativas (hex puro/prueba rápida):"
    xxd -p -s 0x1244 -l 6 binary/level1 || true
    xxd -p -s 0x1244 -l 6 level1/level1_patched || true
    python3 - <<'PY'
from pathlib import Path
try:
    b1 = Path('binary/level1').read_bytes()[0x1244:0x124a].hex()
    b2 = Path('level1/level1_patched').read_bytes()[0x1244:0x124a].hex()
    print('\npython hex (before):', b1)
    print('python hex (after) :', b2)
except Exception as e:
    print('Python check failed:', e)
PY

    siguiente_paso
}

paso_9() {
    encabezado "Bonus — Verificar comportamiento parcheado"
    paso "Probar binarios parcheados con entradas arbitrarias"
    descripcion "Debemos ver 'Good job.' independientemente de la entrada."
    comando_usuario "printf 'anything\n' | ./level1/level1_patched\nprintf 'anything\n' | ./level2/level2_patched\nprintf 'anything\n' | ./level3/level3_patched\nprintf 'anything\n' | ./level2/level2_patched_failredir\nprintf 'anything\n' | ./level3/level3_patched_failredir"
    descripcion "Nota: ejecuta SOLO las líneas anteriores en OTRA terminal. No pegues comentarios ni texto adicional; eso puede causar errores en la shell al pegar bloques."
    pausa

    echo -e "\nProbando level1 patched: (se espera 'Good job.' para cualquier entrada)"
    printf "anything\n" | ./level1/level1_patched || true
    echo -e "\nProbando level2 patched: (nota: este parche puede NO forzar siempre la salida de éxito)"
    echo -e "  - Si ves 'Nope.' en level2 es normal. El parche aplica NOPs en offsets concretos, pero hay más puntos de validación de la contraseña que no han saltado al bloque final de éxito."
    printf "anything\n" | ./level2/level2_patched || true
    
    echo -e "\nProbando level3 patched:"
    echo -e "  - Al igual que en level2, su NOP/xor parcial puede requerir entradas concretas para llegar al éxito."
    printf "anything\n" | ./level3/level3_patched || true

    echo -e "\nProbando level2 patched (failredir) - Variante que SÍ fuerza el éxito re-direccionando:"
    echo -e "  - Esta variante altera el salto de 'error' para enviarlo a la cadena 'Good job.'"
    echo -e "  - Puede imprimir 'Good job.' más de una vez dependiendo de dónde caiga el bucle interactivo."
    if [[ -x ./level2/level2_patched_failredir ]]; then
        printf "anything\n" | ./level2/level2_patched_failredir || true
    else
        echo -e "  ${AMARILLO}Aviso:${RESET} ./level2/level2_patched_failredir no existe"
    fi

    echo -e "\nProbando level3 patched (failredir) - Variante que SÍ fuerza el éxito re-direccionando:"
    echo -e "  - Esta también alteró los saltos, imprimiendo posiblemente un par de secuencias 'Good job.'."
    if [[ -x ./level3/level3_patched_failredir ]]; then
        printf "anything\n" | ./level3/level3_patched_failredir || true
    else
        echo -e "  ${AMARILLO}Aviso:${RESET} ./level3/level3_patched_failredir no existe"
    fi

    siguiente_paso
}

paso_10() {
    encabezado "Cierre y recomendaciones"
    paso "Checklist final antes de entregar"
    descripcion "Asegúrate de tener: por nivel -> carpeta, 'password', 'source.c', y 'patch_explanation.md'. Para bonus: incluir binarios parcheados y explicación detallada."
    echo -e "\n${VERDE}Checklist sugerido:${RESET}\n  - level1/password\n  - level1/source.c\n  - level1/patch_explanation.md\n  - level2/password\n  - level2/source.c\n  - level2/patch_explanation.md\n  - level3/password\n  - level3/source.c (si aplica)\n  - level3/patch_explanation.md\n  - README.md actualizado"
    echo -e "${VERDE}Tutorial completado.${RESET}"
}

# ==========================================================================
# MAIN
# ==========================================================================
clear
preparacion
paso_1 || exit 1
paso_2 || exit 1
paso_3 || exit 1
paso_4 || exit 1
paso_5 || exit 1
paso_6 || exit 1
paso_7 || exit 1
paso_8 || exit 1
paso_9 || exit 1
paso_10 || exit 1

exit 0
