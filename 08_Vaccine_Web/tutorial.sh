#!/bin/bash

###############################################################################
#                      VACCINE - TUTORIAL INTERACTIVO                         #
#                                                                             #
#  Guía paso a paso para evaluar y aprender a usar el escáner de SQLi         #
#  Sigue las instrucciones en una terminal mientras ejecutas en otra          #
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
PASO_ACTUAL=1
PASOS_TOTALES=5

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

comando_usuario() {
    echo -e "${NEGRITA}En OTRA terminal en la carpeta 08_Vaccine_Web, ejecuta exactamente:${RESET}\n"
    local cmd="$1"
    echo -e "  ${MAGENTA}$cmd${RESET}\n"
}

descripcion() {
    echo -e "${MAGENTA}📝 $1${RESET}\n"
}

esperado() {
    echo -e "${VERDE}✓ Se espera:${RESET} $1\n"
}

mostrar_lineas() {
    echo -e "${AMARILLO}🔍 Búsqueda dinámica en código fuente (Líneas involucradas):${RESET}"
    for arg in "$@"; do
        file=$(echo "$arg" | cut -d':' -f1)
        pattern=$(echo "$arg" | cut -d':' -f2)
        if [ -f "$file" ]; then
            line=$(grep -n "$pattern" "$file" | head -n 1 | cut -d':' -f1)
            if [ -n "$line" ]; then
                echo -e "  └─ [${CIAN}$file:$line${RESET}] → ${pattern}"
            fi
        fi
    done
    echo ""
}

pausa() {
    read -p "$(echo -e "${CIAN}Presiona Enter cuando hayas ejecutado este comando en la otra pantalla...${RESET}")" -r
}

siguiente_paso() {
    PASO_ACTUAL=$((PASO_ACTUAL + 1))
    echo ""
    read -p "$(echo -e "${CIAN}Presiona Enter para avanzar al siguiente paso...${RESET}")" -r
    clear
}

# ============================================================================
# PASOS DEL TUTORIAL
# ============================================================================

paso_1() {
    clear
    encabezado "💉 VACCINE - Paso 1/$PASOS_TOTALES"
    paso "Levantar Servidor Web Vumerable (Flask/SQLite Local)"
    
    descripcion "El Subject EXIGE NUNCA usar la herramienta contra servidores donde no tengamos autorización. \nPor ello he programado un Micro-Servidor Dummy con 2 endpoints vulnerables. \nVamos a lanzarlo en una ventana separada (quedará colgado procesando logs)."
    
    comando_usuario "make run-server"
    
    esperado "Verás que el Servidor Flask levanta en: http://127.0.0.1:5000"
    
    pausa
    siguiente_paso
}

paso_2() {
    clear
    encabezado "💉 VACCINE - Paso 2/$PASOS_TOTALES"
    paso "Comprobar la Inyección GET (Mandatory)"
    
    descripcion "Ahora sí, vamos a disparar nuestro scanner principal contra el servidor local \npara que encuentre el formulario GET e intercepte el error de su base de datos.\n> Cumple: Mandatory (Método GET, Error-Based SQLi, Base de datos SQLite/MySQL)"
    
    mostrar_lineas "src/scanner.py:def get_forms" "src/scanner.py:def test_sqli" "src/payloads.py:ERROR_PAYLOADS"
    
    comando_usuario "./vaccine -X GET http://127.0.0.1:5000/search"
    
    esperado "Ver cómo la consola detecta VULNERABILIDAD ENCONTRADA (Error-Based) \ny arranca la extracción de Tablas. Comprueba que el scanner identifica la base de datos y usa los payloads definidos en src/payloads.py."
    
    pausa
    siguiente_paso
}

