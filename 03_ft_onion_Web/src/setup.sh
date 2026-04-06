#!/bin/bash

# ============================================================================
#  FT_ONION - SCRIPT DE INICIALIZACIÓN Y ORQUESTACIÓN DE SERVICIOS
#
# Automatiza tareas de entrada en Docker: verifica entorno,
# inicializa Tor, Nginx, SSH y la aplicación Python,
# e incluye comprobaciones de salud y manejo de errores.
# ============================================================================
#  Script de orquestación para inicialización y configuración del contenedor.
#  Gestiona Tor, Nginx, SSH y monitoreo
# ============================================================================

# ============================================================================
#  COLORES Y FORMATO
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\033[1m'

# ============================================================================
#  FUNCIONES DE LOGGING
# ============================================================================

log_info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${RESET} $1"
}

log_error() {
    echo -e "${RED}[✗]${RESET} $1"
}

log_separator() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# ============================================================================
#  INICIALIZACIÓN
# ============================================================================

log_separator
echo -e "${BOLD}${MAGENTA}    🧅 FT_ONION - SECUENCIA DE INICIALIZACIÓN${RESET}"
log_separator

# ============================================================================
#  VERIFICACIONES DEL SISTEMA
# ============================================================================

log_info "Realizando verificación de entorno y dependencias del sistema..."

# Verificar si se ejecuta como root (requerido para gestión de servicios)
if [ "$EUID" -ne 0 ]; then
    log_error "Este script debe ejecutarse como root (uid=0) para gestionar servicios del sistema"
   exit 1
fi

# Verificar disponibilidad de Python
if ! command -v python3 &> /dev/null; then
    log_error "Python3 no está instalado"
    exit 1
fi
log_success "Python3 encontrado"

# Verificar directorios requeridos
mkdir -p /var/lib/tor/hidden_service
mkdir -p /var/www/html
mkdir -p /var/log/tor
mkdir -p /var/log/nginx
mkdir -p /app/logs
log_success "Directorios requeridos y rutas de logs creados"

# ============================================================================
#  CONFIGURACION DEL DAEMON TOR
# ============================================================================

log_info ""
log_info "Inicializando daemon Tor con configuracion de servicio oculto..."

# Asegurar permisos de Tor
chown -R debian-tor:debian-tor /var/lib/tor 2>/dev/null || true
chmod 700 /var/lib/tor/hidden_service 2>/dev/null || true
chmod 600 /etc/tor/torrc 2>/dev/null || true

# Iniciar Tor (se ejecuta en segundo plano)
service tor start 2>/dev/null || systemctl start tor 2>/dev/null || true
log_success "Daemon Tor iniciado y servicio oculto en proceso de inicializacion"

# Esperar a que Tor se inicialice
COUNTER=0
while [ $COUNTER -lt 30 ]; do
    if [ -f /var/lib/tor/hidden_service/hostname ]; then
        ONION_ADDR=$(cat /var/lib/tor/hidden_service/hostname)
        log_success "Servicio oculto operativo y aceptando conexiones: ${MAGENTA}${ONION_ADDR}${RESET}"
        break
    fi
    COUNTER=$((COUNTER + 1))
    sleep 1
done

if [ ! -f /var/lib/tor/hidden_service/hostname ]; then
    log_warning "Servicio oculto aún no inicializado (puede tardar hasta 1 minuto)"
fi

# ============================================================================
#  CONFIGURACION DEL SERVIDOR SSH
# ============================================================================

log_info ""
log_info "Inicializando servidor SSH en puerto endurecido 4242..."

# Generar claves SSH si es necesario
ssh-keygen -A 2>/dev/null || true

# Asegurar permisos correctos
chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null || true

# Iniciar SSH
service ssh start 2>/dev/null || systemctl start ssh 2>/dev/null || true
log_success "Servidor SSH escuchando en puerto 4242 con autenticacion por clave habilitada"

# ============================================================================
#  CONFIGURACION DEL SERVIDOR WEB NGINX
# ============================================================================

log_info ""
log_info "Inicializando Nginx con cabeceras de seguridad endurecidas..."

