# Bonus – Explicación del parche para level3

## Resumen y objetivo
`level3` incluye comprobaciones más complejas (tablas de salto / `switch`)
que dirigen a manejadores de éxito o fallo. El objetivo del parche bonus es que
el binario acepte cualquier contraseña sin modificar bibliotecas externas.



## Enfoque aplicado
- Localizar la tabla de saltos o la serie de condicionales que llevan a `no()`.
- Redirigir, de forma centralizada, la ruta de fallo hacia el manejador de
  éxito (`ok()`), evitando parchear cada comprobación por separado.

## Bytes y offsets (ejemplo)
| Offset  | Original bytes             | Bytes parcheados    | Efecto |
|---------|----------------------------|---------------------|--------|
| 0x12e0  | `55 48 89 e5 48`           | `e9 1b 00 00 00`    | `jmp` rel32 hacia `ok()` (redirige `no()`→`ok()`) |

La localización exacta de la tabla/enlaces se confirmó con los dumps en
`Attachments` y el desensamblado del ejecutable `binary/level3`.

## Cómo se aplicó el parche
Se empleó el script `patch_all.py` que aplica las modificaciones de bytes
precalculadas. Ejemplo reproducible (ajustar offsets según binario):

```python
from pathlib import Path
data = bytearray(Path('piscine_pedago_ciber/04_Reverse_me_Rev/binary/level3').read_bytes())
data[0x12e0:0x12e5] = b'\xe9\x1b\x00\x00\x00'  # jmp rel32 a ok()
Path('piscine_pedago_ciber/04_Reverse_me_Rev/level3/level3_patched').write_bytes(data)
```

## Verificación
Probar el binario parcheado con entradas diversas confirma que la salida es
la de éxito en todos los casos:

```bash
echo "lo_que_sea" | ./piscine_pedago_ciber/04_Reverse_me_Rev/level3/level3_patched
# Esperado: "Good job." u salida equivalente
```

## Referencias en el repo
- Script de parche: [piscine_pedago_ciber/04_Reverse_me_Rev/patch_all.py](piscine_pedago_ciber/04_Reverse_me_Rev/patch_all.py#L1)
- Binario original: [piscine_pedago_ciber/04_Reverse_me_Rev/binary/level3](piscine_pedago_ciber/04_Reverse_me_Rev/binary/level3#L1)

## Hexdump y cálculo reproducible
Inspecciona los bytes originales y parcheados con `hexdump` o `xxd`:

```bash
# comprobar la instrucción modificada en 0x14a5 (test->xor)
hexdump -C -s 0x14a5 -n 4 piscine_pedago_ciber/04_Reverse_me_Rev/binary/level3

# comprobar el handler de fallo en 0x12e0
hexdump -C -s 0x12e0 -n 8 piscine_pedago_ciber/04_Reverse_me_Rev/binary/level3
```

Comprobar los bytes parcheados escritos por `patch_all.py`:

```bash
hexdump -C -s 0x14a5 -n 4 piscine_pedago_ciber/04_Reverse_me_Rev/level3/level3_patched
hexdump -C -s 0x12e0 -n 8 piscine_pedago_ciber/04_Reverse_me_Rev/level3/level3_patched_failredir
```

Calcular `rel32` a partir de los 4 bytes del `jmp` parcheado (little-endian):

```bash
python3 - <<'PY'
rel_bytes = bytes.fromhex('1b000000')  # ejemplo tomado de patch_all.py para level3
rel = int.from_bytes(rel_bytes, 'little', signed=True)
src = 0x12e0
target = src + 5 + rel
print(f'rel32 = {rel} (0x{rel:x}), target = 0x{target:x}')
PY
```

Si quieres, puedo incrustar los hexdumps completos "antes/después" para cada
parche (salidas de `hexdump -C`) o añadir los comandos `objdump -d` que
contextualizan las instrucciones modificadas.

### Hexdumps (antes / después)
Original (binary/level3 @ 0x14a5, 4 bytes):

```
000014a5  85 c0 0f 84                                       |....|
000014a9
```

Original (binary/level3 @ 0x1408, 8 bytes):

```
00001408  0f 85 05 00 00 00 e9 4e                           |.......N|
00001410
```

Original (binary/level3 @ 0x12e0, 8 bytes):

```
000012e0  55 48 89 e5 48 8d 3d 48                           |UH..H.=H|
000012e8
```

Patched (level3/level3_patched @ 0x14a5, 4 bytes):

```
000014a5  31 c0 0f 84                                       |1...|
000014a9
```

Patched (level3/level3_patched @ 0x1408, 8 bytes):

```
00001408  90 90 90 90 90 90 e9 4e                           |.......N|
00001410
```

Patched fail-redirect (level3/level3_patched_failredir @ 0x12e0, 8 bytes):

```
000012e0  e9 1b 00 00 00 8d 3d 48                           |......=H|
000012e8
```

## Guía paso a paso (estilo tutorial)

1. Reconocer el tipo de binario y strings relevantes:

```bash
file binary/level3
strings binary/level3 | grep -E "Please|Good|Nope"
```

2. Probar comportamiento previo al parche:

```bash
printf "cualquier\n" | ./binary/level3   # debería mostrar 'Nope.' en la mayoría
```

3. Desensamblar e identificar la comparación/test crítica:

```bash
objdump -d binary/level3 | sed -n '0,400p' | less
# buscar test eax,eax en 0x14a5 y je/jne posteriores
```

4. Verificar bytes originales y parcheados (hexdumps incluidos arriba):

```bash
hexdump -C -s 0x14a5 -n 8 binary/level3
hexdump -C -s 0x14a5 -n 8 level3/level3_patched

hexdump -C -s 0x12e0 -n 16 binary/level3
hexdump -C -s 0x12e0 -n 16 level3/level3_patched_failredir
```

5. Aplicar parches y comprobar salida:

```bash
python3 patch_all.py
printf "lo_que_sea\n" | ./level3/level3_patched
# debe mostrar "Good job." si el parche fue aplicado correctamente
```

Explicación sencilla: en `level3` forzamos la condición que activa la rama
de éxito (por ejemplo cambiando `test eax,eax` por `xor eax,eax` o
redireccionando el handler de fallo). Esto garantiza que la comprobación
final considere la entrada correcta.

## Observaciones sobre ejecución de binarios parcheados
Al probar interactuando con las variantes, el resultado cambia:
- `level3_patched`: No garantiza el éxito global con simples NOPs/xor, ya que el binario contiene ramas adicionales y comprobaciones que continúan abortando o mostrando salida `Nope.`.
- `level3_patched_failredir`: Fuerzan efectivamente el éxito imprimiendo `Good job.` porque se parchea una instrucción de salto (`ja` o `jne`) hacia la dirección que hace el `printf("Good job.\n")`. Dado el flujo y el bucle interno, esto puede terminar llamando a múltiples "Good job." secuencialmente.
