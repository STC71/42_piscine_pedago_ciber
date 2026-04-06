#!/usr/bin/make -f
# ============================================================================
#  VACCINE - MAKEFILE (AUTOMATIZACIÓN EN ESPAÑOL)
# ============================================================================
#  Herramienta de Detección de SQL Injection (SQLi Scanner)
#  Proyecto Ciberseguridad 42
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

# VARIABLES
VENV        := venv
PYTHON      := $(VENV)/bin/python3
PIP         := $(VENV)/bin/pip
APP         := vaccine
TUTORIAL    := tutorial.sh

# ============================================================================
# REGLAS PRINCIPALES
# ============================================================================

.DEFAULT_GOAL := help

help:
	@echo "$(AZUL)$(NEGRITA)====================================================$(RESET)"
	@echo "$(AZUL)$(NEGRITA)              🛡️  VACCINE - AYUDA 🛡️$(RESET)"
	@echo "$(AZUL)$(NEGRITA)====================================================$(RESET)"
	@echo "$(VERDE)Comandos Disponibles:$(RESET)"
	@echo "  $(CIAN)make help$(RESET)        - Muestra este mensaje de ayuda (por defecto)."
	@echo "  $(CIAN)make setup$(RESET)       - Crea el entorno virtual 'venv' e instala dependencias."
	@echo "  $(CIAN)make run-server$(RESET)  - Ejecuta el servidor HTTP vulnerable de pruebas en el puerto 5000."
	@echo "  $(CIAN)make tutorial$(RESET)    - Lanza el script interactivo tutorial.sh para probar Vaccine."
	@echo "  $(CIAN)make clean$(RESET)       - Elimina archivos temporales y la caché de Python."
	@echo "  $(CIAN)make fclean$(RESET)      - Ejecuta clean, y purga el entorno virtual (venv) y logs."
	@echo "  $(CIAN)make re$(RESET)          - Ejecuta fclean seguido de setup."
	@echo "$(AZUL)$(NEGRITA)====================================================$(RESET)"

all: setup

setup:
	@echo "$(AZUL)$(NEGRITA)=== Configurando entorno para Vaccine ===$(RESET)"
	@if [ ! -d "$(VENV)" ]; then \
		echo "$(CIAN)[*] Creando entorno virtual (venv)...$(RESET)"; \
		python3 -m venv $(VENV); \
	fi
	@echo "$(CIAN)[*] Instalando dependencias (requirements.txt)...$(RESET)"
	@$(PIP) install -r requirements.txt -q
	@echo "$(CIAN)[*] Dando permisos de ejecución a los scripts...$(RESET)"
	@chmod +x $(APP) src/vaccine.py $(TUTORIAL)
	@echo "$(VERDE)[+] Setup completado con éxito. Usa './vaccine' o 'make tutorial'.$(RESET)"

run-server:
	@echo "$(AMARILLO)$(NEGRITA)=== Iniciando servidor Dummy (Vulnerable) ===$(RESET)"
	@$(PYTHON) test_env/dummy_server.py

tutorial: setup
	@echo "$(AZUL)$(NEGRITA)=== Iniciando Tutorial Interactivo ===$(RESET)"
	@./$(TUTORIAL)

clean:
	@echo "$(ROJO)[*] Limpiando archivos temporales y cachés...$(RESET)"
	@rm -rf src/__pycache__ test_env/__pycache__
	@rm -f test_env/test_vuln.db

fclean: clean
	@echo "$(ROJO)[*] Eliminando entorno virtual y base de datos...$(RESET)"
	@fuser -k 5000/tcp 2>/dev/null || true
	-@rm -rf $(VENV) 2>/dev/null || true
	@rm -f vaccine_results.txt *.log

re: fclean all

.PHONY: all setup run-server tutorial clean fclean re help