#!/usr/bin/env python3

"""
Escorpión Bonificación (Scorpion Bonus) - Editor avanzado de metadatos e interfaz gráfica
Características: Ver, editar y eliminar metadatos EXIF de archivos de imagen
Este módulo proporciona herramientas para manipular números datos EXIF de imágenes,
tanto desde línea de comandos como desde una interfaz gráfica (GUI) con Tkinter.
"""

import sys
import os
from pathlib import Path
from datetime import datetime
import piexif
from PIL import Image
from PIL.ExifTags import TAGS
import argparse


class MetadataEditor:
    """
    Editor avanzado de metadatos con capacidades de modificación.
    
    Este editor permite:
    - Listar todos los datos EXIF de una imagen
    - Eliminar todos los datos EXIF
    - Eliminar etiquetas específicas
    - Modificar valores de etiquetas EXIF
    - Crear copias de seguridad antes de cualquier cambio
    """
    
    # Conjunto de extensiones de archivo soportadas
    VALID_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp'}
    
    def __init__(self, filepath):
        """
        Inicializa el editor con un archivo de imagen.
        
        Este método:
        1. Valida que el archivo existe
        2. Verifica que la extensión sea soportada
        3. Almacena la ruta para operaciones posteriiores
        
        Args:
            filepath (str): Ruta al archivo de imagen a editar
            
        Lanza:
            ValueError: Si el archivo no existe o tiene extensión no soportada
        """
        self.filepath = Path(filepath)
        self.filename = self.filepath.name
        
        # Validar que el archivo existe en el sistema de archivos
        if not self.filepath.exists():
            raise ValueError(f"Archivo no encontrado: {filepath}")
        
        # Validar que la extensión es soportada
        if self.filepath.suffix.lower() not in self.VALID_EXTENSIONS:
            raise ValueError(f"Tipo de archivo no soportado: {self.filepath.suffix}")
    
    def get_exif_data(self):
        """
        Obtiene los datos EXIF actuales de la imagen.
        
        Carga todos los datos EXIF del archivo usando piexif.
        Estos datos están estructurados en secciones IFD (Image File Directory).
        
        Retorna:
            dict: Diccionario con datos EXIF, o None si no hay EXIF o hubo error
        """
        try:
            # Cargar datos EXIF del archivo
            exif_dict = piexif.load(str(self.filepath))
            return exif_dict
        except Exception:
            return None
    
    def remove_all_exif(self, backup=True):
        """
        Elimina TODOS los datos EXIF de una imagen.
        
        Este método:
        1. Opcionalmente crea una copia de seguridad del archivo original
        2. Abre la imagen con PIL
        3. Convierte a modo compatible si es necesario
        4. Guarda la imagen sin datos EXIF
        5. Reporta el éxito o error de la operación
        
        Args:
            backup (bool): Si True, crear copia de seguridad antes de eliminar EXIF
            
        Retorna:
            bool: True si fue exitoso, False si falló
        """
        try:
            # Crear copia de seguridad del archivo original
            if backup:
                # Añadir extensión .bak al nombre del archivo
                backup_path = self.filepath.with_suffix(self.filepath.suffix + '.bak')
                import shutil
                # Copiar el archivo original como respaldo
                shutil.copy2(self.filepath, backup_path)
                print(f"[Respaldo] Creado: {backup_path}")
            
            # Abrir la imagen con PIL
            img = Image.open(self.filepath)
            
            # Convertir si es necesario para compatibilidad de guardado
            # PNG con transparencia (RGBA) debe convertirse a RGB
            if img.mode == 'RGBA':
                # Crear imagen RGB con fondo blanco
                rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                # Pegar la imagen RGBA usando su canal alfa como máscara
                rgb_img.paste(img, mask=img.split()[3])
                img = rgb_img
            elif img.mode not in ['RGB', 'L']:
                # Convertir otros modos de color a RGB
                img = img.convert('RGB')
            
            # Guardar la imagen sin datos EXIF
            # Para JPEG, usar alta calidad (95) para no perder demasiada calidad
            if self.filepath.suffix.lower() in {'.jpg', '.jpeg'}:
                img.save(self.filepath, 'JPEG', quality=95)
            else:
                # Para otros formatos, guardar tal cual
                img.save(self.filepath)
            
            print(f"[Éxito] Todos los datos EXIF eliminados de: {self.filename}")
            return True
        
        except Exception as e:
            print(f"[Error] Fallo al eliminar EXIF: {e}")
            return False
    
    def remove_specific_exif(self, tag_names, backup=True):
        """
        Elimina etiquetas EXIF específicas de una imagen.
        
        Este método:
        1. Carga los datos EXIF actuales
        2. Busca las etiquetas especificadas por nombre
        3. Las elimina de sus secciones IFD
        4. Guarda la imagen modificada
        5. Reporte el número de etiquetas eliminadas
        
        Args:
            tag_names (list): Lista de nombres de etiquetas EXIF a eliminar
            backup (bool): Si True, crear copia de seguridad antes de modificar
            
        Retorna:
            bool: True si fue exitoso, False si falló
        """
        try:
            # Cargar datos EXIF del archivo
            exif_dict = piexif.load(str(self.filepath))
            
            if not exif_dict:
                print("[Información] No se encontraron datos EXIF para eliminar")
                return False
            
            # Contador de etiquetas eliminadas
            removed_count = 0
            
            # Iterar sobre todas las secciones IFD (Image File Directory)
            for ifd_name in ('0th', 'Exif', 'GPS', '1st'):
                ifd = exif_dict.get(ifd_name, {})
                # Lista para almacenar IDs de etiquetas a eliminar
                tags_to_remove = []
                
                # Encontrar las etiquetas a eliminar
                for tag_id, value in ifd.items():
                    # Obtener nombre legible de la etiqueta
                    tag_name = TAGS.get(tag_id, {}).get('name', f'Unknown_0x{tag_id:04x}')
                    # Si el nombre coincide con uno de los buscados, marcar para eliminar
                    if tag_name in tag_names:
                        tags_to_remove.append(tag_id)
                
                # Eliminar las etiquetas marcadas
                for tag_id in tags_to_remove:
                    del ifd[tag_id]
                    removed_count += 1
            
            # Verificar si se encontró algo para eliminar
            if removed_count == 0:
                print("[Información] No se encontraron etiquetas coincidentes para eliminar")
                return False
            
            # Crear copia de seguridad
            if backup:
                backup_path = self.filepath.with_suffix(self.filepath.suffix + '.bak')
                import shutil
                shutil.copy2(self.filepath, backup_path)
                print(f"[Respaldo] Creado: {backup_path}")
            
            # Guardar con los datos EXIF modificados
            exif_bytes = piexif.dump(exif_dict)
            img = Image.open(self.filepath)
            
            if self.filepath.suffix.lower() in {'.jpg', '.jpeg'}:
                img.save(self.filepath, 'JPEG', exif=exif_bytes, quality=95)
            else:
                img.save(self.filepath)
            
            print(f"[Éxito] Se eliminaron {removed_count} etiqueta(s) EXIF")
            return True
        
        except Exception as e:
            print(f"[Error] Fallo al eliminar etiquetas EXIF: {e}")
            return False
    
    def set_exif_tag(self, tag_name, value, backup=True):
        """
        Establece o modifica una etiqueta EXIF específica.
        
        Este método:
        1. Carga los datos EXIF actuales
        2. Encuentra la etiqueta por nombre
        3. Modifica su valor
        4. Guarda la imagen con los nuevos datos EXIF
        
        Args:
            tag_name (str): Nombre de la etiqueta EXIF a modificar
            value (str): Nuevo valor para la etiqueta
            backup (bool): Si True, crear copia de seguridad antes de modificar
            
        Retorna:
            bool: True si fue exitoso, False si falló
        """
        try:
            # Cargar datos EXIF del archivo
            exif_dict = piexif.load(str(self.filepath))
            
            # Crear copia de seguridad
            if backup:
                backup_path = self.filepath.with_suffix(self.filepath.suffix + '.bak')
                import shutil
                shutil.copy2(self.filepath, backup_path)
                print(f"[Respaldo] Creado: {backup_path}")
            
            # Codificar el valor si es string
            if isinstance(value, str):
                value = value.encode('utf-8')
            
            # Buscar y establecer la etiqueta en las secciones IFD
            found = False
            for ifd_name in ('0th', 'Exif', 'GPS'):
                ifd = exif_dict.get(ifd_name, {})
                # Iterar sobre las etiquetas existentes
                for tag_id, tag_value in ifd.items():
                    # Verificar si el nombre coincide
                    if TAGS.get(tag_id, {}).get('name', '') == tag_name:
                        # Actualizar el valor
                        ifd[tag_id] = value
                        found = True
                        break
            
            if not found:
                print(f"[Advertencia] Etiqueta '{tag_name}' no encontrada en datos EXIF actuales")
                return False
            
            # Guardar con los datos EXIF modificados
            exif_bytes = piexif.dump(exif_dict)
            img = Image.open(self.filepath)
            
            if self.filepath.suffix.lower() in {'.jpg', '.jpeg'}:
                img.save(self.filepath, 'JPEG', exif=exif_bytes, quality=95)
            else:
                img.save(self.filepath)
            
            print(f"[Éxito] Etiqueta EXIF actualizada: {tag_name} = {value}")
            return True
        
        except Exception as e:
            print(f"[Error] Fallo al establecer etiqueta EXIF: {e}")
            return False
    
    def list_exif_tags(self):
        """
        Lista todas las etiquetas EXIF disponibles en la imagen.
        
        Retorna:
            dict: Diccionario con nombres de etiquetas y sus valores
        """
        try:
            # Cargar datos EXIF del archivo
            exif_dict = piexif.load(str(self.filepath))
            
            if not exif_dict:
                return {}
            
            tags = {}
            # Iterar sobre todas las secciones IFD
            for ifd_name in ("0th", "Exif", "GPS", "1st"):
                ifd = exif_dict.get(ifd_name, {})
                if isinstance(ifd, dict):
                    # Iterar sobre las etiquetas en esta sección
                    for tag_id, value in ifd.items():
                        try:
                            # Obtener nombre legible de la etiqueta
                            tag_name = piexif.TAGS[ifd_name][tag_id]["name"]
                        except KeyError:
                            # Si no se encuentra, usar ID hexadecimal
                            tag_name = f"Unknown_0x{tag_id:04x}"
                        
                        # Formatear valor para presentación
                        if isinstance(value, bytes):
                            try:
                                # Intentar decodificar como UTF-8
                                value = value.decode('utf-8', errors='ignore')
                            except Exception:
                                # Si falla, usar representación string limitada
                                value = str(value)[:60]
                        else:
                            # Limitar longitud de presentación
                            value = str(value)[:100]
                        
                        tags[tag_name] = value
            
            return tags
        
        except Exception as e:
            return {}


