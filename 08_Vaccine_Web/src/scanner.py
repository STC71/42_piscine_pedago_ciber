# Importaciones de librerías necesarias
from bs4 import BeautifulSoup   # Beautiful Soup se usa para rastrear el código HTML y "leer" las etiquetas como 'input' o 'form'
import requests                 # Ejecuta las peticiones HTTP a internet
from urllib.parse import urljoin # Para convertir paths relativos (/login) en URL completas (http://s.com/login)
import time                     # Controlar el tiempo de espera (Para detectar inyecciones Time-Based)

# Importamos las bases de diccionarios vulnerables que definimos antes
from src.payloads import ERROR_PAYLOADS, BOOLEAN_PAYLOADS, TIME_PAYLOADS, UNION_PAYLOADS, DB_ERRORS
from colorama import Fore, Style # Para darle colorcitos en terminal a los loggers 

# La Calse Scanner es el "corazón" de la aplicación Vaccine
# Actúa como un sabueso, arrastrándose por el formulario de una web en busca de fallos lógicos
class Scanner:
    # constructor (__init__)
    # Inicializa cada vez que detectemos una url. Guarda qué método usaremos y la sesión (con cookies y variables compartidas)
    def __init__(self, url, method="GET", user_agent=None):
        self.url = url
        self.method = method.upper() # Pasamos GET o POST a mayúsculas para compararlos fácilmente
        self.session = requests.Session() # Session() recuerda si hubieran credenciales a futuro durante el barrido
        
        # BONUS: Si el flag --user-agent se activó en Main, el header se enmascarará
        if user_agent:
            self.session.headers.update({"User-Agent": user_agent})
        
    def get_forms(self):
        """
        Scrapea la página objetivo escaneando a fondo y buscando formularios HTML (<form>).
        Un formulario es el vector número 1 para SQL Injection, ya que pasa inputs a la Base de Datos.
        """
        try:
            # Enviamos una petición para ver qué devuelve
            response = self.session.get(self.url)
            # Pasamos su respuesta HTML plana (content) a BeautifulSoup para que lo trate como un árbol navegable
            soup = BeautifulSoup(response.content, "html.parser")
            # Devolvemos una lista con absolutamente todos los <form> que esta web presente.
            return soup.find_all("form")
        except Exception as e:
            # Capturamos fallos como "Error DNS, servidor apagado" etc
            print(f"{Fore.RED}[!] Error conectando a {self.url}: {e}{Style.RESET_ALL}")
            return []

    def form_details(self, form):
        """
        Extrae la información importante de un formulario concreto: su acción, cómo comunica y qué campos solicita.
        """
        details = {}
        # El atributo 'action' de un HTML dice "a qué link" se envían los datos
        action = form.attrs.get("action", self.url)
        # El método será comúnmente un get o post
        method = form.attrs.get("method", "get").upper()
        inputs = []
        
        # Iteramos por cada etiqueta <input> hallada en el formulario (ej: cajas de texto, mail, contraseñas)
        for input_tag in form.find_all("input"):
            input_type = input_tag.attrs.get("type", "text")
            input_name = input_tag.attrs.get("name")
            input_value = input_tag.attrs.get("value", "") # Ej: un recuadro autocompletado en HTML
            
            if input_name:
                # Apuntamos todas las características en un array diccionario
                inputs.append({"type": input_type, "name": input_name, "value": input_value})
        
        # Embalamos la info y la retornamos a Main
        details["action"] = action
        details["method"] = method
        details["inputs"] = inputs
        return details

    def detect_db_engine(self, response_text):
        """
        BONUS Y MANDATORY (Firmas de Motor)
        Esta función identifica qué base de datos corre por detrás (MySQL, SQLite...) leyendo los mensajes
        de error "vomitados" en el HTML cada vez que rompemos su sintaxis con una inyección.
        """
        # Hacemos minúscula todo el volcado HTML de error devuelto y así evitamos fallos de mayúsculas (case check)
        resp_lower = response_text.lower()
        found_engines = []
        
        # Leemos nuestro diccionario de de DB_ERRORS de payloads.py
        for db_name, signatures in DB_ERRORS.items():
            for sig in signatures: # Por cada variante de firma (ej: "syntax error at or near", "mysql_query()")
                # Si una de las firmas textuales se imprimió errónamente en la respuesta HTML: ES CULPABLE.
                if sig.lower() in resp_lower:
                    if db_name not in found_engines:
                        found_engines.append(db_name) # Sabemos qué motor está detrás
        return found_engines

    def test_sqli(self, url, method, data, param_name, log_file):
        """
        El núcleo inyector de la Máquina. Manda payloads preconstruidos 
        y analiza sus consecuencias lógicas y pasivas.
        """
        # Banderas por defecto 
        vulnerable = False
        engines = []
        payload_used = ""
        inj_method = ""
        
        # ==============================================================================
        # PRUEBA 1. Error-Based (Provocar Caos Visual)
        # Lanzamos comillas, contrabarras o dobles comillas para ver si rompen la sintaxis DB
        # ==============================================================================
        for payload in ERROR_PAYLOADS:
            test_data = data.copy()
            # Concatenamos la basura venenosa (payload) al valor del parámetro apuntado
            test_data[param_name] = test_data[param_name] + payload
            
            # Lanzamos ataque
            if method == "POST":
                res = self.session.post(url, data=test_data)
            else:
                res = self.session.get(url, params=test_data)
            
            # Llamamos a detect_db_engine si saltó Error-based la firma delatará todo
            detected_engines = self.detect_db_engine(res.text)
            
            if detected_engines:
                vulnerable = True
                engines = detected_engines
                payload_used = payload
                inj_method = "Error-Based" # Informamos del método de descubrimiento
                break # Frenar: La meta ya cayó
        
        # ==============================================================================
        # PRUEBA 2. Union-Based (Extracción de Ceros de Información)
        # Lanzamos consultas UNION anexadas que buscan emular/inyectar un array textual nuevo
        # Nos permite exfiltrar información pasándola como output de las mismas tablas HTML
        # ==============================================================================
        if not vulnerable:
            for payload in UNION_PAYLOADS:
                test_data = data.copy()
                # Modificamos el ID de este usuario a -1, asegurándonos que el output solo sea
                # lo que diga la parte derecha (Nuestra UNION)
                test_data[param_name] = "-1" + payload 
                if method == "POST":
                    res = self.session.post(url, data=test_data)
                else:
                    res = self.session.get(url, params=test_data)
                
                # Si vemos nuestro keyword secreto en pantalla, el volcado con UNION ha existido
                if "VACCINE_UNION_TEST" in res.text:
                    vulnerable = True
                    payload_used = payload
                    inj_method = "Union-Based"
                    engines = ["Unknown (Detectado via UNION)"]
                    break
        
        # ==============================================================================
        # PRUEBA 3. Time-Based Injections (Ataque Demorado) (BONUS)
        # Ordenaremos al servidor SQL que literalmente se duerma. Si la respuesta
        # tarda más que 2.8 segundos en volver, la orden SLEEP fue ejecutada por culpa del SQli
        # ==============================================================================
        if not vulnerable:
            for payload in TIME_PAYLOADS:
                test_data = data.copy()
                test_data[param_name] = data[param_name] + payload
                
                start_time = time.time()
                # Ejecutamos asíncronamente
                if method == "POST":
                    self.session.post(url, data=test_data)
                else:
                    self.session.get(url, params=test_data)
                end_time = time.time()
                
                # Descontamos el tiempo inicial del final, y obtenemos el tiempo bruto de demora...
                if (end_time - start_time) > 2.8: # Retraso enorme confirmador (Normalmente toman ms)
                    vulnerable = True
                    payload_used = payload
                    inj_method = "Time-Based"
                    engines = ["SQLite/MySQL/PgSQL (Detectado via Time-Delay)"]
                    break

        # ==============================================================================
        # PRUEBA 4. Boolean-Based (Ceguera Lógica) (MANDATORY)
        # Modificamos un boolean OR 1=1 (lo pasamos a ALWAYS TRUE) en las comparaciones de auth.
        # Si un query era 'WHERE auth = "FALSE"', lo pasamos a ('WHERE auth="FALSE" OR 1=1"')... 
        # Que provocará el loggeo de administradores indiscriminado sin dar alerta de Errores DB.
        # ==============================================================================
        if not vulnerable:
            for payload in BOOLEAN_PAYLOADS:
                test_data = data.copy()
                test_data[param_name] = "admin" + payload  # Construimos seed base y el bypass
                
                if method == "POST":
                    res = self.session.post(url, data=test_data)
                else:
                    res = self.session.get(url, params=test_data)
                    
                # Si una de estas combinaciones nos devuelve HTML dando las gracias en lugar
                # del error original "Invalid credential", estamos dentro.
                if "Welcome" in res.text or "Successful" in res.text:
                    vulnerable = True
                    payload_used = payload
                    inj_method = "Boolean-Based"
                    engines = ["Unknown (Blind/Boolean)"]
                    break

        # ==============================================================================
        # PROCESAMIENTO FINAL TRAS TODAS LAS INYECCIONES 
        # ==============================================================================
        if vulnerable:
            # Embalamos la info relevante del ataque con variables interpoladas F-strings
            info = f"[*] VULNERAVILIDAD ENCONTRADA:\n" \
                   f"    Metodo: {method}\n" \
                   f"    Parametro: {param_name}\n" \
                   f"    Typo de Inyeccion: {inj_method}\n" \
                   f"    Payload: {payload_used}\n" \
                   f"    Database Engine: {', '.join(engines)}\n"
                   
            # Lo mostramos bonito en terminal...
            print(f"{Fore.GREEN}{info}{Style.RESET_ALL}")
            # ... y si había fichero de log (-o), lo escribiremos en la hoja plana.
            if log_file:
                log_file.write(info + "\n")
                
            # Devolvemos un Diccionario ordenado con las directrices directas al Extractor.py...   
            return {
                "param": param_name,
                "engine": engines[0] if engines else "Unknown",
                "method": method,
                "action": url,
                "payload": payload_used
            }
            
        # En caso opuesto (sin hackeo), falló estrepitosamente o estaba bien blindado. Retorna Nulo.
        return None
