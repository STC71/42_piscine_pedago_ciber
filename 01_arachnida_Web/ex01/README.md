# Scorpion - Analizador de Metadatos y EXIF de Imágenes

## Descripción General

Scorpion es un analizador integral de metadatos de imágenes que extrae y muestra datos EXIF y otros metadatos de archivos de imagen. Proporciona información detallada sobre imágenes, incluyendo dimensiones, fechas de creación, configuración de cámara y mucho más.

## Características

✨ **Características Principales:**
- 🔍 Extracción y visualización completa de datos EXIF
- 📸 Análisis de dimensiones de imagen
- 📅 Información de marcas de tiempo y fecha de creación
- 📷 Modelo de cámara y configuración (cuando está disponible)
- 🎯 Soporte para múltiples formatos: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`
- 🛡️ Manejo robusto de errores
- 📊 Visualización de metadatos organizada y legible
- 🔄 Procesamiento por lotes de múltiples archivos

## Instalación

```bash
make 01
```

O manualmente:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Uso

### Analizar una Imagen Individual
```bash
./scorpion.py imagen.jpg
```
**Qué hace:** Extrae y muestra todos los metadatos (EXIF, dimensiones, fechas) de `imagen.jpg`.

### Analizar Múltiples Imágenes
```bash
./scorpion.py foto1.jpg foto2.png foto3.gif
```
**Qué hace:** Analiza y muestra metadatos de **todos los archivos especificados en secuencia**.

**Útil para:**
- Procesar lotes de fotos de una cámara
- Auditar metadatos de múltiples documentos
- Verificar información EXIF de galerías

### Analizar Usando Rutas Completas
```bash
./scorpion.py /ruta/a/imagen1.jpg /ruta/a/imagen2.png
./scorpion.py /tmp/datos/*.jpg
```
**Qué hace:** Funciona con rutas absolutas y globbing de shell (wildcards con `*`).

### Analizar Imágenes en Directorio
```bash
./scorpion.py ./imagenes_descargadas/*.jpg
./scorpion.py ./fotos/*.{jpg,png,gif}
```
**Qué hace:** Analiza todas las imágenes que coincidan con el patrón en el directorio.

## Sintaxis Completa

```
./scorpion.py ARCHIVO1 [ARCHIVO2 ...]

Argumentos Posicionales:
  ARCHIVO1, ARCHIVO2, ...   Rutas de archivos de imagen a analizar
                           (soporta rutas relativas, absolutas y patrones globbing)
```

## Ejemplos de Uso

```bash
# Ejemplo 1: Analizar una foto
./scorpion.py vacaciones.jpg
# Resultado: Muestra EXIF, dimensiones, fechas, etc.

# Ejemplo 2: Analizar múltiples fotos de una cámara
./scorpion.py ./fotos/DSC_001.jpg ./fotos/DSC_002.jpg ./fotos/DSC_003.jpg
# Resultado: Analiza los 3 archivos secuencialmente

# Ejemplo 3: Analizar todas las imágenes descargadas por Spider
./scorpion.py ./imagenes_descargadas/*
# Resultado: Extrae metadatos de TODAS las imágenes en esa carpeta

# Ejemplo 4: Analizar usando globbing de shell (todos los JPG)
./scorpion.py /tmp/galeria/*.jpg
# Resultado: Procesa solo archivos JPG en /tmp/galeria/
```

## Formatos Soportados

- `.jpg` / `.jpeg`
- `.png`
- `.gif`
- `.bmp`

## Formato de Salida

El analizador proporciona una salida estructurada organizada como sigue:

### 1. Información del Archivo
- Nombre de archivo y extensión
- Ruta completa del archivo
- Tamaño del archivo (en KB y bytes)
- Marcas de tiempo (creado, modificado, accedido)

### 2. Dimensiones de Imagen
- Ancho y alto en píxeles
- Información de resolución

### 3. Datos EXIF
- Campos críticos mostrados primero (DateTime, Modelo de Cámara, ISO, etc.)
- Metadatos EXIF adicionales organizados alfabéticamente
- Manejo seguro de codificación y tipos de datos

## Ejemplo de Salida

```
======================================================================
📸 ANÁLISIS DE METADATOS DE IMAGEN
======================================================================

📄 Archivo: foto_vacaciones.jpg
   Tipo: .JPG
   Ruta: /home/usuario/imagenes/foto_vacaciones.jpg
   Tamaño: 2543.45 KB (2605633 bytes)
   Creado: 2023-06-15 14:32:18.123456
   Modificado: 2023-06-15 14:32:18.123456

🖼️  Dimensiones: 4000x3000 píxeles

----------------------------------------------------------------------
📋 METADATOS Y DATOS EXIF
----------------------------------------------------------------------

   FechaHoraOriginal: 2023:06:15 14:32:18
   Fabricante Cámara: Canon
   Modelo Cámara: Canon EOS 5D Mark IV
   Velocidad ISO: 400

   Datos EXIF Adicionales:

      • Valor de Brillo: 127
      • Espacio de Color: sRGB
      • Contraste: Normal
      • Sesgo de Exposición: 0
      • Tiempo de Exposición: 1/250
      • Número F: 5.6
      • Distancia Focal: 50
      • Distancia Focal en 35mm: 50
      • Control de Ganancia: Ganancia baja hacia arriba
      • Modelo de Objetivo: EF50mm f/1.8

======================================================================
```

## Detalles de Implementación

### Arquitectura
- **Clase MetadataAnalyzer**: Analizador principal de metadatos de imagen
- **Análisis EXIF**: Usa la librería piexif para extracción robusta de EXIF
- **Mecanismo de Respaldo**: Recurre a PIL si piexif falla
- **Manejo de Errores**: Manejo elegante de metadatos corruptos o incompletos
- **Formato de Salida**: Visualización organizada y legible

### Métodos Clave
- `analyze()`: Extraer todos los metadatos de la imagen
- `_parse_exif_data()`: Analizar EXIF usando piexif
- `_get_pil_exif_data()`: Respaldo en PIL para datos EXIF
- `_get_image_dimensions()`: Extraer dimensiones de imagen
- `_get_file_info()`: Recuperar información del sistema de archivos
- `format_output()`: Formatear metadatos para visualización
- `display()`: Analizar y mostrar metadatos

### Fuentes de Metadatos
1. **Librería Piexif**: Fuente principal para datos EXIF
2. **PIL (Pillow)**: Respaldo para EXIF y propiedades de imagen
3. **Sistema de Archivos**: Dimensiones, marcas de tiempo, tamaños de archivo

## Códigos de Salida

- `0`: Éxito (uno o más archivos analizados correctamente)
- `1`: Error (todos los archivos fallaron u ocurrió un error específico)

## Manejo de Errores

Scorpion maneja varias condiciones de error:
- Archivos faltantes
- Tipos de archivo no soportados
- Datos de imagen corrupta
- Datos EXIF faltantes o inválidos
- File system permission issues
- Encoding errors in metadata

All errors are logged to stderr while attempting to process remaining files.

## Performance Considerations

- Fast metadata extraction (typically < 50ms per image)
- Minimal memory usage
- Efficient batch processing
- No external processes or dependencies beyond Python libraries

## Known Limitations

- PNG files typically have minimal EXIF data
- GIF files may have limited metadata
- Some camera-specific EXIF extensions may not be displayed
- Corrupted image headers may prevent metadata extraction

## Requires

- Python 3.6+
- Pillow (PIL) - Image processing
- piexif - EXIF data extraction

See `requirements.txt` for specific versions.

## Future Enhancements

- Metadata editing/removal (Bonus feature)
- GUI for visual metadata management (Bonus feature)
- Additional metadata sources (IPTC, XMP)
- Metadata comparison between multiple files
- Automated metadata cleanup

## Contributing

This is an educational project for the 42 Piscine Cybersecurity curriculum.

## License

Created for educational purposes only.
