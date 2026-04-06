# Bonus – Explicación del parche para level1

## Resumen y objetivo
Hemos implementado la parte *mandatory* y la parte *bonus* para `level1`. El
objetivo del parche (bonus) es que el binario acepte cualquier contraseña
sin modificar bibliotecas externas ni usar `LD_PRELOAD`.



## Idea del parche
Después de la comparación `strcmp(input, ref)` el resultado queda en `%eax`.
Si `%eax == 0` se continúa hacia `ok()`; si `%eax != 0` hay un `jne` que salta
a la ruta de fallo. Convertir ese `jne` en NOPs fuerza siempre la ejecución
hacia `ok()` independientemente de la entrada.

## Bytes y offsets relevantes (ejemplo real)
| Offset | Bytes originales     | Bytes parcheados    | Efecto |
|--------|----------------------|---------------------|--------|
| 0x1244 | `0f 85 16 00 00 00`  | `90 90 90 90 90 90` | `jne` → 6×`NOP` (fall-through a `ok()`)

Los offsets se obtuvieron comparando el desensamblado con el binario original
(`piscine_pedago_ciber/04_Reverse_me_Rev/binary/level1`) y confirmando la
instrucción condicional que controla la salida "Nope.".

## Cómo se aplicó el parche (herramienta reproducible)
Usamos `patch_all.py` en la raíz del proyecto para aplicar los cambios.
También vale este fragmento Python reproducible:

```python
from pathlib import Path
data = bytearray(Path('piscine_pedago_ciber/04_Reverse_me_Rev/binary/level1').read_bytes())
data[0x1244:0x1250] = b'\x90' * 6
Path('piscine_pedago_ciber/04_Reverse_me_Rev/level1/level1_patched').write_bytes(data)
```

## Verificación
Comprobar manualmente que cualquier contraseña produce la salida de éxito:

```bash
echo "cualquier_cosa" | ./piscine_pedago_ciber/04_Reverse_me_Rev/level1/level1_patched
# Resultado esperado: "Please enter key: Good job." (o flujo equivalente)
```

## Referencias dentro del repositorio
- Script de parche: [piscine_pedago_ciber/04_Reverse_me_Rev/patch_all.py](piscine_pedago_ciber/04_Reverse_me_Rev/patch_all.py#L1)
- Binario original: [piscine_pedago_ciber/04_Reverse_me_Rev/binary/level1](piscine_pedago_ciber/04_Reverse_me_Rev/binary/level1#L1)

## Hexdump y comandos reproducibles
Puedes inspeccionar los bytes originales y parcheados con `hexdump` o `xxd`.

Comprobar 6 bytes originales en `binary/level1` (offset 0x1244):

```bash
hexdump -C -s 0x1244 -n 6 piscine_pedago_ciber/04_Reverse_me_Rev/binary/level1
```

Comprobar 6 bytes parcheados en el binario resultante:

```bash
hexdump -C -s 0x1244 -n 6 piscine_pedago_ciber/04_Reverse_me_Rev/level1/level1_patched
```

Verificación rápida del parche con Python (muestra los 6 bytes en hex):

```bash
python3 - <<'PY'
from pathlib import Path
data = Path('piscine_pedago_ciber/04_Reverse_me_Rev/binary/level1').read_bytes()
print(data[0x1244:0x1250].hex())
data2 = Path('piscine_pedago_ciber/04_Reverse_me_Rev/level1/level1_patched').read_bytes()
print(data2[0x1244:0x1250].hex())
PY
```

Explicación rápida: los 6 bytes originales suelen ser `0f8501000000` (ejemplo)
y quedan reemplazados por `909090909090` (6×NOP). El script `patch_all.py`
ya valida que los bytes esperados están presentes antes de escribir el parche.

### Hexdumps (antes / después)
Original (binary/level1 @ 0x1244, 6 bytes):

```
00001244  0f 85 16 00 00 00                                 |......|
0000124a
```

Parcheado (level1/level1_patched @ 0x1244, 6 bytes):

```
00001244  90 90 90 90 90 90                                 |......|
0000124a
```

Si quieres, puedo añadir también el volcado completo (antes/después) embebido
en este documento.

## Guía paso a paso (estilo tutorial)
1. Inspeccionar el binario:

```bash
file binary/level1
strings binary/level1 | grep -E "Please|Good|Nope|__stack_check"
```

2. Confirmar comportamiento:

```bash
printf "prueba\n" | ./binary/level1   # debería mostrar "Nope."
printf "__stack_check\n" | ./binary/level1   # debería mostrar "Good job."
```

3. Localizar la instrucción condicional y comprobar bytes originales:

```bash
objdump -d binary/level1 | sed -n '0,200p' | less
hexdump -C -s 0x1244 -n 16 binary/level1
```

4. Aplicar parche reproducible (ya incluido en `patch_all.py`):

```bash
python3 patch_all.py

# comprobar bytes parcheados
hexdump -C -s 0x1244 -n 16 level1/level1_patched
```

5. Verificar resultado:

```bash
printf "algo\n" | ./level1/level1_patched  # ahora debe imprimir "Good job."
```

Explicaciones sencillas: buscamos la comparación (`strcmp`) seguida de un
`jne` que envía la ejecución a "Nope."; al convertir ese salto en `NOP` forzamos
el flujo hacia la rama de éxito.
