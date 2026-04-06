# 🔐 Piscina Pedago de Ciberseguridad - 42 Málaga

Colección de proyectos de ciberseguridad de la Piscina de Ciberseguridad de 42, cubriendo seguridad web, análisis de red, criptografía y anonimato.

## 📋 Tabla de Contenidos
- [Descripción General](#descripción-general)
- [Proyectos](#proyectos)
- [Habilidades Desarrolladas](#habilidades-desarrolladas)
- [Requisitos Previos](#requisitos-previos)
- [Directrices Generales](#directrices-generales)

---

## 🎯 Descripción General

La **Piscina Pedago de Ciberseguridad** es un programa intensivo centrado en habilidades prácticas de ciberseguridad. Estos proyectos cubren conceptos fundamentales de seguridad y vectores de ataque:

- **Seguridad Web**: Scraping, análisis de metadatos
- **Seguridad de Red**: Envenenamiento ARP, interceptación de tráfico
- **Criptografía**: Contraseñas de un solo uso basadas en tiempo (TOTP)
- **Anonimato**: Servicios ocultos Tor

---

## 📚 Proyectos

### 🕷️ [01 - Arachnida (Web Scraping y Metadatos)](./01_arachnida_Web/)

**Tipo**: Seguridad Web  
**Dificultad**: ⭐⭐  
**Habilidades**: Python, HTTP, EXIF, Web Scraping

Crear dos programas:
- **Spider**: Extraer recursivamente imágenes de sitios web
- **Scorpion**: Analizar y mostrar metadatos EXIF de imágenes

**Aprendizaje Clave**:
- Técnicas de web scraping
- Manejo de peticiones HTTP
- Extracción de metadatos EXIF
- Implicaciones de privacidad de los metadatos

[📖 Documentación Completa](./01_arachnida_Web/README.md)

---

### 🧅 [02 - ft_onion (Servicio Oculto Tor)](./02_ft_onion_Web/)

**Tipo**: Anonimato de Red  
**Dificultad**: ⭐⭐⭐  
**Habilidades**: Nginx, Tor, SSH, Docker

Desplegar un servidor web accesible a través de la red Tor:
- Configurar servidor web Nginx
- Configurar servicio oculto Tor
- Implementar fortificación SSH
- Crear página accesible mediante `.onion`

**Aprendizaje Clave**:
- Arquitectura de la red Tor
- Configuración de servicios ocultos
- Despliegue de servidor web
- Conceptos de anonimato y privacidad

[📖 Documentación Completa](./02_ft_onion_Web/README.md)

---

### 🔑 [03 - ft_otp (OTP Basado en Tiempo)](./03_ft_otp_OTP/)

**Tipo**: Criptografía y Autenticación  
**Dificultad**: ⭐⭐⭐  
**Habilidades**: HMAC, TOTP, Criptografía

Implementar sistema TOTP (Contraseña de Un Solo Uso Basada en Tiempo):
- Generar y almacenar claves cifradas
- Producir códigos de 6 dígitos basados en tiempo
- Compatible con estándar RFC 6238
- Validar contra herramientas estándar (oathtool)

**Aprendizaje Clave**:
- Autenticación de dos factores (2FA)
- Criptografía basada en HMAC
- Sincronización de tiempo
- Almacenamiento seguro de claves

[📖 Documentación Completa](./03_ft_otp_OTP/README.md)

---

### 🔍 [04 - Inquisitor (Envenenamiento ARP)](./04_Inquisitor_Network/)

**Tipo**: Seguridad de Red  
**Dificultad**: ⭐⭐⭐⭐  
**Habilidades**: ARP, Sniffing de Paquetes, Man-in-the-Middle

Implementar ataque de envenenamiento ARP para interceptar y analizar tráfico de red:
- ARP spoofing bidireccional
- Interceptación de tráfico FTP
- Restauración de tabla ARP
- Sniffing de paquetes con libpcap

**Aprendizaje Clave**:
- Vulnerabilidades de Capa 2 OSI
- Ataques Man-in-the-Middle
- Análisis de protocolos de red
- Principios de hacking ético

[📖 Documentación Completa](./04_Inquisitor_Network/README.md)

---

### 🛡️ [06 - Iron Dome (Detector de Ransomware)](./06_Iron_Dome_Malware_Optional/)

**Tipo**: Ciberseguridad de Sistemas y Malware (Opcional/Bonus)  
**Dificultad**: ⭐⭐⭐⭐  
**Habilidades**: Python, Monitorización de OS, Heurística de Entropía, Hilos

Desarrollar un daemon que proteja el sistema contra comportamiento tipo Ransomware:
- Monitoreo en background de abusos en I/O de disco
- Medición de Entropía de Shannon para detectar cifrados en caliente
- Reconocimiento de extensiones mágicas (`.wncry`, etc.)
- Control exhaustivo de memoria (Bonus RAM < 100MB)

**Aprendizaje Clave**:
- Creación de demonios (`daemons`)
- Interceptación y gestión de señales UNIX
- Análisis Heurístico estadístico
- Control de recursos del sistema

[📖 Documentación Completa](./06_Iron_Dome_Malware_Optional/README.md)

---

### 💉 [08 - Vaccine (Escáner SQLi)](./08_Vaccine_Web/)

**Tipo**: Seguridad Web Ofensiva (Pentesting)  
**Dificultad**: ⭐⭐⭐⭐  
**Habilidades**: Python, HTTP, SQL Injection, Data Dump

Desarrollar una herramienta de auditoría automatizada que detecte y explote inyecciones SQL:
- Múltiples técnicas (Error-Based, Boolean, Union, Time-Based)
- Extracción de información (`schemas`, `tables`, `columns`)
- Evasión mediante alteración de User-Agent
- Generación de informes históricos

**Aprendizaje Clave**:
- Vectores de ataque SQLi
- Motores de bases de datos variados (SQLite, MySQL, Postgres, Oracle)
- Automatización de scraping de formularios
- Explotación y mitigación en aplicaciones reales

[📖 Documentación Completa](./08_Vaccine_Web/README.md)

---

## 🛠️ Habilidades Desarrolladas

### Habilidades Técnicas

| Categoría de Habilidad | Tecnologías |
|------------------------|-------------|
| **Programación** | Python, C/C++, Shell scripting |
| **Web** | HTTP, HTML, Nginx, Web scraping |
| **Red** | ARP, FTP, TCP/IP, libpcap, Wireshark |
| **Criptografía** | HMAC, TOTP, Cifrado |
| **Seguridad** | Metasploit, Tor, Fortificación SSH |
| **DevOps** | Docker, Docker Compose, Makefiles |

### Conceptos de Seguridad

- ✅ Vulnerabilidades OWASP
- ✅ Ataques Man-in-the-Middle
- ✅ Conciencia de ingeniería social
- ✅ Vulnerabilidades de protocolo de red
- ✅ Autenticación criptográfica
- ✅ Privacidad y anonimato
- ✅ Filtración de metadatos
- ✅ Principios de hacking ético

---

## 📋 Requisitos Previos

### Requisitos Generales
```bash
# Entorno Linux/Unix
# Python 3.8+
# Docker & Docker Compose
# Acceso root/sudo (para algunos proyectos)
```

### Requisitos por Proyecto

#### Arachnida
```bash
pip install requests beautifulsoup4 pillow
```

#### ft_onion
```bash
apt-get install nginx tor openssh-server
```

#### ft_otp
```bash
pip install pyotp
# O implementar desde cero
```

#### Inquisitor
```bash
apt-get install libpcap-dev
pip install scapy
```

---

## 📖 Directrices Generales

### Principios de Desarrollo

1. **Seguridad Primero**: Nunca comprometer la seguridad por conveniencia
2. **Hacking Ético**: Siempre obtener permiso antes de realizar pruebas
3. **Documentación**: Documentar tu enfoque y hallazgos
4. **Calidad del Código**: Escribir código limpio y mantenible
5. **Gestión de Errores**: Nunca crashear inesperadamente

### Pruebas

Cada proyecto debe incluir:
- ✅ Suite de pruebas demostrando funcionalidad
- ✅ Validación contra implementaciones de referencia
- ✅ Manejo de casos extremos
- ✅ Cobertura de escenarios de error

### Entregables

Entregables estándar para todos los proyectos:
- Código fuente (bien comentado)
- Makefile (cuando sea aplicable)
- README con instrucciones de uso
- Scripts de prueba
- Archivos de configuración

---

## 🔒 Consideraciones Legales y Éticas

### ⚠️ **ADVERTENCIAS IMPORTANTES**

**Estos proyectos incluyen herramientas potencialmente peligrosas:**
- El envenenamiento ARP es un ataque de red
- El web scraping puede violar términos de servicio
- Los servicios ocultos requieren uso responsable

**Siempre:**
1. ✅ Obtener permiso explícito por escrito
2. ✅ Probar solo en redes que posees/operas
3. ✅ Seguir leyes y regulaciones locales
4. ✅ Usar solo para propósitos educativos
5. ✅ Nunca desplegar en sistemas de producción sin autorización

**El uso no autorizado puede resultar en:**
- ❌ Persecución criminal
- ❌ Responsabilidad civil
- ❌ Expulsión académica
- ❌ Prohibiciones de red

---

## 📚 Recursos Adicionales

### Materiales de Aprendizaje
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Documentación del Proyecto Tor](https://www.torproject.org/docs/)
- [RFC 6238 (TOTP)](https://datatracker.ietf.org/doc/html/rfc6238)
- [Documentación de Scapy](https://scapy.readthedocs.io/)

### Herramientas
- **Wireshark**: Analizador de protocolo de red
- **Burp Suite**: Pruebas de seguridad web
- **Metasploit**: Framework de pruebas de penetración
- **nmap**: Descubrimiento de redes y auditoría de seguridad

### Libros
- "The Web Application Hacker's Handbook"
- "Metasploit: The Penetration Tester's Guide"
- "Network Security Assessment"
- "Applied Cryptography" de Bruce Schneier

---

## 🎓 Resultados de Aprendizaje

Después de completar la Piscina de Ciberseguridad, serás capaz de:

### Comprender
- Vulnerabilidades y exploits web comunes
- Debilidades de protocolo de red
- Sistemas de autenticación criptográfica
- Tecnologías de anonimato y privacidad

### Ser Capaz De
- Realizar evaluaciones de seguridad
- Implementar autenticación segura
- Analizar tráfico de red
- Desplegar servicios web seguros
- Escribir código orientado a la seguridad

### Apreciar
- La importancia del hacking ético
- Implicaciones de privacidad y seguridad
- Estrategias de defensa en profundidad
- Prácticas de divulgación responsable

---

## 📂 Estructura del Proyecto

```
piscine_pedago_ciber/
├── README.md                      # Este archivo
├── .gitignore
│
├── 01_arachnida_Web/
│   ├── README.md
│   ├── .gitignore
│   ├── en.subject.pdf
│   ├── spider*
│   └── scorpion*
│
├── 02_ft_onion_Web/
│   ├── README.md
│   ├── .gitignore
│   ├── en.subject.pdf
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── nginx.conf
│   ├── torrc
│   └── index.html
│
├── 03_ft_otp_OTP/
│   ├── README.md
│   ├── .gitignore
│   ├── en.subject.pdf
│   ├── ft_otp*
│   └── ft_otp.key
│
└── 04_Inquisitor_Network/
    ├── README.md
    ├── .gitignore
    ├── en.subject.pdf
    ├── inquisitor*
    ├── Dockerfile
    └── docker-compose.yml
```

---

## 🏆 Criterios de Completitud

Cada proyecto se considera completo cuando:
- ✅ Todos los requisitos obligatorios implementados
- ✅ El código compila/ejecuta sin errores
- ✅ La suite de pruebas pasa todas las pruebas
- ✅ La documentación está completa
- ✅ El código sigue las mejores prácticas
- ✅ Las funcionalidades bonus (si se intentan) funcionan correctamente

---

## 🤝 Contribuir

Estos proyectos son educativos. Si tienes mejoras o encuentras problemas:
1. Documenta el problema/mejora
2. Prueba exhaustivamente
3. Sigue el estilo de código existente
4. Actualiza la documentación

---

## 📝 Notas

- Los **archivos PDF** están excluidos de git (`.gitignore`)
- Los **datos sensibles** nunca deben ser commiteados
- Los **entornos de prueba** deben estar aislados
- **Permisos root** requeridos para algunos proyectos

---

**Recuerda**: Estas habilidades son poderosas. Úsalas de forma responsable y ética.

Un gran poder conlleva una gran responsabilidad. 🦸‍♂️
