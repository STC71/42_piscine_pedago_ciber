# 🕵️‍♂️  Reverse me — Reto de Reverse Engineering

Repositorio con 3 binarios para reversing y un bonus que demuestra parches directos sobre la sección `.text`.

Resumen rápido

```bash
# Ejecutar pruebas rápidas
python3 -m pip install -r requirements.txt  # si procede
python3 patch_all.py                        # reproduce los parches (bonus)
```

Estructura principal

```
04_Reverse_me_Rev/
├── binary/              # Binarios originales (no modificados)
├── level1/              # Nivel 1: fuente reconstruida, password, patch
├── level2/              # Nivel 2
├── level3/              # Nivel 3
└── patch_all.py         # Script que aplica los parches (bonus)
```

Quick start

1. Inspecciona los binarios con `strings`, `file`, `objdump -d`.
2. Extrae cadenas y páginas de datos: `objdump -s -j .rodata`.
3. Para aplicar los parches de ejemplo: `python3 patch_all.py`.

Detalles por nivel (expandir para ver más)

<details>
<summary><strong>Nivel 1 — ELF 32-bit x86 (fácil)</strong></summary>

- Algoritmo: cadena fija `__stack_check` en `.rodata`, copia a pila y `strcmp`.
- Contraseña: `__stack_check`.
- Herramientas: `objdump -d`, `objdump -s -j .rodata`, `gdb`, `strings`.

</details>

<details>
<summary><strong>Nivel 2 — ELF 32-bit x86 (medio)</strong></summary>

- Algoritmo: lectura hasta 23 chars; verifica prefijo `00`; interpreta grupos de 3 dígitos como valores ASCII para reconstruir la cadena objetivo (`delabere`).
- Contraseña: `00101108097098101114101` (ver `level2/` para derivación).

</details>

<details>
<summary><strong>Nivel 3 — ELF 64-bit x86-64 (difícil)</strong></summary>

- Algoritmo: misma codificación que nivel 2 con prefijo `42` y objetivo formado por `'*'` (42).
- Contraseña: `42042042042042042042042`.

</details>

Bonus — Parches binarios

- Técnica: modificamos la sección `.text` (bytes concretos) para cambiar el control de flujo y forzar salida "Good job.".
- Resumen de parches: `level1` (NOP `jne`), `level2` (NOP `jne`), `level3` (`test` → `xor eax,eax`).

Cómo reproducir los parches

```bash
python3 patch_all.py
```

Consejos para la defensa

- Documenta la derivación de la contraseña y las instrucciones `objdump`/`gdb` clave.
- Muestra el flujo de control y por qué el parche cambia el comportamiento.

---

**Documentación y parches**

- **Explicaciones de parche (detalladas)**:
	- [Nivel 1 — patch_explanation.md](level1/patch_explanation.md#L1)
	- [Nivel 2 — patch_explanation.md](level2/patch_explanation.md#L1)
	- [Nivel 3 — patch_explanation.md](level3/patch_explanation.md#L1)

- **Script de parche**: [patch_all.py](patch_all.py#L1)

- **Comandos reproducibles (hexdumps + verificación)**

```bash
# aplicar parches (genera los binarios en level1/, level2/, level3/)
python3 patch_all.py

# hexdump ejemplo: comparar 6 bytes en level1 antes/después (offset 0x1244)
hexdump -C -s 0x1244 -n 6 binary/level1
hexdump -C -s 0x1244 -n 6 level1/level1_patched

# calcular rel32 (ejemplo) y mostrar bytes little-endian
python3 - <<'PY'
rel = (0x12a0 - (0x1220 + 5))  # sustituir destino real
print(rel.to_bytes(4, 'little', signed=True).hex())
PY
```

- **Hexdumps incrustados**: cada `patch_explanation.md` incluye volcados
	"antes/después" ya generados para los offsets parcheados, junto con los
	comandos `hexdump` y pequeños snippets Python utilizados para verificar y
	calcular `rel32`.


**Documentación y parches (organizado)**

- Resumen: la carpeta contiene los binarios originales (`binary/`), las
	explicaciones de parche por nivel (`level1/..`), y el script
	`patch_all.py` que aplica los parches demostrativos (bonus).

- Enlaces rápidos:
	- `patch_all.py` — script que aplica y valida los parches. [patch_all.py](patch_all.py#L1)
	- `level1/patch_explanation.md` — explicación, offsets y hexdumps. [level1/patch_explanation.md](level1/patch_explanation.md#L1)
	- `level2/patch_explanation.md` — explicación, offsets y hexdumps. [level2/patch_explanation.md](level2/patch_explanation.md#L1)
	- `level3/patch_explanation.md` — explicación, offsets y hexdumps. [level3/patch_explanation.md](level3/patch_explanation.md#L1)

- Cómo reproducir los parches (rápido):

```bash
# desde la raíz del proyecto
python3 patch_all.py

# los binarios parcheados aparecerán en level1/, level2/, level3/
```

- Comprobaciones y verificación (ejemplos útiles):

```bash
# mostrar bytes antes/después (hexdump)
hexdump -C -s 0x1244 -n 6 binary/level1
hexdump -C -s 0x1244 -n 6 level1/level1_patched

# comprobar un parche rel32: leer 4 bytes y calcular destino
python3 - <<'PY'
from pathlib import Path
data = Path('level2/level2_patched_failredir').read_bytes()
rel = int.from_bytes(data[0x1221:0x1225], 'little', signed=True)
src = 0x1220
print(hex(src + 5 + rel))
PY
```

- Notas importantes:
	- `level1` y `level2` son ELF 32-bit; `level3` es ELF 64-bit. Ejecuta en un
		entorno con las librerías compatibles.
	- `patch_all.py` valida los bytes esperados antes de parchear — si cambias
		los binarios originales, los offsets pueden fallar.


