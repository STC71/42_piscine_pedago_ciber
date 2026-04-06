#!/usr/bin/env python3

"""
Escorpión (Scorpion) - Analizador de metadatos e información EXIF para el proyecto Arachnida
Este módulo extrae y muestra información detallada de metadatos de archivos de imagen,
incluyendo datos EXIF como fecha de captura, cámara utilizada, configuración de fotografía, etc.
"""

import sys
import os
from pathlib import Path
from datetime import datetime
import piexif
from PIL import Image
from PIL.ExifTags import TAGS


class MetadataAnalyzer:
    """
    Analizador de metadatos que extrae y muestra información EXIF de imágenes.
    
    Esta clase realiza las siguientes funciones:
    - Valida que el archivo sea una imagen soportada
    - Lee información de archivo (tamaño, fechas de creación, etc.)
    - Extrae datos EXIF usando la biblioteca piexif
    - Obtiene dimensiones de la imagen
    - Formatea la información para presentación legible
    """
    
    # Conjunto de extensiones de archivo soportadas
    # Solo se analizan archivos que terminen con estas extensiones
    VALID_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp'}
    
    # Categorías de etiquetas EXIF para organizar la presentación
    # Agrupa etiquetas relacionadas por tema
    EXIF_CATEGORIES = {
        'Image': [0x0100, 0x0101, 0x0102, 0x0103, 0x0106, 0x011a, 0x011b, 0x011c],
        'Camera': [0x010f, 0x0110, 0x0112, 0x0131, 0x0132],
        'Photo': [0x8827, 0x8828, 0x8830, 0x9000, 0x9003, 0x9004, 0xa000, 0xa001, 
                  0xa002, 0xa003, 0xa20e, 0xa20f, 0xa210],
        'Lens': [0x010f, 0x0110, 0xa405, 0xa406, 0xa407, 0xa408, 0xa409, 0xa40a],
        'Location': [0x0001, 0x0002, 0x0003, 0x0004],
    }
    
    # Diccionario que mapea códigos EXIF hexadecimales a nombres legibles
    # Facilita la interpretación de las etiquetas EXIF
    EXIF_TAG_NAMES = {
        0x0100: 'Ancho de Imagen',
        0x0101: 'Alto de Imagen',
        0x0102: 'Bits por Muestra',
        0x0103: 'Compresión',
        0x0106: 'Interpretación Fotométrica',
        0x010f: 'Marca de Cámara',
        0x0110: 'Modelo de Cámara',
        0x0112: 'Orientación',
        0x011a: 'Resolución X',
        0x011b: 'Resolución Y',
        0x011c: 'Unidad de Resolución',
        0x0131: 'Software',
        0x0132: 'Fecha y Hora',
        0x8827: 'Velocidad ISO',
        0x8828: 'OECF',
        0x8830: 'Tipo de Sensibilidad',
        0x9000: 'Versión EXIF',
        0x9003: 'Fecha y Hora Original',
        0x9004: 'Fecha y Hora Digitalizada',
        0xa000: 'Espacio de Color',
        0xa001: 'Índice Interop',
        0xa002: 'Dimensión X en Píxeles',
        0xa003: 'Dimensión Y en Píxeles',
        0xa20e: 'Resolución Plano Focal X',
        0xa20f: 'Resolución Plano Focal Y',
        0xa210: 'Unidad Resolución Plano Focal',
        0xa405: 'Longitud Focal en 35mm',
        0xa406: 'Tipo de Captura de Escena',
        0xa407: 'Control de Ganancia',
        0xa408: 'Contraste',
        0xa409: 'Saturación',
        0xa40a: 'Nitidez',
    }
    
    def __init__(self, filepath):
        """
        Inicializa el analizador con un archivo de imagen.
        
        Este método realiza:
        1. Valida que el archivo existe en el sistema de archivos
        2. Verifica que la extensión sea soportada
        3. Almacena la ruta y nombre del archivo para uso posterior
        
        Args:
            filepath (str): Ruta al archivo de imagen a analizar
            
        Lanza:
            ValueError: Si el archivo no existe o tiene una extensión no soportada
        """
        self.filepath = Path(filepath)
        self.filename = self.filepath.name
        
        # Validar que el archivo existe
        if not self.filepath.exists():
            raise ValueError(f"Archivo no encontrado: {filepath}")
        
        # Validar que la extensión es soportada
        if self.filepath.suffix.lower() not in self.VALID_EXTENSIONS:
            raise ValueError(f"Tipo de archivo no soportado: {self.filepath.suffix}")
    
    def _get_image_dimensions(self):
        """
        Obtiene las dimensiones de la imagen (ancho x alto).
        
        Utiliza PIL (Python Imaging Library) para abrir la imagen
        y extraer sus dimensiones en píxeles.
        
        Retorna:
            tuple: (ancho, alto) en píxeles, o (None, None) si no se puede determinar
        """
        try:
            with Image.open(self.filepath) as img:
                return img.size
        except Exception:
            return None, None
    
    def _get_file_info(self):
        """
        Obtiene información básica del archivo de imagen.
        
        Extrae información del sistema de archivos como:
        - Tamaño del archivo en bytes
        - Fecha de creación
        - Fecha de última modificación
        - Fecha de último acceso
        
        Retorna:
            dict: Diccionario con información del archivo
        """
        try:
            # Obtener estadísticas del archivo del sistema operativo
            stat = self.filepath.stat()
            return {
                'size': stat.st_size,
                'created': datetime.fromtimestamp(stat.st_ctime),
                'modified': datetime.fromtimestamp(stat.st_mtime),
                'accessed': datetime.fromtimestamp(stat.st_atime),
            }
        except Exception as e:
            return {'error': str(e)}
    
    def _parse_exif_data(self):
        """
        Parsea los datos EXIF del archivo de imagen.
        
        Los datos EXIF están organizados en secciones IFD (Image File Directory):
        - '0th': Información básica de la imagen
        - 'Exif': Datos específicos de fotografía (ISO, apertura, etc.)
        - 'GPS': Información de ubicación geográfica (si disponible)
        - '1st': Información de miniatura (si hay)
        
        Este método:
        1. Carga los datos EXIF con piexif
        2. Itera sobre todas las secciones IFD
        3. Convierte códigos de etiqueta a nombres legibles
        4. Formatea los valores para presentación
        
        Retorna:
            dict: Diccionario con datos EXIF procesados
        """
        exif_data = {}
        
        try:
            # Cargar todos los datos EXIF del archivo
            exif_dict = piexif.load(str(self.filepath))
            
            # Procesar cada sección IFD (Image File Directory)
            for ifd_name in ('0th', 'Exif', 'GPS', '1st'):
                ifd = exif_dict.get(ifd_name, {})
                
                # Iterar sobre cada etiqueta en la sección IFD
                for tag_id, value in ifd.items():
                    # Obtener nombre legible de la etiqueta
                    tag_name = TAGS.get(tag_id, TAGS.get(tag_id, {}).get('name', f'Unknown_0x{tag_id:04x}'))
                    
                    # Procesar el valor según su tipo
                    if tag_id in [0x9003, 0x9004, 0x0132]:  # Campos de fecha y hora
                        try:
                            # Convertir bytes a string si es necesario
                            value = value.decode('utf-8') if isinstance(value, bytes) else str(value)
                        except Exception:
                            value = str(value)
                    elif isinstance(value, bytes):
                        # Convertir bytes a string de forma segura
                        try:
                            value = value.decode('utf-8', errors='ignore')
                        except Exception:
                            # Limitar longitud si hay error en decodificación
                            value = str(value)[:50]
                    else:
                        # Convertir a string cualquier otro tipo de valor
                        value = str(value)
                    
                    exif_data[tag_name] = value
        
        except Exception as e:
            exif_data['Error'] = str(e)
        
        return exif_data
    
    def _get_pil_exif_data(self):
        """
        Obtiene datos EXIF usando PIL como alternativa/respaldo.
        
        La biblioteca PIL proporciona una interfaz alternativa para
        acceder a datos EXIF. Este método se utiliza como respaldo
        si piexif no puede leer los datos correctamente.
        
        Retorna:
            dict: Diccionario con datos EXIF extraídos por PIL
        """
        exif_data = {}
        
        try:
            with Image.open(self.filepath) as img:
                # Obtener datos EXIF crudos de PIL
                exif_raw = img._getexif()
                
                if exif_raw:
                    # Iterar sobre pares etiqueta-valor
                    for tag_id, value in exif_raw.items():
                        # Obtener nombre legible de la etiqueta
                        tag_name = TAGS.get(tag_id, f'Unknown_0x{tag_id:04x}')
                        
                        # Convertir bytes a string de forma segura
                        if isinstance(value, bytes):
                            try:
                                value = value.decode('utf-8')
                            except Exception:
                                value = str(value)[:50]
                        
                        exif_data[tag_name] = value
        
        except AttributeError:
            # No hay datos EXIF disponibles
            pass
        except Exception as e:
            exif_data['Error'] = str(e)
        
        return exif_data
    
    def analyze(self):
        """
        Analiza la imagen y retorna todos sus metadatos.
        
        Este método coordina:
        1. Extracción de dimensiones de la imagen
        2. Lectura de información del archivo del sistema
        3. Parseo de datos EXIF
        4. Respaldo a PIL si es necesario
        
        Retorna:
            dict: Diccionario completo con toda la información de metadatos
        """
        # Obtener dimensiones de la imagen
        width, height = self._get_image_dimensions()
        # Obtener información del archivo del sistema
        file_info = self._get_file_info()
        # Extraer datos EXIF
        exif_data = self._parse_exif_data()
        
        # Si piexif no funcionó, intentar con PIL
        if not exif_data or 'Error' in exif_data:
            exif_data_pil = self._get_pil_exif_data()
            if exif_data_pil:
                exif_data = exif_data_pil
        
        return {
            'filepath': str(self.filepath),
            'filename': self.filename,
            'filetype': self.filepath.suffix.upper(),
            'dimensions': {
                'width': width,
                'height': height,
            },
            'file_info': file_info,
            'exif': exif_data,
        }
    
    def format_output(self, metadata):
        """
        Formatea los metadatos para presentación legible por humanos.
        
        Organiza la información de la siguiente manera:
        1. Encabezado con información del archivo
        2. Información técnica del archivo (tamaño, fechas)
        3. Dimensiones de la imagen
        4. Datos EXIF importantes primero
        5. Datos EXIF adicionales de forma ordenada
        
        Args:
            metadata (dict): Metadatos analizados
            
        Retorna:
            str: String formato para imprimir en consola
        """
        lines = []
        
        # Encabezado
        lines.append("")
        lines.append("=" * 70)
        lines.append(f"📸 ANÁLISIS DE METADATOS DE IMAGEN")
        lines.append("=" * 70)
        lines.append("")
        
        # Información del archivo
        lines.append(f"📄 Archivo: {metadata['filename']}")
        lines.append(f"   Tipo: {metadata['filetype']}")
        lines.append(f"   Ruta: {metadata['filepath']}")
        
        # Estadísticas del archivo
        if 'error' not in metadata['file_info']:
            file_info = metadata['file_info']
            size_kb = file_info['size'] / 1024
            lines.append(f"   Tamaño: {size_kb:.2f} KB ({file_info['size']} bytes)")
            lines.append(f"   Creado: {file_info['created']}")
            lines.append(f"   Modificado: {file_info['modified']}")
        
        lines.append("")
        
        # Dimensiones de la imagen
        if metadata['dimensions']['width'] and metadata['dimensions']['height']:
            lines.append(f"🖼️  Dimensiones: {metadata['dimensions']['width']}x{metadata['dimensions']['height']} píxeles")
            lines.append("")
        
        # Datos EXIF
        if metadata['exif']:
            lines.append("-" * 70)
            lines.append("📋 METADATOS E INFORMACIÓN EXIF")
            lines.append("-" * 70)
            lines.append("")
            
            # Extraer campos importantes para mostrar primero
            important_fields = ['DateTimeOriginal', 'DateTime', 'Camera Make', 
                              'Camera Model', 'ISO Speed', 'Focal Length']
            
            shown_fields = set()
            
            # Mostrar campos importantes primero
            for field in important_fields:
                if field in metadata['exif']:
                    value = metadata['exif'][field]
                    lines.append(f"   {field}: {value}")
                    shown_fields.add(field)
            
            # Mostrar campos restantes
            if len(shown_fields) > 0:
                lines.append("")
            
            other_fields = sorted([k for k in metadata['exif'].keys() if k not in shown_fields])
            
            if other_fields:
                lines.append("   Datos EXIF Adicionales:")
                lines.append("   ├─ Estos campos contienen información técnica complementaria")
                lines.append("   └─ Pueden incluir: offset de datos, resoluciones internas, software, etc.")
                lines.append("")
                for field in other_fields:
                    value = metadata['exif'][field]
                    # Truncar valores muy largos
                    if len(str(value)) > 60:
                        value = str(value)[:57] + "..."
                    lines.append(f"      • {field}: {value}")
            else:
                lines.append("   (No se encontraron datos EXIF adicionales)")
        else:
            lines.append("-" * 70)
            lines.append("📋 METADATOS E INFORMACIÓN EXIF")
            lines.append("-" * 70)
            lines.append("   (No se encontraron datos EXIF en esta imagen)")
        
        lines.append("")
        lines.append("=" * 70)
        lines.append("")
        
        return "\n".join(lines)
    
    def display(self):
        """
        Analiza y muestra los metadatos de la imagen en la consola.
        
        Este método:
        1. Llama a analyze() para obtener los metadatos
        2. Formatea la salida con format_output()
        3. Imprime el resultado formateado
        4. Retorna True si fue exitoso, False si hubo error
        
        Retorna:
            bool: True si el análisis fue exitoso, False si hubo error
        """
        try:
            metadata = self.analyze()
            output = self.format_output(metadata)
            print(output)
            return True
        except Exception as e:
            print(f"Error analizando {self.filename}: {e}", file=sys.stderr)
            return False


