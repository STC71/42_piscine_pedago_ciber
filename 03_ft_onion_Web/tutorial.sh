#!/bin/bash

# ============================================================================
#  FT_ONION - TUTORIAL DE EVALUACION
# ============================================================================
#  Guia interactiva para preparar y ejecutar la evaluacion de ft_onion
#  Basado en en.subject.pdf + evaluation_en.pdf
# ============================================================================

set -o pipefail

# Colores
readonly ROJO='\033[0;31m'
readonly VERDE='\033[0;32m'
readonly AMARILLO='\033[1;33m'
readonly AZUL='\033[0;34m'
readonly CIAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NEGRITA='\033[1m'
readonly RESET='\033[0m'

# Configuracion
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_NAME="ft_onion"
readonly CONTAINER_NAME="ft_onion_container"
readonly IMAGE_NAME="ft_onion:latest"

PASO_ACTUAL=1
PASOS_TOTALES=10
MODO_AUTO=false
SSH_HOST_PORT="4243"

# ============================================================================
#  UTILIDADES
# ============================================================================

encabezado() {
    clear
    echo -e "\n${NEGRITA}${AZUL}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEGRITA}${AZUL}║${RESET} $1"
    echo -e "${NEGRITA}${AZUL}╚════════════════════════════════════════════════════════════╝${RESET}\n"
}

paso() {
    echo -e "${NEGRITA}${CIAN}PASO $PASO_ACTUAL/$PASOS_TOTALES: $1${RESET}"
    echo -e "${CIAN}─────────────────────────────────────────────────────────────${RESET}\n"
}

info() {
    echo -e "${AZUL}[INFO]${RESET} $1"
}

ok() {
    echo -e "${VERDE}[OK]${RESET} $1"
}

warn() {
    echo -e "${AMARILLO}[WARN]${RESET} $1"
}

err() {
    echo -e "${ROJO}[ERROR]${RESET} $1"
}

bloque_cmd() {
    echo -e "${NEGRITA}Comando(s):${RESET}"
    echo -e "${MAGENTA}$1${RESET}\n"
}

esperado() {
    echo -e "${VERDE}Se espera:${RESET} $1\n"
}

qa() {
    echo -e "${NEGRITA}${AMARILLO}Pregunta tipica:${RESET} $1"
    echo -e "${VERDE}Respuesta corta:${RESET} $2\n"
}

ref_dinamica() {
    local archivo="$1"
    local patron="$2"
    local etiqueta="$3"
    local ruta="$SCRIPT_DIR/$archivo"
    local linea

    if [[ ! -f "$ruta" ]]; then
        warn "Referencia no disponible ($etiqueta): falta $archivo"
        return 1
    fi

    linea="$(grep -n -m1 -E "$patron" "$ruta" 2>/dev/null | cut -d: -f1)"
    if [[ -n "$linea" ]]; then
        echo -e "${CIAN}Referencia dinamica:${RESET} $etiqueta -> $archivo:$linea"
        return 0
    fi

    warn "Patron no encontrado para $etiqueta en $archivo"
    return 1
}

mostrar_refs_mandatory() {
    ref_dinamica "Dockerfile" "COPY nginx\\.conf /etc/nginx/nginx\\.conf" "Docker usa nginx.conf root"
    ref_dinamica "Dockerfile" "COPY torrc /etc/tor/torrc" "Docker usa torrc root"
    ref_dinamica "Dockerfile" "COPY sshd_config /etc/ssh/sshd_config" "Docker usa sshd_config root"
    ref_dinamica "Dockerfile" "COPY index\\.html /var/www/html/index\\.html" "Docker usa index.html root"
    ref_dinamica "sshd_config" "^Port 4242" "Puerto SSH mandatory"
    ref_dinamica "sshd_config" "^PubkeyAuthentication yes" "Auth por clave habilitada"
    ref_dinamica "sshd_config" "^PasswordAuthentication yes" "Auth por password habilitada para evaluacion"
    ref_dinamica "sshd_config" "^# PasswordAuthentication no" "Modo key-only preparado (comentado)"
    ref_dinamica "torrc" "^HiddenServicePort 80 127\\.0\\.0\\.1:80" "Publicacion web por Tor"
    ref_dinamica "torrc" "^HiddenServicePort 4242 127\\.0\\.0\\.1:4242" "Publicacion SSH por Tor"
}

