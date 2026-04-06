#!/usr/bin/env python3
"""
Reemplazo completo del contenido anterior por una versión con comentarios
detallados en español (línea a línea y secciones). No se cambia la lógica.

Explicación del cambio:
- Añade comentarios explicativos junto a las operaciones críticas.
- Mantiene la misma estructura y valores de parches.
"""

import os
import sys


def patch_binary(src_path: str, dst_path: str, patches: list, label: str) -> None:
    """
    Aplica parches a un binario y escribe la copia parcheada.

    Véase la documentación dentro del propio archivo para el detalle de
    cada parámetro y las razones del diseño (seguridad, reproducibilidad).
    """

    # 1) Abrimos y leemos todo el archivo en memoria.
    #    Usamos bytearray para permitir escritura por índices.
    with open(src_path, 'rb') as f:
        data = bytearray(f.read())

    # 2) Iteramos los parches y los aplicamos uno a uno.
    for offset, original, replacement, description in patches:
        # Extraemos los bytes actuales en la posición indicada.
        actual = data[offset:offset + len(original)]

        # Verificación: si lo que hay en disco no coincide con la expectativa
        # (original) abortamos la operación para evitar dañar el binario.
        if actual != bytearray(original):
            print(f"  [ERROR] {label}: se esperaban los bytes {bytes(original).hex()} "
                  f"en 0x{offset:x}, pero se encontraron {bytes(actual).hex()}")
            sys.exit(1)

        # Reemplazamos en el buffer los bytes antiguos por los nuevos.
        data[offset:offset + len(replacement)] = bytearray(replacement)

        # Notificamos qué cambio hemos hecho (offset en hex, bytes antes/después,
        # y una breve descripción útil para auditoría).
        print(f"  [{label}] 0x{offset:04x}: {bytes(original).hex()} "
              f"→ {bytes(replacement).hex()}  ({description})")

    # 3) Aseguramos que la carpeta de destino exista y escribimos el archivo.
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    with open(dst_path, 'wb') as f:
        f.write(data)

    # 4) Ajustamos permisos para que sea ejecutable por conveniencia.
    os.chmod(dst_path, 0o755)

    # Mensaje final por cada archivo parcheado.
    print(f"  [{label}] Escrito: {dst_path}\n")


def main():
    # Base: carpeta donde está este script. Esto permite ejecutar desde
    # cualquier directorio y usar rutas relativas coherentes.
    base = os.path.dirname(os.path.abspath(__file__))
    binary_dir = os.path.join(base, 'binary')

    # Nivel 1: NOP sobre 'jne' para saltar la comprobación de strcmp.
    patch_binary(
        src_path=os.path.join(binary_dir, 'level1'),
        dst_path=os.path.join(base, 'level1', 'level1_patched'),
        patches=[
            (
                0x1244,
                [0x0f, 0x85, 0x16, 0x00, 0x00, 0x00],
                [0x90, 0x90, 0x90, 0x90, 0x90, 0x90],
                'jne -> 6×NOP: saltar la rama de fallo de strcmp'
            ),
        ],
        label='level1'
    )

    # Nivel 2 (opción A): redirección del handler de fallo a ok() via jmp rel32.
    patch_binary(
        src_path=os.path.join(binary_dir, 'level2'),
        dst_path=os.path.join(base, 'level2', 'level2_patched_failredir'),
        patches=[
            (
                0x1220,
                [0x55, 0x89, 0xe5, 0x53, 0x83],
                [0xe9, 0x7b, 0x00, 0x00, 0x00],
                'jmp rel32 -> ok() (redirigir no() a ok())'
            ),
        ],
        label='level2-failredir'
    )

    # Nivel 2 (opción B): NOPs sobre los JNE críticos.
    patch_binary(
        src_path=os.path.join(binary_dir, 'level2'),
        dst_path=os.path.join(base, 'level2', 'level2_patched'),
        patches=[
            (
                0x146d,
                [0x0f, 0x85, 0x0d, 0x00, 0x00, 0x00],
                [0x90, 0x90, 0x90, 0x90, 0x90, 0x90],
                'jne -> 6×NOP: saltar la comprobación final de strcmp'
            ),
            (
                0x13f3,
                [0x0f, 0x85, 0x05, 0x00, 0x00, 0x00],
                [0x90, 0x90, 0x90, 0x90, 0x90, 0x90],
                'jne -> 6×NOP: saltar la comprobación temprana de formato'
            ),
        ],
        label='level2'
    )

    # Nivel 3: forzar condición mediante xor y saltar una comprobación temprana.
    patch_binary(
        src_path=os.path.join(binary_dir, 'level3'),
        dst_path=os.path.join(base, 'level3', 'level3_patched'),
        patches=[
            (
                0x14a5,
                [0x85, 0xc0],
                [0x31, 0xc0],
                'test eax,eax -> xor eax,eax: forzar eax=0 (condición de éxito)'
            ),
            (
                0x1408,
                [0x0f, 0x85, 0x05, 0x00, 0x00, 0x00],
                [0x90, 0x90, 0x90, 0x90, 0x90, 0x90],
                'jne -> 6×NOP: saltar comprobación temprana de formato'
            ),
        ],
        label='level3'
    )

    # Nivel 3 (opcional): redirección del handler de fallo a handler de éxito.
    patch_binary(
        src_path=os.path.join(binary_dir, 'level3'),
        dst_path=os.path.join(base, 'level3', 'level3_patched_failredir'),
        patches=[
            (
                0x12e0,
                [0x55, 0x48, 0x89, 0xe5, 0x48],
                [0xe9, 0x1b, 0x00, 0x00, 0x00],
                'jmp rel32 -> handler éxito (redirigir fail a success)'
            ),
        ],
        label='level3-failredir'
    )

    # Mensajes finales en español indicando que la operación ha terminado.
    print("Todos los parches se han aplicado correctamente.")
    print("Los binarios parcheados requieren el mismo entorno de ejecución que los originales")
    print("(librerías 32-bit para level1/level2, librerías 64-bit para level3).")


if __name__ == '__main__':
    main()
