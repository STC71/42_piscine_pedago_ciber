#!/usr/bin/env python3

# Importaciones de librerías necesarias
import argparse     # Para manejar argumentos pasados por la línea de comandos (CLI)
import sys          # Para la interacción con el sistema (ej. forzar la salida con sys.exit)
from src.scanner import Scanner     # Importamos nuestra clase Scanner (que detecta la inyección)
from src.extractor import Extractor # Importamos nuestra clase Extractor (que extrae los datos si es vulnerable)
from colorama import init, Fore, Style # Librería para dar color y estilos a los textos en la terminal

# Inicializamos colorama para que limpie el color después de cada print automáticamente
init(autoreset=True)

# Función visual: Simplemente imprime un cartel bonito de presentación al ejecutar el script
def print_banner():
    # Fore.MAGENTA pinta el texto en color magenta (rosa)
    print(f"{Fore.MAGENTA}")
    print("=========================================================")
    print(" V A C C I N E  -  SQLi D E T E C T O R  &  D U M P E R ")
    print("=========================================================")
    # Style.RESET_ALL devuelve el color a la normalidad en la consola
    print(f"{Style.RESET_ALL}")

# Función principal que coordina el programa entero
def main():
    # Usamos ArgumentParser para definir cómo el usuario debe escribir las opciones en la consola
    parser = argparse.ArgumentParser(description="Vaccine - Herramienta de Detección de SQL Injection")
    
    # Argumento Obligatorio: URL del objetivo (Ej. http://127.0.0.1:5000)
    parser.add_argument("URL", help="La URL objetivo a examinar.")
    
    # Argumento Opcional (-o): Archivo donde se guardará todo el proceso
    # El projecto (Mandatory) dice que si no se da un fichero, debe usar uno por defecto ("vaccine_results.txt")
    parser.add_argument("-o", "--output", default="vaccine_results.txt", help="Archivo de logs donde guardar resultados (MANDATORY).")
    
    # Argumento Opcional (-X): El tipo de método a usar
    # El projecto (Mandatory) pide testear GET y POST, si no se especifica el defecto debe ser GET.
    parser.add_argument("-X", "--method", default="GET", choices=["GET", "POST", "PUT", "DELETE"], help="Tipo de petición a forzar (MANDATORY).")
    
    # Argumento Opcional Extra (--user-agent): BONUS
    # Permite al usuario enmascarar su herramienta como si fuera un Navegador de verdad (Chrome, Firefox, etc.)
    parser.add_argument("--user-agent", default="Vaccine/1.0", help="Modificar el User-Agent (BONUS).")
    
    # Parseamos todos los argumentos introducidos por el usuario y los guardamos en 'args'
    args = parser.parse_args()
    
    # Pintamos el banner de bienvenida
    print_banner()
    
    # Abrimos o creamos el archivo de log (output) en modo "a" (append, respeta el histórico completo)
    f_log = open(args.output, "a")
    f_log.write("\n" + "="*57 + "\n") # Separador visual en el archivo
    start_msg = f"[*] Iniciando escaneo en: {args.URL}\n[*] Método: {args.method} | User-Agent: {args.user_agent}"
    
    # Imprimimos información básica en pantalla y también en el archivo de registro
    print(start_msg)
    f_log.write(start_msg + "\n")
    
    # Instanciamos (creamos) el objeto Scanner, pasándole los datos básicos que ingresó el usuario
    scanner = Scanner(args.URL, args.method, args.user_agent)
    
    print("[*] Buscando formularios interactivos en la URL...")
    
    # Le pedimos al Scanner que busque etiquetas <form> en el HTML de la web
    forms = scanner.get_forms()
    
    # Si la lista de formularios está vacía, no hay nada que atacar de manera interactiva
    if not forms:
        print(f"{Fore.YELLOW}[!] No se encontraron formularios en HTML. Saliendo...{Style.RESET_ALL}")
        f_log.close()
        sys.exit(0)
    
    print(f"{Fore.CYAN}[+] Parseados {len(forms)} formularios. Analizando...{Style.RESET_ALL}")
    
    # Lista donde guardaremos los datos de todas las vulnerabilidades que hallemos
    vulnerabilities = []
    
    # Recorremos (iteramos) todos los formularios detectados en la página
    for i, form in enumerate(forms):
        # details almacena un diccionario con 'action' (URL destino), 'method' (estrategia) y los inputs
        details = scanner.form_details(form)
        
        # Obtenemos hacia dónde apunta el formulario (el action)
        action_path = details["action"]
        
        # Como a veces el action es una ruta relativa (ej: "/login"), urljoin la pega a la URL grande (http://server.com/login)
        from urllib.parse import urljoin
        action = urljoin(args.URL, action_path)
        
        # Recogemos cuál es la intencion de envío del HTML
        method = details["method"]
        inputs = details["inputs"]
        
        # Sobreescribimos el método original del HTML si el usuario forzó uno distinto (ej: escribió -X POST)
        if args.method in ["POST", "PUT"]:
            method = args.method
        
        print(f"\n[*] Testeando Forumulario #{i+1} ({method} -> {action})")
        
        # Diccionario vacío donde imitaremos los datos válidos que enviaría una persona normal
        # Esto sirve para que las verificaciones HTML (ej. empty password) no bloqueen nuestra inyección
        data_dict = {}
        
        # Ignoramos inputs de tipo de envío puro (botones)
        for inp in inputs:
            if inp["type"] not in ["submit", "button"] and inp["name"] is not None:
                # Llenamos todo por defecto con "test" temporalmente
                data_dict[inp["name"]] = "test"
                
        # Ahora sí, vamos campo por campo de texto: en uno pondremos la Inyección, en el resto dejaremos "test"
        for inp in inputs:
            if inp["type"] not in ["submit", "button"] and inp["name"] is not None:
                print(f"    -> Probando parametro: '{inp['name']}'...")
                
                # Le decimos al Scanner que dispare fuego real contra ESTE parámetro en concreto
                vuln_info = scanner.test_sqli(action, method, data_dict, inp['name'], f_log)
                
                # Si fallaron las defensas de la web y descubrimos SQL Injection, vuln_info tendrá datos.
                if vuln_info:
                    vulnerabilities.append(vuln_info)

    # Si la lista vulnerabilities tiene al menos un fallo de seguridad registrado:
    if vulnerabilities:
        print(f"\n{Fore.RED}[!!!] SISTEMA VULNERABLE: Procediendo a fase de EXTRACCION...{Style.RESET_ALL}")
        
        # Iniciamos nuestro ladrón de datos (Extractor) usando solo la info de la PRIMERA vulnerabilidad detectada
        ext = Extractor(vulnerabilities[0], scanner.session, f_log)
        
        # Ejecutamos el vaciado (Dump) de la base de datos
        ext.run_extraction()
    else:
        # Si la lista está vacía, el servidor estaba blindado
        print(f"\n{Fore.GREEN}[+] El objetivo no parece vulnerable a inyecciones SQL basicas.{Style.RESET_ALL}")
        
    # Mensajes finales de limpieza
    f_log.write("\n[*] Escaneo completado.\n")
    f_log.close()
    print(f"\n[+] Resultados guardados en: {args.output}")

# Esta condición verifica si el script se está ejecutando directamente y no siendo importado
if __name__ == "__main__":
    main()

