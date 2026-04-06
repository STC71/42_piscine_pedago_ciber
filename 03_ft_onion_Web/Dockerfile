# ============================================================================
#  FT_ONION - DOCKERFILE MULTIETAPA (Orquestado con Python3)
# ============================================================================
#  Servicio oculto Tor con Python3 como orquestador de procesos
#  Compilación optimizada sobre Debian:bookworm
# ============================================================================

# Etapa 1: imagen base con todas las dependencias del sistema
FROM debian:bookworm-slim AS base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    nginx \
    tor \
    openssh-server \
    openssh-client \
    curl \
    wget \
    nano \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo de la aplicación
WORKDIR /app

# Etapa 2: compilación de dependencias de Python
FROM base AS builder

COPY src/requirements.txt .
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Etapa 3: imagen final de ejecución
FROM base AS final

LABEL maintainer="42 Student" \
      description="ft_onion - Tor Hidden Service" \
      version="1.0.0"

# Copiar entorno virtual de Python compilado desde la etapa de compilación
COPY --from=builder /opt/venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH

# Crear usuario sin privilegios para Tor y la aplicación
RUN useradd -m -s /bin/bash -d /var/lib/tor tor 2>/dev/null || true && \
    useradd -m -s /bin/bash user 2>/dev/null || true && \
    echo "user:password" | chpasswd && \
    usermod -aG sudo user 2>/dev/null || true

# Crear directorios requeridos con permisos adecuados
RUN mkdir -p /var/run/sshd \
    /var/lib/tor/hidden_service \
    /var/www/html \
    /app/logs \
    /app/config

# Copiar archivos mandatory desde la raíz del repositorio
COPY nginx.conf /etc/nginx/nginx.conf
COPY torrc /etc/tor/torrc
COPY sshd_config /etc/ssh/sshd_config
COPY index.html /var/www/html/index.html

# Copiar código de la aplicación FastAPI
# COPY src/app /app/app
COPY src/*.py /app/

# Script de entrada para orquestación de servicios
COPY src/setup.sh /app/setup.sh
RUN chmod +x /app/setup.sh

# Establecer permisos y propietarios correctos
RUN chown -R debian-tor:debian-tor /var/lib/tor \
    /etc/tor/torrc && \
    chmod 700 /var/lib/tor/hidden_service && \
    chmod 600 /etc/tor/torrc && \
    chmod 644 /etc/ssh/sshd_config && \
    chmod 755 /app && \
    chmod 644 /var/www/html/index.html

# Puerto SSH para administración remota
EXPOSE 4242

# Puertos internos (no expuestos externamente)
EXPOSE 80 9000

# Verificación de salud del contenedor
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Punto de entrada: orquestador de procesos en Python
ENTRYPOINT ["/bin/bash"]
CMD ["/app/setup.sh"]
