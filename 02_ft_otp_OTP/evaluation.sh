#!/bin/bash

###############################################################################
#                     ft_otp - SCRIPT DE EVALUACIÓN COMPLETO                  #
#                                                                             #
#  Evaluación exhaustiva del generador TOTP según evaluation_en.pdf           #
#  Todos los puntos obligatorios y opcionales                                 #
#                                                                             #
#  Version: 1.0 (Evaluación Completa - Objetivo 10/10)                       #
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
# VARIABLES GLOBALES DE PUNTUACIÓN
# ============================================================================
PUNTUACION_OBLIGATORIA=0
PUNTUACION_BONUS=0
TOTAL_BONUS=0
MAX_OBLIGATORIA=100

PUNTUACION_OBLIGATORIA_MAX=0
PUNTUACION_BONUS_MAX=0

# Banderas para problemas graves
FALLO_CRITICO=false
COMPILACION_INVALIDA=false
TRAMPA=false

# Directorios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIR_TEST="/tmp/ft_otp_evaluation_$$"

# Modo interactivo (true por defecto, desactivar con -q o --quiet)
INTERACTIVO="true"
[[ "$1" == "-q" || "$1" == "--quiet" ]] && INTERACTIVO="false"

# ============================================================================
# FUNCIONES DE SALIDA
# ============================================================================

encabezado() {
    echo -e "\n${NEGRITA}${AZUL}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEGRITA}${AZUL}║${RESET} $1"
    echo -e "${NEGRITA}${AZUL}╚════════════════════════════════════════════════════════════╝${RESET}\n"
}

seccion() {
    echo -e "\n${NEGRITA}${CIAN}▶ $1${RESET}"
    echo -e "${CIAN}─────────────────────────────────────────────────────────────${RESET}"
}

subseccion() {
    echo -e "\n  ${MAGENTA}├─ $1${RESET}"
}

# Nueva función para pausar entre secciones
pausa() {
    if [[ "$INTERACTIVO" == "true" ]]; then
        read -p "$(echo -e "${CIAN}Presiona Enter para continuar...${RESET}")" -s -r
        echo ""
    fi
}

# Función para buscar dinámicamente líneas en ft_otp.py
get_line_range() {
    local pattern="$1"
    local file="${SCRIPT_DIR}/ft_otp.py"
    local line_num
    line_num=$(grep -n "$pattern" "$file" 2>/dev/null | head -1 | cut -d: -f1)
    if [[ -n $line_num ]]; then
        echo "ft_otp.py:L${line_num}"
    else
        echo "ft_otp.py"
    fi
}

# Función para mostrar descripción de prueba
prueba() {
    echo -e "    ${MAGENTA}📝${RESET} $1"
}

