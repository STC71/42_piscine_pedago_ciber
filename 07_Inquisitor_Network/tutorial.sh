#!/bin/bash

###############################################################################
#                     INQUISITOR - TUTORIAL INTERACTIVO                       #
#                                                                             #
#  Guía paso a paso para aprender a usar y evaluar Inquisitor.                #
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
PASOS_TOTALES=6

# ============================================================================
# FUNCIONES DE UTILIDAD
# ============================================================================

encabezado() {
    clear
    echo -e "\n${NEGRITA}${AZUL}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEGRITA}${AZUL}║${RESET} $1"
    echo -e "${NEGRITA}${AZUL}╚════════════════════════════════════════════════════════════╝${RESET}\n"
}

paso() {
    echo -e "${NEGRITA}${CIAN}🔄 PASO $PASO_ACTUAL/$PASOS_TOTALES: $1${RESET}"
    echo -e "${CIAN}─────────────────────────────────────────────────────────────${RESET}\n"
}

comando_terminal() {
    local actor="$1"
    local cmd="$2"
    if [ "$actor" = "BASE" ]; then
        echo -e "${NEGRITA}👉 En tu terminal ${AMARILLO}BASE${RESET}${NEGRITA} (ésta u otra libre), ejecuta:${RESET}\n"
    else
        echo -e "${NEGRITA}👉 En tu terminal designada para el ${AMARILLO}[${actor}]${RESET}${NEGRITA}, ejecuta:${RESET}\n"
    fi
    
    # Imprimimos los comandos con su color para resaltarlos
    echo "$cmd" | while read -r line; do
        echo -e "  ${MAGENTA}$line${RESET}"
    done
    echo ""
}

descripcion() {
    echo -e "${AMARILLO}📝 Contexto:${RESET} $1\n"
}

esperado() {
    echo -e "${VERDE}✓ Presta atención a:${RESET} $1\n"
}

demostrar_codigo() {
    echo -e "${CIAN}🔍 Demostración técnica en el código:${RESET}"
    local archivo="$1"
    local busqueda="$2"
    local explicacion="$3"
    
    echo -e "  Archivo: ${NEGRITA}$archivo${RESET}"
    echo -e "  Motivo: $explicacion\n"
    echo -e "  ${NEGRITA}Líneas involucradas:${RESET}"
    
    # Búsqueda dinámica y muestra de las líneas
    grep -n -C 2 "$busqueda" "$SCRIPT_DIR/$archivo" | while read -r line; do
        echo -e "    ${AMARILLO}$line${RESET}"
    done
    echo ""
}

pausa() {
    read -p "$(echo -e "${CIAN}Presiona Enter cuando hayas ejecutado y revisado los comandos...${RESET}")" -r
}

siguiente_paso() {
    PASO_ACTUAL=$((PASO_ACTUAL + 1))
    echo ""
    read -p "$(echo -e "${CIAN}Presiona Enter para el siguiente paso...${RESET}")" -r
}

# ============================================================================
# PASOS DEL TUTORIAL
# ============================================================================

paso_1() {
    encabezado "🛡️  TUTORIAL INTERACTIVO - Entorno de pruebas"
    paso "Levantar la infraestructura Docker y preparar terminales"
    
    descripcion "Según el subject, no debemos fastidiar la red real de 42. Usaremos un entorno aislado.\n  ${NEGRITA}⚠️  Por favor, para este roleplay prepara 3 terminales y nómbralas: ATACANTE, CLIENTE y SERVIDOR.${RESET}"
    
    comando_terminal "BASE" "make re"
    
    comando_terminal "SERVIDOR" "docker logs -f inquisitor_ftp_server"
    
    esperado "Verás que se levantan las tres imágenes. La terminal del SERVIDOR se quedará bloqueada escuchando permanentemente las subidas al FTP."
    
    demostrar_codigo "docker-compose.yml" "cap_add:" "Es necesario para el Inquisitor tener privilegios de red (NET_ADMIN) en el contenedor atacante para poder hacer IP forwarding."
    
    pausa
    siguiente_paso
}

paso_2() {
    encabezado "📡  TUTORIAL INTERACTIVO - Recopilando datos de red"
    paso "Averiguar las IPs y MACs de nuestras víctimas"
    
    descripcion "Para envenenar (Spoofing) necesitamos las direcciones exactas (IP y MAC) del Cliente y del Servidor."
    
    comando_terminal "ATACANTE" "docker exec -it inquisitor_attacker bash\n# Una vez dentro del contenedor, ejecuta:\nping -c 1 10.0.0.20 && ping -c 1 10.0.0.30\narp -n"
    
    esperado "Anota las direcciones MAC asociadas a 10.0.0.20 (servidor) y 10.0.0.30 (cliente). Las usaremos continuamente en tu terminal ATACANTE."
    
    demostrar_codigo "inquisitor.py" "def check_mac" "El mandatory exige que debes validar que los argumentos parezcan direcciones IP y MAC reales, cosa que confirmamos en Python con Regex."
    
    pausa
    siguiente_paso
}

