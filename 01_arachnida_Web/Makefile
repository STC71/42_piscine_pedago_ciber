# ============================================================================
#  ARACHNIDA - MAKEFILE (AUTOMATIZACIÓN EN ESPAÑOL)
# ============================================================================
#  Proyecto educativo de Piscina de Ciberseguridad 42
#  Extracción de imágenes web y análisis de metadatos EXIF
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

# DIRECTORIOS DEL PROYECTO
DIR_EX00    := ex00
DIR_EX01    := ex01

# Objetivo por defecto (se ejecuta con 'make' sin argumentos)
.DEFAULT_GOAL := help

# Targets sin archivos asociados (PHONY = falso, no corresponde a archivos reales)
.PHONY: help 00 01 clean fclean re all gui bonus-cli

# ============================================================================
#  TARGET: HELP - Muestra la información de uso del Makefile
# ============================================================================
help: all

all:
	@echo "$(NEGRITA)$(CIAN)"
	@echo "┌─────────────────────────────────────────────────────────────┐"
	@echo "│                  🕷️  ARACHNIDA - INSTALACIÓN                 │"
	@echo "└─────────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@echo "$(NEGRITA)Objectivos disponibles:$(RESET)"
	@echo ""
	@echo "  $(VERDE)make 00$(RESET)            Instala dependencias de $(NEGRITA)ex00$(RESET)"
	@echo "                      └─ Crea .venv e instala paquetes pip"
	@echo ""
	@echo "  $(VERDE)make 01$(RESET)            Instala dependencias de $(NEGRITA)ex01$(RESET)"
	@echo "                      └─ Crea .venv e instala paquetes pip"
	@echo ""
	@echo "  $(AMARILLO)make clean$(RESET)       Elimina ambiente virtual (sesión actual)"
	@echo "                      └─ Desactiva ambiente y elimina .venv"
	@echo ""
	@echo "  $(ROJO)make fclean$(RESET)       Limpieza completa - TODOS los módulos"
	@echo "                      └─ Desactiva & elimina todas las carpetas .venv"
	@echo ""
	@echo "  $(MAGENTA)make re$(RESET)          Reinstalación completa (fclean + instalar todo)"
	@echo ""
	@echo "$(NEGRITA)Objetivos Bonificación (Interfaz Gráfica y Herramientas Avanzadas):$(RESET)"
	@echo ""
	@echo "  $(VERDE)make gui$(RESET)          Lanza la interfaz gráfica de Scorpion (editor de metadatos)"
	@echo "                      └─ Requiere: pantalla X11 + soporte tkinter"
	@echo ""
	@echo "  $(VERDE)make bonus-cli$(RESET)    Muestra ejemplos de uso de CLI bonus"
	@echo ""
	@echo "  $(AZUL)make help$(RESET)         Muestra este mensaje de ayuda"
	@echo ""
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""

# ============================================================================
#  OBJETIVOS DE INSTALACIÓN
# ============================================================================

00:
	@echo "$(NEGRITA)$(VERDE)[ex00]$(RESET) Creando ambiente virtual..."
	@cd $(DIR_EX00) && python3 -m venv .venv
	@echo "$(NEGRITA)$(VERDE)[ex00]$(RESET) Instalando dependencias..."
	@cd $(DIR_EX00) && . .venv/bin/activate && pip install -r requirements.txt
	@echo "$(NEGRITA)$(VERDE)[ex00]$(RESET) ✓ ¡Instalación completada!"
	@echo ""

01:
	@echo "$(NEGRITA)$(VERDE)[ex01]$(RESET) Creando ambiente virtual..."
	@cd $(DIR_EX01) && python3 -m venv .venv
	@echo "$(NEGRITA)$(VERDE)[ex01]$(RESET) Instalando dependencias..."
	@cd $(DIR_EX01) && . .venv/bin/activate && pip install -r requirements.txt
	@echo "$(NEGRITA)$(VERDE)[ex01]$(RESET) ✓ ¡Instalación completada!"
	@echo ""
	@echo "$(NEGRITA)$(AMARILLO)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "$(NEGRITA)$(AMARILLO)⚠️  PRÓXIMO PASO:$(RESET)"
	@echo "$(NEGRITA)$(AMARILLO)Activa el ambiente virtual de ex01:$(RESET)"
	@echo ""
	@echo "   $(MAGENTA)source ./$(DIR_EX01)/.venv/bin/activate$(RESET)"
	@echo ""
	@echo "$(NEGRITA)$(AMARILLO)Luego podrás usar:$(RESET)"
	@echo "   $(VERDE)./$(DIR_EX01)/scorpion.py imagen.jpg$(RESET)"
	@echo "   $(VERDE)./$(DIR_EX01)/scorpion_bonus.py --gui$(RESET)"
	@echo "$(NEGRITA)$(AMARILLO)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""

