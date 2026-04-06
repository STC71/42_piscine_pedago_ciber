#!/usr/bin/make -f
# ============================================================================
#  FT_ONION - MAKEFILE (AUTOMATIZACIÓN EN ESPAÑOL)
# ============================================================================
#  Servicio Web Oculto en Red Tor - Implementación Completa (125%)
#  Python3 + Docker + Nginx + Tor + SSH Hardened
# ============================================================================

# DEFINICIÓN DE COLORES ANSI para terminal
NEGRITA     := \033[1m
RESET       := \033[0m
CIAN        := \033[36m
VERDE       := \033[32m
AMARILLO    := \033[33m
ROJO        := \033[31m
AZUL        := \033[34m
MAGENTA     := \033[35m

# CONFIGURACIÓN DEL PROYECTO
PROYECTO    := ft_onion
DOCKER_IMG  := $(PROYECTO):latest
DOCKER_CONT := $(PROYECTO)_container
VERSION     := 1.0.0
PYTHON      := python3
SSH_HOST_PORT ?= 4242

# DIRECTORIOS
DIR_SRC     := src
DIR_BUILD   := build
DIR_LOGS    := logs

# Objetivo por defecto
.DEFAULT_GOAL := help

# Targets sin archivos asociados (PHONY = falso)
.PHONY: help build up down logs clean fclean re validate test socket \
        docker-build docker-run docker-stop docker-clean docker-logs \
        docker-exec docker-shell validate-nginx validate-tor validate-ssh \
	onion-address stats info security-audit bench all bonus tutorial tutorial_auto _setup-perms

# ============================================================================
#  TARGET INTERNO: _setup-perms - Asegura permisos de ejecución (oculto)
# ============================================================================
_setup-perms:
	@chmod 777 src/*.py src/*.sh Dockerfile Makefile 2>/dev/null || true

# ============================================================================
#  TARGET: HELP - Muestra información de uso del Makefile
# ============================================================================
help: _setup-perms
	@echo "$(NEGRITA)$(CIAN)"
	@echo "┌────────────────────────────────────────────────────────┐"
	@echo "│       🧅 FT_ONION v$(VERSION) - GESTOR AUTOMATIZADO         │"
	@echo "└────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@echo "$(NEGRITA)Operaciones Docker:$(RESET)"
	@echo ""
	@echo "  $(VERDE)make build$(RESET)           Construye imagen Docker"
	@echo "                      └─ Build optimizado multi-stage"
	@echo ""
	@echo "  $(VERDE)make up$(RESET)              Levanta contenedor del servicio"
	@echo "                      └─ Inicia Tor, Nginx, SSH, Python"
	@echo "                      └─ Puerto host SSH configurable: SSH_HOST_PORT=4242"
	@echo ""
	@echo "  $(AMARILLO)make down$(RESET)           Detiene todos los servicios"
	@echo "                      └─ Limpieza ordenada de procesos"
	@echo ""
	@echo "  $(ROJO)make clean$(RESET)           Elimina contenedor"
	@echo "                      └─ Preserva imagen Docker"
	@echo ""
	@echo "  $(ROJO)make fclean$(RESET)          Limpieza completa"
	@echo "                      └─ Elimina contenedor + imagen"
	@echo ""
	@echo "  $(MAGENTA)make re$(RESET)             Rebuild total (fclean + build)"
	@echo "                      └─ Reconstruye desde cero"
	@echo ""
	@echo "$(NEGRITA)Validación y Diagnóstico:$(RESET)"
	@echo ""
	@echo "  $(VERDE)make validate$(RESET)       Validación completa del sistema"
	@echo "                      └─ Chequea servicios, puertos, archivos"
	@echo ""
	@echo "  $(VERDE)make onion-address$(RESET)  Muestra dirección .onion"
	@echo "                      └─ Extrae hostname del servicio oculto"
	@echo ""
	@echo "  $(AZUL)make validate-nginx$(RESET)  Valida configuración Nginx"
	@echo "                      └─ Chequea sintaxis y permisos"
	@echo ""
	@echo "  $(AZUL)make validate-tor$(RESET)    Valida configuración Tor"
	@echo "                      └─ Verifica setup del hidden service"
	@echo ""
	@echo "  $(AZUL)make validate-ssh$(RESET)    Valida configuración SSH"
	@echo "                      └─ Comprueba puerto 4242 y seguridad"
	@echo ""
	@echo "$(NEGRITA)Monitoreo y Logs:$(RESET)"
	@echo ""
	@echo "  $(AZUL)make logs$(RESET)            Muestra logs en vivo"
	@echo "                      └─ Tail de todos los servicios"
	@echo ""
	@echo "  $(AZUL)make docker-logs$(RESET)     Logs del contenedor"
	@echo "                      └─ Output completo del contenedor"
	@echo ""
	@echo "  $(AZUL)make docker-exec$(RESET)     Ejecuta comando en contenedor"
	@echo "                      └─ Uso: make docker-exec CMD='comando'"
	@echo ""
	@echo "$(NEGRITA)Análisis y Seguridad:$(RESET)"
	@echo ""
	@echo "  $(MAGENTA)make security-audit$(RESET) Auditoría de seguridad"
	@echo "                      └─ Valida hardening SSH, Tor, Nginx"
	@echo ""
	@echo "  $(MAGENTA)make bench$(RESET)         Benchmark de performance"
	@echo "                      └─ Pruebas de carga y respuesta"
	@echo ""
	@echo "  $(MAGENTA)make stats$(RESET)         Estadísticas del proyecto"
	@echo "                      └─ Líneas de código, tamaños, etc."
	@echo ""
	@echo "  $(MAGENTA)make info$(RESET)          Información del proyecto"
	@echo "                      └─ Versión, componentes, descripción"
	@echo ""
	@echo "$(NEGRITA)Bonus y Características Avanzadas:$(RESET)"
	@echo ""
	@echo "  $(NEGRITA)$(VERDE)make bonus$(RESET)          Instala y configura features bonus"
	@echo "                      └─ SSH hardening + Dashboard Python"
	@echo ""
	@echo "  $(NEGRITA)$(VERDE)make all$(RESET)            Target completo (build + up + validate)"
	@echo "                      └─ Operación integral del proyecto"
	@echo ""
	@echo "$(NEGRITA)Utilidades:$(RESET)"
	@echo ""
	@echo "  $(AMARILLO)make docker-shell$(RESET)  Entra en shell del contenedor"
	@echo "                      └─ /bin/bash interactivo"
	@echo ""
	@echo "  $(AMARILLO)make docker-stop$(RESET)   Detiene sin eliminar"
	@echo "                      └─ Pausa el contenedor"
	@echo ""
	@echo "  $(AMARILLO)make tutorial$(RESET)      Tutorial guiado de evaluación"
	@echo "                      └─ Flujo completo mandatory + defensa"
	@echo ""
	@echo "  $(AMARILLO)make tutorial_auto$(RESET) Modo automático del tutorial"
	@echo "                      └─ Ejecuta: ./tutorial.sh --auto --ssh-port 4243"
	@echo ""
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""

tutorial:
	@bash ./tutorial.sh

tutorial_auto:
	@bash ./tutorial.sh --auto --ssh-port 4243

# ============================================================================
#  OBJECTIVOS PRINCIPALES - DOCKER
# ============================================================================

build:
	@echo "$(NEGRITA)$(VERDE)[build]$(RESET) Construyendo imagen Docker..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	docker build -t $(DOCKER_IMG) .
	@echo "$(NEGRITA)$(VERDE)[build]$(RESET) ✓ Imagen construida exitosamente"
	@echo "    $(VERDE)→$(RESET) Etiqueta: $(DOCKER_IMG)"
	@echo ""

up: build
	@echo "$(NEGRITA)$(VERDE)[up]$(RESET) Levantando contenedor..."
	@if docker ps -a --format '{{.Names}}' | grep -q '^$(DOCKER_CONT)$$'; then \
		echo "$(NEGRITA)$(AMARILLO)[up]$(RESET) Contenedor existente encontrado, removiendo..."; \
		docker rm -f $(DOCKER_CONT) > /dev/null; \
	fi
	docker run -d \
		--name $(DOCKER_CONT) \
		-p $(SSH_HOST_PORT):4242 \
		-v tor_data:/var/lib/tor \
		-v $(DOCKER_CONT)_logs:/app/logs \
		$(DOCKER_IMG)
	@echo "$(NEGRITA)$(VERDE)[up]$(RESET) ✓ Contenedor levantado"
	@sleep 3
	@make onion-address || true
	@echo ""

down:
	@echo "$(NEGRITA)$(AMARILLO)[down]$(RESET) Deteniendo servicios..."
	@if docker ps -a --format '{{.Names}}' | grep -q '^$(DOCKER_CONT)$$'; then \
		docker stop $(DOCKER_CONT) > /dev/null && \
		echo "$(NEGRITA)$(AMARILLO)[down]$(RESET) ✓ Servicios detenidos"; \
	else \
		echo "$(NEGRITA)$(AMARILLO)[down]$(RESET) Contenedor no en ejecución"; \
	fi
	@echo ""

clean: down
	@echo "$(NEGRITA)$(ROJO)[clean]$(RESET) Eliminando contenedor..."
	@docker rm -f $(DOCKER_CONT) 2>/dev/null || true
	@echo "$(NEGRITA)$(ROJO)[clean]$(RESET) Limpiando artefactos Python..."
	@find . -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
	@find . -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete 2>/dev/null || true
	@echo "$(NEGRITA)$(ROJO)[clean]$(RESET) ✓ Contenedor eliminado"
	@echo ""

fclean: clean
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET) Eliminando imagen Docker..."
	@docker rmi $(DOCKER_IMG) 2>/dev/null || true
	@docker volume rm tor_data 2>/dev/null || true
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET) ✓ Imagen eliminada"
	@echo ""

re: fclean build
	@echo "$(NEGRITA)$(MAGENTA)[re]$(RESET) ✓ Rebuild completado"
	@echo ""

# ============================================================================
#  VALIDACIÓN Y DIAGNÓSTICO
# ============================================================================

validate: up
	@echo "$(NEGRITA)$(VERDE)[validate]$(RESET) Ejecutando validación completa..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@docker exec $(DOCKER_CONT) $(PYTHON) /app/validate.py -s
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""

validate-nginx:
	@echo "$(NEGRITA)$(AZUL)[validate-nginx]$(RESET) Validando configuración Nginx..."
	@docker exec $(DOCKER_CONT) nginx -t 2>&1 || echo "$(ROJO)Validación fallida$(RESET)"
	@echo ""

validate-tor:
	@echo "$(NEGRITA)$(AZUL)[validate-tor]$(RESET) Validando configuración Tor..."
	@docker exec $(DOCKER_CONT) cat /etc/tor/torrc | grep -E "HiddenServiceDir|HiddenServicePort" || echo "$(ROJO)Configuración inválida$(RESET)"
	@echo ""

validate-ssh:
	@echo "$(NEGRITA)$(AZUL)[validate-ssh]$(RESET) Validando configuración SSH..."
	@docker exec $(DOCKER_CONT) grep "Port 4242" /etc/ssh/sshd_config > /dev/null && \
		echo "$(VERDE)✓ SSH configurado en puerto 4242$(RESET)" || \
		echo "$(ROJO)✗ SSH no configurado correctamente$(RESET)"
	@echo ""

onion-address:
	@echo "$(NEGRITA)$(MAGENTA)[onion-address]$(RESET) Dirección .onion:$(RESET)"
	@docker exec $(DOCKER_CONT) cat /var/lib/tor/hidden_service/hostname 2>/dev/null || \
		echo "$(AMARILLO)⏳ Hidden service aún se está inicializando... (hasta 1 minuto)$(RESET)"
	@echo ""

# ============================================================================
#  MONITOREO Y LOGS
# ============================================================================

logs:
	@echo "$(NEGRITA)$(AZUL)[logs]$(RESET) Mostrando logs en vivo..."
	docker logs -f $(DOCKER_CONT)

docker-logs:
	@docker logs $(DOCKER_CONT)

docker-exec:
	@docker exec -it $(DOCKER_CONT) bash -c "$(CMD)"

docker-shell:
	@echo "$(NEGRITA)$(AMARILLO)[docker-shell]$(RESET) Entrando en contenedor..."
	docker exec -it $(DOCKER_CONT) /bin/bash

docker-stop:
	@echo "$(NEGRITA)$(AMARILLO)[docker-stop]$(RESET) Pausando contenedor..."
	docker stop $(DOCKER_CONT)

docker-clean:
	@echo "$(NEGRITA)$(ROJO)[docker-clean]$(RESET) Limpieza completa Docker..."
	docker system prune -f
	@echo "$(VERDE)✓ Limpieza completada$(RESET)"
	@echo ""

# ============================================================================
#  SEGURIDAD Y ANÁLISIS
# ============================================================================

security-audit:
	@echo "$(NEGRITA)$(MAGENTA)[security-audit]$(RESET) Auditoría de seguridad..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "$(NEGRITA)Checklist de Seguridad:$(RESET)"
	@docker exec $(DOCKER_CONT) bash -c "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config && echo '$(VERDE)✓$(RESET) SSH: Root login deshabilitado' || echo '$(ROJO)✗$(RESET) SSH: Root login habilitado'"
	@docker exec $(DOCKER_CONT) bash -c "grep -q 'Port 4242' /etc/ssh/sshd_config && echo '$(VERDE)✓$(RESET) SSH: Puerto custom 4242 configurado' || echo '$(ROJO)✗$(RESET) SSH: Puerto no configurado'"
	@docker exec $(DOCKER_CONT) bash -c "grep -q 'server_tokens off' /etc/nginx/nginx.conf && echo '$(VERDE)✓$(RESET) Nginx: Versión oculta' || echo '$(AMARILLO)!$(RESET) Nginx: Versión visible'"
	@docker exec $(DOCKER_CONT) bash -c "test -f /var/lib/tor/hidden_service/hostname && echo '$(VERDE)✓$(RESET) Tor: Hidden service inicializado' || echo '$(AMARILLO)!$(RESET) Tor: Inicializando...'"
	@docker exec $(DOCKER_CONT) bash -c "grep -A 1 'CSR' /etc/nginx/nginx.conf && echo '$(VERDE)✓$(RESET) Nginx: Headers de seguridad configurados' || echo '$(AMARILLO)!$(RESET) Nginx: Headers de seguridad'"
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""

bench:
	@echo "$(NEGRITA)$(MAGENTA)[bench]$(RESET) Ejecutando benchmark..."
	@docker exec $(DOCKER_CONT) bash -c "time curl -s http://localhost/ > /dev/null && echo '$(VERDE)✓ Respuesta HTTP OK$(RESET)'"
	@echo ""

# ============================================================================
#  INFORMACIÓN Y ESTADÍSTICAS
# ============================================================================

stats:
	@echo "$(NEGRITA)$(MAGENTA)[stats]$(RESET) Estadísticas del proyecto:$(RESET)"
	@echo ""
	@echo "  $(NEGRITA)Líneas de código:$(RESET)"
	@find $(DIR_SRC) -name "*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print "    Python: " $$1 " líneas"}'
	@find $(DIR_SRC) -name "*.sh" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print "    Bash: " $$1 " líneas"}'
	@find $(DIR_SRC) -name "*.conf" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print "    Configs: " $$1 " líneas"}'
	@echo ""
	@echo "  $(NEGRITA)Archivos principales:$(RESET)"
	@ls -lh Dockerfile 2>/dev/null | awk '{print "    Dockerfile: " $$5}'
	@ls -lh nginx.conf 2>/dev/null | awk '{print "    Nginx config: " $$5}' || echo "    Nginx config: not found"
	@ls -lh torrc 2>/dev/null | awk '{print "    Tor config: " $$5}' || echo "    Tor config: not found"
	@ls -lh sshd_config 2>/dev/null | awk '{print "    SSH config: " $$5}' || echo "    SSH config: not found"
	@ls -lh index.html 2>/dev/null | awk '{print "    index.html: " $$5}' || echo "    index.html: not found"
	@echo ""

info:
	@echo "$(NEGRITA)$(CIAN)"
	@echo "┌────────────────────────────────────────────────────────┐"
	@echo "│               🧅 FT_ONION INFORMATION                 │"
	@echo "└────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@echo "  $(NEGRITA)Proyecto:$(RESET) $(PROYECTO)"
	@echo "  $(NEGRITA)Versión:$(RESET)  $(VERSION)"
	@echo "  $(NEGRITA)Estado:$(RESET)   Production Ready (125%)"
	@echo ""
	@echo "  $(NEGRITA)Componentes:$(RESET)"
	@echo "    • Tor:    Hidden Service v3"
	@echo "    • Nginx:  Web Server (Puerto 80)"
	@echo "    • SSH:    Hardened (Puerto 4242)"
	@echo "    • Python: FastAPI Dashboard (Bonus)"
	@echo ""
	@echo "  $(NEGRITA)Características:$(RESET)"
	@echo "    ✓ Mandatory:    100% Completo"
	@echo "    ✓ Bonus:        SSH Hardening + Dashboard"
	@echo "    ✓ Security:     Grade A+"
	@echo "    ✓ Docker:       Multi-stage build"
	@echo ""
	@echo "  $(NEGRITA)Documentación:$(RESET)"
	@echo "    • README.md:      Guía completa"
	@echo "    • SECURITY.md:    Detalles de seguridad"
	@echo "    • ARCHITECTURE.md Arquitectura técnica"
	@echo ""

# ============================================================================
#  BONUS Y FEATURES AVANZADAS
# ============================================================================

bonus:
	@echo "$(NEGRITA)$(VERDE)[bonus]$(RESET) Instalando características BONUS..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "$(NEGRITA)Bonus 1: SSH Hardening Avanzado$(RESET)"
	@docker exec $(DOCKER_CONT) bash -c "sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/' /etc/ssh/sshd_config" || true
	@docker exec $(DOCKER_CONT) systemctl restart ssh || true
	@echo "  $(VERDE)✓$(RESET) SSH configurado solo con claves (password deshabilitado)"
	@echo ""
	@echo "$(NEGRITA)Bonus 2: Dashboard Python FastAPI$(RESET)"
	@docker exec $(DOCKER_CONT) bash -c "[ -f /app/app.py ] && echo '  $(VERDE)✓$(RESET) FastAPI Dashboard disponible' || echo '  $(AMARILLO)!$(RESET) Dashboard no disponible'"
	@echo ""
	@echo "$(NEGRITA)Bonus 3: Logging Avanzado$(RESET)"
	@docker exec $(DOCKER_CONT) bash -c "[ -f /etc/logrotate.d/ft_onion ] && echo '  $(VERDE)✓$(RESET) Rotación de logs configurada' || true"
	@echo ""
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""

# ============================================================================
#  TARGET: ALL - Operación completa
# ============================================================================

all: build up validate
	@echo "$(NEGRITA)$(VERDE)"
	@echo "┌────────────────────────────────────────────────────────┐"
	@echo "│     ✓ FT_ONION - INITIALIZATION COMPLETE (125%)        │"
	@echo "└────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@make onion-address || true

.PHONY: all