paso_3() {
    encabezado "☠️  TUTORIAL INTERACTIVO - Ataque Man-In-The-Middle (Mandatory)"
    paso "Ejecutar el Inquisitor en modo estándar"
    
    descripcion "El Inquisitor será ejecutado para interceptar tráfico haciendo 'ARP Poisoning' sin interrumpir la red."
    
    comando_terminal "ATACANTE" "# Sustituye las MACs por las que anotaste en el paso anterior\n./inquisitor 10.0.0.30 <MAC_CLIENTE> 10.0.0.20 <MAC_SERVIDOR>"
    
    esperado "La terminal del ATACANTE se quedará bloqueada imprimiendo 'Envenenamiento ARP iniciado'. Ya eres el puente de red transparente."
    
    demostrar_codigo "inquisitor.py" "_set_ip_forwarding" "El subject exige reenviar el tráfico para no causar negación de servicio (DoS). Activamos el IP Forwarding programáticamente en Linux."
    demostrar_codigo "inquisitor.py" "tcp port 21" "Solo debemos rastrear el tráfico FTP como especifica la parte mandatory, filtrando dinámicamente con scapy."
    
    pausa
    siguiente_paso
}

paso_4() {
    encabezado "📥  TUTORIAL INTERACTIVO - Generando tráfico FTP"
    paso "Simular una subida y bajada de archivos en la red"
    
    descripcion "El atacante ya está espiando en las sombras. Simularemos ser la víctima de la red conectándose al Servidor."
    
    comando_terminal "CLIENTE" "docker exec -it inquisitor_ftp_client bash\n# Una vez dentro de la máquina:\necho 'secreto' > archivo.txt\nftp 10.0.0.20\n# Usa 'user' como usuario y 'pass' como contraseña\n# Dentro del FTP:\nput archivo.txt\nget archivo.txt\nexit"
    
    esperado "En la consola del ${NEGRITA}ATACANTE${RESET} deberías haber visto en directo los mensajes del archivo subido o descargado (STOR y RETR). A su vez, puedes ver en el ${NEGRITA}SERVIDOR${RESET} las peticiones en el log."
    
    demostrar_codigo "inquisitor.py" "payload.upper().startswith(\"RETR \")" "Si filtramos en modo estándar, procesamos las descargas (RETR) y subidas (STOR) mostrando solo los nombres de archivos involucrados."
    
    pausa
    siguiente_paso
}

paso_5() {
    encabezado "👀  TUTORIAL INTERACTIVO - Parte Bonus (-v verbose)"
    paso "Ejecutar Inquisitor en modo verboso para capturar credenciales"
    
    descripcion "Vamos a detener nuestro atacante actual e iniciarlo de nuevo pero exigiendo ver todos los comandos crudos FTP."
    
    comando_terminal "ATACANTE" "CTRL+C (en la terminal del atacante para pararlo)\n# Verás el mensaje de limpieza y restauración...\n\n# Ejecuta otra vez añadiendo el flag -v:\n./inquisitor 10.0.0.30 <MAC_CLIENTE> 10.0.0.20 <MAC_SERVIDOR> -v"

    comando_terminal "CLIENTE" "# Vuelve a loguearte, el atacante debería interceptar credenciales\nftp 10.0.0.20\n# User: user / Password: pass"
    
    esperado "¡Ahora el ${NEGRITA}ATACANTE${RESET} intercepta todo en texto plano! Deberías ver las instrucciones del protocolo como 'USER user' y 'PASS pass', vulnerando contraseñas por red."
    
    demostrar_codigo "inquisitor.py" "if self.verbose:" "La evaluación bonus pide la flag -v que imprime todo el tráfico recabado, útil para robar passwords."
    
    pausa
    siguiente_paso
}

paso_6() {
    encabezado "🧹  TUTORIAL INTERACTIVO - Limpieza y fin"
    paso "Detenemos la arquitectura"
    
    descripcion "Al pulsar CTRL+C tu herramienta envía paquetes correctivos originales a las víctimas y apaga el forwarding. Ya puedes cerrar todas las terminales."
    
    comando_terminal "BASE / CUALQUIERA" "make fclean"
    
    esperado "Los contenedores Inquisitor y la red puente virtual son eliminados, dejando todo limpio. Ya puedes cerrar las terminales extra."
    
    demostrar_codigo "Makefile" "fclean:" "Como todos tus proyectos, el Makefile permite limpiar a fondo tu máquina de estados basura mediante la orden fclean."
    
    pausa
    echo -e "${VERDE}¡TUTORIAL COMPLETADO CON ÉXITO! 🎉${RESET}"
}

# ============================================================================
# EJECUCIÓN PRINCIPAL
# ============================================================================

# Comprobar instalación de dependencias si fuera necesario
if ! command -v docker &> /dev/null; then
    echo -e "${ROJO}Error: Docker no está instalado o no se encuentra en el PATH.${RESET}"
    exit 1
fi

paso_1
paso_2
paso_3
paso_4
paso_5
paso_6

exit 0