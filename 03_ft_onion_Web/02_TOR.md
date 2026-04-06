# 02 - TOR (Hidden Service config) 🧭

Traducción evaluativa:

> TOR

El archivo de configuración del servicio oculto contiene estos parámetros (o un equivalente que debe explicarse):
- Directorio del servicio oculto
- Puerto del servicio oculto

Resumen breve

- El proyecto publica servicios como Hidden Services de Tor. La configuración clave está en `torrc`.
- Parámetros obligatorios a demostrar: `HiddenServiceDir` (directorio donde Tor crea el servicio oculto) y `HiddenServicePort` (mapeo de puertos locales a puertos onion).

Dónde está la configuración en este repositorio

- `torrc` principal: [torrc](torrc#L32-L34) — contiene `HiddenServiceDir /var/lib/tor/hidden_service/` y las líneas `HiddenServicePort 80 127.0.0.1:80` y `HiddenServicePort 4242 127.0.0.1:4242`.
- También hay una copia en `src/torrc`: [src/torrc](src/torrc#L32-L34).
- El `Makefile` incluye una comprobación rápida que valida la presencia de estas opciones dentro del contenedor: [Makefile](Makefile#L227).

Qué demostrar en la defensa (punto por punto)

1. Mostrar `HiddenServiceDir` (explicar permisos y ubicación)

- Comando para revisar (ejecutado por el evaluado en el host o dentro del contenedor):

```bash
grep -n '^HiddenServiceDir' /etc/tor/torrc || grep -n '^HiddenServiceDir' torrc
```

- En este repositorio: [torrc](torrc#L32) — `HiddenServiceDir /var/lib/tor/hidden_service/`.

2. Mostrar `HiddenServicePort` (qué puertos publica el servicio onion)

- Comando para revisar:

```bash
grep -n '^HiddenServicePort' /etc/tor/torrc || grep -n '^HiddenServicePort' torrc
```

- En este repositorio: [torrc](torrc#L33-L34) — `HiddenServicePort 80 127.0.0.1:80` y `HiddenServicePort 4242 127.0.0.1:4242`.

3. Explicar equivalencias y seguridad

- `HiddenServiceDir` debe tener permisos seguros (ej. `chmod 700`) porque contiene la clave privada y el fichero `hostname` que publica la dirección .onion. En este proyecto `setup.sh` y `Dockerfile` fijan permisos sobre `/var/lib/tor/hidden_service` (ver [Dockerfile](Dockerfile#L60-L67) y [src/setup.sh](src/setup.sh#L24-L30)).
- `HiddenServicePort 4242 127.0.0.1:4242` publica el servicio SSH a través de Tor, lo que permite que el evaluador se conecte vía `.onion` al puerto 4242 sin exponerlo públicamente.

4. Comprobaciones útiles durante la evaluación

```bash
# Mostrar hostname .onion generado por Tor dentro del contenedor
docker exec ft_onion_container cat /var/lib/tor/hidden_service/hostname

# Ver el torrc usado por el contenedor (Makefile tiene una regla similar)
docker exec ft_onion_container cat /etc/tor/torrc | grep -E 'HiddenServiceDir|HiddenServicePort'
```

5. Qué decir en la defensa

- Mostrar las líneas en `torrc` que definen `HiddenServiceDir` y `HiddenServicePort` y explicar que el directorio contiene claves y el archivo `hostname` con la dirección .onion.
- Explicar que `HiddenServicePort 80` publica la web y `HiddenServicePort 4242` publica SSH (permite acceso seguro vía Tor al servicio SSH sin abrir puertos al Internet público).
- Indicar que se han fijado permisos y que el `Makefile` y los scripts de arranque validan/configuran el servicio para que el .onion se genere correctamente.

---

Archivo creado para explicar cómo este proyecto cumple el requisito TOR de la evaluación; modifica localmente si necesitas adaptar mensajes o rutas.