validar_estrategia_auth_ssh() {
    local f="$SCRIPT_DIR/sshd_config"

    if [[ ! -f "$f" ]]; then
        warn "No se puede validar estrategia SSH: falta sshd_config"
        return 1
    fi

    if grep -qE '^PubkeyAuthentication yes' "$f" && grep -qE '^PasswordAuthentication yes' "$f"; then
        ok "Estrategia recomendada para evaluacion detectada: PasswordAuthentication yes + PubkeyAuthentication yes"
        return 0
    fi

    warn "No coincide con la estrategia recomendada para evaluar (password+pubkey)"
    return 1
}

mostrar_proceso_key_only() {
    cat << 'EOF'
Proceso post-evaluacion para activar key-only (sin password):
1) Editar sshd_config y dejar:
   - PasswordAuthentication no
   - PubkeyAuthentication yes
2) Validar sintaxis dentro del contenedor:
   docker exec ft_onion_container sshd -t
3) Reiniciar servicio SSH dentro del contenedor:
   docker exec ft_onion_container service ssh restart
4) Probar acceso SOLO con clave:
   ssh -i /ruta/a/tu_clave -p <SSH_HOST_PORT> user@127.0.0.1
5) Si te bloqueas, rollback rapido:
   - volver PasswordAuthentication yes
   - repetir sshd -t y restart
EOF
}

pausa() {
    if [[ "$MODO_AUTO" == "true" ]]; then
        return
    fi
    read -r -p "$(echo -e "${CIAN}Pulsa Enter para continuar...${RESET}")"
}

siguiente_paso() {
    PASO_ACTUAL=$((PASO_ACTUAL + 1))
    pausa
}

comprobar_archivos_root() {
    local faltan=0
    local archivos=("index.html" "nginx.conf" "sshd_config" "torrc" "Dockerfile" "Makefile")

    for f in "${archivos[@]}"; do
        if [[ -f "$SCRIPT_DIR/$f" ]]; then
            ok "Existe: $f"
        else
            err "Falta: $f"
            faltan=1
        fi
    done

    return $faltan
}

imagen_existe() {
    docker image inspect "$IMAGE_NAME" >/dev/null 2>&1
}

contenedor_activo() {
    [[ "$(docker ps --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}')" == "$CONTAINER_NAME" ]]
}

obtener_onion() {
    docker exec "$CONTAINER_NAME" cat /var/lib/tor/hidden_service/hostname 2>/dev/null | tr -d '\r\n'
}

verificar_onion() {
    local onion
    onion="$(obtener_onion)"

    if [[ "$onion" =~ ^[a-z2-7]{56}\.onion$ ]]; then
        ok "Direccion onion valida detectada: $onion"
        return 0
    fi

    warn "Direccion onion aun no disponible o formato no valido"
    return 1
}

mostrar_discurso_defensa() {
    cat << 'EOF'
1) Nginx escucha en localhost:80 y Tor expone el servicio via HiddenServicePort 80.
2) SSH usa puerto 4242 (requisito mandatory) y root login esta deshabilitado.
3) El servicio no actua como relay publico (ExitPolicy reject *:*).
4) Docker se usa para reproducibilidad: build limpio, run controlado, validaciones directas.
5) Si el host tiene conflicto en 4242, se usa SSH_HOST_PORT (ej. 4243) sin romper requisito interno.
EOF
}

# ============================================================================
#  EJECUCION DE PASOS
# ============================================================================

paso_1_contexto() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Objetivo y estrategia"

    info "Este tutorial prioriza pasar mandatory con estabilidad y defensa clara."
    info "En bonus, se recomienda no romper accesibilidad SSH durante evaluacion."
    echo ""
    esperado "Flujo reproducible: fclean -> build -> up -> validate -> onion"
    esperado "Checklist mandatory completo y demostrable"
    qa "Que priorizas: bonus o mandatory?" "Primero mandatory estable y reproducible; bonus sin romper la demo."

    siguiente_paso
}

