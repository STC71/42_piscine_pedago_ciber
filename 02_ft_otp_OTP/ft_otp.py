#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
ft_otp - Generador de Contraseñas de Un Solo Uso Basadas en Tiempo (TOTP)


Descripción:
    Implementación completa de los estándares RFC 6238 (TOTP) y RFC 4226 (HOTP) 
    para generar códigos de autenticación de dos factores.

Características:
    - Generación de claves seguras con validación hexadecimal
    - Cifrado XOR de claves para almacenamiento seguro
    - Generación de códigos TOTP de 6 dígitos cada 30 segundos
    - Interfaz de línea de comandos y GUI (Tkinter)
    - Generación de códigos QR para aplicaciones móviles
    - Compatibilidad con herramientas estándar (oathtool)
"""

import sys
import os
import time
import hmac
import hashlib
import struct
from pathlib import Path
from typing import Optional, Tuple

# Try to import optional dependencies
try:
    from cryptography.fernet import Fernet
    CRYPTO_AVAILABLE = True
except ImportError:
    CRYPTO_AVAILABLE = False

try:
    import qrcode
    import qrcode.image.svg
    QRCODE_AVAILABLE = True
except ImportError:
    QRCODE_AVAILABLE = False

try:
    from PIL import Image
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

try:
    import tkinter as tk
    from tkinter import messagebox, filedialog
    from tkinter import ttk
    import threading
    GUI_AVAILABLE = True
except ImportError:
    GUI_AVAILABLE = False

# Constants
ENCRYPTED_KEY_FILE = "ft_otp.key"
KEY_LENGTH = 32  # 256 bits
TOTP_TIME_STEP = 30  # seconds
TOTP_T0 = 0  # Unix epoch
TOTP_DIGITS = 6
TOTP_ALGORITHM = hashlib.sha1


class OTPError(Exception):
    """Excepción base para errores de OTP"""
    pass


class KeyValidationError(OTPError):
    """Excepción para errores de validación de claves"""
    pass


class FileError(OTPError):
    """Excepción para errores relacionados con archivos"""
    pass


def is_valid_hex_key(key: str) -> bool:
    """
    Valida si la clave es una cadena hexadecimal válida de al menos 64 caracteres.
    
    Args:
        key: Cadena a validar
        
    Returns:
        True si es válida, False en caso contrario
    """
    if not key:
        return False
    
    # Strip whitespace
    key = key.strip()
    
    # Check minimum length (64 hex chars = 32 bytes = 256 bits)
    if len(key) < 64:
        return False
    
    # Check if all characters are valid hex
    try:
        int(key, 16)
        return True
    except ValueError:
        return False


def read_key_from_file(filename: str) -> str:
    """
    Lee y parsea la clave del archivo.
    
    Args:
        filename: Ruta del archivo de clave
        
    Returns:
        Cadena de clave con espacios en blanco eliminados
        
    Raises:
        FileError: Si el archivo no puede leerse
    """
    try:
        with open(filename, 'r') as f:
            content = f.read()
        return content.strip()
    except FileNotFoundError:
        raise FileError(f"Error: wrong file")
    except Exception as e:
        raise FileError(f"Error: cannot read file: {e}")


def hex_str_to_bytes(hex_str: str) -> bytes:
    """
    Convierte una cadena hexadecimal a bytes.
    
    Args:
        hex_str: Cadena hexadecimal (mín 64 caracteres para 32 bytes)
        
    Returns:
        Objeto bytes
        
    Raises:
        ValueError: Si la cadena hexadecimal es inválida
    """
    # Take first 64 hex characters (32 bytes)
    hex_str = hex_str[:64]
    return bytes.fromhex(hex_str)


def get_encryption_key() -> bytes:
    """
    Obtiene o genera una clave de cifrado coherente para almacenar claves TOTP.
    Utiliza un cifrado simple basado en XOR con una clave maestra codificada.
    Para producción, considere usar una función de derivación de clave adecuada.
    
    Returns:
        Clave de cifrado como bytes
    """
    # Master password (hardcoded for this implementation)
    # In production, this should be derived from user input or environment
    master_password = b"ft_otp_master_key_32_bytes_long!"
    return master_password[:32]


def encrypt_key(key_bytes: bytes) -> bytes:
    """
    Cifra la clave TOTP usando XOR con la clave maestra.
    Cifrado XOR simple para seguridad.
    
    Args:
        key_bytes: Los bytes de clave a cifrar (deben ser 32 bytes)
        
    Returns:
        Bytes cifrados
    """
    master_key = get_encryption_key()
    encrypted = bytes(a ^ b for a, b in zip(key_bytes, master_key))
    return encrypted


def decrypt_key(encrypted_bytes: bytes) -> bytes:
    """
    Descifra la clave TOTP usando XOR con la clave maestra.
    
    Args:
        encrypted_bytes: Los bytes cifrados (deben ser 32 bytes)
        
    Returns:
        Bytes de clave descifrados
    """
    master_key = get_encryption_key()
    decrypted = bytes(a ^ b for a, b in zip(encrypted_bytes, master_key))
    return decrypted


def save_encrypted_key(key_bytes: bytes, filename: str = ENCRYPTED_KEY_FILE) -> None:
    """
    Cifra y guarda la clave en un archivo.
    
    Args:
        key_bytes: Los bytes de clave a guardar (deben ser 32 bytes)
        filename: Nombre del archivo de salida
        
    Raises:
        FileError: Si el archivo no puede escribirse
    """
    try:
        encrypted = encrypt_key(key_bytes)
        with open(filename, 'wb') as f:
            f.write(encrypted)
    except Exception as e:
        raise FileError(f"Error: cannot write file: {e}")


def load_encrypted_key(filename: str = ENCRYPTED_KEY_FILE) -> bytes:
    """
    Carga y descifra la clave de un archivo.
    
    Args:
        filename: Nombre del archivo de entrada
        
    Returns:
        Bytes de clave descifrados
        
    Raises:
        FileError: Si el archivo no puede leerse
    """
    try:
        with open(filename, 'rb') as f:
            encrypted = f.read()
        
        if len(encrypted) != KEY_LENGTH:
            raise FileError(f"Error: bad file")
        
        decrypted = decrypt_key(encrypted)
        return decrypted
    except FileNotFoundError:
        raise FileError(f"Error: wrong file")
    except Exception as e:
        raise FileError(f"Error: bad file: {e}")


def hotp(key: bytes, counter: int, digits: int = TOTP_DIGITS) -> int:
    """
    Genera valor HOTP (Contraseña de Un Solo Uso basada en HMAC).
    Implementa RFC 4226.
    
    Args:
        key: Clave secreta (bytes)
        counter: Valor del contador (normalmente basado en tiempo para TOTP)
        digits: Número de dígitos para la salida (predeterminado 6)
        
    Returns:
        Valor OTP como entero (0 a 10^digits - 1)
    """
    # Step 1: Generate HMAC-SHA1
    counter_bytes = struct.pack('>Q', counter)  # 8 bytes, big-endian
    hmac_result = hmac.new(key, counter_bytes, TOTP_ALGORITHM).digest()
    
    # Step 2: Dynamic Truncation
    offset = hmac_result[-1] & 0x0F
    
    # Extract 4 bytes from offset
    code = (
        ((hmac_result[offset] & 0x7F) << 24) |
        ((hmac_result[offset + 1] & 0xFF) << 16) |
        ((hmac_result[offset + 2] & 0xFF) << 8) |
        (hmac_result[offset + 3] & 0xFF)
    )
    
    # Step 3: Modulo 10^digits
    otp = code % (10 ** digits)
    
    return otp


def totp(key: bytes, time_value: Optional[int] = None,
         time_step: int = TOTP_TIME_STEP,
         t0: int = TOTP_T0,
         digits: int = TOTP_DIGITS) -> int:
    """
    Genera valor TOTP (Contraseña de Un Solo Uso basada en Tiempo).
    Implementa RFC 6238.
    
    Args:
        key: Clave secreta (bytes)
        time_value: Marca de tiempo Unix (predeterminado: hora actual)
        time_step: Paso de tiempo en segundos (predeterminado: 30)
        t0: Valor de tiempo inicial (predeterminado: 0 - época Unix)
        digits: Número de dígitos para la salida (predeterminado: 6)
        
    Returns:
        Valor OTP como entero
    """
    if time_value is None:
        time_value = int(time.time())
    
    # Calculate time counter
    counter = (time_value - t0) // time_step
    
    # Generate HOTP with time counter
    return hotp(key, counter, digits)


def generate_mode(key_file: str) -> None:
    """
    Maneja modo -g: Genera y almacena clave cifrada.
    
    Args:
        key_file: Ruta del archivo que contiene la clave hexadecimal
        
    Raises:
        KeyValidationError: Si la clave es inválida
        FileError: Si las operaciones de archivo fallan
    """
    try:
        # Read key from file
        key_hex = read_key_from_file(key_file)
        
        # Validate hex key
        if not is_valid_hex_key(key_hex):
            print("./ft_otp: error: la clave debe ser 64 caracteres hexadecimales.")
            sys.exit(1)
        
        # Convert hex to bytes
        key_bytes = hex_str_to_bytes(key_hex)
        
        # Save encrypted key
        save_encrypted_key(key_bytes)
        
        print("Key was successfully saved in ft_otp.key.")
    except FileError as e:
        print(str(e))
        sys.exit(1)


def key_mode(key_file: str) -> None:
    """
    Maneja modo -k: Genera y muestra contraseña TOTP.
    
    Args:
        key_file: Ruta del archivo de clave cifrada
        
    Raises:
        FileError: Si el archivo de clave no puede leerse
    """
    try:
        # Load encrypted key
        key_bytes = load_encrypted_key(key_file)
        
        # Generate TOTP
        otp_value = totp(key_bytes)
        
        # Print formatted 6-digit code
        print(f"{otp_value:06d}")
    except FileError as e:
        print(str(e))
        sys.exit(1)


def generate_qr_code(key_hex: str, label: str = "ft_otp", issuer: str = "ft_otp", format: str = "png") -> bytes:
    """
    Genera código QR para configuración de TOTP.
    Implementa formato de URI otpauth://.
    
    Args:
        key_hex: Clave hexadecimal
        label: Etiqueta para el código QR
        issuer: Nombre del emisor
        format: Formato de salida ('png' o 'svg'). Por defecto PNG
        
    Returns:
        Representación del código QR como bytes (PNG) o string (SVG)
        
    Raises:
        ImportError: Si las librerías requeridas no están disponibles
    """
    if not QRCODE_AVAILABLE:
        raise ImportError("qrcode library not available. Install with: pip install qrcode[pil]")
    
    # Convert hex to base32 for otpauth URI
    import base64
    key_bytes = hex_str_to_bytes(key_hex)
    key_base32 = base64.b32encode(key_bytes).decode().rstrip('=')
    
    # Create otpauth URI
    uri = f"otpauth://totp/{label}?secret={key_base32}&issuer={issuer}&algorithm=SHA1&digits=6&period=30"
    
    # Generate QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(uri)
    qr.make(fit=True)
    
    if format.lower() == "png":
        if not PIL_AVAILABLE:
            raise ImportError("PIL/Pillow not available. Install with: pip install Pillow")
        # Create PNG image
        img = qr.make_image(fill_color="black", back_color="white")
        from io import BytesIO
        png_buffer = BytesIO()
        img.save(png_buffer, format='PNG')
        return png_buffer.getvalue()
    else:
        # Create SVG image
        img = qr.make_image(image_factory=qrcode.image.svg.SvgPathImage)
        from io import BytesIO
        svg_buffer = BytesIO()
        img.save(svg_buffer)
        return svg_buffer.getvalue().decode('utf-8')


def generate_mode_qr(key_file: str, output_file: Optional[str] = None) -> None:
    """
    Maneja modo -g con generación de código QR.
    
    Args:
        key_file: Ruta del archivo que contiene la clave hexadecimal
        output_file: Archivo de salida opcional para el código QR (formato PNG o SVG)
                    Si no se especifica, se guarda como qr_code.png en la carpeta actual
        
    Raises:
        KeyValidationError: Si la clave es inválida
        FileError: Si las operaciones de archivo fallan
    """
    try:
        # Read key from file
        key_hex = read_key_from_file(key_file)
        
        # Validate hex key
        if not is_valid_hex_key(key_hex):
            print("./ft_otp: error: la clave debe ser 64 caracteres hexadecimales.")
            sys.exit(1)
        
        # Convert hex to bytes
        key_bytes = hex_str_to_bytes(key_hex)
        
        # Save encrypted key
        save_encrypted_key(key_bytes)
        print("Key was successfully saved in ft_otp.key.")
        
        # Generate QR code
        try:
            # Use default filename if not specified
            if output_file is None:
                output_file = "qr_code.png"
            
            # Determine format from file extension
            format = "png" if output_file.endswith(".png") else "svg"
            
            qr_data = generate_qr_code(key_hex, format=format)
            
            # Write as binary for PNG, text for SVG
            mode = 'wb' if format == 'png' else 'w'
            with open(output_file, mode) as f:
                f.write(qr_data)
            print(f"QR code saved to {output_file}.")
        except ImportError as e:
            print(f"Warning: {e}")
    except FileError as e:
        print(str(e))
        sys.exit(1)


class TOTPGui:
    """Interfaz gráfica simple con Tkinter para generación y gestión de TOTP."""
    
    def __init__(self, root):
        """Inicializa la interfaz gráfica."""
        self.root = root
        self.root.title("ft_otp - Generador TOTP")
        self.root.geometry("400x300")
        self.root.resizable(False, False)
        
        self.key_bytes = None
        self.current_otp = None
        self.time_remaining = 0
        self.updating = True
        
        self.setup_ui()
        self.update_time_display()
    
    def setup_ui(self):
        """Configura los elementos de la interfaz gráfica."""
        # Título
        title_label = ttk.Label(
            self.root,
            text="Generador TOTP",
            font=("Arial", 16, "bold")
        )
        title_label.pack(pady=10)
        
        # Botón cargar clave
        load_button = ttk.Button(
            self.root,
            text="Cargar Archivo de Clave",
            command=self.load_key
        )
        load_button.pack(pady=5)
        
        # Etiqueta de estado
        self.status_label = ttk.Label(
            self.root,
            text="Ninguna clave cargada",
            foreground="red"
        )
        self.status_label.pack(pady=5)
        
        # Visualización de código
        code_frame = ttk.LabelFrame(self.root, text="Código Actual")
        code_frame.pack(pady=10, padx=10, fill="x")
        
        self.code_label = ttk.Label(
            code_frame,
            text="------",
            font=("Arial", 24, "bold"),
            foreground="blue"
        )
        self.code_label.pack(pady=10)
        
        # Tiempo restante
        self.time_label = ttk.Label(
            code_frame,
            text="Tiempo restante: 30s",
            font=("Arial", 10)
        )
        self.time_label.pack(pady=5)
        
        # Botón copiar
        self.copy_button = ttk.Button(
            self.root,
            text="Copiar al Portapapeles",
            command=self.copy_code,
            state="disabled"
        )
        self.copy_button.pack(pady=5)
        
        # Generar QR nuevo
        qr_button = ttk.Button(
            self.root,
            text="Generar Código QR",
            command=self.show_qr_code
        )
        qr_button.pack(pady=5)
    
    def load_key(self):
        """Carga clave cifrada del archivo."""
        file_path = filedialog.askopenfilename(
            title="Seleccionar archivo de clave cifrada",
            filetypes=[("Archivos de clave", "*.key"), ("Todos los archivos", "*")]
        )
        
        if file_path:
            try:
                self.key_bytes = load_encrypted_key(file_path)
                self.status_label.config(
                    text="Clave cargada exitosamente",
                    foreground="green"
                )
                self.copy_button.config(state="normal")
            except FileError as e:
                self.status_label.config(
                    text=f"Error: {str(e)}",
                    foreground="red"
                )
                self.copy_button.config(state="disabled")
    
    def update_time_display(self):
        """Actualiza la visualización del código TOTP y tiempo."""
        if self.key_bytes:
            current_time = int(time.time())
            self.current_otp = totp(self.key_bytes)
            self.code_label.config(text=f"{self.current_otp:06d}")
            
            # Calcular tiempo restante en el paso actual
            self.time_remaining = TOTP_TIME_STEP - (current_time % TOTP_TIME_STEP)
            self.time_label.config(
                text=f"Tiempo restante: {self.time_remaining}s"
            )
        
        if self.updating:
            self.root.after(1000, self.update_time_display)
    
    def copy_code(self):
        """Copia el código actual al portapapeles."""
        if self.current_otp:
            self.root.clipboard_clear()
            self.root.clipboard_append(f"{self.current_otp:06d}")
            messagebox.showinfo("Copiado", "¡Código copiado al portapapeles!")
    
    def show_qr_code(self):
        """Muestra ventana de código QR."""
        if not self.key_bytes:
            messagebox.showwarning("Advertencia", "Por favor, cargue un archivo de clave primero")
            return
        
        try:
            # Esto requeriría que el código QR se muestre en una ventana separada
            messagebox.showinfo("Código QR", "La generación de código QR en GUI aún no está completamente implementada")
        except Exception as e:
            messagebox.showerror("Error", f"No se pudo generar código QR: {e}")
    
    def on_closing(self):
        """Maneja el cierre de la ventana."""
        self.updating = False
        self.root.destroy()


def launch_gui():
    """Inicia la aplicación de interfaz gráfica."""
    if not GUI_AVAILABLE:
        print("Error: Tkinter not available. Cannot launch GUI.")
        print("Install with: sudo apt-get install python3-tk")
        sys.exit(1)
    
    root = tk.Tk()
    app = TOTPGui(root)
    root.protocol("WM_DELETE_WINDOW", app.on_closing)
    root.mainloop()


def print_usage():
    """Imprime información de uso."""
    usage = """
