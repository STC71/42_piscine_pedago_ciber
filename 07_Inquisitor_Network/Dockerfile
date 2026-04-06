# Usamos una imagen base oficial de Python 3.12, versión 'slim' para que sea más ligera
FROM python:3.12-slim

# Establecemos el directorio de trabajo dentro del contenedor
WORKDIR /workspace

# Actualizamos los repositorios e instalamos herramientas de red básicas
# --no-install-recommends evita instalar paquetes adicionales innecesarios
# rm -rf ... limpia la caché de apt para reducir el tamaño final de la imagen
RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 \
    tcpdump \
    iptables \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Copiamos el archivo de dependencias de Python al contenedor
COPY requirements.txt .
# Instalamos las dependencias de Python especificadas en requirements.txt sin usar caché para ahorrar espacio
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos nuestro script del inquisitor al contenedor
COPY inquisitor .
# Damos permisos de ejecución al script copiado
RUN chmod +x inquisitor

# Comando por defecto: mantiene el contenedor vivo indefinidamente leyendo /dev/null
CMD ["tail", "-f", "/dev/null"]
