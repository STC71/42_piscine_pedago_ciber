# 03 - SSH (Conectividad y ayuda) 🛡️

Traducción evaluativa:

> SSH
> The evaluator must be able to connect to the server with SSH.
> The person being evaluated must be able to help you.

Resumen rápido

- El servicio SSH está disponible en el contenedor en el puerto `4242` y permite autenticación por contraseña (temporal, para evaluación) y por clave pública (`PubkeyAuthentication yes`). Ver `sshd_config`.
- Usuario por defecto: `user` (creado en la imagen). El script de arranque genera claves host y arranca `sshd`.

Conectar (comandos de ejemplo)

- Con contraseña (evaluación):

```bash
ssh -p 4242 user@<HOST_OR_ONION>
# Ejemplo local: ssh -p 4242 user@127.0.0.1
```

- Con clave pública (recomendado en producción):

```bash
ssh -i /ruta/a/tu_clave -p 4242 user@<HOST_OR_ONION>
```

Puntos clave y referencias

1. Puerto y servicio SSH
   - `Port 4242` en `sshd_config` — [sshd_config](sshd_config#L13)
   - `EXPOSE 4242` en `Dockerfile` — [Dockerfile](Dockerfile#L92)

2. Usuarios y acceso
   - Usuario `user` creado en la imagen — [Dockerfile](Dockerfile#L57)
   - `PasswordAuthentication yes` (temporal para evaluación) — [sshd_config](sshd_config#L29); el modo key-only preparado está comentado en [sshd_config](sshd_config#L115)

3. Arranque y disponibilidad
   - Generación de claves host: `ssh-keygen -A` — [src/setup.sh](src/setup.sh#L126)
   - Arranque del servicio SSH: `service ssh start` — [src/setup.sh](src/setup.sh#L133)

Procedimiento para que el evaluador te ayude (dos escenarios)

A) Evaluador conecta desde la terminal del evaluado (tú ejecutas comandos localmente)

1. Demuestra la conexión local funcionando:

```bash
ssh -p 4242 user@127.0.0.1
```

2. Si el evaluador te envía su clave pública, agrégala al contenedor (reemplaza `<PUBKEY>` por la clave proporcionada):

```bash
docker exec -i ft_onion_container bash -c 'mkdir -p /home/user/.ssh && cat >> /home/user/.ssh/authorized_keys' <<'EOF'
<PUBKEY>
EOF
docker exec ft_onion_container bash -c 'chown -R user:user /home/user/.ssh && chmod 700 /home/user/.ssh && chmod 600 /home/user/.ssh/authorized_keys'
```

3. Validar sintaxis y reiniciar si se cambia configuración:

```bash
docker exec ft_onion_container sshd -t
docker exec ft_onion_container service ssh restart
```

B) Evaluador conecta desde su terminal remota (no está en tu máquina)

1. Obtener dirección y puerto a facilitar al evaluador:

```bash
# Dirección IP pública del host (si aplica)
hostname -I | awk '{print $1}'

# O la .onion generada por Tor (si se usa):
docker exec ft_onion_container cat /var/lib/tor/hidden_service/hostname
```

2. Indicaciones al evaluador para conectar:

```bash
# Por IP/host mapeado:
ssh -p 4242 user@<HOST_IP>

# Vía Tor (requiere cliente Tor o torsocks):
ssh -p 4242 user@[tu-direccion-onion].onion
```

3. Si el evaluador no tiene clave pública cargada, puede usar la contraseña temporal `password` (solo para evaluación), o bien enviarte su clave pública para que tú la agregues (ver sección A.2).

Comprobaciones y comandos útiles que puede pedir el evaluador (ejecutados por el evaluado o mostrados en pantalla)

```bash
docker exec ft_onion_container sshd -t            # valida la sintaxis de sshd_config
docker exec ft_onion_container service ssh status # estado del servicio
docker exec ft_onion_container cat /var/lib/tor/hidden_service/hostname  # muestra .onion
grep -n '^PasswordAuthentication' sshd_config
```

Notas para la defensa

- Explica que el evaluador puede conectar de forma remota vía IP o vía Tor; en ambos casos el puerto interno es `4242` y está documentado en `sshd_config` y `Dockerfile`.
- Indica que `PasswordAuthentication` se mantiene activo por compatibilidad de evaluación pero puedes cambiarlo a `PasswordAuthentication no` y validar con `sshd -t` antes de reiniciar (ver [tutorial.sh](tutorial.sh#L133-L135)).
- Si el evaluador necesita acceso inmediato sin pedirte acciones, proponle que te envíe su clave pública y muéstrale cómo la has añadido (captura de pantalla o compartir la salida de `cat /home/user/.ssh/authorized_keys`).

---

Archivo creado para ayudar a explicar y demostrar el requisito SSH en la evaluación; modifica localmente si necesitas adaptar mensajes o comandos.