def create_gui():
    """
    Crea una interfaz gráfica (GUI) con Tkinter para gestionar metadatos.
    
    Esta función implementa una aplicación gráfica completa que permite:
    - Seleccionar archivos de imagen
    - Ver metadatos EXIF
    - Eliminar todos los datos EXIF
    - Editar etiquetas EXIF individuales
    - Crear copias de seguridad automáticas
    
    Retorna:
        bool: True si se ejecutó exitosamente, False si hubo error
    """
    try:
        import tkinter as tk
        from tkinter import ttk, filedialog, messagebox
        import webbrowser
    except ImportError:
        print("Error: tkinter no disponible. Por favor instala python3-tk", file=sys.stderr)
        return False
    
    class ScorpionGUI:
        """Aplicación gráfica para gestión de metadatos de imágenes"""
        
        def __init__(self, root):
            """
            Inicializa la ventana principal de la aplicación.
            
            Args:
                root: Objeto raíz de Tkinter
            """
            self.root = root
            self.root.title("🦂 Escorpión - Gestor de Metadatos")
            self.root.geometry("1400x1100")
            self.root.configure(bg="#1e1e2e")
            
            # Variable para almacenar el archivo actual
            self.current_file = None
            # Variable para almacenar el editor
            self.editor = None
            
            # Crear todos los widgets de la interfaz
            self._create_widgets()
        
        def _create_widgets(self):
            """Crea todos los widgets (elementos) de la interfaz gráfica"""
            
            # Marco de título
            title_frame = tk.Frame(self.root, bg="#1e1e2e")
            title_frame.pack(fill=tk.X, padx=20, pady=15)
            
            # Etiqueta de título principal
            title_label = tk.Label(title_frame, text="🦂 Gestión de Metadatos Escorpión", 
                                  font=("Arial", 20, "bold"), bg="#1e1e2e", fg="#89dceb")
            title_label.pack(side=tk.LEFT)
            
            # Marco para selección de archivo
            file_frame = tk.Frame(self.root, bg="#313244", height=60)
            file_frame.pack(fill=tk.X, padx=20, pady=15)
            file_frame.pack_propagate(False)
            
            # Etiqueta para selector de archivo
            tk.Label(file_frame, text="📁 Seleccionar Imagen:", bg="#313244", fg="#cdd6f4", font=("Arial", 10)).pack(side=tk.LEFT, padx=10, pady=10)
            
            # Etiqueta que muestra el archivo seleccionado
            self.file_label = tk.Label(file_frame, text="No se ha seleccionado archivo", 
                                       bg="#313244", fg="#a6e3a1", width=50, font=("Arial", 9))
            self.file_label.pack(side=tk.LEFT, padx=10, pady=10)
            
            # Botón para explorar sistema de archivos
            tk.Button(file_frame, text="📁 Examinar...", command=self._browse_file,
                     bg="#89dceb", fg="#1e1e2e", font=("Arial", 10, "bold"), 
                     padx=20, pady=8).pack(side=tk.RIGHT, padx=10, pady=10)
            
            # Marco principal para contenido
            main_frame = tk.Frame(self.root, bg="#1e1e2e")
            main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
            
            # Marco para mostrar metadatos
            metadata_frame = tk.LabelFrame(main_frame, text="📋 Información de Metadatos", 
                                          bg="#313244", fg="#cdd6f4", font=("Arial", 11, "bold"))
            metadata_frame.pack(fill=tk.BOTH, expand=True, padx=0, pady=10)
            
            # Barra de desplazamiento para metadatos
            scroll = tk.Scrollbar(metadata_frame)
            scroll.pack(side=tk.RIGHT, fill=tk.Y)
            
            # Área de texto para mostrar metadatos
            self.metadata_text = tk.Text(metadata_frame, bg="#45475a", fg="#cdd6f4",
                                        yscrollcommand=scroll.set, font=("Courier", 9),
                                        height=15, padx=15, pady=15)
            self.metadata_text.pack(fill=tk.BOTH, expand=True)
            scroll.config(command=self.metadata_text.yview)
            self.metadata_text.config(state=tk.DISABLED)
            
            # Mostrar mensaje de bienvenida inicial
            self._show_welcome_message()
            
            # Marco de botones de acción
            button_frame = tk.Frame(self.root, bg="#1e1e2e")
            button_frame.pack(fill=tk.X, padx=20, pady=15)
            
            # Botón para actualizar metadatos
            tk.Button(button_frame, text="🔄 Actualizar", command=self._refresh_metadata,
                     bg="#94e2d5", fg="#1e1e2e", font=("Arial", 10, "bold"), 
                     padx=15, pady=8).pack(side=tk.LEFT, padx=5)
            
            # Botón para eliminar todos los EXIF
            tk.Button(button_frame, text="🗑️  Eliminar Todo EXIF", command=self._remove_all_exif,
                     bg="#f38ba8", fg="#1e1e2e", font=("Arial", 10, "bold"), 
                     padx=15, pady=8).pack(side=tk.LEFT, padx=5)
            
            # Botón para editar etiquetas
            tk.Button(button_frame, text="📝 Editar Etiquetas", command=self._show_edit_dialog,
                     bg="#f9e2af", fg="#1e1e2e", font=("Arial", 10, "bold"), 
                     padx=15, pady=8).pack(side=tk.LEFT, padx=5)
            
            # Botón para salir
            tk.Button(button_frame, text="❌ Salir", command=self.root.quit,
                     bg="#6c7086", fg="#cdd6f4", font=("Arial", 10, "bold"), 
                     padx=15, pady=8).pack(side=tk.RIGHT, padx=5)
        
        def _show_welcome_message(self):
            """
            Muestra un mensaje de bienvenida e instrucciones iniciales.
            
            Este mensaje aparece cuando la GUI se abre por primera vez,
            guiando al usuario sobre cómo usar la aplicación.
            """
            welcome_text = """╔═══════════════════════════════════════════════════════════════════╗
║    🦂 BIENVENIDO A ESCORPIÓN - GESTOR DE METADATOS               ║
╚═══════════════════════════════════════════════════════════════════╝

📌 Instrucciones de Inicio:

1️⃣  Haz clic en "📁 Examinar..." para seleccionar una imagen
    └─ Los formatos soportados son: JPG, PNG, GIF, BMP

2️⃣  Una vez seleccionada, verás todos los metadatos EXIF:
    ├─ Información de la cámara (marca, modelo, lente)
    ├─ Datos de la fotografía (ISO, apertura, distancia focal)
    ├─ Fechas de captura y edición
    └─ Otros datos técnicos

3️⃣  Puedes realizar las siguientes acciones:
    ├─ 🔄 Actualizar: Recarga los metadatos del archivo
    ├─ 🗑️  Eliminar Todo EXIF: Borra todos los metadatos (con respaldo)
    └─ 📝 Editar Etiquetas: Ver las etiquetas EXIF disponibles

⚠️  Nota: Al eliminar metadatos, se crea automáticamente una copia
    de seguridad con extensión .bak

═══════════════════════════════════════════════════════════════════

🎯 Comienza: Haz clic en "📁 Examinar..." para cargar una imagen"""
            self.metadata_text.config(state=tk.NORMAL)
            self.metadata_text.delete(1.0, tk.END)
            self.metadata_text.insert(1.0, welcome_text)
            self.metadata_text.config(state=tk.DISABLED)
        
        def _browse_file(self):
            """
            Abre un diálogo para seleccionar un archivo de imagen.
            
            Permite al usuario navegar el sistema de archivos y seleccionar
            una imagen para analizar.
            """
            filename = filedialog.askopenfilename(
                title="Seleccionar archivo de imagen",
                filetypes=[("Imágenes", "*.jpg *.jpeg *.png *.gif *.bmp"),
                          ("Todos los Archivos", "*.*")]
            )
            
            if filename:
                try:
                    # Crear editor para el nuevo archivo
                    self.editor = MetadataEditor(filename)
                    self.current_file = filename
                    # Actualizar etiqueta con nombre del archivo
                    self.file_label.config(text=Path(filename).name)
                    # Mostrar los metadatos del archivo
                    self._refresh_metadata()
                except ValueError as e:
                    # Mostrar error si hay problema con el archivo
                    messagebox.showerror("Error", str(e))
        
        def _refresh_metadata(self):
            """
            Actualiza la pantalla de metadatos con la información actual del archivo.
            
            Obtiene los metadatos del archivo seleccionado y los muestra
            formateados en el área de texto.
            """
            if not self.editor:
                messagebox.showwarning("Advertencia", "Por favor selecciona una imagen primero")
                return
            
            # Permitir edición del campo de texto
            self.metadata_text.config(state=tk.NORMAL)
            # Borrar contenido anterior
            self.metadata_text.delete(1.0, tk.END)
            
            try:
                # Importar el analizador de metadatos
                from scorpion import MetadataAnalyzer
                # Crear analizador para el archivo actual
                analyzer = MetadataAnalyzer(self.current_file)
                # Obtener metadatos
                metadata = analyzer.analyze()
                # Formatear para presentación
                output = analyzer.format_output(metadata)
                # Insertar en el área de texto
                self.metadata_text.insert(1.0, output)
            except Exception as e:
                # Mostrar error si hay problema
                self.metadata_text.insert(1.0, f"Error cargando metadatos: {e}")
            
            # Desactivar edición del campo de texto
            self.metadata_text.config(state=tk.DISABLED)
        
        def _remove_all_exif(self):
            """
            Elimina todos los datos EXIF del archivo actual.
            
            Pregunta al usuario para confirmar y luego elimina
            todos los metadatos EXIF, creando una copia de seguridad.
            """
            if not self.editor:
                messagebox.showwarning("Advertencia", "Por favor selecciona una imagen primero")
                return
            
            # Pedir confirmación al usuario
            if messagebox.askyesno("Confirmar", "¿Eliminar todos los datos EXIF de esta imagen?\n\nSe creará un respaldo."):
                # Ejecutar eliminación
                if self.editor.remove_all_exif(backup=True):
                    messagebox.showinfo("Éxito", "¡Datos EXIF eliminados exitosamente!")
                    # Actualizar pantalla
                    self._refresh_metadata()
                else:
                    messagebox.showerror("Error", "Fallo al eliminar datos EXIF")
        
        def _show_edit_dialog(self):
            """
            Muestra un diálogo para editar las etiquetas EXIF.
            
            Crea una ventana secundaria que lista todas las etiquetas EXIF
            disponibles en la imagen actual.
            """
            if not self.editor:
                messagebox.showwarning("Advertencia", "Por favor selecciona una imagen primero")
                return
            
            # Crear ventana secundaria (diálogo)
            dialog = tk.Toplevel(self.root)
            dialog.title("Editar Etiquetas EXIF")
            dialog.geometry("500x400")
            dialog.configure(bg="#1e1e2e")
            
            # Etiqueta para el diálogo
            tk.Label(dialog, text="Etiquetas EXIF Disponibles:", bg="#1e1e2e", 
                    fg="#cdd6f4", font=("Arial", 10, "bold")).pack(padx=10, pady=10)
            
            # Marco para la lista de etiquetas
            frame = tk.Frame(dialog, bg="#313244")
            frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
            
            # Barra de desplazamiento para la lista
            scroll = tk.Scrollbar(frame)
            scroll.pack(side=tk.RIGHT, fill=tk.Y)
            
            # Listbox con las etiquetas EXIF
            listbox = tk.Listbox(frame, bg="#45475a", fg="#cdd6f4",
                               yscrollcommand=scroll.set, font=("Courier", 9))
            listbox.pack(fill=tk.BOTH, expand=True)
            scroll.config(command=listbox.yview)
            
            # Obtener lista de etiquetas del archivo
            tags = self.editor.list_exif_tags()
            # Agregar cada etiqueta a la lista
            for tag_name, value in sorted(tags.items()):
                listbox.insert(tk.END, f"{tag_name}")
            
            # Botón para cerrar el diálogo
            tk.Button(dialog, text="Cerrar", command=dialog.destroy,
                     bg="#6c7086", fg="#cdd6f4", padx=15, pady=8).pack(pady=10)
    
    # Crear ventana principal de Tkinter
    root = tk.Tk()
    # Crear la aplicación
    app = ScorpionGUI(root)
    # Iniciar el loop de eventos
    root.mainloop()
    return True


