# Use Python 3.11 slim como base
FROM python:3.11-slim

# Define o diretório de trabalho
WORKDIR /app

# Variáveis de ambiente para otimização do Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Copia apenas o arquivo de requisitos primeiro (para cache de layer)
COPY requirements.txt .

# Instala as dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia o resto da aplicação
COPY . .

# Cria o diretório para métricas Prometheus
RUN mkdir -p /tmp/prometheus_multiproc && \
    chmod 777 /tmp/prometheus_multiproc

# Cria usuário não-root para executar a aplicação
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app /tmp/prometheus_multiproc

# Muda para o usuário não-root
USER appuser

# Expõe a porta da aplicação
EXPOSE 8000

# Comando para executar a aplicação com Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "main:app"]
