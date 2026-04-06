#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
    FT_ONION - MÓDULO DE VALIDACIÓN Y DIAGNÓSTICO DEL SISTEMA

    Ejecuta verificaciones automáticas de salud, estado de servicios,
    archivos de configuración y servicio oculto Tor.

    Produce salida coloreada para interpretación rápida en terminal,
    y permite exportar estado completo en formato JSON.
"""

import subprocess
import os
import sys
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

# ============================================================================
#  COLORES Y FORMATO
# ============================================================================

class Colors:
    """Códigos de color ANSI para formato y legibilidad en terminal."""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    MAGENTA = '\033[0;35m'
    CYAN = '\033[0;36m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


class Logger:
    """Sistema de logging unificado con niveles de salida coloreados."""
    
    @staticmethod
    def info(message: str) -> None:
        """Registra un mensaje informativo."""
        print(f"{Colors.CYAN}[INFO]{Colors.RESET} {message}")
    
    @staticmethod
    def success(message: str) -> None:
        """Registra un mensaje de éxito."""
        print(f"{Colors.GREEN}[✓]{Colors.RESET} {message}")
    
    @staticmethod
    def warning(message: str) -> None:
        """Registra un mensaje de advertencia."""
        print(f"{Colors.YELLOW}[!]{Colors.RESET} {message}")
    
    @staticmethod
    def error(message: str) -> None:
        """Registra un mensaje de error."""
        print(f"{Colors.RED}[✗]{Colors.RESET} {message}")
    
    @staticmethod
    def separator() -> None:
        """Imprime una línea separadora visual."""
        print(f"{Colors.CYAN}{'━' * 60}{Colors.RESET}")


# ============================================================================
#  VALIDADORES
# ============================================================================

class ServiceValidator:
    """Validación de estado de servicios y comprobaciones de salud."""
    
    @staticmethod
    def check_service_running(service_name: str) -> bool:
        """Comprueba si un servicio systemd está en ejecución."""
        try:
            result = subprocess.run(
                ['systemctl', 'is-active', service_name],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except Exception as e:
            Logger.warning(f"No se pudo verificar {service_name}: {e}")
            return False
    
    @staticmethod
    def check_port_listening(port: int) -> bool:
        """Comprueba si un puerto de red está escuchando conexiones."""
        try:
            result = subprocess.run(
                ['netstat', '-tuln'],
                capture_output=True,
                text=True,
                timeout=5
            )
            return f":{port}" in result.stdout
        except Exception as e:
            Logger.warning(f"No se pudo verificar puerto {port}: {e}")
            return False
    
    @staticmethod
    def get_service_status(service_name: str) -> Dict[str, any]:
        """Obtiene estado detallado de un servicio con marca temporal."""
        status = {
            'name': service_name,
            'running': ServiceValidator.check_service_running(service_name),
            'timestamp': datetime.now().isoformat()
        }
        return status


class ConfigValidator:
    """Validación de archivos de configuración y sintaxis."""
    
    REQUIRED_FILES = {
        '/etc/nginx/nginx.conf': 'Configuración de Nginx',
        '/etc/tor/torrc': 'Configuración de Tor',
        '/etc/ssh/sshd_config': 'Configuración de SSH',
        '/var/www/html/index.html': 'Página web estática',
    }
    
    @staticmethod
    def validate_file_exists(filepath: str) -> Tuple[bool, str]:
        """Verifica existencia, tipo y legibilidad de un archivo."""
        path = Path(filepath)
        if not path.exists():
            return False, f"Archivo no encontrado: {filepath}"
        if not path.is_file():
            return False, f"No es un archivo: {filepath}"
        if not os.access(filepath, os.R_OK):
            return False, f"Archivo no legible: {filepath}"
        return True, "OK"
    
    @staticmethod
    def validate_nginx_config() -> Tuple[bool, str]:
        """Valida sintaxis de configuración de Nginx usando nginx -t."""
        try:
            result = subprocess.run(
                ['nginx', '-t'],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                return True, "Configuración Nginx válida"
            else:
                return False, result.stderr.strip()
        except Exception as e:
            return False, str(e)
    
    @staticmethod
    def validate_tor_config() -> Tuple[bool, str]:

        """Valida configuración básica obligatoria del archivo torrc."""
        valid, msg = ConfigValidator.validate_file_exists('/etc/tor/torrc')
        if valid:
            try:
                # Comprobar directivas básicas requeridas
                with open('/etc/tor/torrc', 'r') as f:
                    content = f.read()
                    if 'HiddenServiceDir' in content and 'HiddenServicePort' in content:
                        return True, "Configuración Tor válida"
                    else:
                        return False, "Falta configuración obligatoria de Tor"
            except Exception as e:
                return False, str(e)
        return valid, msg
    
    @staticmethod
    def validate_ssh_config() -> Tuple[bool, str]:
        """Valida configuración del daemon SSH y puerto obligatorio."""
        valid, msg = ConfigValidator.validate_file_exists('/etc/ssh/sshd_config')
        if valid:
            try:
                with open('/etc/ssh/sshd_config', 'r') as f:
                    content = f.read()
                    if 'Port 4242' in content:
                        return True, "Configuración SSH válida"
                    else:
                        return False, "Puerto 4242 no configurado"
            except Exception as e:
                return False, str(e)
        return valid, msg


class HiddenServiceValidator:
    """Valida inicialización y estado del servicio oculto Tor."""
    
    @staticmethod
    def get_onion_address() -> str:
        """Lee la dirección .onion desde hidden_service/hostname."""
        hostname_file = '/var/lib/tor/hidden_service/hostname'
        try:
            if os.path.exists(hostname_file):
                with open(hostname_file, 'r') as f:
                    return f.read().strip()
            return "Aún no generada"
        except Exception as e:
            return f"Error: {e}"
    
    @staticmethod
    def validate_hidden_service() -> Dict[str, any]:
        """Comprueba que el servicio oculto esté configurado y accesible."""
        result = {
            'status': 'checking',
            'onion_address': None,
            'directory_exists': False,
            'private_key_exists': False,
            'public_key_exists': False,
            'hostname_file_exists': False,
        }
        
        # Comprobar directorio del servicio oculto
        service_dir = '/var/lib/tor/hidden_service'
        result['directory_exists'] = os.path.isdir(service_dir)
        
        if result['directory_exists']:
            # Comprobar archivos de clave y hostname
            private_key = os.path.join(service_dir, 'hs_ed25519_secret_key')
            public_key = os.path.join(service_dir, 'hs_ed25519_public_key')
            hostname = os.path.join(service_dir, 'hostname')
            
            result['private_key_exists'] = os.path.exists(private_key)
            result['public_key_exists'] = os.path.exists(public_key)
            result['hostname_file_exists'] = os.path.exists(hostname)
            
            if result['hostname_file_exists']:
                result['onion_address'] = HiddenServiceValidator.get_onion_address()
                result['status'] = 'initialized' if '.' in result['onion_address'] else 'initializing'
            else:
                result['status'] = 'initializing'
        else:
            result['status'] = 'not_configured'
        
        return result


# ============================================================================
#  DIAGNÓSTICO DEL SISTEMA
# ============================================================================

class SystemDiagnostics:
    """Diagnóstico integral del sistema, servicios y configuración."""
    
    @staticmethod
    def get_full_status() -> Dict[str, any]:
        """Agrega estado de servicios, puertos, ficheros y configuración."""
        status = {
            'timestamp': datetime.now().isoformat(),
            'services': {
                'tor': ServiceValidator.get_service_status('tor'),
                'nginx': ServiceValidator.get_service_status('nginx'),
                'ssh': ServiceValidator.get_service_status('ssh'),
            },
            'ports': {
                'http_80': ServiceValidator.check_port_listening(80),
                'ssh_4242': ServiceValidator.check_port_listening(4242),
            },
            'files': {},
            'tor_hidden_service': HiddenServiceValidator.validate_hidden_service(),
            'configurations': {
                'nginx': ConfigValidator.validate_nginx_config(),
                'tor': ConfigValidator.validate_tor_config(),
                'ssh': ConfigValidator.validate_ssh_config(),
            }
        }
        
        # Verificar archivos requeridos
        for filepath, description in ConfigValidator.REQUIRED_FILES.items():
            valid, msg = ConfigValidator.validate_file_exists(filepath)
            status['files'][description] = {'valid': valid, 'message': msg}
        
        return status


# ============================================================================
#  REPORT GENERATION
# ============================================================================

def print_status_report(status: Dict) -> None:
    """Imprime un reporte de estado formateado y coloreado."""
    Logger.separator()
    print(f"{Colors.BOLD}{Colors.MAGENTA}🧅 FT_ONION - REPORTE DE ESTADO DEL SISTEMA{Colors.RESET}")
    Logger.separator()
    
    # Servicios
    print(f"\n{Colors.BOLD}Servicios:{Colors.RESET}")
    for service, info in status['services'].items():
        status_icon = f"{Colors.GREEN}✓{Colors.RESET}" if info['running'] else f"{Colors.RED}✗{Colors.RESET}"
        print(f"  {status_icon} {service.upper():6} {'Ejecutando' if info['running'] else 'Detenido'}")
    
    # Puertos
    print(f"\n{Colors.BOLD}Puertos de Red:{Colors.RESET}")
    for port, listening in status['ports'].items():
        status_icon = f"{Colors.GREEN}✓{Colors.RESET}" if listening else f"{Colors.YELLOW}✗{Colors.RESET}"
        print(f"  {status_icon} {port:15} {'Escuchando' if listening else 'No escuchando'}")
    
    # Archivos de configuración
    print(f"\n{Colors.BOLD}Archivos de Configuración:{Colors.RESET}")
    for file_desc, file_status in status['files'].items():
        status_icon = f"{Colors.GREEN}✓{Colors.RESET}" if file_status['valid'] else f"{Colors.RED}✗{Colors.RESET}"
        print(f"  {status_icon} {file_desc}")
    
    # Servicio oculto
    hs = status['tor_hidden_service']
    print(f"\n{Colors.BOLD}Servicio Oculto Tor:{Colors.RESET}")
    status_icon = {
        'initialized': f'{Colors.GREEN}✓{Colors.RESET}',
        'initializing': f'{Colors.YELLOW}⏳{Colors.RESET}',
        'not_configured': f'{Colors.RED}✗{Colors.RESET}',
    }.get(hs['status'], f'{Colors.YELLOW}?{Colors.RESET}')
    
    print(f"  {status_icon} Estado: {hs['status']}")
    if hs['onion_address']:
        print(f"  🌐 Dirección: {Colors.MAGENTA}{hs['onion_address']}{Colors.RESET}")
    
    Logger.separator()


# ============================================================================
#  CLI INTERFACE
# ============================================================================

def main() -> int:
    """Punto de entrada principal del validador."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Validador del sistema FT_ONION',
        epilog='Para más información, consulta la documentación del proyecto.'
    )
    
    parser.add_argument(
        '-s', '--status',
        action='store_true',
        help='Mostrar estado del sistema'
    )
    
    parser.add_argument(
        '-j', '--json',
        action='store_true',
        help='Muestra salida en formato JSON'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Muestra salida detallada'
    )
    
    args = parser.parse_args()
    
    # Recopilar estado del sistema
    status = SystemDiagnostics.get_full_status()
    
    if args.json:
        print(json.dumps(status, indent=2))
    else:
        print_status_report(status)
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
