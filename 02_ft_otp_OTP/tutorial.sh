#!/bin/bash

###############################################################################
#                     ft_otp - TUTORIAL INTERACTIVO                          #
#                                                                             #
#  Guía paso a paso para aprender a usar ft_otp.py                           #
#  Sigue las instrucciones en una terminal mientras ejecutas en otra         #
#                                                                             #
###############################################################################

set -o pipefail

# ============================================================================
# COLORES Y FORMATOS
# ============================================================================
readonly ROJO='\033[0;31m'
readonly VERDE='\033[0;32m'
readonly AMARILLO='\033[1;33m'
readonly AZUL='\033[0;34m'
readonly CIAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NEGRITA='\033[1m'
readonly RESET='\033[0m'

# ============================================================================
# VARIABLES GLOBALES
# ============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIR_TUTORIAL="$SCRIPT_DIR/tmp"
PASO_ACTUAL=1
PASOS_TOTALES=12

# ============================================================================
# FUNCIONES DE UTILIDAD
# ============================================================================

encabezado() {
    echo -e "\n${NEGRITA}${AZUL}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEGRITA}${AZUL}║${RESET} $1"
    echo -e "${NEGRITA}${AZUL}╚════════════════════════════════════════════════════════════╝${RESET}\n"
}

paso() {
    echo -e "${NEGRITA}${CIAN}🔄 PASO $PASO_ACTUAL/$PASOS_TOTALES: $1${RESET}"
    echo -e "${CIAN}─────────────────────────────────────────────────────────────${RESET}\n"
}

info_dir() {
    echo -e "${AMARILLO}📍 Directorio de trabajo:${RESET} ${CIAN}tmp${RESET}\n"
}

comando_usuario() {
    echo -e "${NEGRITA}En OTRA terminal, ejecuta estos comandos exactamente:${RESET}\n"
    local cmd="$1"
    echo -e "  ${MAGENTA}$cmd${RESET}\n"
}

descripcion() {
    echo -e "${MAGENTA}📝 $1${RESET}\n"
}

esperado() {
    echo -e "${VERDE}✓ Se esperaba:${RESET} $1\n"
}

no_debe_existir() {
    echo -e "${ROJO}✗ NO debe existir:${RESET} $1\n"
}

pausa() {
    read -p "$(echo -e "${CIAN}Presiona Enter cuando hayas ejecutado los comandos...${RESET}")" -r
}

verificar() {
    local archivo="$1"
    local debe_existir="${2:-true}"
    
    if [[ "$debe_existir" == "true" ]]; then
        if [[ -f "$DIR_TUTORIAL/$archivo" ]]; then
            echo -e "  ${VERDE}✓${RESET} Archivo creado: ${CIAN}$archivo${RESET}"
            return 0
        else
            echo -e "  ${ROJO}✗${RESET} Archivo NO encontrado: ${CIAN}$archivo${RESET}"
            return 1
        fi
    else
        if [[ ! -f "$DIR_TUTORIAL/$archivo" ]]; then
            echo -e "  ${VERDE}✓${RESET} Archivo NO creado (correcto): ${CIAN}$archivo${RESET}"
            return 0
        else
            echo -e "  ${ROJO}✗${RESET} Archivo existe (no debería): ${CIAN}$archivo${RESET}"
            return 1
        fi
    fi
}

limpiar_paso() {
    cd "$DIR_TUTORIAL" || exit
    rm -f ft_otp.key 2>/dev/null
}

siguiente_paso() {
    PASO_ACTUAL=$((PASO_ACTUAL + 1))
    echo ""
    read -p "$(echo -e "${CIAN}Presiona Enter para el siguiente paso...${RESET}")" -r
    clear
}

# ============================================================================
# PREPARACIÓN
# ============================================================================

preparacion() {
    mkdir -p "$DIR_TUTORIAL"
    cd "$DIR_TUTORIAL" || exit 1
}

limpiar() {
    rm -rf "$DIR_TUTORIAL"
}

trap limpiar EXIT

# ============================================================================
# PASOS DEL TUTORIAL
# ============================================================================

paso_1() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 1/$PASOS_TOTALES"
    info_dir
    paso "Genera una clave hexadecimal CORTA (debe rechazarse)"
    
    descripcion "ft_otp.py rechaza claves que no tengan al menos 64 caracteres hexadecimales"
    
    comando_usuario "cd tmp
echo -n 'AABBCCDD' > clave_corta.hex
../ft_otp.py -g clave_corta.hex"
    
    esperado "Mensaje de error (rechaza porque tiene solo 8 caracteres)"
    no_debe_existir "ft_otp.key"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    verificar "clave_corta.hex" true || return 1
    verificar "ft_otp.key" false || return 1
    
    siguiente_paso
}