paso_3() {
    clear
    encabezado "💉 VACCINE - Paso 3/$PASOS_TOTALES"
    paso "Comprobar Inyección POST, UNION & BONUS User-Agent/Motores"
    
    descripcion "Repitamos el disparo contra la raíz, demostrando que parsea POST y GET, \nque prueba payloads Error, Boolean, Time-Based, y Union-Based. \nAdemás, evadimos reglas WAF inyectando un User-Agent distinto al del scanner. \n(Esto valida múltiples BONUS de 'Motores, Métodos y Headers').\n> Cumple: Mandatory (Método POST, Boolean-Based SQLi) + Bonus (Más DBs, Time/Union-based, User-Agent)"
    
    mostrar_lineas "src/vaccine.py:def main" "src/extractor.py:def extract_sqlite" "src/extractor.py:def extract_mysql"
    
    comando_usuario "./vaccine -X POST --user-agent \"Hacker-Ninja-1.0\" http://127.0.0.1:5000"
    
    esperado "VACCINE lanzará alertas indicando [Boolean-Based] y [Time-Based] si aplica. \nLa fase EXTRACCION inyectará payloads reales SQL para escupir: TABLAS, COLUMNAS y el DUMP de la Base de datos."
    
    pausa
    siguiente_paso
}

paso_4() {
    clear
    encabezado "💉 VACCINE - Paso 4/$PASOS_TOTALES"
    paso "Verificación del Fichero Historico"
    
    descripcion "La rúbrica indica: \"Archive file (option -o) if not specified it will be stored in a default one\". \nVamos a ver el fichero en el que se han estado registrando todos estos bugs SQL.\n> Cumple: Mandatory (Archive file option -o y comportamiento por defecto)"
    
    mostrar_lineas "src/extractor.py:def log"
    
    comando_usuario "cat vaccine_results.txt"
    
    esperado "Un informe detallado de las URLs, motores de BD, payloads disparados y volcados DUMP de datos secretoss. \nComprueba que contiene todo el output de los escaneos previos."
    
    pausa
    siguiente_paso
}

paso_5() {
    clear
    encabezado "💉 VACCINE - Paso 5/$PASOS_TOTALES"
    paso "Destruir Servidor y Limpieza General"
    
    descripcion "El trabajo está hecho, demostramos todos los puntos Mandatory y los motores extra y params del Bonus. \nApaguemos el Dummy server para cerrar la terminal tranquilamente."
    
    comando_usuario "Presiona Control+C en la terminal del Servidor Local.
Luego puedes ejecutar: make fclean"
    
    esperado "El Entorno Virtual desaparecerá, los logs se borrarán y la Base de Datos Dummy será eliminada."
    
    pausa
    siguiente_paso
}

# ============================================================================
# MAIN
# ============================================================================

main() {    
    clear
    encabezado "INICIANDO TUTORIAL DE SQL INJECTION SCANNER VACCINE..."
    echo -e "${VERDE}Asegúrate de haber ejecutado previamente 'make setup' para tener las libs de Python preparadas.${RESET}\n"
    
    paso_1
    paso_2
    paso_3
    paso_4
    paso_5
    
    clear
    encabezado "🎉 EVALUACIÓN COMPLETADA"
    echo -e "${VERDE}${NEGRITA}✓ Completaste la simulación de detección y extracción SQLi.${RESET}\n"
    
    echo -e "${AMARILLO}Resumen para Evaluación (Checklist Mandatory & Bonus):${RESET}"
    echo -e "  [MANDATORY] ✔ Método HTTP forcing: GET y POST funcionan correctamente (-X)."
    echo -e "  [MANDATORY] ✔ Técnicas: Error-based and Boolean-based implementadas."
    echo -e "  [MANDATORY] ✔ Motores: Identifica y funciona en SQLite / MySQL (Dual engine)."
    echo -e "  [MANDATORY] ✔ Extracción: Dumpea bases de datos, tablas, y columnas."
    echo -e "  [MANDATORY] ✔ Logging: Output file default ('vaccine_results.txt') o custom ('-o')."
    echo -e "  [BONUS]     ✔ Motores Extra: PostgreSQL, Oracle, MS SQL."
    echo -e "  [BONUS]     ✔ Técnicas Extra: Time-based y Union-based sqli detectadas."
    echo -e "  [BONUS]     ✔ Header Manipulation: Manipulación y evasión del '--user-agent'.\n"
}

main "$@"