def parse_arguments():
    """
    Parsea los argumentos de línea de comandos.
    
    Maneja tus opciones para:
    - Mostrar GUI (--gui)
    - Eliminar todos los EXIF (--remove-all)
    - Eliminar etiquetas específicas (--remove-tag)
    - Establecer valores de etiquetas (--set-tag)
    - Listar todas las etiquetas (--list-tags)
    - Crear o no copia de seguridad (--no-backup)
    
    Retorna:
        argparse.Namespace: Objeto con los argumentos parseados
    """
    parser = argparse.ArgumentParser(
        description='Escorpión Bonificación: Editor avanzado de metadatos',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  %(prog)s --gui                              # Lanzar GUI
  %(prog)s --remove-all imagen.jpg            # Eliminar todos los EXIF
  %(prog)s --remove-tag DateTime imagen.jpg   # Eliminar etiqueta específica
  %(prog)s --list-tags imagen.jpg             # Listar todas las etiquetas
        """
    )
    
    # Argumento posicional: archivo de imagen
    parser.add_argument('file', nargs='?', help='Archivo de imagen a editar')
    # Opción para lanzar GUI
    parser.add_argument('--gui', action='store_true', help='Lanzar aplicación GUI')
    # Opción para eliminar todos los EXIF
    parser.add_argument('--remove-all', action='store_true', help='Eliminar todos los datos EXIF')
    # Opción para eliminar etiqueta específica
    parser.add_argument('--remove-tag', help='Eliminar etiqueta EXIF específica por nombre')
    # Opción para establecer valor de etiqueta
    parser.add_argument('--set-tag', nargs=2, metavar=('ETIQUETA', 'VALOR'), 
                       help='Establecer valor de etiqueta EXIF')
    # Opción para listar todas las etiquetas
    parser.add_argument('--list-tags', action='store_true', help='Listar todas las etiquetas EXIF')
    # Opción para no crear respaldo
    parser.add_argument('--no-backup', action='store_true', help='No crear copia de seguridad')
    
    return parser.parse_args()


def main():
    """
    Punto de entrada principal del programa.
    
    Maneja:
    1. Modo GUI o modo línea de comandos
    2. Parseo de argumentos
    3. Ejecución de la acción solicitada
    4. Manejo de errores y excepciones
    """
    # Parsear argumentos de línea de comandos
    args = parse_arguments()
    
    # MODO GUI
    if args.gui or (not args.file and not any([args.remove_all, args.remove_tag, 
                                                args.set_tag, args.list_tags])):
        # Intenta ejecutar la GUI
        try:
            create_gui()
        except ImportError:
            print("El modo GUI requiere tkinter. Instalar con: sudo apt install python3-tk", 
                 file=sys.stderr)
            sys.exit(1)
        return
    
    # MODO LÍNEA DE COMANDOS
    # Verificar que se proporcionó un archivo
    if not args.file:
        print("Error: No se especificó archivo", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Crear editor para el archivo
        editor = MetadataEditor(args.file)
        
        # Operación: Listar etiquetas EXIF
        if args.list_tags:
            tags = editor.list_exif_tags()
            if tags:
                print(f"\nEtiquetas EXIF en {args.file}:")
                print("-" * 70)
                for tag_name, value in sorted(tags.items()):
                    value_str = str(value)[:60]
                    print(f"  {tag_name}: {value_str}")
                print("-" * 70)
            else:
                print("No se encontraron etiquetas EXIF")
        
        # Operación: Eliminar todos los EXIF
        elif args.remove_all:
            editor.remove_all_exif(backup=not args.no_backup)
        
        # Operación: Eliminar etiqueta específica
        elif args.remove_tag:
            editor.remove_specific_exif([args.remove_tag], 
                                       backup=not args.no_backup)
        
        # Operación: Establecer valor de etiqueta
        elif args.set_tag:
            tag_name, value = args.set_tag
            editor.set_exif_tag(tag_name, value, 
                              backup=not args.no_backup)
        
        # Si no se especificó ninguna acción
        else:
            print("Por favor especifica una acción (--remove-all, --remove-tag, --set-tag, --list-tags)\n"
                  "--remove-all: Eliminar todos los datos EXIF\n"
                  "--remove-tag ETIQUETA: Eliminar etiqueta EXIF específica\n"
                  "--set-tag ETIQUETA VALOR: Establecer valor de etiqueta EXIF\n"
                  "          etiqueta EXIF es el nombre legible de la etiqueta (ej: DateTime, Model)\n"
                  "--list-tags: Listar todas las etiquetas EXIF", 
                  file=sys.stderr)
            sys.exit(1)
    
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error inesperado: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