paso_2() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 2/$PASOS_TOTALES"
    info_dir
    paso "Genera una clave hexadecimal INVÁLIDA (caracteres no hex)"
    
    descripcion "ft_otp.py valida que TODOS los caracteres sean hexadecimales (0-9, A-F)"
    
    limpiar_paso
    comando_usuario "cd tmp
printf 'Z%.0s' {1..64} > clave_invalida.hex
../ft_otp.py -g clave_invalida.hex"
    
    esperado "Mensaje de error (contiene 'Z' que no es hexadecimal)"
    no_debe_existir "ft_otp.key"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    verificar "clave_invalida.hex" true || return 1
    verificar "ft_otp.key" false || return 1
    
    siguiente_paso
}

paso_3() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 3/$PASOS_TOTALES"
    info_dir
    paso "Genera una clave hexadecimal VÁLIDA (64 caracteres hex)"
    
    descripcion "Una clave válida tiene exactamente 64+ caracteres hexadecimales (0-9, A-F)"
    
    limpiar_paso
    comando_usuario "cd tmp
echo '3132333435363738393031323334353637383930313233343536373839303132' > clave_valida.hex
../ft_otp.py -g clave_valida.hex"
    
    esperado "Mensaje: 'successfully saved' (o similar)"
    esperado "Se crea archivo: ft_otp.key"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    verificar "clave_valida.hex" true || return 1
    verificar "ft_otp.key" true || return 1
    
    siguiente_paso
}

paso_4() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 4/$PASOS_TOTALES"
    info_dir
    paso "Manejo de espacios en blanco (trim)"
    
    descripcion "ft_otp.py debe eliminar espacios al inicio/final de la clave"
    
    limpiar_paso
    comando_usuario "cd tmp
echo '  3132333435363738393031323334353637383930313233343536373839303132  ' > clave_espacios.hex
../ft_otp.py -g clave_espacios.hex"
    
    esperado "Debe funcionar correctamente (espacios se eliminan automáticamente)"
    esperado "Se crea archivo: ft_otp.key"
    
    echo -e "${NEGRITA}${AZUL}💡 ¿Qué es TOTP?${RESET}"
    echo -e "${AZUL}TOTP (Time-based One-Time Password) es un código que cambia cada 30 segundos."
    echo -e "Se genera usando:${RESET}"
    echo -e "  • ${CIAN}Clave secreta${RESET} (guardada en ft_otp.key)"
    echo -e "  • ${CIAN}Marca de tiempo${RESET} (hora actual / 30 segundos)"
    echo -e "  • ${CIAN}Algoritmo HMAC-SHA1${RESET} (RFC 6238)${RESET}"
    echo -e "${AZUL}En el próximo paso usaremos ${NEGRITA}-k ft_otp.key${RESET}${AZUL} para generar uno.${RESET}\n"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    verificar "clave_espacios.hex" true || return 1
    verificar "ft_otp.key" true || return 1
    
    siguiente_paso
}

paso_5() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 5/$PASOS_TOTALES"
    info_dir
    paso "Genera un código TOTP desde la clave cifrada"
    
    descripcion "Lee la clave cifrada (ft_otp.key) con ${NEGRITA}-k${RESET} y genera un código TOTP de 6 dígitos."
    descripcion "Este código cambia cada 30 segundos automáticamente."
    
    # Asegurar que exista ft_otp.key
    echo "3132333435363738393031323334353637383930313233343536373839303132" > "$DIR_TUTORIAL/clave_paso5.hex"
    cd "$DIR_TUTORIAL"
    python3 "$SCRIPT_DIR/ft_otp.py" -g clave_paso5.hex > /dev/null 2>&1
    
    comando_usuario "cd tmp
../ft_otp.py -k ft_otp.key"
    
    esperado "Se muestra un código TOTP de 6 dígitos (ejemplo: 123456)"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    local codigo=$(python3 "$SCRIPT_DIR/ft_otp.py" -k ft_otp.key 2>/dev/null)
    if [[ $codigo =~ ^[0-9]{6}$ ]]; then
        echo -e "  ${VERDE}✓${RESET} Código TOTP válido generado: ${CIAN}$codigo${RESET}"
    else
        echo -e "  ${ROJO}✗${RESET} Código TOTP inválido o no generado"
        return 1
    fi
    
    siguiente_paso
}

paso_6() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 6/$PASOS_TOTALES"
    info_dir
    paso "Cambio de código cada 30 segundos"
    
    descripcion "Los códigos TOTP deben cambiar cada 30 segundos (según RFC 6238)"
    
    comando_usuario "cd tmp
