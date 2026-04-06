# 04 - SSH Hardening - Refuerzo de seguridad SSH 🔒

Traducción evaluativa:

Refuerzo de seguridad SSH:
- 🔐 El archivo `sshd_config` contiene parámetros avanzados para evitar el acceso no protegido habitual.
- 📝 El estudiante debe poder explicar los motivos de sus elecciones de configuración.
- ⚠️ Por ejemplo, no se permite la autenticación por contraseña ni el acceso del usuario `root`.

## Resumen rápido

- 🔧 Configuración principal: [sshd_config](sshd_config#L13-L115)
- 📦 Docker copia la configuración: [Dockerfile](Dockerfile#L71)
- ⚙️ Arranque y generación de claves host: [src/setup.sh](src/setup.sh#L126-L133)
- 📚 Guía de evaluación y procedimientos: [tutorial.sh](tutorial.sh#L122-L135)

## Checklist para la defensa (punto por punto)

1. `Port 4242` — motivo: requisito del ejercicio y separación de servicios. Referencia: [sshd_config](sshd_config#L13).
2. `PubkeyAuthentication yes` — motivo: método seguro por clave pública. Referencia: [sshd_config](sshd_config#L25).
3. `PasswordAuthentication yes` (temporal) — motivo: accesibilidad durante la evaluación; en producción debe desactivarse. Referencia: [sshd_config](sshd_config#L29) y modo key-only comentado en [sshd_config](sshd_config#L115).
4. `PermitRootLogin no` — motivo: evitar acceso directo a la cuenta más privilegiada. Referencia: [sshd_config](sshd_config#L37).
5. `AllowUsers user` — motivo: restringir usuarios permitidos. Referencia: [sshd_config](sshd_config#L40).
6. `MaxAuthTries 3` — motivo: limitar intentos de autenticación (mitiga fuerza bruta). Referencia: [sshd_config](sshd_config#L52).
7. `StrictModes yes` — motivo: forzar permisos correctos en directorios y claves. Referencia: [sshd_config](sshd_config#L58).
8. Algoritmos y cifrados modernos (`KexAlgorithms`, `Ciphers`, `MACs`) — motivo: evitar suites criptográficas débiles. Referencias: [sshd_config](sshd_config#L87-L93).
9. `sshd_config` es copiado en la imagen Docker y el usuario `user` se crea en `Dockerfile` — referencias: [Dockerfile](Dockerfile#L71), [Dockerfile](Dockerfile#L57), [Dockerfile](Dockerfile#L92).
10. El script de arranque genera claves host y arranca SSH — referencias: [src/setup.sh](src/setup.sh#L126), [src/setup.sh](src/setup.sh#L133).

## 🛠️ Procedimiento recomendado (comandos)

## Nota importante sobre la política de contraseñas

Aunque el enunciado de evaluación recomienda no permitir autenticación por contraseña, en este repositorio `PasswordAuthentication` se mantiene en `yes` para facilitar el acceso del evaluador. En la defensa deberás explicar que:

- La decisión es temporal y motivada por la evaluación.
- Sabes cómo endurecer el servicio cambiando a `PasswordAuthentication no`, validando con `sshd -t` y reiniciando el servicio (`service ssh restart`).
- Puedes demostrar el proceso de rollback si fuera necesario (volver a `yes`).

Incluye esta aclaración breve al presentar: "Durante la evaluación he dejado `PasswordAuthentication` habilitado por compatibilidad; en producción lo cambio a `PasswordAuthentication no` y uso sólo autenticación por clave pública, validando con `sshd -t` antes de reiniciar." 🔁


1. 🛠️ Validar sintaxis del `sshd_config` dentro del contenedor:

```bash
sshd -t
```

2. Reiniciar servicio SSH:

```bash
service ssh restart
```

3. Para pasar a key-only (post-evaluación): editar `sshd_config` y cambiar `PasswordAuthentication no`, validar con `sshd -t` y reiniciar. (Ver pasos en [tutorial.sh](tutorial.sh#L133-L135)).

## Puntos a explicar oralmente

- Por qué se deshabilita `PermitRootLogin` (menor riesgo, mejores prácticas) — ver [sshd_config](sshd_config#L37).
- Por qué preferir `PubkeyAuthentication` y desactivar `PasswordAuthentication` en producción — ver [sshd_config](sshd_config#L25,sshd_config#L115).
- Cómo validar cambios sin bloquear el acceso (comprobar `sshd -t`, mantener acceso alternativo, rollback). Referencia: [tutorial.sh](tutorial.sh#L133-L135).
- Relación con Tor: el puerto expuesto internamente y la publicación por `torrc` (ver `torrc` y `Dockerfile` para la exposición de puerto 4242).

---

Archivo creado para apoyar la evaluación; modifica localmente si necesitas adaptar mensajes o líneas de referencia.
