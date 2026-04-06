#!/usr/bin/make -f
# ============================================================================
#  FT_OTP - MAKEFILE (AUTOMATIZACIÓN EN ESPAÑOL)
# ============================================================================
#  Generador de Contraseñas de Un Solo Uso Basadas en Tiempo (TOTP)
#  RFC 6238 - One-Time Password Generator
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
PROYECTO    := ft_otp
PYTHON      := python3
VERSION     := 1.0.0

# Objetivo por defecto
.DEFAULT_GOAL := help

# Targets sin archivos asociados (PHONY = falso, no corresponde a archivos reales)
.PHONY: help build clean test evaluation evaluation-quiet validate run gui install-deps check-oathtool benchmark syntax-check stats dev-setup dev-teardown info _setup-perms

# ============================================================================
#  TARGET INTERNO: _setup-perms - Asegura permisos de ejecución (oculto)
# ============================================================================
_setup-perms:
	@chmod 777 ft_otp ft_otp.py test_auto.sh 2>/dev/null || true

# ============================================================================
#  TARGET: HELP - Muestra la información de uso del Makefile
# ============================================================================
help: _setup-perms
	@echo "$(NEGRITA)$(CIAN)"
	@echo "┌─────────────────────────────────────────────────────────────┐"
	@echo "│              🔐 FT_OTP v$(VERSION) - GENERADOR TOTP              │"
	@echo "└─────────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@echo "$(NEGRITA)Objetivos disponibles:$(RESET)"
	@echo ""
	@echo "  $(VERDE)make build$(RESET)          Prepara el proyecto (permisos de ejecución)"
	@echo "                       └─ Hace ejecutables los scripts"
	@echo ""
	@echo "  $(VERDE)make test$(RESET)           Ejecuta la suite completa de pruebas"
	@echo "                       └─ 9 pruebas requeridas + 2 bonus"
	@echo ""
	@echo "  $(VERDE)make evaluation$(RESET)     Evaluación exhaustiva del proyecto"
	@echo "                       └─ Scoring: RFC 4226/6238, flags, QR, GUI"
	@echo "                       └─ Con pausas interactivas (usar -q para modo rápido)"
	@echo ""
	@echo "  $(VERDE)make evaluation-quiet$(RESET) Evaluación sin pausas (modo automático)"
	@echo "                       └─ Ejecución rápida sin esperas"
	@echo ""
	@echo "  $(AMARILLO)make validate$(RESET)       Validación rápida del funcionamiento"
	@echo "                       └─ Comprueba generación y regeneración TOTP"
	@echo ""
	@echo "  $(AZUL)make run$(RESET)            Genera un código TOTP"
	@echo "                       └─ Requiere: ft_otp.key"
	@echo ""
	@echo "  $(MAGENTA)make gui$(RESET)            Lanza interfaz gráfica (Tkinter)"
	@echo "                       └─ Interfaz interactiva con temporizador"
	@echo ""
	@echo "$(NEGRITA)Herramientas y Análisis:$(RESET)"
	@echo ""
	@echo "  $(VERDE)make install-deps$(RESET)   Instala dependencias opcionales"
	@echo "                       └─ qrcode para generar códigos QR"
	@echo ""
	@echo "  $(AZUL)make check-oathtool$(RESET)  Verifica instalación de oathtool"
	@echo "                       └─ Herramienta de compatibilidad"
	@echo ""
	@echo "  $(AMARILLO)make benchmark$(RESET)     Realiza prueba de rendimiento"
	@echo "                       └─ Mide velocidad de generación TOTP"
	@echo ""
	@echo "  $(MAGENTA)make stats$(RESET)         Muestra estadísticas del proyecto"
	@echo "                       └─ Líneas, tamaños, versión Python"
	@echo ""
	@echo "$(NEGRITA)Limpieza:$(RESET)"
	@echo ""
	@echo "  $(AMARILLO)make clean$(RESET)         Elimina archivos generados"
	@echo "                       └─ ft_otp.key, qr_code.png, __pycache__, *.pyc"
	@echo ""
	@echo "  $(ROJO)make syntax-check$(RESET)   Comprueba sintaxis de Python"
	@echo "                       └─ Valida ft_otp.py sin ejecutar"
	@echo ""
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""

# ============================================================================
#  OBJETIVOS PRINCIPALES
# ============================================================================

