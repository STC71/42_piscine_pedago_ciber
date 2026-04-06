# 01 - Web (verificación de archivos y contenido) 🌐

Traducción evaluativa:

> Web

Debes encontrar al menos los siguientes archivos en la raíz del repositorio:
- Un archivo index.html con contenido.
- Un archivo de configuración nginx.conf.
- Un archivo de configuración sshd_config.
- Un archivo de configuración torrc. El servidor utiliza el servicio Nginx para entregar la página web. - - Con el evaluador, debes encontrar una URL que termine en .onion. Debes abrirla y comprobar que el contenido de la página sea idéntico al del archivo index.html visible.

Resumen rápido

- Archivos obligatorios en la raíz del repositorio: `index.html`, `nginx.conf`, `sshd_config`, `torrc`.
- Nginx entrega la página desde `/var/www/html` (configuración `root` en `nginx.conf`). Tor publica la dirección `.onion` mediante `HiddenServiceDir`/`HiddenServicePort` en `torrc`.

Archivos y referencias (líneas relevantes)

- `index.html` (página principal): [index.html](index.html#L1)
- `nginx.conf` (configuración del servidor web, raíz de documentos y virtual host): [nginx.conf](nginx.conf#L28-L40) (bloque del server principal) y `root /var/www/html` en [nginx.conf](nginx.conf#L48-L50).
- `sshd_config` (configuración SSH): [sshd_config](sshd_config#L13-L40)
- `torrc` (configuración de servicio oculto): [torrc](torrc#L32-L34)

Qué demostrar durante la evaluación

1) Presencia de los ficheros obligatorios

```bash
ls -la index.html nginx.conf sshd_config torrc
```

2) Demostrar que Nginx sirve el `index.html`

- Comprobar que Nginx está configurado con `root /var/www/html` y que `index.html` existe en esa ruta dentro del contenedor:

```bash
docker exec ft_onion_container test -f /var/www/html/index.html && echo "index.html presente"
docker exec ft_onion_container cat /etc/nginx/nginx.conf | sed -n '1,120p'  # ver bloque server
```

- Comparar el `index.html` del repositorio con el contenido servido por Nginx (dentro del contenedor):

```bash
docker exec ft_onion_container curl -sS http://127.0.0.1/ > /tmp/served.html
diff -u index.html /tmp/served.html || true
```

3) Encontrar y abrir la URL `.onion`

- Obtener la dirección `.onion` generada por Tor dentro del contenedor:

```bash
docker exec ft_onion_container cat /var/lib/tor/hidden_service/hostname
```

- Abrir la `.onion` en Tor Browser o con `torsocks curl` (ejemplo):

```bash
torsocks curl -sS http://<onion>/ | sed -n '1,120p'
```

- Comprobar que la página `.onion` coincide con `index.html` (puede usar `diff` sobre el HTML recuperado):

```bash
torsocks curl -sS http://<onion>/ > /tmp/onion.html
diff -u index.html /tmp/onion.html || true
```

4) Verificar que Nginx es el servidor que entrega la página

- El bloque `server` en `nginx.conf` escucha en `127.0.0.1:80` y define `root /var/www/html` — ver: [nginx.conf](nginx.conf#L28-L50).
- Puedes comprobar el encabezado `Server` o la respuesta de Nginx desde dentro del contenedor:

```bash
docker exec ft_onion_container curl -sSI http://127.0.0.1/ | head -n 10
```

Notas y recomendaciones para la defensa

- Explica dónde están los ficheros obligatorios y abre `index.html` en el editor para mostrar el contenido visible (usa [index.html](index.html#L1) como referencia).
- Muestra `nginx.conf` y destaca el `root /var/www/html` y el bloque `server` que escucha en `127.0.0.1:80` (referencia: [nginx.conf](nginx.conf#L28-L50)).
- Muestra la dirección `.onion` con `cat /var/lib/tor/hidden_service/hostname` dentro del contenedor y abre esa URL con Tor Browser; compara el HTML servido con el `index.html` del repositorio.
- Si hay pequeñas diferencias en minificación o cabeceras, explica que la comprobación debe concentrarse en el contenido visible (texto, estructura, imágenes) y no en metadatos de servidor.

---

Archivo creado para ayudar a verificar el requisito Web en la evaluación.
