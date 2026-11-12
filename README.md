# Laboratorio: bucket S3 seguro con Terraform + LocalStack

Actividad 3 de Ciberseguridad. Todo corre en localhost; no se usa AWS real.

## Requisitos
Docker Desktop, Docker Compose v2, Terraform y AWS CLI v2.

## Ejecución
1. `export LOCALSTACK_AUTH_TOKEN="<tu token>"` (no lo subas a Git).
2. `docker compose up -d` y verifica que el contenedor esté `healthy`.
3. `terraform init && terraform validate && terraform plan` (3 recursos) y `terraform apply`.
4. Verificaciones con AWS CLI usando `--endpoint-url http://localhost:4566`.

## Remediación de contenedores
`docker compose -f compose.hardened.yaml up -d --build`