Uso:
  ./ft_otp -g <archivo_clave>              Genera y almacena clave cifrada
  ./ft_otp -k <archivo_clave>              Genera código TOTP
  ./ft_otp -g <archivo_clave> --qr [arch]  Genera clave con código QR
  ./ft_otp --gui                            Inicia interfaz gráfica
  ./ft_otp --help                           Muestra este mensaje de ayuda

Ejemplos:
  ./ft_otp -g key.hex
  ./ft_otp -k ft_otp.key
  ./ft_otp -g key.hex --qr qrcode.svg
  ./ft_otp --gui
"""
    print(usage)


def main():
    """Punto de entrada principal."""
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "--help":
        print_usage()
        sys.exit(0)
    elif command == "--gui":
        launch_gui()
    elif command == "-g":
        if len(sys.argv) < 3:
            print("Error: -g requiere un nombre de archivo")
            sys.exit(1)
        
        key_file = sys.argv[2]
        
        # Verifica opción de código QR
        if len(sys.argv) > 3 and sys.argv[3] == "--qr":
            output_file = sys.argv[4] if len(sys.argv) > 4 else None
            generate_mode_qr(key_file, output_file)
        else:
            generate_mode(key_file)
    elif command == "-k":
        if len(sys.argv) < 3:
            print("Error: -k requiere un nombre de archivo")
            sys.exit(1)
        
        key_file = sys.argv[2]
        key_mode(key_file)
    else:
        print(f"Error: comando desconocido {command}")
        print_usage()
        sys.exit(1)


if __name__ == "__main__":
    main()
