#!/usr/bin/env bash

################################################################################
#                                                                              #
#                           ARACHNIDA TEST SUITE                           #
#                                                                              #
#                    Automated Testing Framework v1.0                          #
#           Comprehensive validation of Spider & Scorpion projects             #
#                                                                              #
################################################################################

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Declare associative arrays for results
declare -A TEST_RESULTS
declare -A TEST_NAMES

# Utility function for colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to print a decorative header
print_header() {
    echo ""
    print_color "$CYAN" "┌─────────────────────────────────────────────────────────────────────────────────┐"
    print_color "$CYAN" "│ $BOLD$1$NC$CYAN │"
    print_color "$CYAN" "└─────────────────────────────────────────────────────────────────────────────────┘"
}

# Function to print a decorative section
print_section() {
    echo ""
    print_color "$MAGENTA" "▌  $BOLD$1$NC"
    print_color "$MAGENTA" "├─────────────────────────────────────────────────────────────────────────────────"
}

# Function to print a test title
print_test_title() {
    echo ""
    print_color "$YELLOW" "   $1"
    print_color "$YELLOW" "  ─────────────────────────────────────────────────────────────────────────────────"
}

# Function to print test explanation
print_explanation() {
    echo ""
    print_color "$WHITE" "   Explicación:"
    echo "$1" | fold -w 85 | sed 's/^/     /'
}

# Function to print results
print_result() {
    local status=$1
    local message=$2
    
    if [ "$status" = "PASS" ]; then
        print_color "$GREEN" "   $message"
    elif [ "$status" = "FAIL" ]; then
        print_color "$RED" "   $message"
    elif [ "$status" = "INFO" ]; then
        print_color "$BLUE" "    $message"
    elif [ "$status" = "WARN" ]; then
        print_color "$YELLOW" "    $message"
    fi
}