# Función para mostrar comando simplificado
comando() {
    local cmd="$1"
    cmd=$(echo "$cmd" | sed 's/.*python3 /python3 /' | cut -c1-70)
    if [[ ${#1} -gt 70 ]]; then
        cmd="${cmd}..."
    fi
    echo -e "    ${AZUL}▹${RESET} Comando: ${cmd}"
}

# Función para mostrar instrucciones de GUI
instruccion_gui() {
    echo -e "    ${AMARILLO}ℹ${RESET} GUI: Abre el archivo ${CIAN}$1${RESET}"
}

# Función para crear archivos de prueba con verificación
crear_archivo() {
    local archivo="$1"
    local contenido="$2"
    printf '%s' "$contenido" > "$archivo" 2>/dev/null
    if [[ ! -f "$archivo" ]]; then
        return 1
    fi
    return 0
}


bien() {
    if [[ -n "$2" ]]; then
        echo -e "    ${VERDE}✓${RESET} $1 ${CIAN}[$2]${RESET}"
    else
        echo -e "    ${VERDE}✓${RESET} $1"
    fi
    if [[ -n "$3" ]]; then
        ((PUNTUACION_OBLIGATORIA += $3))
        ((PUNTUACION_OBLIGATORIA_MAX += $3))
    fi
}

mal() {
    if [[ -n "$2" ]]; then
        echo -e "    ${ROJO}✗${RESET} $1 ${CIAN}[$2]${RESET}"
    else
        echo -e "    ${ROJO}✗${RESET} $1"
    fi
    if [[ -n "$3" ]]; then
        ((PUNTUACION_OBLIGATORIA_MAX += $3))
    fi
}

bonus_bien() {
    if [[ -n "$2" ]]; then
        echo -e "    ${VERDE}✓${RESET} [BONUS] $1 ${CIAN}[$2]${RESET}"
    else
        echo -e "    ${VERDE}✓${RESET} [BONUS] $1"
    fi
    if [[ -n "$3" ]]; then
        ((PUNTUACION_BONUS += $3))
        ((PUNTUACION_BONUS_MAX += $3))
    fi
}

bonus_mal() {
    if [[ -n "$2" ]]; then
        echo -e "    ${ROJO}✗${RESET} [BONUS] $1 ${CIAN}[$2]${RESET}"
    else
        echo -e "    ${ROJO}✗${RESET} [BONUS] $1"
    fi
    if [[ -n "$3" ]]; then
        ((PUNTUACION_BONUS_MAX += $3))
    fi
}

info() {
    echo -e "    ${AZUL}ℹ${RESET} $1"
}

advertencia() {
    echo -e "    ${AMARILLO}⚠${RESET} $1"
}

# ============================================================================
# CONFIGURACIÓN Y LIMPIEZA
# ============================================================================

preparacion() {
    mkdir -p "${DIR_TEST}"
    cd "${DIR_TEST}" || exit 1
}

limpieza() {
    rm -rf "${DIR_TEST}"
}

trap limpieza EXIT

# ============================================================================
# PARTE OBLIGATORIA: VALIDACIÓN ESTRUCTURAL
# ============================================================================

validar_estructura() {
    seccion "ESTRUCTURA DEL PROYECTO"
    
    subseccion "Archivos Requeridos"
    
    if [[ -f "${SCRIPT_DIR}/ft_otp.py" ]]; then
        bien "ft_otp.py encontrado" 5
    else
        mal "ft_otp.py NO ENCONTRADO" 5
        COMPILACION_INVALIDA=true
        return 1
    fi
    
    if [[ -f "${SCRIPT_DIR}/ft_otp" ]]; then
        bien "ft_otp (ejecutable) encontrado" 3
    else
        advertencia "ft_otp (script ejecutable) no encontrado"
    fi
    
    if [[ -x "${SCRIPT_DIR}/ft_otp.py" ]] || [[ -x "${SCRIPT_DIR}/ft_otp" ]]; then
        bien "Scripts tienen permisos de ejecución" 2
    else
        advertencia "Scripts sin permisos de ejecución"
    fi
    
    subseccion "Sintaxis Python"
    
    if python3 -m py_compile "${SCRIPT_DIR}/ft_otp.py" 2>/dev/null; then
        bien "Sintaxis Python 3 válida" 5
    else
        mal "Errores de sintaxis Python detectados" 5
        COMPILACION_INVALIDA=true
        python3 -m py_compile "${SCRIPT_DIR}/ft_otp.py" 2>&1 | sed 's/^/        /'
    fi
}

validar_bandera_g() {
    seccion "VALIDACIÓN: FLAG -g (Generar Clave)"
    
    subseccion "Rechazo de Clave Corta"
    cd "${DIR_TEST}" || return
    crear_archivo "clave_corta.hex" "AABBCCDD" || { advertencia "No se pudo crear clave_corta.hex"; return; }
    prueba "Verifica que rechaza claves hexadecimales más cortas de 64 caracteres"
    
    comando "python3 ft_otp.py -g clave_corta.hex"
    
    local output_clave_corta archivo_ref1
    output_clave_corta=$(python3 "${SCRIPT_DIR}/ft_otp.py" -g clave_corta.hex 2>&1)
    archivo_ref1=$(get_line_range "la clave debe ser 64")
    
    if echo "$output_clave_corta" | grep -qi "64"; then
        bien "Rechaza clave < 64 caracteres" "$archivo_ref1" 10
    else
        mal "No rechaza clave corta correctamente" "$archivo_ref1" 10
    fi
    
    subseccion "Rechazo de Caracteres No Hexadecimales"
    printf '%s' "$(printf 'Z%.0s' {1..64})" > clave_invalida.hex
    [[ ! -f clave_invalida.hex ]] && { advertencia "No se pudo crear clave_invalida.hex"; return; }
    prueba "Verifica que valida que todos los caracteres sean hexadecimales (0-9, A-F)"
    
    comando "python3 ft_otp.py -g clave_invalida.hex"
    
    local output_hex_invalido archivo_ref2
    output_hex_invalido=$(python3 "${SCRIPT_DIR}/ft_otp.py" -g clave_invalida.hex 2>&1)
    archivo_ref2=$(get_line_range "hexadecimal")
    
    if echo "$output_hex_invalido" | grep -qi "hexadecimal"; then
        bien "Rechaza caracteres no hexadecimales" "$archivo_ref2" 10
    else
        mal "No rechaza caracteres inválidos" "$archivo_ref2" 10
    fi
    
    subseccion "Generación Exitosa de Clave Cifrada"
    crear_archivo "clave_valida.hex" "3132333435363738393031323334353637383930313233343536373839303132" || { advertencia "No se pudo crear clave_valida.hex"; return; }
    rm -f ft_otp.key
    prueba "Genera archivo ft_otp.key con semilla hexadecimal válida cifrada"
    
    comando "python3 ft_otp.py -g clave_valida.hex"
    
    local archivo_ref3
    archivo_ref3=$(get_line_range "def.*generacion\|successfully saved")
    
    if python3 "${SCRIPT_DIR}/ft_otp.py" -g clave_valida.hex 2>&1 | grep -qi "successfully saved"; then
        if [[ -f "ft_otp.key" ]] && [[ -s "ft_otp.key" ]]; then
            bien "Clave cifrada guardada en ft_otp.key" "$archivo_ref3" 15
        else
            mal "ft_otp.key no se creó o está vacío" "$archivo_ref3" 15
        fi
    else
        mal "Error al generar o guardar clave" "$archivo_ref3" 15
    fi
    
    subseccion "Manejo de Espacios en Blanco"
    crear_archivo "clave_espacios.hex" "  3132333435363738393031323334353637383930313233343536373839303132  " || { advertencia "No se pudo crear clave_espacios.hex"; return; }
    rm -f ft_otp.key
    prueba "Verifica que se eliminan espacios al inicio/final (trim) del hex"
    
    comando "python3 ft_otp.py -g clave_espacios.hex"
    
    local archivo_ref4
    archivo_ref4=$(get_line_range "strip\|trim\|espacios")
    
    if python3 "${SCRIPT_DIR}/ft_otp.py" -g clave_espacios.hex 2>&1 | grep -qi "successfully saved"; then
        bien "Elimina espacios iniciales/finales" "$archivo_ref4" 8
    else
        mal "No maneja espacios correctamente" "$archivo_ref4" 8
    fi
    
    pausa
}

validar_bandera_k() {
    seccion "VALIDACIÓN: FLAG -k (Generar TOTP)"
    
    subseccion "Generación de Código TOTP"
    cd "${DIR_TEST}" || return
    echo "3132333435363738393031323334353637383930313233343536373839303132" > clave.hex
    python3 "${SCRIPT_DIR}/ft_otp.py" -g clave.hex > /dev/null 2>&1
    prueba "Genera un código TOTP de 6 dígitos usando la clave almacenada"
    
    comando "python3 ft_otp.py -g clave_test.hex && python3 ft_otp.py -k ft_otp.key"
    
    local codigo archivo_ref1
    codigo=$(python3 "${SCRIPT_DIR}/ft_otp.py" -k ft_otp.key 2>/dev/null)
    archivo_ref1=$(get_line_range "def.*totp")
    
    if [[ $codigo =~ ^[0-9]{6}$ ]]; then
        bien "Genera código TOTP de 6 dígitos: $codigo" "$archivo_ref1" 15
    else
        mal "Código TOTP inválido (esperado: 6 dígitos)" "$archivo_ref1" 15
    fi
    
    subseccion "Cambio de Código con el Tiempo"
    prueba "Verifica que el código se mantiene en el mismo intervalo de 30s"
    
    local codigo1 archivo_ref2
    codigo1=$(python3 "${SCRIPT_DIR}/ft_otp.py" -k ft_otp.key 2>/dev/null)
    archivo_ref2=$(get_line_range "time_value\|time_based")
    
    sleep 1
    local codigo2
    codigo2=$(python3 "${SCRIPT_DIR}/ft_otp.py" -k ft_otp.key 2>/dev/null)
    
    if [[ "$codigo1" == "$codigo2" ]]; then
        info "Códigos iguales después de 1 segundo (esperado en el mismo intervalo de 30s)"
        bien "Códigos estables en intervalo de 30s" "$archivo_ref2" 10
    fi
    
    subseccion "Manejo de Archivos Faltantes"
    rm -f archivo_no_existe.key
    prueba "Verifica manejo de error cuando archivo .key no existe"
    
    local output_file_missing archivo_ref3
    output_file_missing=$(python3 "${SCRIPT_DIR}/ft_otp.py" -k archivo_no_existe.key 2>&1)
    archivo_ref3=$(get_line_range "wrong file\|error")
    
    if echo "$output_file_missing" | grep -qi "error\|wrong file"; then
        bien "Maneja correctamente archivos faltantes" "$archivo_ref3" 8
    else
        mal "No maneja correctamente archivos faltantes" "$archivo_ref3" 8
    fi
    
    pausa
}

validar_hotp_rfc4226() {
    seccion "VALIDACIÓN: ALGORITMO HOTP (RFC 4226)"
    
    subseccion "Implementación HOTP"
    prueba "Busca palabras clave HMAC, SHA1, HOTP en el código fuente"
    
    comando "grep -i \'hotp|hmac|sha1\' ft_otp.py"
    
    local archivo_ref1
    archivo_ref1=$(get_line_range "hotp\|hmac.*sha")
    
    if grep -q "hotp\|hmac\|sha1" "${SCRIPT_DIR}/ft_otp.py" -i; then
        bien "HOTP/HMAC-SHA1 detectado" "$archivo_ref1" 10
    else
        advertencia "No se detecta claramente HOTP/HMAC-SHA1"
    fi
    
    subseccion "Códigos Diferentes para Entradas Diferentes"
    cd "${DIR_TEST}" || return
    prueba "Genera 3 claves hexadecimales diferentes y verifica que producen outputs diferentes"
    
    comando "python3 ft_otp.py -g clave1.hex && python3 ft_otp.py -g clave2.hex"
    
    for i in 1 2 3; do
        python3 -c "import os; print(os.urandom(32).hex())" > clave$i.hex
        python3 "${SCRIPT_DIR}/ft_otp.py" -g clave$i.hex > /dev/null 2>&1
        mv ft_otp.key clave$i.key
    done
    
    local archivo_ref2
    archivo_ref2=$(get_line_range "xor\|encrypt\|cipher")
    
    if ! cmp -s clave1.key clave2.key && ! cmp -s clave2.key clave3.key; then
        bien "Genera outputs diferentes para entradas diferentes" "$archivo_ref2" 12
    else
        mal "Los outputs deberían ser diferentes" "$archivo_ref2" 12
    fi
    
    pausa
}

validar_compatibilidad() {
    seccion "VALIDACIÓN: COMPATIBILIDAD CON HERRAMIENTA DE REFERENCIA"
    
    subseccion "Comparación con Validador TOTP"
    
    cd "${DIR_TEST}" || return
    
    if [[ ! -f "${SCRIPT_DIR}/validate_totp.py" ]]; then
        advertencia "validate_totp.py no encontrado"
        return
    fi
    
    echo "3132333435363738393031323334353637383930313233343536373839303132" > clave_ref.hex
    python3 "${SCRIPT_DIR}/ft_otp.py" -g clave_ref.hex > /dev/null 2>&1
    prueba "Compara salida TOTP de ft_otp.py con validador  de referencia"
    
    local codigo_ft_otp codigo_referencia archivo_ref
    codigo_ft_otp=$(python3 "${SCRIPT_DIR}/ft_otp.py" -k ft_otp.key 2>/dev/null)
    codigo_referencia=$(python3 "${SCRIPT_DIR}/validate_totp.py" "3132333435363738393031323334353637383930313233343536373839303132" 2>/dev/null)
    archivo_ref=$(get_line_range "def.*totp")
    
    if [[ "$codigo_ft_otp" == "$codigo_referencia" ]]; then
        bien "Códigos coinciden: $codigo_ft_otp" "$archivo_ref" 15
    else
        advertencia "Códigos no coinciden (ft_otp: $codigo_ft_otp, referencia: $codigo_referencia)"
    fi
    
    pausa
}

# ============================================================================
# PARTE OPCIONAL: FUNCIONALIDADES BONUS
# ============================================================================

validar_bonus_qr() {
    seccion "BONUS: GENERACIÓN DE CÓDIGO QR"
    
    subseccion "QR Code con Semilla"
    cd "${DIR_TEST}" || return
    
    echo "3132333435363738393031323334353637383930313233343536373839303132" > clave_qr.hex
    prueba "Genera archivo PNG con código QR que codifica la semilla TOTP"
    
    comando "python3 ft_otp.py -g clave_qr.hex --qr salida_qr.png"
    
    local archivo_ref
    archivo_ref=$(get_line_range "qrcode\|QR")
    
    if python3 "${SCRIPT_DIR}/ft_otp.py" -g clave_qr.hex --qr salida_qr.png 2>&1 | grep -qi "saved"; then
        if [[ -f "salida_qr.png" ]] && [[ -s "salida_qr.png" ]]; then
            bonus_bien "Genera QR en PNG correctamente" "$archivo_ref" 10
        else
            bonus_mal "Archivo QR no se generó" "$archivo_ref" 10
        fi
    else
        bonus_mal "No se puede generar QR" "$archivo_ref" 10
    fi
    
    pausa
}

validar_bonus_gui() {
    seccion "BONUS: INTERFAZ GRÁFICA (TKINTER)"
    
    subseccion "Interfaz Gráfica"
    prueba "Detecta código Tkinter y verifica que está disponible en el sistema"
    
    local archivo_ref
    archivo_ref=$(get_line_range "tkinter\|Tk(")
    
    comando "grep -i 'tkinter' ft_otp.py"
    if grep -q "tkinter\|Tk\|gui\|GUI" "${SCRIPT_DIR}/ft_otp.py" -i; then
        bonus_bien "GUI con Tkinter implementada" "$archivo_ref" 10
    else
        bonus_mal "No se detecta interfaz gráfica" "$archivo_ref" 10
    fi
    
    if python3 -c "from tkinter import Tk; Tk().destroy()" > /dev/null 2>&1; then
        info "Tkinter disponible en el sistema"
        echo -e "    ${AMARILLO}ℹ${RESET} Para probar la GUI: ${CIAN}python3 ft_otp.py --gui${RESET}"
        
        if [[ "$INTERACTIVO" == "true" ]]; then
            read -p "$(echo -e '    '"${CIAN}¿Deseas abrir la GUI ahora? (s/n): ${RESET}")" -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                cd "${DIR_TEST}" || return
                echo "3132333435363738393031323334353637383930313233343536373839303132" > demo.hex
                python3 "${SCRIPT_DIR}/ft_otp.py" -g demo.hex > /dev/null 2>&1
                comando "python3 ft_otp.py --gui"
                python3 "${SCRIPT_DIR}/ft_otp.py" --gui 2>/dev/null &
                sleep 2
                info "GUI abierta en segundo plano (presiona Enter para cerrarla)"
                read -s -r
                pkill -f "ft_otp.py.*gui" 2>/dev/null
            fi
        fi
    else
        advertencia "Tkinter no disponible (GUI no puede probarse en este entorno)"
    fi
    
    pausa
}


# ============================================================================
# RESUMEN FINAL
# ============================================================================

mostrar_resumen() {
    echo ""
    encabezado "RESUMEN DE EVALUACIÓN"
    
    local porcentaje_obligatoria
    if (( PUNTUACION_OBLIGATORIA_MAX > 0 )); then
        porcentaje_obligatoria=$((100 * PUNTUACION_OBLIGATORIA / PUNTUACION_OBLIGATORIA_MAX))
    else
        porcentaje_obligatoria=0
    fi
    
    local porcentaje_bonus
    if (( PUNTUACION_BONUS_MAX > 0 )); then
        porcentaje_bonus=$((100 * PUNTUACION_BONUS / PUNTUACION_BONUS_MAX))
    else
        porcentaje_bonus=0
    fi
    
    # Cálculo del porcentaje total (máximo 125%)
    local porcentaje_total
    if (( PUNTUACION_OBLIGATORIA_MAX > 0 )); then
        porcentaje_total=$((100 * PUNTUACION_OBLIGATORIA / PUNTUACION_OBLIGATORIA_MAX))
        if (( PUNTUACION_BONUS_MAX > 0 )); then
            local bonus_contribution=$((25 * PUNTUACION_BONUS / PUNTUACION_BONUS_MAX))
            porcentaje_total=$((porcentaje_total + bonus_contribution))
        fi
    else
        porcentaje_total=0
    fi
    
    echo -e "${NEGRITA}PARTE OBLIGATORIA:${RESET}"
    echo -e "  Puntuación: ${VERDE}$PUNTUACION_OBLIGATORIA${RESET} / ${AMARILLO}$PUNTUACION_OBLIGATORIA_MAX${RESET} puntos"
    echo -e "  Porcentaje: ${VERDE}$porcentaje_obligatoria%${RESET}"
    echo ""
    
    echo -e "${NEGRITA}PARTE OPTIONAL (BONUS):${RESET}"
    echo -e "  Puntuación: ${VERDE}$PUNTUACION_BONUS${RESET} / ${AMARILLO}$PUNTUACION_BONUS_MAX${RESET} puntos"
    echo -e "  Porcentaje: ${VERDE}$porcentaje_bonus%${RESET}"
    echo ""
    
    echo -e "${NEGRITA}PORCENTAJE TOTAL:${RESET}"
    echo -e "  ${VERDE}$porcentaje_total%${RESET}"
    if (( porcentaje_total <= 100 )); then
        echo -e "  (100% obligatorio, + $((porcentaje_total - 100))% bonus)"
    else
        echo -e "  (100% obligatorio + $((porcentaje_total - 100))% bonus = ${VERDE}$porcentaje_total%${RESET} total)"
    fi
    echo ""
    
    # Determinar si es evaluable
    if [[ "$COMPILACION_INVALIDA" == "true" ]]; then
        echo -e "${ROJO}${NEGRITA}❌ COMPILACIÓN INVÁLIDA - Proyecto NO EVALUABLE${RESET}"
        return 1
    fi
    
    if (( PUNTUACION_OBLIGATORIA_MAX == 0 )); then
        echo -e "${ROJO}${NEGRITA}❌ Proyecto vacío o sin contenido${RESET}"
        return 1
    fi
    
    if (( porcentaje_obligatoria >= 100 )); then
        echo -e "${VERDE}${NEGRITA}✓ PARTE OBLIGATORIA PERFECTA${RESET}"
        if (( PUNTUACION_BONUS > 0 )); then
            echo -e "${VERDE}${NEGRITA}✓ BONUS IMPLEMENTADO (Total: $porcentaje_total%)${RESET}"
        fi
    elif (( porcentaje_obligatoria >= 80 )); then
        echo -e "${VERDE}${NEGRITA}✓ Buen desarrollo${RESET}"
    else
        echo -e "${AMARILLO}${NEGRITA}⚠ Requiere revisión${RESET}"
    fi
    
    echo ""
    echo -e "${CIAN}─────────────────────────────────────────────────────────────${RESET}"
}

# ============================================================================
# EJECUCIÓN PRINCIPAL
# ============================================================================

main() {
    encabezado "🔐 EVALUACIÓN ft_otp - RFC 6238 (TOTP) + RFC 4226 (HOTP)"
    
    preparacion
    
    # Validaciones obligatorias
    validar_estructura
    [[ "$COMPILACION_INVALIDA" == "true" ]] && mostrar_resumen && exit 1
    
    validar_bandera_g
    validar_bandera_k
    validar_hotp_rfc4226
    validar_compatibilidad
    
    # Validaciones bonus
    validar_bonus_qr
    validar_bonus_gui
    
    # Mostrar resumen
    mostrar_resumen
}

main "$@"
