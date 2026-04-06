# Spider - Extractor Recursivo de Imágenes Web

## Descripción General

Spider es un extractor recursivo de imágenes web que extrae imágenes de sitios web y las guarda localmente. Respeta los límites de dominio e implementa un control inteligente de profundidad de recursión.

## Características

✨ **Características Principales:**
- 🔗 Rastreo recursivo de sitios web con control de profundidad
- 📥 Descarga automática de imágenes desde fuentes válidas
- 🎨 Soporte para múltiples formatos: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`
- 🛡️ Filtrado inteligente de dominios (solo mismo dominio)
- 🔄 Prevención de duplicados (evita descargar la misma imagen de nuevo)
- ⚙️ Directorio de salida configurable
- 📊 Progreso de descarga en tiempo real y estadísticas

## Instalación

```bash
make 00
```

O manualmente:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Uso

### Uso Básico (Sin Recursión)
```bash
./spider.py https://example.com
```
**Qué hace:** Descarga todas las imágenes de la página principal **solamente** (profundidad 0).  
**Dónde guarda:** En `./data/` (carpeta por defecto).

### Rastreo Recursivo con Profundidad Estándar
```bash
./spider.py -r https://example.com
```
**Qué hace:**  
- `-r` = **Recursivo**: Sigue los enlaces encontrados en las páginas  
- Profundidad default = **5 niveles** (si -l no se especifica)

**Ejemplo de profundidad:**
- Nivel 0: Homepage
- Nivel 1: Páginas enlazadas desde homepage
- Nivel 2: Páginas enlazadas desde nivel 1
- Etc...

### Rastreo Recursivo con Profundidad Personalizada
```bash
./spider.py -r -l 2 https://example.com
```
**Qué hace:**
- `-r` = **Recursivo**: Sigue enlaces  
- `-l 2` = **Level/Profundidad = 2**: Límite máximo de 2 niveles de profundidad  

**Útil para:** Evitar descargar miles de imágenes (sitios grandes). Con `-l 2` solo explora 2 niveles.

### Guardar en Directorio Personalizado
```bash
./spider.py -r -p ./mis_imagenes https://example.com
```
**Qué hace:**
- `-p ./mis_imagenes` = **Path/Ruta = ./mis_imagenes**: Carpeta donde guardar imágenes  

**Sin -p:** Usa `./data/` (por defecto)  
**Con -p:** Usa la carpeta que especifiques

### Combinar Todas las Opciones
```bash
./spider.py -r -l 2 -p ./imagenes_descargadas https://example.com
```
**Qué hace:**
1. `-r` = Rastring recursivo habilitado
2. `-l 2` = Máximo 2 niveles de profundidad
3. `-p ./imagenes_descargadas` = Guarda en carpeta `./imagenes_descargadas`
4. `https://example.com` = Comienza en esta URL

## Sintaxis Completa

```
./spider.py [-h] [-r] [-l NIVEL] [-p RUTA] url

Argumentos Posicionales:
  url                     URL del sitio web por donde comenzar

Argumentos Opcionales:
  -h, --help              Muestra el mensaje de ayuda y sale
  -r, --recursive         Habilita el rastreo recursivo de enlaces
  -l NIVEL, --level NIVEL Profundidad máxima de recursión (por defecto: 5)
  -p RUTA, --path RUTA    Directorio de salida para imágenes (por defecto: ./data/)
```

## Ejemplos de Uso

```bash
# Ejemplo 1: Solo la página principal
./spider.py https://example.com
# Resultado: Imágenes en ./data/

# Ejemplo 2: Explorá hasta 2 niveles, guarda en mi_carpeta
./spider.py -r -l 2 -p ./mi_carpeta https://example.com
# Resultado: Imágenes en ./mi_carpeta

# Ejemplo 3: Rastreo profundo (5 niveles) con ruta personalizada
./spider.py -r -p /tmp/imagenes https://example.com
# Resultado: Imágenes en /tmp/imagenes (profundidad = 5, default)
```

## Detalles de Implementación

### Arquitectura
- **Clase Spider**: Extractor principal con capacidades recursivas
- **Validación de URL**: Valida URLs HTTP(S) antes de procesar
- **Filtrado de Dominio**: Se mantiene dentro del mismo dominio para evitar expansión de alcance
- **Detección de Imágenes**: Identifica tipos de imagen válidos a partir de extensiones de archivo
- **Rastreo Recursivo**: Utiliza el enfoque primero en amplitud con seguimiento de profundidad
- **Manejo de Errores**: Manejo elegante de errores de red y URLs inválidas

### Métodos Clave
- `scrape()`: Motor de recursión principal
- `_download_image()`: Maneja descargas de imágenes individuales
- `_get_page_content()`: Obtiene y analiza HTML
- `_extract_image_urls()`: Encuentra etiquetas de imagen en HTML
- `_extract_page_urls()`: Encuentra enlaces para rastreo recursivo

## Formatos de Imagen Soportados

- `.jpg` / `.jpeg`
- `.png`
- `.gif`
- `.bmp`

## Output

All downloaded images are saved to the specified output directory (default: `./data/`).

### Filename Handling
- Original filenames are preserved when possible
- If filename is invalid, a unique hash-based name is generated
- Duplicate filenames are numbered automatically (e.g., `image_1.png`, `image_2.png`)

## Requirements

- Python 3.6+
- requests (HTTP library)
- beautifulsoup4 (HTML parsing)

See `requirements.txt` for specific versions.

## Performance Considerations

- **Timeout**: 10 seconds per request (configurable in code)
- **Depth Limit**: Default is 5 levels (configurable via `-l` option)
- **Domain Boundary**: Respects domain boundaries to avoid external sites

## Error Handling

Spider handles various error conditions:
- Invalid URLs
- Network timeouts
- HTTP errors (404, 500, etc.)
- SSL/TLS certificate issues
- File system errors
- Invalid HTML

All errors are logged to stderr while maintaining operation.

## Known Limitations

- Does not follow JavaScript-generated content
- Cannot handle login-required pages
- Does not support cookies/sessions
- Image discovery limited to `<img>` tags

## Contributing

This is an educational project for the 42 Piscine Cybersecurity curriculum.

## License

Created for educational purposes only.