def parse_arguments():
    """
    Parsea los argumentos de línea de comandos.
    
    Espera que se pasen uno o más nombres de archivo como argumentos.
    Si no se proporcionan archivos, muestra un mensaje de uso y sale.
    
    Retorna:
        list: Lista de rutas de archivo pasadas como argumentos
    """
    if len(sys.argv) < 2:
        print(f"Uso: {sys.argv[0]} ARCHIVO1 [ARCHIVO2 ...]", file=sys.stderr)
        print(f"\nAnalizar metadatos e información EXIF de archivos de imagen.", file=sys.stderr)
        print(f"\nEjemplo:", file=sys.stderr)
        print(f"  {sys.argv[0]} imagen.jpg", file=sys.stderr)
        print(f"  {sys.argv[0]} foto1.jpg foto2.png foto3.gif", file=sys.stderr)
        sys.exit(1)
    
    return sys.argv[1:]


def main():
    """
    Punto de entrada principal del programa.
    
    Este función:
    1. Obtiene la lista de archivos de los argumentos
    2. Crea una instancia de MetadataAnalyzer para cada archivo
    3. Llama a display() para mostrar los metadatos
    4. Mantiene conteo de análisis exitosos y fallidos
    5. Muestra un resumen al final
    6. Retorna código de salida apropiado
    """
    # Obtener lista de archivos de los argumentos
    filepaths = parse_arguments()
    
    if not filepaths:
        print("Error: No se especificaron archivos", file=sys.stderr)
        sys.exit(1)
    
    # Mostrar encabezado
    print("\n" + "=" * 70)
    print("🦂  ESCORPIÓN - Analizador de Metadatos de Imagen")
    print("=" * 70)
    
    # Contadores de éxito y error
    successful = 0
    failed = 0
    
    # Procesar cada archivo
    for filepath in filepaths:
        try:
            analyzer = MetadataAnalyzer(filepath)
            if analyzer.display():
                successful += 1
            else:
                failed += 1
        except ValueError as e:
            print(f"\n❌ Error: {e}", file=sys.stderr)
            failed += 1
        except Exception as e:
            print(f"\n❌ Error inesperado analizando {filepath}: {e}", file=sys.stderr)
            failed += 1
    
    # Mostrar resumen si se analizaron múltiples archivos
    if len(filepaths) > 1:
        print("-" * 70)
        print(f"Resumen: {successful} archivo(s) analizados, {failed} error(es)")
        print("-" * 70)
        
        # Salir con código de error si hubo fallos
        if failed > 0:
            sys.exit(1)
    
    sys.exit(0)


if __name__ == '__main__':
    main()