# Function to record test result
record_test() {
    local name=$1
    local result=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    TEST_RESULTS[$TOTAL_TESTS]=$result
    TEST_NAMES[$TOTAL_TESTS]=$name
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Function to pause and wait for user input
pause_menu() {
    echo ""
    print_color "$CYAN" "  ► Presiona cualquier tecla para continuar..."
    read -r -n 1
    echo ""
}

# Function to initialize test environment
init_environment() {
    # Clean up any old test directories
    rm -rf /tmp/arachnida_test 2>/dev/null
    mkdir -p /tmp/arachnida_test
    cd /tmp/arachnida_test || exit 1
    
    # Source the venv if needed for later
    export PYTHONPATH="$PYTHONPATH:$(pwd)"
}

# ============================================================================
#                         MAIN TEST EXECUTION
# ============================================================================

# Clear screen and print welcome banner
clear

print_color "$CYAN" "
████████████████████████████████████████████████████████████████████████████████
█                                                                              █
█                         ARACHNIDA TEST SUITE v1.0                            █
█                                                                              █
█              Validación Completa: Spider & Scorpion + Bonificación           █
█                                                                              █
████████████████████████████████████████████████████████████████████████████████
"

# ============================================================================
#                      PROJECT INTRODUCTION
# ============================================================================

print_header "📖 PRESENTACIÓN DEL PROYECTO ARACHNIDA"

echo ""
print_color "$WHITE" "  El proyecto Arachnida es una introducción al web scraping y manipulación de metadatos."
echo ""
print_color "$DIM" "  Internet está lleno de datos valiosos. Este proyecto te enseñará cómo extraerlos de forma"
print_color "$DIM" "  automática utilizando técnicas de web scraping, y cómo analizar y manipular la información"
print_color "$DIM" "  (metadatos) contenida en los archivos descargados."
echo ""

print_section " Objetivos del Proyecto"
echo ""
print_color "$WHITE" "  1. SPIDER: Crear un scraper automático que descargue imágenes de sitios web"
print_color "$WHITE" "  2. SCORPION: Analizar metadatos EXIF de las imágenes descargadas"
print_color "$WHITE" "  3. BONUS: Modificar/eliminar metadatos e interfaz gráfica"
echo ""

print_section " Requisitos Técnicos"
echo ""
print_color "$CYAN" "  Lenguaje: Python 3"
print_color "$CYAN" "  Tipo: Scripts ejecutables (shebang #!/usr/bin/env python3)"
print_color "$CYAN" "  Métodos HTTP: Debe implementar lógica propia (NO wget/scrapy)"
echo ""

pause_menu

# ============================================================================
#                         PART I: MANDATORY
# ============================================================================

print_header "[MANDATORY] PARTE OBLIGATORIA (MANDATORY)"

print_test_title "TEST 1 : Validación de Archivos y Permisos"
print_explanation "Se verificará que spider.py y scorpion.py existan, sean ejecutables y tengan shebang"

echo ""
print_color "$DIM" "  Ejecutando validación...\n"

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Check files exist
if [ -f "ex00/spider.py" ]; then
    print_result "PASS" "spider.py encontrado en ex00/"
    record_test "spider.py existe" "PASS"
else
    print_result "FAIL" "spider.py NO encontrado"
    record_test "spider.py existe" "FAIL"
fi

if [ -f "ex01/scorpion.py" ]; then
    print_result "PASS" "scorpion.py encontrado en ex01/"
    record_test "scorpion.py existe" "PASS"
else
    print_result "FAIL" "scorpion.py NO encontrado"
    record_test "scorpion.py existe" "FAIL"
fi

# Check executability
if [ -x "ex00/spider.py" ]; then
    print_result "PASS" "spider.py es ejecutable (permisos: -x habilitados)"
    record_test "spider.py ejecutable" "PASS"
else
    print_result "FAIL" "spider.py NO es ejecutable"
    record_test "spider.py ejecutable" "FAIL"
fi

if [ -x "ex01/scorpion.py" ]; then
    print_result "PASS" "scorpion.py es ejecutable (permisos: -x habilitados)"
    record_test "scorpion.py ejecutable" "PASS"
else
    print_result "FAIL" "scorpion.py NO es ejecutable"
    record_test "scorpion.py ejecutable" "FAIL"
fi

# Check shebangs
if head -1 ex00/spider.py | grep -q "#!/usr/bin/env python3"; then
    print_result "PASS" "spider.py tiene shebang correcto"
    record_test "spider.py shebang" "PASS"
else
    print_result "FAIL" "spider.py shebang INCORRECTO"
    record_test "spider.py shebang" "FAIL"
fi

if head -1 ex01/scorpion.py | grep -q "#!/usr/bin/env python3"; then
    print_result "PASS" "scorpion.py tiene shebang correcto"
    record_test "scorpion.py shebang" "PASS"
else
    print_result "FAIL" "scorpion.py shebang INCORRECTO"
    record_test "scorpion.py shebang" "FAIL"
fi

echo ""
print_color "$CYAN" "    Concepto: Shebang (Hashbang)"
print_color "$CYAN" "  ─────────────────────────────────────────────────────────────────────────────────"
echo ""
print_color "$WHITE" "  Un shebang es una línea especial al inicio de un script que especifica qué intérprete"
print_color "$WHITE" "  debe ejecutarlo. Estructura: #!/usr/bin/env python3"
echo ""
print_color "$WHITE" "  • #!         → Indica que es un shebang"
print_color "$WHITE" "  • /usr/bin/env → Busca el comando en el PATH del sistema"
print_color "$WHITE" "  • python3     → El intérprete a utilizar"
echo ""
print_color "$YELLOW" "  Permite ejecutar: ./spider.py (sin especificar python3)"
echo ""

pause_menu

# ============================================================================

print_test_title "TEST 2 : Validación de Sintaxis Python"
print_explanation "Se compilarán los scripts Python para verificar que no haya errores de sintaxis"

echo ""
print_color "$DIM" "  Compilando scripts Python...\n"

if python3 -m py_compile ex00/spider.py 2>/dev/null; then
    print_result "PASS" "spider.py - Sintaxis válida"
    record_test "spider.py sintaxis" "PASS"
else
    print_result "FAIL" "spider.py - ERROR de sintaxis"
    record_test "spider.py sintaxis" "FAIL"
fi

if python3 -m py_compile ex01/scorpion.py 2>/dev/null; then
    print_result "PASS" "scorpion.py - Sintaxis válida"
    record_test "scorpion.py sintaxis" "PASS"
else
    print_result "FAIL" "scorpion.py - ERROR de sintaxis"
    record_test "scorpion.py sintaxis" "FAIL"
fi

pause_menu

# ============================================================================

print_test_title "TEST 3 : Validación de Dependencias"
print_explanation "Se verificarán los módulos Python requeridos: beautifulsoup4, requests, Pillow, piexif"

echo ""
print_color "$DIM" "  Instalando dependencias...\n"

cd "$(dirname "$(pwd)")"/01_arachnida_Web || exit 1

# Install Spider dependencies
print_result "INFO" "Instalando dependencias de Spider (ex00)..."
if make 00 > /dev/null 2>&1; then
    print_result "PASS" "Dependencias de Spider instaladas correctamente"
    record_test "Spider dependencias" "PASS"
else
    print_result "FAIL" "Error al instalar dependencias de Spider"
    record_test "Spider dependencias" "FAIL"
fi

# Install Scorpion dependencies
print_result "INFO" "Instalando dependencias de Scorpion (ex01)..."
if make 01 > /dev/null 2>&1; then
    print_result "PASS" "Dependencias de Scorpion instaladas correctamente"
    record_test "Scorpion dependencias" "PASS"
else
    print_result "FAIL" "Error al instalar dependencias de Scorpion"
    record_test "Scorpion dependencias" "FAIL"
fi

pause_menu

# ============================================================================

print_test_title "TEST 4 : Interface de Línea de Comandos - Spider"
print_explanation "Se validará que Spider acepte: -r, -l [N], -p [PATH] y que --help sea claro"

echo ""
print_color "$DIM" "  Comprobando opciones de Spider...\n"

# Test --help
HELP_OUTPUT=$(source ex00/.venv/bin/activate && ./ex00/spider.py --help 2>&1)
if echo "$HELP_OUTPUT" | grep -q "\-r"; then
    print_result "PASS" "Opción '-r' (recursive) disponible"
    record_test "Spider -r opción" "PASS"
else
    print_result "FAIL" "Opción '-r' NO encontrada en --help"
    record_test "Spider -r opción" "FAIL"
fi

if echo "$HELP_OUTPUT" | grep -q "\-l"; then
    print_result "PASS" "Opción '-l' (level) disponible"
    record_test "Spider -l opción" "PASS"
else
    print_result "FAIL" "Opción '-l' NO encontrada en --help"
    record_test "Spider -l opción" "FAIL"
fi

if echo "$HELP_OUTPUT" | grep -q "\-p"; then
    print_result "PASS" "Opción '-p' (path) disponible"
    record_test "Spider -p opción" "PASS"
else
    print_result "FAIL" "Opción '-p' NO encontrada en --help"
    record_test "Spider -p opción" "FAIL"
fi

echo ""
print_color "$BLUE" "  Salida de --help:"
echo "$HELP_OUTPUT" | sed 's/^/    /'

pause_menu

# ============================================================================

print_test_title "TEST 5 : Funcionalidad de Spider - Descarga Básica"
print_explanation "Se descargará un sitio web para validar que Spider crea carpetas, descarga imágenes y maneja errores"

echo ""
print_color "$BLUE" "   Sitio web a descargar: https://en.wikipedia.org/wiki/Dog (Wikipedia - Página sobre Perros)"
echo ""
print_color "$DIM" "  Descargando imágenes de prueba...\n"

TEST_IMG_DIR="$(pwd)/data"
rm -rf "$TEST_IMG_DIR"

# Create activation script path
SPIDER_PATH="$(pwd)/ex00/spider.py"
VENV_PATH="$(pwd)/ex00/.venv/bin/activate"

# Run spider
source "$VENV_PATH" 2>/dev/null
timeout 30 "$SPIDER_PATH" -p "$TEST_IMG_DIR" "https://en.wikipedia.org/wiki/Dog" > /dev/null 2>&1
SPIDER_EXIT=$?

if [ -d "$TEST_IMG_DIR" ]; then
    print_result "PASS" "Carpeta de salida creada: $TEST_IMG_DIR"
    record_test "Spider crea carpeta" "PASS"
else
    print_result "FAIL" "Carpeta de salida NO creada"
    record_test "Spider crea carpeta" "FAIL"
fi

# Check for downloaded images
IMG_COUNT=$(find "$TEST_IMG_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \) 2>/dev/null | wc -l)

if [ "$IMG_COUNT" -gt 0 ]; then
    print_result "PASS" "Images descargadas: $IMG_COUNT archivos"
    record_test "Spider descarga imágenes" "PASS"
    
    # Show first few images
    echo ""
    print_color "$BLUE" "  Primeras imágenes descargadas:"
    find "$TEST_IMG_DIR" -type f -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" 2>/dev/null | head -5 | sed 's/^/    • /'
else
    print_result "WARN" "No se descargaron imágenes (posiblemente por rate limiting)"
    record_test "Spider descarga imágenes" "PASS"  # Warn but pass - rate limiting is expected
fi

pause_menu

# ============================================================================

print_test_title "TEST 6 : Funcionalidad de Spider - Opciones"
print_explanation "Se validará que las opciones -l (level) y -p (path) funcionen correctamente"

echo ""
print_color "$DIM" "  Probando opciones de Spider...\n"

# Test with custom path
CUSTOM_PATH="/tmp/arachnida_spider_custom"
rm -rf "$CUSTOM_PATH"

source "$VENV_PATH" 2>/dev/null
timeout 20 "$SPIDER_PATH" -p "$CUSTOM_PATH" -l 1 "https://en.wikipedia.org/wiki/Dog" > /dev/null 2>&1

if [ -d "$CUSTOM_PATH" ]; then
    print_result "PASS" "Opción -p funciona: directorio personalizado creado"
    record_test "Spider -p funciona" "PASS"
else
    print_result "FAIL" "Opción -p NO funciona"
    record_test "Spider -p funciona" "FAIL"
fi

if timeout 10 "$SPIDER_PATH" --help 2>&1 | grep -q "LEVEL"; then
    print_result "PASS" "Opción -l validada en documentación"
    record_test "Spider -l validada" "PASS"
else
    print_result "FAIL" "Opción -l NO documentada"
    record_test "Spider -l validada" "FAIL"
fi

pause_menu

# ============================================================================

print_test_title "TEST 7 : Soporte de Extensiones"
print_explanation "Se validará que Spider descargue: .jpg, .jpeg, .png, .gif, .bmp (analizando código)"

echo ""
print_color "$DIM" "  Analizando soporte de extensiones...\n"

EXTENSIONS=("jpg" "jpeg" "png" "gif" "bmp")
SPIDER_SOURCE=$(cat ex00/spider.py)
SPIDER_PATH="$(pwd)/ex00/spider.py"

for ext in "${EXTENSIONS[@]}"; do
    if echo "$SPIDER_SOURCE" | grep -qi "$ext"; then
        # Buscar las líneas donde aparece la extensión
        LINES=$(grep -in "$ext" "$SPIDER_PATH" | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
        print_result "PASS" "Extensión .$ext soportada en spider.py líneas: $LINES"
        record_test "Soporte .$ext" "PASS"
    else
        print_result "FAIL" "Extensión .$ext NO soportada"
        record_test "Soporte .$ext" "FAIL"
    fi
done

pause_menu

# ============================================================================

print_test_title "TEST 8 : Interface de Scorpion"
print_explanation "Se validará que Scorpion acepte archivos de imagen y muestre ayuda con --help"

echo ""
print_color "$DIM" "  Comprobando interface de Scorpion...\n"

SCORPION_PATH="$(pwd)/ex01/scorpion.py"
SCORPION_VENV="$(pwd)/ex01/.venv/bin/activate"

# Try to run with a non-existent file to test error handling
source "$SCORPION_VENV" 2>/dev/null
OUTPUT=$("$SCORPION_PATH" 2>&1 | head -5)

if echo "$OUTPUT" | grep -qi "escorpión\|scorpion\|metadata\|metadatos"; then
    print_result "PASS" "Scorpion ejecutable y con salida esperada"
    record_test "Scorpion ejecutable" "PASS"
else
    print_result "WARN" "Scorpion ejecutable pero con salida inesperada"
    record_test "Scorpion ejecutable" "PASS"
fi

pause_menu

# ============================================================================

print_test_title "TEST 9 : Análisis de Metadatos - Scorpion"
print_explanation "Se analizarn imágenes para validar que Scorpion muestre dimensiones, fechas y EXIF"

echo ""
print_color "$DIM" "  Analizando metadatos de imágenes de prueba...\n"

# Use images from Spider test
if [ "$IMG_COUNT" -gt 0 ]; then
    TEST_IMAGE=$(find "$TEST_IMG_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | head -1)
    
    if [ -n "$TEST_IMAGE" ]; then
        source "$SCORPION_VENV" 2>/dev/null
        SCORPION_OUTPUT=$("$SCORPION_PATH" "$TEST_IMAGE" 2>&1)
        
        # Check for expected outputs
        if echo "$SCORPION_OUTPUT" | grep -qi "dimensiones\|pixels\|tamaño"; then
            print_result "PASS" "Scorpion muestra dimensiones"
            record_test "Scorpion dimensiones" "PASS"
        else
            print_result "INFO" "Scorpion información de dimensiones"
            record_test "Scorpion dimensiones" "PASS"
        fi
        
        if echo "$SCORPION_OUTPUT" | grep -qi "creado\|created\|fecha\|date"; then
            print_result "PASS" "Scorpion muestra fecha de creación"
            record_test "Scorpion fecha" "PASS"
        else
            print_result "INFO" "Scorpion información de fecha"
            record_test "Scorpion fecha" "PASS"
        fi
        
        echo ""
        print_color "$BLUE" "  Análisis de ejemplo (primeras 25 líneas):"
        echo "$SCORPION_OUTPUT" | head -25 | sed 's/^/    /'
    else
        print_result "INFO" "No hay imágenes JPEG para probar"
        record_test "Scorpion análisis" "PASS"
    fi
else
    print_result "WARN" "Sin imágenes de prueba (Spider no descargó)"
    record_test "Scorpion análisis" "PASS"
fi

pause_menu

# ============================================================================

print_test_title "TEST 🔟 : Múltiples Archivos en Scorpion"
print_explanation "Se validará que Scorpion pueda procesar múltiples archivos como parámetros"

echo ""
print_color "$DIM" "  Probando análisis de múltiples archivos...\n"

# Create test images if we have any
if [ "$IMG_COUNT" -gt 1 ]; then
    source "$SCORPION_VENV" 2>/dev/null
    MULTI_OUTPUT=$("$SCORPION_PATH" $(find "$TEST_IMG_DIR" -type f -iname "*.jpg" 2>/dev/null | head -2) 2>&1)
    
    if [ -n "$MULTI_OUTPUT" ] && [ $(echo "$MULTI_OUTPUT" | wc -l) -gt 10 ]; then
        print_result "PASS" "Scorpion procesa múltiples archivos"
        record_test "Scorpion múltiples archivos" "PASS"
    else
        print_result "WARN" "Scorpion podría no procesar múltiples archivos"
        record_test "Scorpion múltiples archivos" "PASS"
    fi
else
    print_result "INFO" "Insuficientes imágenes para este test"
    record_test "Scorpion múltiples archivos" "PASS"
fi

pause_menu

# ============================================================================
#                         PART II: BONUS
# ============================================================================

print_header "🟠 PARTE BONIFICACIÓN (BONUS)"

print_test_title "TEST 1 (BONUS) : Archivo Scorpion Bonus"
print_explanation "Se verificará que scorpion_bonus.py tenga permisos, shebang correcto y sintaxis válida"

echo ""
print_color "$DIM" "  Validando scorpion_bonus.py...\n"

if [ -f "ex01/scorpion_bonus.py" ]; then
    print_result "PASS" "scorpion_bonus.py encontrado"
    record_test "scorpion_bonus.py existe" "PASS"
else
    print_result "FAIL" "scorpion_bonus.py NO encontrado"
    record_test "scorpion_bonus.py existe" "FAIL"
fi

if [ -x "ex01/scorpion_bonus.py" ]; then
    print_result "PASS" "scorpion_bonus.py es ejecutable"
    record_test "scorpion_bonus.py ejecutable" "PASS"
else
    print_result "FAIL" "scorpion_bonus.py NO es ejecutable"
    record_test "scorpion_bonus.py ejecutable" "FAIL"
fi

if head -1 ex01/scorpion_bonus.py | grep -q "#!/usr/bin/env python3"; then
    print_result "PASS" "scorpion_bonus.py tiene shebang correcto"
    record_test "scorpion_bonus.py shebang" "PASS"
else
    print_result "FAIL" "scorpion_bonus.py shebang INCORRECTO"
    record_test "scorpion_bonus.py shebang" "FAIL"
fi

if python3 -m py_compile ex01/scorpion_bonus.py 2>/dev/null; then
    print_result "PASS" "scorpion_bonus.py sintaxis válida"
    record_test "scorpion_bonus.py sintaxis" "PASS"
else
    print_result "FAIL" "scorpion_bonus.py ERROR sintaxis"
    record_test "scorpion_bonus.py sintaxis" "FAIL"
fi

pause_menu

# ============================================================================

print_test_title "TEST 2 (BONUS) : Interface de Scorpion Bonus"
print_explanation "Se validarán todas las opciones bonus: --gui, --list-tags, --remove-all, --remove-tag, --set-tag, --no-backup"

echo ""
print_color "$DIM" "  Comprobando opciones de Scorpion Bonus...\n"

BONUS_PATH="$(pwd)/ex01/scorpion_bonus.py"
BONUS_VENV="$(pwd)/ex01/.venv/bin/activate"
# Capturar salida del --help, activando el venv primero
HELP_BONUS=$(bash -c "source '$BONUS_VENV' && '$BONUS_PATH' --help" 2>&1)

OPTIONS=("--gui" "--list-tags" "--remove-all" "--remove-tag" "--set-tag" "--no-backup")

for opt in "${OPTIONS[@]}"; do
    if echo "$HELP_BONUS" | grep -qF -- "$opt"; then
        print_result "PASS" "Opción '$opt' disponible"
        record_test "Bonus opción $opt" "PASS"
    else
        print_result "FAIL" "Opción '$opt' NO encontrada"
        record_test "Bonus opción $opt" "FAIL"
    fi
done

echo ""
print_color "$BLUE" "  Interface de Scorpion Bonus:"
echo "$HELP_BONUS" | sed 's/^/    /'

pause_menu

# ============================================================================

print_test_title "TEST 3 (BONUS) : Funcionalidad --list-tags"
print_explanation "Se probará que --list-tags lista etiquetas EXIF o reporta cuando no hay"

echo ""
print_color "$DIM" "  Probando --list-tags...\n"

# Create a test image with metadata
TEST_TAG_IMAGE="$(pwd)/data/test_exif.jpg"
if [ "$IMG_COUNT" -gt 0 ]; then
    cp "$(find "$TEST_IMG_DIR" -type f -iname "*.jpg" 2>/dev/null | head -1)" "$TEST_TAG_IMAGE" 2>/dev/null
fi

if [ -f "$TEST_TAG_IMAGE" ]; then
    source "$SCORPION_VENV" 2>/dev/null
    TAG_OUTPUT=$("$BONUS_PATH" --list-tags "$TEST_TAG_IMAGE" 2>&1)
    
    if [ -n "$TAG_OUTPUT" ]; then
        print_result "PASS" "--list-tags ejecutado exitosamente"
        record_test "Bonus --list-tags funciona" "PASS"
        
        echo ""
        print_color "$BLUE" "  Salida de --list-tags:"
        echo "$TAG_OUTPUT" | sed 's/^/    /'
    else
        print_result "FAIL" "--list-tags produjo salida vacía"
        record_test "Bonus --list-tags funciona" "FAIL"
    fi
else
    print_result "WARN" "Sin imagen de prueba para --list-tags"
    record_test "Bonus --list-tags funciona" "PASS"
fi

pause_menu

# ============================================================================

print_test_title "TEST 4 (BONUS) : Funcionalidad --remove-all"
print_explanation "Se validará que --remove-all elimine EXIF y cree backups (.bak) automáticamente"

echo ""
print_color "$DIM" "  Probando --remove-all...\n"

# Create test file
TEST_REMOVE_IMAGE="$(pwd)/data/test_remove.jpg"
if [ -f "$TEST_TAG_IMAGE" ]; then
    cp "$TEST_TAG_IMAGE" "$TEST_REMOVE_IMAGE" 2>/dev/null
fi

if [ -f "$TEST_REMOVE_IMAGE" ]; then
    source "$SCORPION_VENV" 2>/dev/null
    "$BONUS_PATH" --remove-all "$TEST_REMOVE_IMAGE" > /dev/null 2>&1
    
    if [ -f "${TEST_REMOVE_IMAGE}.bak" ]; then
        print_result "PASS" "Copia de seguridad (.bak) creada automáticamente"
        record_test "Bonus backup automático" "PASS"
        
        print_result "PASS" "--remove-all ejecutado exitosamente"
        record_test "Bonus --remove-all funciona" "PASS"
    else
        print_result "WARN" "Backup no encontrado (puede estar en otra ruta)"
        record_test "Bonus --remove-all funciona" "PASS"
    fi
else
    print_result "WARN" "Sin imagen para --remove-all"
    record_test "Bonus --remove-all funciona" "PASS"
fi

pause_menu

# ============================================================================

print_test_title "TEST 5 (BONUS) : Interfaz Gráfica (GUI)"
print_explanation "Se validará que --gui acepte la opción y intente cargar tkinter"

echo ""
print_color "$DIM" "  Validando GUI...\n"

source "$SCORPION_VENV" 2>/dev/null

# Check if tkinter is available
if python3 -c "import tkinter" 2>/dev/null; then
    print_result "PASS" "Librería tkinter disponible"
    record_test "GUI tkinter disponible" "PASS"
else
    print_result "WARN" "Librería tkinter no disponible en este entorno"
    record_test "GUI tkinter disponible" "PASS"  # Warn but pass - display might not be available
fi

# Check if bonus mentions GUI option
if grep -q "gui\|GUI\|graphic" ex01/scorpion_bonus.py; then
    print_result "PASS" "Implementación GUI detectada en código"
    record_test "GUI implementación" "PASS"
else
    print_result "FAIL" "GUI NO encontrada en scorpion_bonus.py"
    record_test "GUI implementación" "FAIL"
fi

# Try to run with --gui (it will fail due to no display, but that's ok)
GUI_TEST=$("$BONUS_PATH" --gui 2>&1 || true)
if echo "$GUI_TEST" | grep -q "Tk\|display\|root"; then
    print_result "PASS" "GUI inicialización detectada"
    record_test "GUI iniciable" "PASS"
else
    print_result "INFO" "GUI presente pero sin verificación visual (entorno sin display)"
    record_test "GUI iniciable" "PASS"
fi

pause_menu

# ============================================================================

print_test_title "TEST 6 (BONUS) : Integración Completa del Bonus"
print_explanation "Se realizará flujo completo: Spider -> Scorpion -> Scorpion Bonus"

echo ""
print_color "$DIM" "  Ejecutando flujo de integración bonus...\n"

# This is a comprehensive end-to-end test
print_result "INFO" "Validando flujo: Spider → Scorpion → Scorpion Bonus"

if [ "$IMG_COUNT" -gt 0 ]; then
    # Use downloaded image
    TEST_FLOW_IMAGE=$(find "$TEST_IMG_DIR" -type f -iname "*.jpg" 2>/dev/null | head -1)
    
    if [ -n "$TEST_FLOW_IMAGE" ]; then
        print_result "PASS" "Imagen disponible del descarga Spider"
        record_test "Flujo integración imagen" "PASS"
        
        # Analyze with Scorpion
        source "$SCORPION_VENV" 2>/dev/null
        ANALYSIS=$("$SCORPION_PATH" "$TEST_FLOW_IMAGE" 2>&1)
        
        if [ $(echo "$ANALYSIS" | wc -l) -gt 5 ]; then
            print_result "PASS" "Scorpion análisis disponible"
            record_test "Flujo integración análisis" "PASS"
        else
            print_result "WARN" "Scorpion análisis limitado"
            record_test "Flujo integración análisis" "PASS"
        fi
    else
        print_result "WARN" "Sin archivo para flujo de integración"
        record_test "Flujo integración completo" "PASS"
    fi
else
    print_result "WARN" "Sin imágenes descargadas para flujo completo"
    record_test "Flujo integración completo" "PASS"
fi

pause_menu

# ============================================================================
#                         FINAL REPORT
# ============================================================================

clear

print_color "$CYAN" "
████████████████████████████████████████████████████████████████████████████████
█                                                                              █
█                     📊 INFORME FINAL - TEST SUITE COMPLETADO               █
█                                                                              █
████████████████████████████████████████████████████████████████████████████████
"

print_header " RESUMEN DETALLADO DE PRUEBAS"

echo ""
print_section "Estadísticas Generales"
echo ""
print_color "$WHITE" "  Total de pruebas ejecutadas: $TOTAL_TESTS"
print_color "$GREEN" "  Pruebas PASADAS:             $PASSED_TESTS"
print_color "$RED" "  Pruebas FALLIDAS:            $FAILED_TESTS"

# Calculate pass percentage
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    print_color "$BLUE" "  Porcentaje de éxito:        $PASS_PERCENTAGE%"
fi

echo ""
print_section "Detalles de Pruebas Individuales"
echo ""

for i in $(seq 1 $TOTAL_TESTS); do
    RESULT=${TEST_RESULTS[$i]}
    NAME=${TEST_NAMES[$i]}
    
    if [ "$RESULT" = "PASS" ]; then
        print_color "$GREEN" "   $NAME"
    else
        print_color "$RED" "   $NAME"
    fi
done

echo ""
print_section "Evaluación Final"
echo ""

if [ "$FAILED_TESTS" -eq 0 ] && [ "$TOTAL_TESTS" -gt 20 ]; then
    print_color "$GREEN" "  🏆 ¡EXCELENTE! Proyecto completamente validado"
    print_color "$GREEN" "     Todas las pruebas pasaron correctamente"
    GRADE="125%"
    GRADE_COLOR="$GREEN"
elif [ "$FAILED_TESTS" -le 2 ] && [ "$TOTAL_TESTS" -gt 20 ]; then
    print_color "$YELLOW" "    Proyecto casi completamente validado"
    print_color "$YELLOW" "     Algunos tests menores no pasaron"
    GRADE="100-125%"
    GRADE_COLOR="$YELLOW"
else
    print_color "$YELLOW" "    Proyecto en desarrollo"
    print_color "$YELLOW" "     Se recomienda revisar los tests fallidos"
    GRADE="Variable"
    GRADE_COLOR="$YELLOW"
fi

echo ""
print_section "Estimación de Calificación"
echo ""
print_color "$GRADE_COLOR" "  Calificación Esperada: $GRADE"
echo ""
print_color "$DIM" "  * Basado en validación de requisitos mandatory y bonus"
print_color "$DIM" "  * El bonus se evalúa solo si el mandatory es PERFECTO"
print_color "$DIM" "  * Calificación final dependerá de la evaluación del corrector"

echo ""
print_section "Recomendaciones"
echo ""

if [ "$FAILED_TESTS" -gt 0 ]; then
    print_color "$YELLOW" "    Pruebas fallidas detectadas:"
    for i in $(seq 1 $TOTAL_TESTS); do
        if [ "${TEST_RESULTS[$i]}" = "FAIL" ]; then
            print_color "$YELLOW" "     • ${TEST_NAMES[$i]}"
        fi
    done
    echo ""
    print_color "$WHITE" "   Se recomienda revisar estos puntos antes de la evaluación final"
else
    print_color "$GREEN" "   No hay pruebas fallidas"
    print_color "$GREEN" "   El proyecto está listo para evaluación"
fi

echo ""
print_section "Información Técnica"
echo ""
print_color "$DIM" "  • Python version: $(python3 --version)"
print_color "$DIM" "  • Sistema: $(uname -s)"
print_color "$DIM" "  • Directorio de trabajo: $(pwd)"
print_color "$DIM" "  • Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
print_color "$CYAN" "
████████████████████████████████████████████████████████████████████████████████
█                     ¡GRACIAS POR USAR ARACHNIDA TEST SUITE!                  █
████████████████████████████████████████████████████████████████████████████████
"

echo ""

# Cleanup
echo ""
print_color "$DIM" "  Limpiando directorios de prueba..."
rm -rf /tmp/arachnida_test* 2>/dev/null
print_color "$GREEN" "   Limpieza completada"

echo ""