paso_2_prechecks() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Prechecks del entorno"

    bloque_cmd "cd \"$SCRIPT_DIR\""

    if command -v docker >/dev/null 2>&1; then
        ok "Docker disponible"
    else
        err "Docker no esta instalado o no esta en PATH"
        exit 1
    fi

    if command -v make >/dev/null 2>&1; then
        ok "make disponible"
    else
        err "make no esta instalado"
        exit 1
    fi

    info "Comprobando archivos mandatory en la raiz..."
    if ! comprobar_archivos_root; then
        err "No se puede continuar: faltan archivos mandatory en raiz"
        exit 1
    fi

    echo ""
    mostrar_refs_mandatory
    validar_estrategia_auth_ssh || true
    echo ""
    qa "Como pruebas que no inventaste lineas?" "Uso busqueda dinamica por patron con grep -n, sin hardcode de numeros."
    qa "Que config SSH usas para evaluar?" "PasswordAuthentication yes + PubkeyAuthentication yes para evitar bloqueo del evaluador."

    siguiente_paso
}

paso_3_clean_start() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Reinicio limpio (obligatorio antes de evaluar)"

    local cmd="cd \"$SCRIPT_DIR\" && make fclean"
    bloque_cmd "$cmd"

    if [[ "$MODO_AUTO" == "true" ]]; then
        eval "$cmd" || { err "Fallo make fclean"; exit 1; }
        ok "make fclean completado"
    else
        info "Ejecuta el comando en otra terminal"
    fi

    esperado "Sin contenedor activo y sin imagen previa"
    qa "Por que haces fclean antes de evaluar?" "Para demostrar reproducibilidad desde cero y evitar estado residual."
    siguiente_paso
}

paso_4_build() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Build de la imagen"

    local cmd="cd \"$SCRIPT_DIR\" && make build"
    bloque_cmd "$cmd"

    if [[ "$MODO_AUTO" == "true" ]]; then
        eval "$cmd" || { err "Fallo make build"; exit 1; }
    else
        info "Ejecuta el comando en otra terminal"
    fi

    if imagen_existe; then
        ok "Imagen construida: $IMAGE_NAME"
    else
        warn "No se detecta imagen aun (si estas en modo manual, continua tras build)"
    fi

    esperado "Build exitoso sin errores"
    qa "Que garantiza Docker aqui?" "Que el evaluador obtenga el mismo entorno y resultado."
    siguiente_paso
}

paso_5_up() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Levantar contenedor para evaluacion"

    local cmd="cd \"$SCRIPT_DIR\" && make up SSH_HOST_PORT=$SSH_HOST_PORT"
    bloque_cmd "$cmd"

    if [[ "$MODO_AUTO" == "true" ]]; then
        eval "$cmd" || { err "Fallo make up"; exit 1; }
    else
        info "Ejecuta el comando en otra terminal"
    fi

    if contenedor_activo; then
        ok "Contenedor activo: $CONTAINER_NAME"
    else
        warn "No se detecta contenedor activo aun"
    fi

    esperado "Contenedor arriba, servicios iniciados, onion en inicializacion"
    qa "Si el host usa 4242, incumples el subject?" "No; dentro del contenedor SSH sigue en 4242, solo cambia el mapeo host."
    siguiente_paso
}

paso_6_validaciones() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Validaciones mandatory"

    local cmd="cd \"$SCRIPT_DIR\" && make validate-nginx && make validate-tor && make validate-ssh"
    bloque_cmd "$cmd"

    if [[ "$MODO_AUTO" == "true" ]]; then
        eval "$cmd" || { err "Fallo alguna validacion mandatory"; exit 1; }
        ok "Validaciones mandatory completadas"
    else
        info "Ejecuta y revisa que todas den OK"
    fi

    esperado "Nginx syntax OK, HiddenService* presente, SSH en puerto 4242"
    qa "Como demuestras mandatory rapido?" "Con validate-nginx, validate-tor y validate-ssh en la misma sesion."
    siguiente_paso
}

