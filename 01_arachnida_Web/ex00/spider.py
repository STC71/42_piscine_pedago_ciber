#!/usr/bin/env python3

"""
Araña (Spider) - Descargador de imágenes web para el proyecto Arachnida
Este módulo extrae y descarga imágenes de sitios web de forma recursiva.
Permite explorar múltiples niveles de profundidad en un sitio web y guardar
todas las imágenes encontradas en una carpeta local especificada.
"""

import sys
import os
import argparse
import requests
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
from pathlib import Path

# Suprimir advertencias de SSL para ambiente de desarrollo
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class Spider:
    """
    Raspador web especializado en descargar imágenes de forma recursiva.
    
    Esta clase implementa un algoritmo de rastreo web que:
    - Accede a un sitio web a través de su URL
    - Extrae todas las imágenes de la página actual
    - Sigue recursivamente los enlaces encontrados (si está habilitado)
    - Descarga todas las imágenes encontradas en el proceso
    - Mantiene registro de las URLs visitadas para evitar duplicados
    """
    
    # Conjunto de extensiones de archivo válidas para imágenes
    # Solo se descargarán archivos que terminen con estas extensiones
    VALID_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp'}
    
    # Valores por defecto de configuración
    # PROFUNDIDAD MÁXIMA: cuántos niveles de enlaces seguir recursivamente
    DEFAULT_MAX_DEPTH = 5
    # RUTA DE SALIDA: carpeta donde se guardarán las imágenes descargadas
    DEFAULT_PATH = './data/'
    
    # Encabezados HTTP para simular un navegador real
    # Algunos servidores web pueden rechazar solicitudes sin un User-Agent válido
    # Este encabezado simula una solicitud de navegador Mozilla/Chrome real
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    def __init__(self, url, max_depth=DEFAULT_MAX_DEPTH, output_path=DEFAULT_PATH):
        """
        Inicializa la instancia de la araña web.
        
        Este método realiza las siguientes tareas:
        1. Almacena la URL inicial y los parámetros de configuración
        2. Inicializa los conjuntos para seguimiento de descargas y URLs visitadas
        3. Valida que la URL proporcionada sea válida (HTTP/HTTPS)
        4. Crea la carpeta de salida donde se guardarán las imágenes
        
        Args:
            url (str): URL del sitio web por donde comenzar el rastreo
            max_depth (int): Profundidad máxima de recursión (por defecto: 5)
                            - 0 significa solo la página actual
                            - 1 significa la página actual + enlaces de esa página
                            - n significa explorar hasta n niveles de profundidad
            output_path (str): Ruta de la carpeta donde guardar las imágenes
                             (por defecto: ./data/)
        
        Lanza:
            ValueError: Si la URL proporcionada no es válida (no es HTTP/HTTPS)
        """
        self.url = url
        self.max_depth = max_depth
        self.output_path = Path(output_path)
        
        # Conjunto para almacenar URLs de imágenes ya descargadas
        # Evita descargar la misma imagen múltiples veces
        self.downloaded_images = set()
        
        # Conjunto para almacenar URLs de páginas ya visitadas
        # Previene caer en ciclos infinitos al rastrear enlaces circulares
        self.visited_urls = set()
        
        # Validar y normalizar la URL proporcionada
        if not self._is_valid_url(url):
            raise ValueError(f"URL inválida: {url}")
        
        # Crear la carpeta de salida si no existe
        self._create_output_dir()
    
    def _is_valid_url(self, url):
        """
        Valida que la URL sea una URL válida HTTP(S).
        
        Este método verifica:
        1. Que el esquema (protocolo) sea HTTP o HTTPS
        2. Que la URL tenga un nombre de dominio válido
        3. Que la URL tenga un formato correcto
        
        Args:
            url (str): La URL a validar
            
        Retorna:
            bool: True si la URL es válida, False si no lo es
        """
        try:
            # urlparse divide la URL en componentes: scheme, netloc, path, etc.
            result = urlparse(url)
            # Verificar que el esquema sea HTTP o HTTPS y que haya un dominio
            return all([result.scheme in ['http', 'https'], result.netloc])
        except Exception:
            # Si ocurre cualquier error al parsear, la URL es inválida
            return False
    
    def _create_output_dir(self):
        """
        Crea la carpeta de salida si no existe.
        
        Este método:
        1. Intenta crear la carpeta en la ruta especificada
        2. El parámetro parents=True crea carpetas intermedias si es necesario
        3. El parámetro exist_ok=True no lanza error si ya existe
        4. Si falla, muestra un error y termina el programa
        
        Lanza:
            OSError: Si no tiene permisos para crear la carpeta
        """
        try:
            self.output_path.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            print(f"Error al crear carpeta de salida: {e}", file=sys.stderr)
            sys.exit(1)
    
    def _get_domain(self, url):
        """
        Extrae el dominio de una URL completa.
        
        Por ejemplo:
        - "https://example.com/page" -> "example.com"
        - "https://sub.example.com/path" -> "sub.example.com"
        
        Esto se usa para asegurar que solo se descargan elementos del mismo dominio,
        evitando seguir enlaces a sitios web externos.
        
        Args:
            url (str): URL completa de la cual extraer el dominio
            
        Retorna:
            str: El nombre del dominio extraído
        """
        return urlparse(url).netloc
    
    def _is_same_domain(self, url, base_url):
        """
        Verifica si una URL pertenece al mismo dominio que la URL base.
        
        Esto es importante para:
        1. No seguir enlaces a sitios web externos
        2. Mantener el rastreo dentro del sitio web objetivo
        3. Respetar las limitaciones de un dominio específico
        
        Ejemplo:
        - base_url = "https://example.com/page"
        - url = "https://example.com/otro" -> True (mismo dominio)
        - url = "https://otro.com/page" -> False (diferente dominio)
        
        Args:
            url (str): URL a verificar
            base_url (str): URL base para comparar
            
        Retorna:
            bool: True si pertenecen al mismo dominio, False en caso contrario
        """
        try:
            return self._get_domain(url) == self._get_domain(base_url)
        except Exception:
            return False
    
    def _is_valid_image_url(self, url):
        """
        Verifica si una URL apunta a un archivo de imagen válido.
        
        Comprueba que:
        1. La URL terminé con una extensión de imagen válida (.jpg, .png, etc.)
        2. Solo se consideran válidas las extensiones en VALID_EXTENSIONS
        
        Este método evita intentar descargar:
        - Archivos ejecutables
        - Documentos (PDF, Word, etc.)
        - Scripts (JavaScript, PHP, etc.)
        - Cualquier cosa que no sea imagen
        
        Args:
            url (str): URL a validar
            
        Retorna:
            bool: True si es una imagen válida, False en caso contrario
        """
        try:
            # Convertir a minúsculas la ruta para comparación consistente
            path = urlparse(url.lower()).path
            # Verificar que la ruta termine con una extensión válida
            return any(path.endswith(ext) for ext in self.VALID_EXTENSIONS)
        except Exception:
            return False
    
    def _download_image(self, image_url):
        """
        Descarga una imagen individual desde una URL.
        
        Este método realiza:
        1. Una solicitud HTTP GET a la URL de la imagen
        2. Verifica si la descarga fue exitosa
        3. Genera un nombre de archivo a partir de la URL
        4. Evita sobrescribir archivos existentes añadiendo números
        5. Guarda el contenido binario de la imagen en disco
        6. Registra la descarga en el conjunto de imágenes descargadas
        
        Args:
            image_url (str): URL completa de la imagen a descargar
            
        Retorna:
            bool: True si la descarga fue exitosa, False si falló
        """
        # Verificar si la imagen ya fue descargada antes
        if image_url in self.downloaded_images:
            return False
        
        try:
            # Solicitar la imagen con timeout de 10 segundos
            # verify=False permite trabajar con certificados SSL auto-firmados (desarrollo)
            response = requests.get(image_url, headers=self.HEADERS, timeout=10, verify=False)
            # Lanzar excepción si el código de estado es de error
            response.raise_for_status()
            
            # Extraer el nombre de archivo de la URL
            # Por ejemplo: "https://example.com/images/photo.jpg" -> "photo.jpg"
            filename = os.path.basename(urlparse(image_url).path)
            
            # Si el nombre está vacío o no tiene extensión, generar uno
            if not filename or '.' not in filename:
                filename = self._generate_filename(image_url)
            
            # Crear la ruta completa donde guardar el archivo
            filepath = self.output_path / filename
            
            # Evitar sobrescribir archivos existentes
            # Si el archivo ya existe, añadir un número al nombre
            # Ejemplo: photo.jpg -> photo_1.jpg -> photo_2.jpg
            counter = 1
            base_name, ext = os.path.splitext(filename)
            while filepath.exists():
                filepath = self.output_path / f"{base_name}_{counter}{ext}"
                counter += 1
            
            # Escribir el contenido binario de la imagen en el archivo
            with open(filepath, 'wb') as f:
                f.write(response.content)
            
            # Registrar la imagen como descargada
            self.downloaded_images.add(image_url)
            print(f"[Descargada] {filename}")
            return True
            
        except requests.RequestException as e:
            print(f"[Error] Fallo al descargar {image_url}: {e}", file=sys.stderr)
            return False
        except IOError as e:
            print(f"[Error] Fallo al guardar la imagen: {e}", file=sys.stderr)
            return False
    
    def _generate_filename(self, url):
        """
        Genera un nombre de archivo a partir de una URL cuando no se puede extraer uno válido.
        
        Utiliza:
        1. Un hash MD5 de la URL para crear un nombre único
        2. Solo los primeros 8 caracteres del hash para brevedad
        3. La extensión original de la imagen, o .jpg por defecto
        
        Ejemplo:
        - Input: "https://example.com/image?id=12345"
        - Output: "image_a1b2c3d4.jpg"
        
        Args:
            url (str): URL de la imagen
            
        Retorna:
            str: Nombre de archivo generado (ejemplo: "image_a1b2c3d4.jpg")
        """
        import hashlib
        # Crear un hash MD5 único basado en la URL
        url_hash = hashlib.md5(url.encode()).hexdigest()[:8]
        # Obtener la extensión de la URL o usar .jpg por defecto
        path = urlparse(url).path.lower()
        ext = next((e for e in self.VALID_EXTENSIONS if path.endswith(e)), '.jpg')
        return f"image_{url_hash}{ext}"
    
    def _get_page_content(self, url):
        """
        Obtiene y analiza el contenido HTML de una página web.
        
        Este método:
        1. Realiza una solicitud HTTP GET a la URL
        2. Parsea el HTML usando BeautifulSoup
        3. Retorna un objeto BeautifulSoup para análisis posterior
        4. Maneja errores de red de forma elegante
        
        Args:
            url (str): URL de la página a obtener
            
        Retorna:
            BeautifulSoup object: Objeto con el HTML parseado, o None si falló
        """
        try:
            # Solicitar la página con timeout de 10 segundos
            response = requests.get(url, headers=self.HEADERS, timeout=10, verify=False)
            response.raise_for_status()
            # Parsear el contenido HTML con BeautifulSoup
            # 'html.parser' es el parseador integrado de Python
            return BeautifulSoup(response.content, 'html.parser')
        except requests.RequestException as e:
            print(f"[Advertencia] No se pudo obtener {url}: {e}", file=sys.stderr)
            return None
    
    def _extract_image_urls(self, soup, base_url):
        """
        Extrae todas las URLs de imágenes de una página HTML parseada.
        
        Este método:
        1. Busca todas las etiquetas <img> en el HTML
        2. Extrae el atributo 'src' de cada imagen
        3. Convierte URLs relativas a URLs absolutas
        4. Valida que sean imágenes válidas (extensión correcta)
        
        Ejemplo:
        - HTML contiene: <img src="logo.png">
        - Si base_url = "https://example.com/page/"
        - Resultado: "https://example.com/page/logo.png"
        
        Args:
            soup (BeautifulSoup): HTML parseado de la página
            base_url (str): URL base para resolver enlaces relativos
            
        Retorna:
            list: Lista de URLs absolutas de imágenes válidas
        """
        image_urls = []
        
        if not soup:
            return image_urls
        
        # Iterar sobre todas las etiquetas <img> encontradas
        for img_tag in soup.find_all('img'):
            # Obtener el atributo 'src' de la imagen (puede ser None)
            src = img_tag.get('src')
            if src:
                # Convertir URLs relativas a URLs absolutas
                # urljoin maneja tanto URLs relativas como absolutas correctamente
                absolute_url = urljoin(base_url, src)
                
                # Validar que sea una imagen con extensión válida
                if self._is_valid_image_url(absolute_url):
                    image_urls.append(absolute_url)
        
        return image_urls
    
    def _extract_page_urls(self, soup, base_url):
        """
        Extrae todas las URLs de páginas del HTML parseado para rastreo recursivo.
        
        Este método:
        1. Busca todas las etiquetas <a> (enlaces) en el HTML
        2. Extrae el atributo 'href' de cada enlace
        3. Convierte URLs relativas a URLs absolutas
        4. Remove fragmentos de URL (#sección)
        5. Filtra solo enlaces del mismo dominio
        
        Esto permite que la araña siga enlaces dentro del sitio web
        pero no siga enlaces a sitios web externos.
        
        Args:
            soup (BeautifulSoup): HTML parseado de la página
            base_url (str): URL base para resolver enlaces relativos
            
        Retorna:
            list: Lista de URLs (páginas) del mismo dominio para visitar
        """
        page_urls = []
        
        if not soup:
            return page_urls
        
        # Iterar sobre todas las etiquetas <a> encontradas
        for link in soup.find_all('a'):
            # Obtener el atributo 'href' del enlace
            href = link.get('href')
            if href:
                # Convertir URLs relativas a URLs absolutas
                absolute_url = urljoin(base_url, href)
                
                # Remover fragmentos de URL (todo después de #)
                # Ejemplo: "page.html#sección" -> "page.html"
                absolute_url = absolute_url.split('#')[0]
                
                # Solo seguir enlaces del mismo dominio (evitar salir del sitio)
                if self._is_same_domain(absolute_url, base_url):
                    page_urls.append(absolute_url)
        
        return page_urls
    
    def scrape(self, url=None, depth=0):
        """
        Rastrea recursivamente imágenes desde una URL.
        
        Este es el método principal que:
        1. Obtiene el contenido HTML de la página
        2. Extrae todas las imágenes de la página actual
        3. Las descarga una por una
        4. Si no se alcanzó la profundidad máxima, sigue los enlaces
        5. Llama recursivamente para cada página encontrada
        
        El parámetro 'depth' controla cuántos niveles de profundidad explorar.
        Ejemplo con max_depth=2:
        - depth=0: página inicial
        - depth=1: páginas enlazadas desde la inicial
        - depth=2: páginas enlazadas desde las páginas de depth=1
        - No explora más allá de depth=2
        
        Args:
            url (str): URL a rastrar (por defecto usa self.url)
            depth (int): Profundidad actual de recursión (comienza en 0)
        """
        # Si no se especifica URL, usar la URL inicial
        if url is None:
            url = self.url
        
        # Parar si se alcanzó la profundidad máxima
        if depth > self.max_depth:
            return
        
        # Evitar visitar la misma URL múltiples veces
        if url in self.visited_urls:
            return
        
        # Marcar esta URL como visitada
        self.visited_urls.add(url)
        print(f"[Rastreando] {url} (profundidad: {depth})")
        
        # Obtener y parsear el contenido HTML de la página
        soup = self._get_page_content(url)
        if not soup:
            return
        
        # Extraer y descargar todas las imágenes de esta página
        image_urls = self._extract_image_urls(soup, url)
        for image_url in image_urls:
            self._download_image(image_url)
        
        print(f"[Encontradas] {len(image_urls)} imágenes en esta página")
        
        # Rastrear recursivamente páginas enlazadas si aún no alcanzamos profundidad máxima
        if depth < self.max_depth:
            page_urls = self._extract_page_urls(soup, url)
            for page_url in page_urls:
                # Llamar recursivamente con profundidad incrementada
                self.scrape(page_url, depth + 1)
    
    def get_stats(self):
        """
        Obtiene estadísticas sobre la operación de rastreo.
        
        Retorna un diccionario con:
        - total_downloaded: Número total de imágenes descargadas
        - total_visited: Número total de páginas visitadas
        - output_path: Ruta donde se guardaron las imágenes
        
        Retorna:
            dict: Diccionario con estadísticas de la operación
        """
        return {
            'total_downloaded': len(self.downloaded_images),
            'total_visited': len(self.visited_urls),
            'output_path': str(self.output_path)
        }