build:
	@echo "$(NEGRITA)$(VERDE)[build]$(RESET) Preparando proyecto..."
	@chmod +x ft_otp ft_otp.py test_auto.sh
	@echo "$(NEGRITA)$(VERDE)[build]$(RESET) Generando QR de ejemplo..."
	@echo "3132333435363738393031323334353637383930313233343536373839303132" > .qr_temp.hex && \
	$(PYTHON) ft_otp.py -g .qr_temp.hex --qr > /dev/null 2>&1 && \
	rm -f .qr_temp.hex ft_otp.key || true
	@echo "$(NEGRITA)$(VERDE)[build]$(RESET) ✓ Proyecto listo!"
	@echo "    $(VERDE)→$(RESET) ft_otp: Ejecutable principal"
	@echo "    $(VERDE)→$(RESET) ft_otp.py: Implementación Python3"
	@echo "    $(VERDE)→$(RESET) test_auto.sh: Suite de pruebas"
	@echo "    $(VERDE)→$(RESET) qr_code.png: Código QR de ejemplo"
	@echo ""

clean:
	@echo "$(NEGRITA)$(AMARILLO)[clean]$(RESET) Eliminando archivos generados..."
	@rm -f ft_otp.key qr_code.png qr_code.svg *.hex clave.hex
	@rm -rf __pycache__ *.pyc .pytest_cache tmp/
	@echo "$(NEGRITA)$(AMARILLO)[clean]$(RESET) ✓ Limpieza completada"
	@echo ""

test: build
	@echo "$(NEGRITA)$(VERDE)[test]$(RESET) Ejecutando suite completa de pruebas..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@./test_auto.sh .
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"

evaluation: build
	@echo "$(NEGRITA)$(VERDE)[evaluation]$(RESET) Ejecutando evaluación completa..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "$(AMARILLO)Tip: Usa 'make evaluation-quiet' para modo automático sin pausas$(RESET)"
	@chmod +x evaluation.sh
	@./evaluation.sh
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"

evaluation-quiet: build
	@echo "$(NEGRITA)$(VERDE)[evaluation]$(RESET) Ejecutando evaluación (modo rápido)..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@chmod +x evaluation.sh
	@./evaluation.sh -q
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"

validate: build
	@echo "$(NEGRITA)$(AZUL)[validate]$(RESET) Ejecutando validación rápida..."
	@echo ""
	@echo "$(NEGRITA)Prueba 1:$(RESET) Generar clave desde archivo hexadecimal"
	@echo "3132333435363738393031323334353637383930313233343536373839303132" > /tmp/test_otp.hex
	@if $(PYTHON) ft_otp.py -g /tmp/test_otp.hex 2>&1 | grep -q "successfully saved"; then \
		echo "$(NEGRITA)$(VERDE)✓ Generación de clave OK$(RESET)"; \
	else \
		echo "$(NEGRITA)$(ROJO)✗ Generación de clave FALLÓ$(RESET)"; \
	fi
	@echo ""
	@echo "$(NEGRITA)Prueba 2:$(RESET) Generar código TOTP"
	@if $(PYTHON) ft_otp.py -k ft_otp.key 2>/dev/null | grep -qE '^[0-9]{6}$$'; then \
		CODE=$$($(PYTHON) ft_otp.py -k ft_otp.key 2>/dev/null); \
		echo "$(NEGRITA)$(VERDE)✓ Generación TOTP OK - Código: $$CODE$(RESET)"; \
	else \
		echo "$(NEGRITA)$(ROJO)✗ Generación TOTP FALLÓ$(RESET)"; \
	fi
	@echo ""
	@echo "$(NEGRITA)Prueba 3:$(RESET) Validar código igual en mismo intervalo de 30s"
	@CODE1=$$($(PYTHON) ft_otp.py -k ft_otp.key 2>/dev/null); \
	sleep 2; \
	CODE2=$$($(PYTHON) ft_otp.py -k ft_otp.key 2>/dev/null); \
	if [ "$$CODE1" = "$$CODE2" ]; then \
		echo "$(NEGRITA)$(VERDE)✓ Códigos idénticos en mismo intervalo$(RESET)"; \
	else \
		echo "$(NEGRITA)$(ROJO)✗ Códigos diferentes en mismo intervalo$(RESET)"; \
	fi
	@echo ""
	@rm -f /tmp/test_otp.hex
	@echo "$(NEGRITA)$(AZUL)✓ Validación completada$(RESET)"
	@echo ""