# Ejecuta esto varias veces con 1-2 segundos de diferencia:
../ft_otp.py -k ft_otp.key
sleep 1
../ft_otp.py -k ft_otp.key"
    
    esperado "Mientras estés en el mismo intervalo de 30s, el código es igual"
    esperado "Después de 30s, el código cambia"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    local codigo1=$(python3 "$SCRIPT_DIR/ft_otp.py" -k ft_otp.key 2>/dev/null)
    sleep 1
    local codigo2=$(python3 "$SCRIPT_DIR/ft_otp.py" -k ft_otp.key 2>/dev/null)
    
    if [[ "$codigo1" == "$codigo2" ]]; then
        echo -e "  ${VERDE}✓${RESET} Códigos iguales en el mismo intervalo: ${CIAN}$codigo1${RESET}"
    else
        echo -e "  ${AMARILLO}ℹ${RESET} Códigos diferentes (cambio de intervalo): $codigo1 → $codigo2"
    fi
    
    siguiente_paso
}

paso_7() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 7/$PASOS_TOTALES"
    info_dir
    paso "Manejo de error: archivo .key faltante"
    
    descripcion "Si no existe ft_otp.key, ft_otp.py debe mostrar un error"
    
    cd "$DIR_TUTORIAL"
    rm -f ft_otp.key
    
    comando_usuario "cd tmp
../ft_otp.py -k ft_otp.key"
    
    esperado "Mensaje de error (archivo no encontrado)"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    verificar "ft_otp.key" false || return 1
    
    siguiente_paso
}

paso_8() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 8/$PASOS_TOTALES"
    info_dir
    paso "BONUS: Generación de código QR"
    
    descripcion "ft_otp.py puede generar un código QR que codifique la semilla TOTP"
    
    # Crear una clave válida
    echo "3132333435363738393031323334353637383930313233343536373839303132" > "$DIR_TUTORIAL/clave_qr.hex"
    cd "$DIR_TUTORIAL"
    python3 "$SCRIPT_DIR/ft_otp.py" -g clave_qr.hex > /dev/null 2>&1
    
    comando_usuario "cd tmp
../ft_otp.py -g clave_qr.hex --qr qr_codigo.png"
    
    esperado "Se genera archivo: qr_codigo.png"
    esperado "El QR contiene la información de la semilla TOTP"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    if python3 "$SCRIPT_DIR/ft_otp.py" -g clave_qr.hex --qr qr_codigo_test.png 2>&1 | grep -qi "saved\|success"; then
        echo -e "  ${VERDE}✓${RESET} QR generado correctamente"
    else
        echo -e "  ${AMARILLO}ℹ${RESET} QR no disponible (librería qrcode no instalada)"
    fi
    
    siguiente_paso
}

paso_9() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 9/$PASOS_TOTALES"
    info_dir
    paso "BONUS: Interfaz Gráfica (Tkinter)"
    
    descripcion "ft_otp.py puede mostrar una GUI Tkinter para generar/usar códigos"
    
    # Crear una clave válida
    echo "3132333435363738393031323334353637383930313233343536373839303132" > "$DIR_TUTORIAL/clave_gui.hex"
    cd "$DIR_TUTORIAL"
    python3 "$SCRIPT_DIR/ft_otp.py" -g clave_gui.hex > /dev/null 2>&1
    
    comando_usuario "cd tmp
../ft_otp.py --gui"
    
    esperado "Se abre una ventana gráfica"
    esperado "Puedes ver el código TOTP en tiempo real"
    
    read -p "$(echo -e "${CIAN}Presiona Enter cuando hayas cerrado la GUI...${RESET}")" -r
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    if python3 -c "from tkinter import Tk; Tk().destroy()" > /dev/null 2>&1; then
        echo -e "  ${VERDE}✓${RESET} Tkinter disponible en el sistema"
    else
        echo -e "  ${AMARILLO}ℹ${RESET} Tkinter no disponible en este entorno"
    fi
    
    siguiente_paso
}

paso_10() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 10/$PASOS_TOTALES"
    info_dir
    paso "Validador de referencia (RFC 6328 compatible)"
    
    descripcion "Existe un validador de referencia para verificar compatibilidad RFC"
    
    # Crear una clave válida
    echo "3132333435363738393031323334353637383930313233343536373839303132" > "$DIR_TUTORIAL/clave_ref.hex"
    cd "$DIR_TUTORIAL"
    python3 "$SCRIPT_DIR/ft_otp.py" -g clave_ref.hex > /dev/null 2>&1
    
    comando_usuario "cd tmp
