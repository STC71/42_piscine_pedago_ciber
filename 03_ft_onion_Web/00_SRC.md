
# 00 - Resumen técnico: src/, Dockerfile, docker-compose.yml 🚀

**`src/`** 🗂️
- 🔧 La carpeta `src/` contiene la orquestación y herramientas: `setup.sh` (inicia Tor, Nginx, SSH y muestra la dirección .onion), `validate.py` (diagnóstico/validación) y `app.py` (panel Python opcional).
- 📦 Incluye `requirements.txt` y copias locales de configuración (`nginx.conf`, `torrc`, `sshd_config`) que se usan durante la construcción y pruebas.
- ✅ `setup.sh` asegura permisos, arranca servicios en orden y deja el contenedor operativo; `validate.py` genera informes (terminal/JSON) útiles para la evaluación.

**`Dockerfile`** 🐳
- 🧱 Es multietapa: una base instala dependencias del sistema, `builder` crea el entorno virtual e instala las dependencias, y la etapa `final` prepara la imagen de ejecución.
- 📁 Copia configuraciones (`nginx.conf`, `torrc`, `sshd_config`), `index.html`, scripts y el código Python en `/app`, crea usuarios sin privilegios y aplica permisos seguros para Tor/SSH.
- ⚙️ Expone `4242` (SSH endurecido), declara puertos internos 80/9000, incluye `HEALTHCHECK` y usa `/app/setup.sh` como entrada para orquestar servicios.

**`docker-compose.yml`** ⚙️
- 🧩 Define el servicio `ft_onion` construido desde el `Dockerfile`, con red `tor_network` para aislamiento y nombre de contenedor configurable.
- 🔐 Mapea `4242:4242` para SSH (HTTP solo interno; acceso público por Tor) y monta volúmenes persistentes para `tor_hidden_service`, `tor_data` y `ft_onion_logs`.
- 🛡️ Añade variables de entorno, `restart: unless-stopped`, `healthcheck`, límites de recursos (`cpus`, `memory`), `no-new-privileges` y logging rotado para operación estable.

---

Si quieres, adapto estas fichas a una tarjeta de 30–45 s o las convierto en una tabla imprimible para la defensa. 🎤


