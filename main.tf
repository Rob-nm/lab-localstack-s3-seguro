# Recurso 1: el bucket
resource "aws_s3_bucket" "seguro" {
  bucket = "actividad3-seguro-local"
}

# Recurso 2: cifrado en reposo SSE-S3 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "cifrado" {
  bucket = aws_s3_bucket.seguro.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Recurso 3: los cuatro controles de bloqueo de acceso público
resource "aws_s3_bucket_public_access_block" "bloqueo" {
  bucket = aws_s3_bucket.seguro.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