# Obtener código de ft_otp.py
../ft_otp.py -k ft_otp.key

# Comparar con validador (si existe)
../validate_totp.py 3132333435363738393031323334353637383930313233343536373839303132"
    
    esperado "Ambos comandos generan el MISMO código TOTP"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    local codigo_ft_otp=$(python3 "$SCRIPT_DIR/ft_otp.py" -k ft_otp.key 2>/dev/null)
    if [[ -f "$SCRIPT_DIR/validate_totp.py" ]]; then
        local codigo_ref=$(python3 "$SCRIPT_DIR/validate_totp.py" "3132333435363738393031323334353637383930313233343536373839303132" 2>/dev/null)
        if [[ "$codigo_ft_otp" == "$codigo_ref" ]]; then
            echo -e "  ${VERDE}✓${RESET} Códigos coinciden: ${CIAN}$codigo_ft_otp${RESET}"
        else
            echo -e "  ${AMARILLO}⚠${RESET} Códigos diferentes: ft_otp=$codigo_ft_otp, ref=$codigo_ref"
        fi
    else
        echo -e "  ${AMARILLO}ℹ${RESET} Validador no encontrado, omitiendo"
    fi
    
    siguiente_paso
}

paso_11() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 11/$PASOS_TOTALES"
    info_dir
    paso "Cifrado XOR (seguridad de la clave)"
    
    descripcion "Las claves se cifran con XOR antes de guardarse en ft_otp.key"
    
    comando_usuario "cd tmp
# El contenido de ft_otp.key está cifrado, no es legible:
od -An -tx1 ft_otp.key | head -1"
    
    esperado "Ver bytes hexadecimales aleatorios (contenido cifrado)"
    
    pausa
    
    echo -e "${NEGRITA}Verificando...${RESET}\n"
    if [[ -f "$DIR_TUTORIAL/ft_otp.key" ]]; then
        local bytes=$(od -An -tx1 "$DIR_TUTORIAL/ft_otp.key" 2>/dev/null | head -1)
        echo -e "  ${VERDE}✓${RESET} Archivo cifrado (bytes): ${CIAN}$bytes${RESET}"
    else
        echo -e "  ${ROJO}✗${RESET} ft_otp.key no existe"
    fi
    
    siguiente_paso
}

paso_12() {
    clear
    encabezado "🔐 TUTORIAL INTERACTIVO - Paso 12/$PASOS_TOTALES"
    info_dir
    paso "¡Tutorial completado!"
    
    echo -e "${VERDE}${NEGRITA}✓ Felicidades!${RESET} Has aprendido a usar ft_otp.py\n"
    
    echo -e "${NEGRITA}Resumen de comandos importantes:${RESET}\n"
    echo -e "  ${MAGENTA}Generar clave:${RESET}   ./ft_otp.py -g semilla.hex"
    echo -e "  ${MAGENTA}Generar TOTP:${RESET}    ./ft_otp.py -k ft_otp.key"
    echo -e "  ${MAGENTA}Generar QR:${RESET}      ./ft_otp.py -g semilla.hex --qr qr.png"
    echo -e "  ${MAGENTA}Abrir GUI:${RESET}       ./ft_otp.py --gui\n"
    
    echo -e "${CIAN}Directorio temporal de prueba: $DIR_TUTORIAL${RESET}\n"
    read -p "$(echo -e "${CIAN}Presiona Enter para finalizar y limpiar...${RESET}")" -r
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    preparacion
    
    # Cambiar a directorio temporal
    cd "$DIR_TUTORIAL" || exit 1
    
    paso_1 || { echo -e "${ROJO}Error en paso 1${RESET}"; exit 1; }
    paso_2 || { echo -e "${ROJO}Error en paso 2${RESET}"; exit 1; }
    paso_3 || { echo -e "${ROJO}Error en paso 3${RESET}"; exit 1; }
    paso_4 || { echo -e "${ROJO}Error en paso 4${RESET}"; exit 1; }
    paso_5 || { echo -e "${ROJO}Error en paso 5${RESET}"; exit 1; }
    paso_6
    paso_7
    paso_8
    paso_9
    paso_10
    paso_11
    paso_12
    
    clear
    encabezado "🎉 TUTORIAL COMPLETADO"
    echo -e "${VERDE}${NEGRITA}✓ Aprendiste a usar ft_otp.py correctamente${RESET}\n"
    echo -e "Para ejecutar la evaluación automática, usa:\n"
    echo -e "  ${MAGENTA}make evaluation-quiet${RESET}\n"
}

main "$@"
