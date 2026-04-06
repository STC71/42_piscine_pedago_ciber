#!/bin/bash

# Desactivar cualquier entorno virtual previo (ignora errores si no hay ninguno activado)
deactivate 2>/dev/null || true

# Crear un entorno virtual de Python en el directorio .venv
python3 -m venv .venv

# Activar el entorno virtual
source .venv/bin/activate

# Instalar las dependencias especificadas en requirements.txt
pip install -r requirements.txt