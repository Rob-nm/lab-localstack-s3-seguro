# Dockerfile fortificado (remediación)
FROM python:3.12-slim

# Crear usuario sin privilegios (UID fijo, sin shell de login)
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser

WORKDIR /app
COPY app/app.py /app/app.py

# Ejecutar como usuario no privilegiado: evita correr como root
USER appuser

EXPOSE 8080
CMD ["python", "/app/app.py"]
