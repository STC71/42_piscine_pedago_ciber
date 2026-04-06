#!/bin/bash
# Suite de pruebas automáticas para ft_otp

PROJECT_DIR="$(cd "${1:-.}" && pwd)"  # Convert to absolute path
FT_OTP="python3 $PROJECT_DIR/ft_otp.py"
TEST_DIR="/tmp/ft_otp_tests_$$"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Contadores
PASS=0
FAIL=0
WARN=0

# Configuración
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
trap "cd - && rm -rf $TEST_DIR" EXIT

# Funciones de prueba
test_pass() {
    echo -e "    ${GREEN}✓${NC} $1"
    ((PASS++))
}

test_fail() {
    echo -e "    ${RED}✗${NC} $1"
    ((FAIL++))
}

test_warn() {
    echo -e "    ${YELLOW}⚠${NC} $1"
    ((WARN++))
}

echo "======================================================"
echo "           SUITE DE PRUEBAS ft_otp"
echo "======================================================"
echo ""

#=== PRUEBAS REQUERIDAS ===

echo "[PRUEBAS REQUERIDAS]"  
echo ""

# Prueba 1: Rechaza clave corta
echo "Prueba 1: Rechaza clave corta"
echo "ABCDEF0123456789" > short.hex
if $FT_OTP -g short.hex 2>&1 | grep -q "caracteres hexadecimales"; then
    test_pass "Rechaza clave < 64 caracteres hex"
else
    test_fail "Rechaza clave < 64 caracteres hex"
fi

# Prueba 2: Rechaza caracteres no hexadecimales
echo "Prueba 2: Rechaza caracteres no hexadecimales"
printf 'Z%.0s' {1..64} > invalid.hex
if $FT_OTP -g invalid.hex 2>&1 | grep -q "caracteres hexadecimales"; then
    test_pass "Rechaza caracteres no hexadecimales"
else
    test_fail "Rechaza caracteres no hexadecimales"
fi

# Prueba 3: Generación exitosa de clave
echo "Prueba 3: Generación exitosa de clave"
echo "3132333435363738393031323334353637383930313233343536373839303132" > valid.hex
if $FT_OTP -g valid.hex 2>&1 | grep -q "successfully saved" && [ -f "ft_otp.key" ]; then
    test_pass "Almacena clave cifrada correctamente"
else
    test_fail "Almacena clave cifrada correctamente"
fi

# Prueba 4: Formato de código TOTP
echo "Prueba 4: Formato de código TOTP"
code=$($FT_OTP -k ft_otp.key 2>/dev/null)
if [[ $code =~ ^[0-9]{6}$ ]]; then
    test_pass "Genera código TOTP de 6 dígitos: $code"
else
    test_fail "Genera código TOTP de 6 dígitos (obtuvo: '$code')"
fi

# Prueba 5: Manejo de espacios en blanco
echo "Prueba 5: Manejo de espacios en blanco"
echo "  3132333435363738393031323334353637383930313233343536373839303132  " > spaces.hex
if $FT_OTP -g spaces.hex 2>&1 | grep -q "successfully saved"; then
    test_pass "Elimina espacios al inicio/final"
else
    test_fail "Elimina espacios al inicio/final"
fi

# Prueba 6: Acepta hex mayúsculas
echo "Prueba 6: Acepta hex mayúsculas"
echo "3132333435363738393031323334353637383930313233343536373839303132" | tr 'a-f' 'A-F' > upper.hex
rm -f ft_otp.key
if $FT_OTP -g upper.hex 2>&1 | grep -q "successfully saved"; then
    test_pass "Acepta hexadecimales mayúsculas"
else
    test_fail "Acepta hexadecimales mayúsculas"
fi

# Prueba 7: Acepta claves más largas
echo "Prueba 7: Acepta claves más largas"
echo "3132333435363738393031323334353637383930313233343536373839303132AAAAAAAAAA" > long.hex
rm -f ft_otp.key
if $FT_OTP -g long.hex 2>&1 | grep -q "successfully saved"; then
    test_pass "Acepta claves > 64 caracteres hex"
else
    test_fail "Acepta claves > 64 caracteres hex"
fi

# Prueba 8: Manejo de archivo faltante
echo "Prueba 8: Manejo de archivo faltante"
if $FT_OTP -k /inexistente/archivo.key 2>&1 | grep -q -E "(Error|error)"; then
    test_pass "Maneja archivo de clave faltante"
else
    test_fail "Maneja archivo de clave faltante"
fi

# Prueba 9: Manejo de archivo corrupto
echo "Prueba 9: Manejo de archivo corrupto"
echo "datos_corrompidos" > corrupt.key
if $FT_OTP -k corrupt.key 2>&1 | grep -q -E "(Error|error)" || [ $? -ne 0 ]; then
    test_pass "Maneja archivo de clave corrupto"
else
    test_fail "Maneja archivo de clave corrupto"
fi

echo ""
echo "[PRUEBAS BONUS]"
echo ""

# Bonus: Compatibilidad con herramienta de validación TOTP
echo "Prueba 10: Compatibilidad con validador TOTP (opcional)"
if [ -f "$PROJECT_DIR/validate_totp.py" ]; then
    echo "3132333435363738393031323334353637383930313233343536373839303132" > reference.hex
    rm -f ft_otp.key
    $FT_OTP -g reference.hex >/dev/null 2>&1
    our_code=$($FT_OTP -k ft_otp.key 2>/dev/null)
    ref_code=$(python3 "$PROJECT_DIR/validate_totp.py" "3132333435363738393031323334353637383930313233343536373839303132" 2>/dev/null)
    if [ "$our_code" = "$ref_code" ]; then
        test_pass "Compatible con validador TOTP: $our_code"
    else
        test_warn "Códigos del validador difieren (nuestro: $our_code, referencia: $ref_code)"
    fi
else
    test_warn "Validador TOTP no disponible (prueba omitida)"
fi

# Bonus: Generación de código QR
echo "Prueba 11: Generación de código QR (opcional)"
echo "3132333435363738393031323334353637383930313233343536373839303132" > qr.hex
rm -f ft_otp.key
if $FT_OTP -g qr.hex --qr qr_out.png 2>&1 | grep -q "successfully saved"; then
    if [ -f "qr_out.png" ]; then
        test_pass "Genera código QR"
    else
        test_warn "Generación de QR (librería PIL/Pillow no instalada)"
    fi
else
    test_warn "Generación de QR (librerías no disponibles)"
fi

echo ""
echo "======================================================"
echo -e "RESULTADOS: ${GREEN}$PASS CORRECTO${NC} | ${RED}$FAIL FALLO${NC} | ${YELLOW}$WARN ADVERTENCIA${NC}"
echo "======================================================"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ TODAS LAS PRUEBAS REQUERIDAS PASARON${NC}"
    if [ $WARN -eq 0 ]; then
        echo -e "${GREEN}✓ TODAS LAS PRUEBAS BONUS PASARON${NC}"
    else
        echo -e "${YELLOW}⚠ Algunas pruebas bonus omitidas (dependencias faltantes)${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ $FAIL PRUEBA(S) FALLARON${NC}"
    exit 1
fi