run:
	@if [ ! -f "ft_otp.key" ]; then \
		echo "$(NEGRITA)$(ROJO)Error:$(RESET) ft_otp.key no encontrado"; \
		echo ""; \
		echo "Pasos para generar una clave:"; \
		echo "  1. Obtén una clave hexadecimal de 64+ caracteres"; \
		echo "  2. Guárdala en un archivo (ejemplo: clave.hex)"; \
		echo "  3. Ejecuta: $(MAGENTA)$(PYTHON) ft_otp.py -g clave.hex$(RESET)"; \
		echo ""; \
		exit 1; \
	fi
	@$(PYTHON) ft_otp.py -k ft_otp.key

gui: build
	@echo "$(NEGRITA)$(MAGENTA)[gui]$(RESET) Iniciando interfaz gráfica interactiva..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@$(PYTHON) ft_otp.py --gui
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"

# ============================================================================
#  HERRAMIENTAS Y UTILIDADES
# ============================================================================

install-deps:
	@echo "$(NEGRITA)$(VERDE)[install-deps]$(RESET) Instalando dependencias opcionales..."
	@echo "  $(MAGENTA)→$(RESET) Instalando qrcode para generación de códigos QR..."
	@$(PYTHON) -m pip install -q qrcode[pil] 2>/dev/null && \
		echo "$(NEGRITA)$(VERDE)✓ qrcode instalado$(RESET)" || \
		echo "$(NEGRITA)$(AMARILLO)⚠ Error al instalar qrcode$(RESET)"
	@echo "$(NEGRITA)$(VERDE)✓ Instalación completada$(RESET)"
	@echo ""

check-oathtool:
	@echo "$(NEGRITA)$(AZUL)[check-oathtool]$(RESET) Verificando instalación de oathtool..."
	@if command -v oathtool >/dev/null 2>&1; then \
		VERSION=$$(oathtool --version 2>&1 | head -1); \
		echo "$(NEGRITA)$(VERDE)✓ oathtool está instalado: $$VERSION$(RESET)"; \
		echo ""; \
		echo "  $(VERDE)Ejemplo de uso:$(RESET)"; \
		echo "  $(MAGENTA)oathtool --totp 3132333435363738393031323334353637383930313233343536373839303132$(RESET)"; \
		echo ""; \
	else \
		echo "$(NEGRITA)$(ROJO)✗ oathtool no encontrado$(RESET)"; \
		echo ""; \
		echo "  Instalar en Debian/Ubuntu:"; \
		echo "  $(MAGENTA)apt-get install oathtool$(RESET)"; \
		echo ""; \
	fi

benchmark: build
	@echo "$(NEGRITA)$(MAGENTA)[benchmark]$(RESET) Ejecutando prueba de rendimiento..."
	@echo ""
	@$(PYTHON) -c "import time, sys; sys.path.insert(0, '.'); from ft_otp import *; \
clave = bytes.fromhex('3132333435363738393031323334353637383930313233343536373839303132'); \
inicio = time.time(); \
for _ in range(1000): totp(clave); \
tiempo_pasado = time.time() - inicio; \
velocidad = 1000/tiempo_pasado; \
print(f'  $(VERDE)→$(RESET) Se generaron 1000 códigos TOTP'); \
print(f'  $(VERDE)→$(RESET) Tiempo total: {tiempo_pasado:.3f}s'); \
print(f'  $(VERDE)→$(RESET) Velocidad: {velocidad:.0f} códigos/seg'); \
print(f'  $(VERDE)→$(RESET) Tiempo promedio: {(tiempo_pasado*1000)/1000:.6f}ms/código')"
	@echo ""

syntax-check:
	@echo "$(NEGRITA)$(ROJO)[syntax-check]$(RESET) Comprobando sintaxis de Python..."
	@if $(PYTHON) -m py_compile ft_otp.py 2>/dev/null; then \
		echo "$(NEGRITA)$(VERDE)✓ Sintaxis correcta en ft_otp.py$(RESET)"; \
	else \
		echo "$(NEGRITA)$(ROJO)✗ Error de sintaxis detectado$(RESET)"; \
		$(PYTHON) -m py_compile ft_otp.py; \
	fi
	@echo ""