# ============================================================================
#  OBJETIVOS DE LIMPIEZA
# ============================================================================

clean:
	@echo "$(NEGRITA)$(AMARILLO)[clean]$(RESET) Intentando desactivar ambiente virtual..."
	@deactivate 2>/dev/null || true
	@echo "$(NEGRITA)$(AMARILLO)[clean]$(RESET) Eliminando carpeta de datos..."
	@rm -rf data/ 2>/dev/null || true
	@echo "$(NEGRITA)$(AMARILLO)[clean]$(RESET) ✓ Limpieza completada"

fclean: clean
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET) Eliminando todos los ambientes virtuales..."
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET)   → Eliminando $(DIR_EX00)/.venv"
	@rm -rf $(DIR_EX00)/.venv
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET)   → Eliminando $(DIR_EX01)/.venv"
	@rm -rf $(DIR_EX01)/.venv
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET) Limpiando archivos y carpetas de prueba..."
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET)   → Eliminando imágenes de prueba (*.jpg, *.png, *.bak)"
	@find $(DIR_EX00) $(DIR_EX01) -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.bak" -o -name "*.png" \) -delete 2>/dev/null || true
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET)   → Eliminando directorios de prueba"
	@find $(DIR_EX00) $(DIR_EX01) -maxdepth 1 -type d \( -name "data*" -o -name "test*" -o -name "imagenes*" \) -exec rm -rf {} + 2>/dev/null || true
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET)   → Eliminando cachés de Python (__pycache__)"
	@find $(DIR_EX00) $(DIR_EX01) -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET) ✓ ¡Limpieza completa exitosa!"
	@echo "$(NEGRITA)$(AMARILLO)⚠️  Si tienes un ambiente activado en tu terminal,$(RESET)"
	@echo "$(NEGRITA)$(AMARILLO)   por favor ejecuta: $(MAGENTA)deactivate$(AMARILLO)$(RESET)"
	@echo ""

re: fclean 00 01
	@echo "$(NEGRITA)$(MAGENTA)[re]$(RESET) ✓ ¡Reinstalación completa exitosa!"
	@echo ""

# ============================================================================
#  OBJETIVOS BONUS
# ============================================================================

gui:
	@echo "$(NEGRITA)$(VERDE)[GUI]$(RESET) Lanzando interfaz gráfica de Scorpion..."
	@cd $(DIR_EX01) && . .venv/bin/activate && python3 scorpion_bonus.py --gui

bonus-cli:
	@echo "$(NEGRITA)$(AMARILLO)"
	@echo "═══════════════════════════════════════════════════════════════╗"
	@echo "  🦂 Scorpion Bonus - Editor Avanzado de Metadatos            ║"
	@echo "═══════════════════════════════════════════════════════════════╝"
	@echo "$(RESET)"
	@echo "$(NEGRITA)Ejemplos de uso:$(RESET)"
	@echo ""
	@echo "  $(VERDE)Listar todas las etiquetas EXIF:$(RESET)"
	@echo "    cd $(DIR_EX01) && . .venv/bin/activate"
	@echo "    python3 scorpion_bonus.py --list-tags imagen.jpg"
	@echo ""
	@echo "  $(ROJO)Eliminar todos los datos EXIF:$(RESET)"
	@echo "    python3 scorpion_bonus.py --remove-all imagen.jpg"
	@echo ""
	@echo "  $(AMARILLO)Eliminar etiqueta específica:$(RESET)"
	@echo "    python3 scorpion_bonus.py --remove-tag DateTime imagen.jpg"
	@echo ""
	@echo "  $(MAGENTA)Editar valor de etiqueta EXIF:$(RESET)"
	@echo "    python3 scorpion_bonus.py --set-tag 'Modelo Cámara' 'Mi Cámara' imagen.jpg"
	@echo ""
	@echo "  $(AZUL)Lanzar interfaz gráfica:$(RESET)"
	@echo "    python3 scorpion_bonus.py --gui"
	@echo ""
	@echo "$(NEGRITA)Más información:$(RESET)"
	@echo "  Consulta el README.md para documentación completa"
	@echo ""