def parse_arguments():
    """
    Parsea los argumentos de línea de comandos.
    
    Utiliza argparse para crear una interfaz de línea de comandos intuitiva
    que permite especificar:
    - URL de inicio (argumento posicional)
    - Opción -r para activar rastreo recursivo
    - Opción -l para especificar profundidad máxima
    - Opción -p para especificar carpeta de salida
    
    Retorna:
        argparse.Namespace: Objeto con los argumentos parseados
    """
    parser = argparse.ArgumentParser(
        description='Araña: Extrae imágenes de sitios web de forma recursiva',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  %(prog)s https://example.com
  %(prog)s -r https://example.com
  %(prog)s -r -l 3 https://example.com
  %(prog)s -r -p /tmp/imagenes https://example.com
        """
    )
    
    # Argumento posicional: URL del sitio web
    parser.add_argument('url', help='URL del sitio web a comenzar a rastrar')
    
    # Opción -r / --recursive: Activar rastreo recursivo
    # Sin esta opción, solo se descargan imágenes de la página inicial
    parser.add_argument('-r', '--recursive', action='store_true',
                        help='Activar rastreo recursivo de páginas')
    
    # Opción -l / --level: Profundidad máxima de rastreo
    # Define cuántos niveles de enlaces seguir
    parser.add_argument('-l', '--level', type=int, default=Spider.DEFAULT_MAX_DEPTH,
                        help=f'Profundidad máxima de rastreo (por defecto: {Spider.DEFAULT_MAX_DEPTH})')
    
    # Opción -p / --path: Carpeta de salida para guardar imágenes
    parser.add_argument('-p', '--path', default=Spider.DEFAULT_PATH,
                        help=f'Ruta de salida para las imágenes (por defecto: {Spider.DEFAULT_PATH})')
    
    return parser.parse_args()


def main():
    """
    Punto de entrada principal del programa.
    
    Este función:
    1. Parsea los argumentos de línea de comandos
    2. Configura la profundidad según si se usa -r
    3. Crea una instancia de Spider
    4. Inicia el rastreo
    5. Muestra las estadísticas finales
    6. Maneja excepciones y errores de forma apropiada
    """
    try:
        # Obtener los argumentos de línea de comandos
        args = parse_arguments()
        
        # Si -r no se especifica, establecer profundidad a 0 (solo página actual)
        # Si -r se especifica, usar el nivel proporcionado
        max_depth = args.level if args.recursive else 0
        
        # Crear una instancia de Spider con los parámetros especificados
        spider = Spider(args.url, max_depth=max_depth, output_path=args.path)
        
        # Mostrar encabezado informativo
        print(f"\n{'='*60}")
        print(f"Iniciando Araña (Spider)")
        print(f"{'='*60}")
        print(f"URL:              {args.url}")
        print(f"Profundidad máx:  {max_depth}")
        print(f"Ruta de salida:   {args.path}")
        print(f"{'='*60}\n")
        
        # Iniciar el rastreo
        spider.scrape()
        
        # Obtener y mostrar estadísticas finales
        stats = spider.get_stats()
        print(f"\n{'='*60}")
        print(f"Rastreo Completado")
        print(f"{'='*60}")
        print(f"Imágenes descargadas: {stats['total_downloaded']}")
        print(f"Páginas visitadas:    {stats['total_visited']}")
        print(f"Imágenes guardadas en: {stats['output_path']}")
        print(f"{'='*60}\n")
        
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nAraña interrumpida por el usuario", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"Error inesperado: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
