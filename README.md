Laboratorio: bucket S3 seguro con Terraform + LocalStack

Actividad 3 de Ciberseguridad (Tecmilenio). Este repositorio crea un bucket S3 simulado con cifrado AES256 y los cuatro bloqueos de acceso público, y permite comprobar qué quedó realmente configurado.

Todo corre en tu propia computadora (localhost). No se usa AWS real y no se necesita una cuenta de AWS.

Terraform  ──►  LocalStack (contenedor Docker, puerto 4566)  ──►  Bucket S3 simulado
 (tú declaras)       (simula AWS, solo en localhost)               (cifrado AES256 + bloqueo público x4)
Contenido del repositorio
Archivo	Para qué sirve
compose.yaml	Levanta LocalStack (solo S3, puerto 4566 solo en localhost).
providers.tf	Configura el proveedor AWS de Terraform apuntando a LocalStack, con credenciales ficticias.
main.tf	Define los 3 recursos: bucket, cifrado AES256 y bloqueo de acceso público.
.terraform.lock.hcl	Fija la versión del proveedor para que otra persona obtenga la misma.
Dockerfile, app/app.py, compose.hardened.yaml	Propuesta de remediación: contenedor con usuario sin privilegios, sistema de archivos de solo lectura y puerto solo en localhost.
.gitignore	Evita subir secretos y archivos generados (.env, *.tfstate, .terraform/).
Requisitos
Docker Desktop (incluye Docker Compose v2) abierto y en ejecución.
Terraform.
AWS CLI v2.
Una cuenta gratuita de LocalStack (plan Hobby) y su token de autenticación. Verifica en la página oficial de precios que el plan siga siendo gratuito.

Instalación en macOS con Homebrew:

bash
brew install --cask docker
brew tap hashicorp/tap && brew install hashicorp/tap/terraform
brew install awscli

En Windows o Linux usa los instaladores oficiales de cada herramienta (Docker, Terraform y AWS CLI).

Paso a paso
1. Verifica las herramientas
bash
docker --version
docker compose version
terraform version
aws --version

Abre Docker Desktop y espera a que indique que está en ejecución.

2. Descarga el proyecto
bash
git clone https://github.com/Rob-nm/lab-localstack-s3-seguro.git
cd lab-localstack-s3-seguro

(Sustituye la URL por la de este repositorio.)

3. Comprueba que el puerto 4566 esté libre
bash
lsof -i :4566

Si no imprime nada, está libre.

4. Configura tu token de LocalStack

En la misma terminal donde vas a trabajar:

bash
export LOCALSTACK_AUTH_TOKEN="pega_tu_token_aqui"

El token es un secreto. No lo escribas en ningún archivo, no lo subas a GitHub ni lo muestres en capturas. Si cierras la terminal, repite este paso.

5. Levanta LocalStack
bash
docker compose up -d
docker compose ps

Espera hasta que el estado diga (healthy) (puede tardar uno o dos minutos la primera vez). Luego comprueba el endpoint de salud:

bash
curl http://localhost:4566/_localstack/health

Debe aparecer "s3": "running" o "s3": "available". Los demás servicios aparecen como "disabled" porque el contenedor se inicia solo con S3.

6. Crea el bucket con Terraform
bash
terraform init
terraform validate
terraform plan
terraform apply
plan es una vista previa: debe terminar con Plan: 3 to add, 0 to change, 0 to destroy.
apply crea los recursos. Escribe yes cuando lo pida. Debe terminar con Apply complete! Resources: 3 added.
7. Verifica con AWS CLI

Primero unas credenciales ficticias (para que el CLI no use ninguna cuenta real):

bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

Después, siempre indicando el endpoint local:

bash
aws --endpoint-url http://localhost:4566 s3 ls
aws --endpoint-url http://localhost:4566 s3api get-bucket-encryption --bucket actividad3-seguro-local
aws --endpoint-url http://localhost:4566 s3api get-public-access-block --bucket actividad3-seguro-local

Resultado esperado: el bucket actividad3-seguro-local, cifrado AES256 y los cuatro controles (BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy, RestrictPublicBuckets) en true.

8. Sube un archivo de prueba
bash
echo "archivo de prueba actividad 3" > prueba.txt
aws --endpoint-url http://localhost:4566 s3 cp prueba.txt s3://actividad3-seguro-local/
aws --endpoint-url http://localhost:4566 s3 ls s3://actividad3-seguro-local/
9. Prueba el acceso anónimo

Intenta descargar el archivo sin firmar la solicitud:

bash
aws --endpoint-url http://localhost:4566 s3 cp s3://actividad3-seguro-local/prueba.txt descarga.txt --no-sign-request

Registra el resultado real, sea permitido o denegado. En este laboratorio la descarga fue permitida, aunque el bucket tiene los cuatro bloqueos: LocalStack no replica necesariamente todas las reglas de autorización de AWS. Es una limitación del simulador y no demuestra que el bucket sea realmente público en AWS.

10. Consulta la política del bucket
bash
aws --endpoint-url http://localhost:4566 s3api get-bucket-policy --bucket actividad3-seguro-local

Lo esperado es NoSuchBucketPolicy: significa que no hay una política personalizada. No confirma si el bucket es público o privado.

11. (Opcional) Dashboard de LocalStack

Abre el Dashboard de LocalStack en el navegador de la misma computadora donde corre Docker, configura el endpoint http://localhost:4566, entra al explorador de S3 y localiza el bucket.

12. (Opcional) Prueba la propuesta de remediación
bash
docker compose -f compose.hardened.yaml up -d --build
docker compose -f compose.hardened.yaml ps
13. Limpieza
bash
terraform destroy
docker compose down
docker compose -f compose.hardened.yaml down
Problemas frecuentes
Problema	Causa y solución
variable LOCALSTACK_AUTH_TOKEN is not set	Se perdió el export. Repite el paso 4 en la misma terminal.
El contenedor queda unhealthy	La imagen de LocalStack no incluye curl; el compose.yaml ya usa Python para el chequeo de salud. Revisa con docker inspect --format='{{json .State.Health}}' localstack.
NoSuchBucket al consultar	El bucket aún no existe (falta terraform apply) o se recreó el contenedor: LocalStack no guarda datos entre reinicios. Ejecuta terraform apply de nuevo.
Error de YAML al levantar	Indentación incorrecta en compose.yaml (YAML usa espacios, no tabulaciones).
El puerto 4566 está ocupado	Detén el proceso que lo usa (lsof -i :4566) o el contenedor anterior (docker compose down).
Seguridad
El puerto 4566 se publica solo en 127.0.0.1, no en toda la red.
Solo se habilita el servicio S3 para reducir la superficie de ataque.
No se monta /var/run/docker.sock: S3 no lo necesita y montarlo facilitaría un escape de contenedor.
Las credenciales de AWS son ficticias y el token de LocalStack se pasa por variable de entorno.
No subas a Git: tokens, contraseñas, .env ni *.tfstate.
No apuntes estos comandos a una cuenta real de AWS.
