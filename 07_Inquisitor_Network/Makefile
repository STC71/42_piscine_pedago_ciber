# ============================================================================
# DEFINICIÓN DE COLORES ANSI para la terminal
# ============================================================================
NEGRITA     := \033[1m
RESET       := \033[0m
CIAN        := \033[36m
VERDE       := \033[32m
AMARILLO    := \033[33m
ROJO        := \033[31m
MAGENTA     := \033[35m

# Nombre del ejecutable final que vamos a generar
NAME := inquisitor

# Archivo de configuración de Docker Compose
COMPOSE_FILE := docker-compose.yml

# Comando base para interactuar con Docker Compose, indicando el archivo y el nombre del proyecto
COMPOSE := docker-compose -f $(COMPOSE_FILE) -p $(NAME)

# Objetivo por defecto, si no se especifica regla mostrará la ayuda
.DEFAULT_GOAL := help

# ============================================================================
#  TARGETS PRINCIPALES Y DE AYUDA
# ============================================================================

# Target de ayuda para mostrar las opciones del Makefile
help:
	@echo "$(NEGRITA)$(CIAN)"
	@echo "┌────────────────────────────────────────────────────────┐"
	@echo "│       🕸️  INQUISITOR ✨ Makefile (Evaluación)           │"
	@echo "└────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@echo "$(NEGRITA)Reglas disponibles:$(RESET)"
	@echo ""
	@echo "  $(VERDE)make all$(RESET)           Construye y levanta el entorno Docker (build + up)"
	@echo "                       └─ Asigna también permisos al script inquisitor"
	@echo ""
	@echo "  $(MAGENTA)make tutorial$(RESET)      Lanza el tutorial interactivo automatizado"
	@echo "                       └─ Evalúa el proyecto paso a paso validando subject"
	@echo ""
	@echo "  $(AMARILLO)make build$(RESET)         Construye las imágenes de Docker"
	@echo "  $(AMARILLO)make up$(RESET)            Inicia el entorno docker-compose en detached mode"
	@echo "  $(AMARILLO)make down$(RESET)          Detiene los contenedores y destruye la red"
	@echo ""
	@echo "  $(ROJO)make clean$(RESET)         Detiene entorno y borra el link del ejecutable"
	@echo "  $(ROJO)make fclean$(RESET)        Elimina volcados, contenedores, redes e imágenes base"
	@echo "  $(ROJO)make re$(RESET)            Reconstruye todo el entorno y base desde cero"
	@echo ""

# Regla principal: se ejecuta si fuerza 'make all'.
# Ejecuta las reglas 'perm', 'build' y 'up' en ese orden.
all: perm build up

# Regla para lanzar el tutorial interactivo
tutorial: perm
	@echo "$(NEGRITA)$(MAGENTA)Iniciando el tutorial interactivo de evaluación...$(RESET)"
	@chmod +x tutorial.sh
	@./tutorial.sh

# Regla para construir las imágenes de los contenedores Docker
build:
	@echo "$(NEGRITA)$(AMARILLO)Building containers...$(RESET)"
	$(COMPOSE) build

# Regla para iniciar los contenedores en segundo plano (modo detached -d)
up:
	@echo "$(NEGRITA)$(VERDE)Starting environment...$(RESET)"
	$(COMPOSE) up -d

# Regla para dar permisos de ejecución al script y copiarlo por si no existía como 'inquisitor'
perm:
	@cp -f inquisitor.py inquisitor 2>/dev/null || true
	@chmod +x inquisitor

# Regla para detener y eliminar los contenedores y redes creados por docker-compose
down:
	@echo "$(NEGRITA)$(AMARILLO)Stopping environment...$(RESET)"
	$(COMPOSE) down -v

# Regla para limpiar los archivos generados (elimina el ejecutable 'inquisitor')
clean: down
	@echo "$(NEGRITA)$(ROJO)Cleaning up...$(RESET)"
	@rm -f inquisitor

# Regla para una limpieza total: además de borrar contenedores, elimina las imágenes y los volúmenes
fclean: clean
	@echo "$(NEGRITA)$(ROJO)Full clean...$(RESET)"
	$(COMPOSE) down --rmi all --volumes

# Regla para reconstruir todo desde cero (Borra todo y lo vuelve a crear)
re: fclean all

# Indicamos a Make que estas reglas no son archivos reales, 
# evitando conflictos si existiera un archivo con el mismo nombre en la carpeta.
.PHONY: help all tutorial build up down clean fclean re perm