stats:
	@echo "$(NEGRITA)$(AZUL)[stats]$(RESET) Estadísticas del Proyecto:$(RESET)"
	@echo ""
	@echo "  $(NEGRITA)Líneas de código:$(RESET)"
	@wc -l ft_otp.py | awk '{printf "    $(MAGENTA)→$(RESET) ft_otp.py: \033[32m%s líneas\033[0m\n", $$1}'
	@echo ""
	@echo "  $(NEGRITA)Tamaño de archivos:$(RESET)"
	@ls -lh ft_otp.py ft_otp test_auto.sh Makefile README.md 2>/dev/null | \
		awk 'NR>1 {printf "    $(MAGENTA)→$(RESET) %-20s $(VERDE)%s$(RESET)\n", $$9, $$5}'
	@echo ""
	@echo "  $(NEGRITA)Versión de Python:$(RESET)"
	@$(PYTHON) --version 2>&1 | awk '{printf "    $(MAGENTA)→$(RESET) %s\n", $$0}'
	@echo ""
	@echo "  $(NEGRITA)Estructura del proyecto:$(RESET)"
	@find . -maxdepth 1 -type f \( -name "*.py" -o -name "*.sh" -o -name "*.md" -o -name "Makefile" \) ! -name ".*" | \
		sort | awk '{printf "    $(MAGENTA)→$(RESET) %s\n", $$0}'
	@echo ""

# ============================================================================
#  TARGETS INTERNOS (Desarrollo)
# ============================================================================

dev-setup:
	@echo "$(NEGRITA)$(MAGENTA)[dev-setup]$(RESET) Configurando entorno de desarrollo..."
	@$(PYTHON) -m venv venv
	@echo "$(NEGRITA)$(VERDE)→$(RESET) Ambiente virtual creado"
	@. venv/bin/activate && $(PYTHON) -m pip install -q -U pip
	@echo "$(NEGRITA)$(VERDE)→$(RESET) pip actualizado"
	@. venv/bin/activate && $(PYTHON) -m pip install -q qrcode[pil] pylint
	@echo "$(NEGRITA)$(VERDE)✓ Entorno de desarrollo listo$(RESET)"
	@echo ""
	@echo "Activar venv:"
	@echo "  $(MAGENTA)source ./venv/bin/activate$(RESET)"
	@echo ""

dev-teardown:
	@echo "$(NEGRITA)$(ROJO)[dev-teardown]$(RESET) Eliminando entorno de desarrollo..."
	@rm -rf venv
	@echo "$(NEGRITA)$(VERDE)✓ Entorno de desarrollo eliminado$(RESET)"
	@echo ""

# ============================================================================
#  INFORMACIÓN FINAL
# ============================================================================

.PHONY: info

info:
	@echo "$(NEGRITA)$(CIAN)"
	@echo "┌─────────────────────────────────────────────────────────────┐"
	@echo "│                   🔐 FT_OTP - Información                   │"
	@echo "└─────────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@echo "$(NEGRITA)Proyecto:$(RESET) $(PROYECTO) v$(VERSION)"
	@echo "$(NEGRITA)Lenguaje:$(RESET) Python 3"
	@echo "$(NEGRITA)Estándares:$(RESET) RFC 6238 (TOTP) y RFC 4226 (HOTP)"
	@echo ""
	@echo "$(NEGRITA)Características:$(RESET)"
	@echo "  $(VERDE)✓$(RESET) Generación de claves seguras"
	@echo "  $(VERDE)✓$(RESET) Cifrado XOR de claves"
	@echo "  $(VERDE)✓$(RESET) Generación de códigos TOTP de 6 dígitos"
	@echo "  $(VERDE)✓$(RESET) Interfaz CLI y GUI (Tkinter)"
	@echo "  $(VERDE)✓$(RESET) Generación de códigos QR"
	@echo "  $(VERDE)✓$(RESET) Compatibilidad con oathtool"
	@echo ""
	@echo "$(NEGRITA)Uso rápido:$(RESET)"
	@echo "  1. $(MAGENTA)make build$(RESET)         - Preparar proyecto"
	@echo "  2. $(MAGENTA)python3 ft_otp.py -g clave.hex$(RESET) - Generar clave"
	@echo "  3. $(MAGENTA)python3 ft_otp.py -k ft_otp.key$(RESET) - Generar código TOTP"
	@echo ""
	@echo "$(NEGRITA)Más información:$(RESET)"
	@echo "  $(MAGENTA)make help$(RESET)  - Ver todos los targets disponibles"
	@echo "  $(MAGENTA)make test$(RESET)  - Ejecutar suite completa"
	@echo ""

tutorial: build
	@echo "$(NEGRITA)$(VERDE)[tutorial]$(RESET) Iniciando tutorial interactivo paso a paso..."
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@chmod +x tutorial.sh
	@./tutorial.sh
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