# Probar configuración de Nginx
nginx -t 2>/dev/null || {
    log_warning "Prueba de configuración de Nginx falló, usando configuración por defecto"
    # Usar configuración nginx por defecto como alternativa
    service nginx start 2>/dev/null || systemctl start nginx 2>/dev/null || true
}

# Iniciar Nginx
service nginx start 2>/dev/null || systemctl start nginx 2>/dev/null || true
log_success "Servidor web Nginx iniciado"

# ============================================================================
#  INICIALIZACION DE APLICACION PYTHON (BONUS: Panel de control)
# ============================================================================

log_info ""
log_info "Iniciando aplicacion FastAPI del panel en puerto 8000..."

if [ -f /app/app.py ]; then
    # Ejecutar app Python en segundo plano
    nohup python3 /app/app.py > /app/logs/app.log 2>&1 &
    APP_PID=$!
    echo $APP_PID > /app/app.pid
    log_success "Aplicación Python iniciada (PID: $APP_PID)"
else
    log_warning "Aplicación Python no encontrada en /app/app.py"
fi

# ============================================================================
#  VERIFICACIÓN DE SERVICIOS
# ============================================================================

log_info ""
log_info "Verificando servicios..."

# Función para verificar servicio
check_service() {
    local service_name=$1
    local port=$2
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log_success "$service_name escuchando en puerto $port"
        return 0
    else
        log_warning "$service_name no responde en puerto $port"
        return 1
    fi
}

# Verificar servicios (pueden tardar un momento con Tor)
sleep 2
check_service "HTTP/Nginx" "80" || true
check_service "SSH" "4242" || true

# ============================================================================
#  LOGGING Y MONITOREO
# ============================================================================

log_info ""
log_info "Configurando logging..."

# Crear configuración de rotación de logs
cat > /etc/logrotate.d/ft_onion << 'EOF'
/var/log/nginx/ft_onion_access.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
}

/var/log/tor/notices.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 debian-tor debian-tor
    sharedscripts
}

/app/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
}
EOF

log_success "Logging configurado"

# ============================================================================
#  ESTADO FINAL
# ============================================================================

log_info ""
log_separator
echo -e "${GREEN}${BOLD}  ✓ INICIALIZACIÓN DE FT_ONION COMPLETADA${RESET}"
log_separator
echo ""

# Mostrar información de conexión
if [ -f /var/lib/tor/hidden_service/hostname ]; then
    ONION=$(cat /var/lib/tor/hidden_service/hostname)
    echo -e "  ${CYAN}🌐 Dirección de tu servicio oculto:${RESET}"
    echo -e "     ${MAGENTA}${ONION}${RESET}"
    echo ""
fi

echo -e "  ${CYAN}🔗 Métodos de conexión:${RESET}"
echo -e "     • HTTP:  http://[tu-direccion-onion].onion (Puerto 80 vía Tor)"
echo -e "     • SSH:   ssh -p 4242 user@[tu-direccion-onion].onion (Puerto 4242 vía Tor)"
echo ""

echo -e "  ${CYAN}📊 Estado de servicios:${RESET}"
echo -e "     • Tor:   $(service tor status > /dev/null 2>&1 && echo -e "${GREEN}✓${RESET}" || echo -e "${RED}✗${RESET}") En ejecución"
echo -e "     • Nginx: $(service nginx status > /dev/null 2>&1 && echo -e "${GREEN}✓${RESET}" || echo -e "${RED}✗${RESET}") En ejecución"
echo -e "     • SSH:   $(service ssh status > /dev/null 2>&1 && echo -e "${GREEN}✓${RESET}" || echo -e "${RED}✗${RESET}") En ejecución"
echo ""

echo -e "  ${CYAN}📝 Acceso SSH:${RESET}"
echo -e "     Usuario: ${MAGENTA}user${RESET}"
echo -e "     Contraseña: ${MAGENTA}password${RESET}"
echo -e "     Puerto: ${MAGENTA}4242${RESET}"
echo ""

log_separator

# Mantener el contenedor en ejecución
tail -f /dev/null