paso_7_onion() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Direccion .onion y prueba web"

    local cmd="cd \"$SCRIPT_DIR\" && make onion-address"
    bloque_cmd "$cmd"

    if [[ "$MODO_AUTO" == "true" ]]; then
        eval "$cmd" || true
        sleep 2
        verificar_onion || true
    else
        info "Ejecuta comando y comprueba formato v3 de 56 caracteres"
    fi

    esperado "Direccion con formato xxxxxxxxx...(56).onion"
    esperado "Abrirla en Tor Browser y ver index.html"
    qa "Que prueba que es hidden service real?" "Hostname v3 de 56 caracteres .onion generado por Tor en hidden_service/hostname."
    siguiente_paso
}

paso_8_ssh_demo() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Demostracion SSH (puerto host configurable)"

    local cmd="ssh -p $SSH_HOST_PORT user@127.0.0.1"
    bloque_cmd "$cmd"

    info "Si 4242 esta ocupado en tu host, usa $SSH_HOST_PORT como ya configuraste en make up"
    info "En defensa, explica que dentro del contenedor SSH sigue en 4242 (requisito mandatory)"

    esperado "Login correcto con user/password"
    esperado "Dentro del contenedor, puerto SSH configurado: 4242"
    qa "Por que no root por SSH?" "Porque root login esta deshabilitado en la configuracion SSH."
    qa "Y el modo key-only?" "Ya esta preparado en sshd_config como PasswordAuthentication no comentado, listo para activar despues."
    siguiente_paso
}

paso_9_defensa() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Guion corto para defender arquitectura y seguridad"

    mostrar_discurso_defensa
    echo ""

    esperado "Responder en 60-90 segundos por que cumple mandatory"
    esperado "Mencionar bonus sin sacrificar estabilidad de la demo"
    qa "Por que Nginx escucha en localhost y no publico?" "Porque Tor es la unica puerta de entrada anonima al servicio."
    echo ""
    ref_dinamica "sshd_config" "^PasswordAuthentication yes" "Punto actual recomendado para evaluar"
    ref_dinamica "sshd_config" "^# PasswordAuthentication no" "Punto preparado para key-only"
    echo ""
    mostrar_proceso_key_only
    siguiente_paso
}

paso_10_checklist_final() {
    encabezado "FT_ONION - TUTORIAL DE EVALUACION"
    paso "Checklist final antes de sentarte a evaluar"

    cat << 'EOF'
[ ] index.html, nginx.conf, sshd_config y torrc en raiz del repo
[ ] make fclean ejecutado antes del ensayo final
[ ] make build && make up SSH_HOST_PORT=<puerto> sin errores
[ ] make validate-nginx / validate-tor / validate-ssh en verde
[ ] direccion .onion visible y valida
[ ] acceso SSH demostrado
[ ] explicacion clara: Nginx local + Tor publica + SSH 4242 + no relay
EOF

    echo ""
    qa "Como cierras la defensa?" "Mandatory cumplido con evidencias en vivo y arquitectura explicada de forma trazable."
    ok "Tutorial completado. Estas listo para evaluacion."
}

# ============================================================================
#  PARSEO DE ARGUMENTOS
# ============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto)
            MODO_AUTO=true
            shift
            ;;
        --ssh-port)
            SSH_HOST_PORT="$2"
            shift 2
            ;;
        -h|--help)
            cat << EOF
Uso: ./tutorial.sh [opciones]

Opciones:
  --auto            Ejecuta automaticamente los comandos principales
  --ssh-port <n>    Puerto host para mapear SSH (por defecto: 4243)
  -h, --help        Muestra esta ayuda

Ejemplos:
  ./tutorial.sh
  ./tutorial.sh --auto
  ./tutorial.sh --auto --ssh-port 4243
EOF
            exit 0
            ;;
        *)
            err "Opcion no reconocida: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
#  MAIN
# ============================================================================

paso_1_contexto
paso_2_prechecks
paso_3_clean_start
paso_4_build
paso_5_up
paso_6_validaciones
paso_7_onion
paso_8_ssh_demo
paso_9_defensa
paso_10_checklist_final
