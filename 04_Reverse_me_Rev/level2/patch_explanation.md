# Bonus – Explicación del parche para level2

## Resumen y objetivo
La implementación incluye la parte *mandatory* y el *bonus*. El parche
permite que `level2` acepte cualquier contraseña sin tocar librerías externas.



## Enfoque aplicado
1. Parche mínimo: convertir el `jne` que decide la ruta final en NOPs para forzar
	la ejecución de `ok()` (ruta de éxito).
2. Parche adicional (robusto para el bonus): redirigir el handler de fallo
	(`no()`) hacia el handler de éxito (`ok()`), de forma que cualquier llamada
	a `no()` termine ejecutando `ok()`.

## Bytes y offsets
| Offset | Bytes originales     | Bytes parcheados    | Efecto |
|--------|----------------------|---------------------|--------|
| 0x146d | `0f 85 0d 00 00 00`  | `90 90 90 90 90 90` | `jne` → NOPs (siempre ok())
| 0x1220 | `55 89 e5 53 83`     | `e9 7b 00 00 00`    | `jmp` rel32 a `ok()` (redirige `no()`→`ok()`)

Los offsets se localizaron con las herramientas de desensamblado y los volcados
en `Attachments`.

## Cómo se aplicó el parche
Se usó `patch_all.py` para aplicar los bytes concretos. Alternativamente:

```python
from pathlib import Path
data = bytearray(Path('piscine_pedago_ciber/04_Reverse_me_Rev/binary/level2').read_bytes())
data[0x146d:0x1473] = b'\x90' * 6
data[0x1220:0x1225] = b'\xe9\x7b\x00\x00\x00'  # jmp rel32 (ajustar según reloc)
Path('piscine_pedago_ciber/04_Reverse_me_Rev/level2/level2_patched').write_bytes(data)
```

## Guía paso a paso (estilo tutorial)

1. Inspección rápida:

```bash
file binary/level2
strings binary/level2 | grep -E "Please|Good|Nope|delabere"
```

2. Probar entrada simple:

```bash
printf "delabere\n" | ./binary/level2   # debe fallar
```

3. Desensamblar y localizar validaciones y bucle de decodificación:

```bash
objdump -d binary/level2 | sed -n '0,300p' | less
# buscar cmp/jne alrededor de 0x132c, 0x13f3, 0x146d
```

4. Comprobar bytes originales y parcheados (hexdumps ya incluidos arriba):

```bash
hexdump -C -s 0x1220 -n 16 binary/level2
hexdump -C -s 0x1220 -n 16 level2/level2_patched_failredir

hexdump -C -s 0x146d -n 16 binary/level2
hexdump -C -s 0x146d -n 16 level2/level2_patched
```

5. Reproducir parche y verificar salida:

```bash
python3 patch_all.py
printf "00101108097098101114101\n" | ./level2/level2_patched
# debe mostrar "Good job."
```

Explicación sencilla: el parche principal neutraliza el `jne` final para forzar
la ejecución de `ok()`; los parches adicionales redirigen manejadores de fallo
o eliminan comprobaciones tempranas que impedirían entradas no conformes.
Nota: el `jmp rel32` debe calcularse con el desplazamiento correcto según el
layout del binario; `patch_all.py` aplica los valores ya calculados.

## Verificación

```bash
echo "cualquier" | ./piscine_pedago_ciber/04_Reverse_me_Rev/level2/level2_patched
# Esperado: salida de éxito "Good job." o equivalente
```

## Referencias en el repo
- Script de parche: [piscine_pedago_ciber/04_Reverse_me_Rev/patch_all.py](piscine_pedago_ciber/04_Reverse_me_Rev/patch_all.py#L1)
- Binario original: [piscine_pedago_ciber/04_Reverse_me_Rev/binary/level2](piscine_pedago_ciber/04_Reverse_me_Rev/binary/level2#L1)

## Hexdump y cálculo de `rel32` reproducible
Inspecciona los bytes originales y parcheados con `hexdump`/`xxd`:

```bash
# around handler redirection (offset 0x1220)
hexdump -C -s 0x1220 -n 8 piscine_pedago_ciber/04_Reverse_me_Rev/binary/level2

# around final jne (offset 0x146d)
hexdump -C -s 0x146d -n 8 piscine_pedago_ciber/04_Reverse_me_Rev/binary/level2
```

Verificar los bytes parcheados escritos por `patch_all.py`:

```bash
hexdump -C -s 0x1220 -n 8 piscine_pedago_ciber/04_Reverse_me_Rev/level2/level2_patched_failredir
hexdump -C -s 0x146d -n 8 piscine_pedago_ciber/04_Reverse_me_Rev/level2/level2_patched
```

Calcular el `rel32` usado en `jmp` (ejemplo con los bytes que muestra el script `patch_all.py`):

```bash
python3 - <<'PY'
src = 0x1220
rel = int.from_bytes(bytes.fromhex('7b000000'), 'little', signed=True)
target = src + 5 + rel
print(f'rel32 = {rel} (0x{rel:x}), jump target = 0x{target:x}')
PY
```

Comando para imprimir en little-endian el `rel32` calculado (lista de bytes listos para parchear):

```bash
python3 - <<'PY'
rel = (0x12a0 - (0x1220 + 5))  # ejemplo: target 0x12a0
print(rel.to_bytes(4, 'little', signed=True).hex())
PY
```

Nota: sustituye `0x12a0` por el destino real si calculas el `target` desde el desensamblado.

### Hexdumps (antes / después)
Original (binary/level2 @ 0x1220, 8 bytes):

```
00001220  55 89 e5 53 83 ec 14 e8                           |U..S....|
00001228
```

Original (binary/level2 @ 0x146d, 8 bytes):

```
0000146d  0f 85 0d 00 00 00 8b 5d                           |.......]|
00001475
```

Original (binary/level2 @ 0x13f3, 8 bytes):

```
000013f3  0f 85 05 00 00 00 e9 4c                           |.......L|
000013fb
```

Patched (level2/level2_patched_failredir @ 0x1220, 8 bytes):

```
00001220  e9 7b 00 00 00 ec 14 e8                           |.{......|
00001228
```

Patched (level2/level2_patched @ 0x146d, 8 bytes):

```
0000146d  90 90 90 90 90 90 8b 5d                           |.......]|
00001475
```

Patched (level2/level2_patched @ 0x13f3, 8 bytes):

```
000013f3  90 90 90 90 90 90 e9 4c                           |.......L|
000013fb
```

## Observaciones sobre ejecución de binarios parcheados
Al probar con una entrada arbitraria (p. ej., `printf 'anything\n' | ./level2_patched`):
- `level2_patched` (NOP simple): puede seguir devolviendo `Nope.` ya que la longitud y prefijo también se comprueban, y el NOPeo único no fuerza todas las comprobaciones pre-condicionales al éxito de la rama principal.
- `level2_patched_failredir` (Redirección de salto): imprime `Good job.` (posiblemente varias veces) porque el salto que enviaba el flujo al texto de fallo ("Nope.") se ha sobrescrito con un salto hacia el código que imprime el éxito ("Good job.").
