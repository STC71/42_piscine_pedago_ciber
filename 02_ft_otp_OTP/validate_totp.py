#!/usr/bin/env python3
"""
Herramienta de validación TOTP - Genera códigos TOTP para validar compatibilidad
Uso: ./validate_totp.py <hex_key>
"""

import sys
import time
import hmac
import hashlib
import struct
import base64

def hotp(key_bytes, counter, digits=6):
    """Genera HOTP según RFC 4226"""
    counter_bytes = struct.pack('>Q', counter)
    hmac_result = hmac.new(key_bytes, counter_bytes, hashlib.sha1).digest()
    offset = hmac_result[-1] & 0x0F
    code = (
        ((hmac_result[offset] & 0x7F) << 24) |
        ((hmac_result[offset + 1] & 0xFF) << 16) |
        ((hmac_result[offset + 2] & 0xFF) << 8) |
        (hmac_result[offset + 3] & 0xFF)
    )
    return code % (10 ** digits)

def totp(key_bytes, time_value=None, time_step=30, t0=0, digits=6):
    """Genera TOTP según RFC 6238"""
    if time_value is None:
        time_value = int(time.time())
    counter = (time_value - t0) // time_step
    return hotp(key_bytes, counter, digits)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: ./validate_totp.py <hex_key>")
        sys.exit(1)
    
    hex_key = sys.argv[1].strip()
    
    # Validar longitud
    if len(hex_key) < 64:
        print("Error: key must be 64 hexadecimal characters.", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Convertir hex a bytes (solo primeros 64 caracteres = 32 bytes)
        key_bytes = bytes.fromhex(hex_key[:64])
        
        # Generar TOTP actual
        code = totp(key_bytes)
        print(f"{code:06d}")
    except ValueError:
        print("Error: key must be 64 hexadecimal characters.", file=sys.stderr)
        sys.exit(1)
