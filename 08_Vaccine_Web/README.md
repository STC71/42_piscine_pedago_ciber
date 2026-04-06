# Vaccine - Herramienta de Detección SQLi

**Vaccine** es una herramienta desarrollada en Python para auditar la seguridad de aplicaciones web mediante la detección de vulnerabilidades de **SQL Injection (SQLi)**. El proyecto cumple con todos los requisitos del *mandatory* y *bonus* del bootcamp de Ciberseguridad de 42.

## 🚀 Funcionalidades

### Mandatory Part
- **Métodos HTTP**: Detección de inyecciones a través de peticiones `GET` y `POST`.
- **Múltiples métodos SQLi**: Se apoya en pruebas `Error-Based` y `Boolean-Based`.
- **Extracción de Datos**: Identifica las vulnerabilidades y extrae metadatos y dumps si la base de datos es vulnerable.
- **Reporting**: Exporta automáticamente los hallazgos en un archivo de registro usando la directiva `-o`.
- **Detección Dual (Motores BD)**: Verifica sintaxis y firmas de `SQLite` y `MySQL`.

### Bonus Part
- **Motores DB adicionales**: Capacidad para realizar fingerprinting o detectar fallos provenientes de `PostgreSQL`, `Oracle` o `Microsoft SQL Server`.
- **Más Técnicas de Inyección**: Detección de inyecciones a través de consultas con `UNION`.
- **Manipulación de Petición**: Flag extra `--user-agent` añadido para evadir detecciones WAF básicas y modificar las cabeceras HTTP.

## 🛠️ Instalación y Uso

El proyecto viene preparado con un `Makefile` y dependencias propias gestionadas en un Entorno Virtual de Python, para no dañar tu máquina local.

```bash
# 1. Configurar Entorno y Dependencias
make setup

# 2. Iniciar el Servidor Vulnerable Local (Para Pruebas)
# (Abre una terminal paralela)
make run-server

# 3. Ejecutar Vaccine contra el servidor
./vaccine http://127.0.0.1:5000/ -X GET

# 4. Ejecutar el Tutorial Guiado (Evaluadores 125%)
# (Valida paso a paso Mandatory y Bonus con referencias dinámicas al código)
make tutorial
```

## ⚙️ Opciones de la Herramienta

Sintaxis principal del CLI:
`./vaccine [-o ARCHIVO_LOG] [-X METODO] [--user-agent AGENTE_PERSONALIZADO] <URL>`

* `-o`, `--output` : Archivo donde volcar el log de vulnerabilidades en modo *Append* para guardar el histórico acumulativo (Por defecto: `vaccine_results.txt`).
* `-X`, `--method` : Método HTTP forzado a utilizar (`GET` o `POST`).
* `--user-agent`   : Cabecera User-Agent a inyectar en lugar de la predeterminada de Vaccine (Bonus).

## ⚠️ Aviso Legal
Esta herramienta ha sido creada **exclusivamente con fines educacionales** en el marco de la escuela 42. No debes utilizar este software sobre una página o infraestructura externa sobre la cual no tangas permiso ni autorización formal certificada. 
El repositorio incluye un servidor vulnerable (Dummy Server Local) para las validaciones y correcciones del proyecto bajo un entorno completamente seguro.