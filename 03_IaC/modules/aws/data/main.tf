data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  tags    = merge(var.tags, { Modulo = "aws-data" })
  buckets = { objetos = "objects", exportaciones = "exports" }
}

resource "aws_kms_key" "this" {
  description             = "${var.name} datos (RDS, S3, Backup)"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}-datos"
  target_key_id = aws_kms_key.this.key_id
}

# --- RDS PostgreSQL Multi-AZ (unico escritor en operacion normal) ---
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.data_subnet_ids
  tags       = local.tags
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-pg"
  family = "postgres${var.pg_major}"

  # Requeridos por la replicacion logica hacia OCI (reinicio necesario la primera vez).
  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "immediate"
  }
  tags = local.tags
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-pg"
  engine         = "postgres"
  engine_version = var.pg_major
  instance_class = var.db_instance_class
  db_name        = var.db_name
  username       = "pgadmin"

  # La clave maestra la crea y rota RDS en Secrets Manager: no pasa por Terraform ni por el estado.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.this.arn

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.allocated_storage_gb * 2
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.this.arn

  multi_az               = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  backup_retention_period         = 14
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.this.arn
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  auto_minor_version_upgrade      = true
  apply_immediately               = true

  deletion_protection       = var.protect_from_destroy
  skip_final_snapshot       = !var.protect_from_destroy
  final_snapshot_identifier = var.protect_from_destroy ? "${var.name}-pg-final" : null

  tags = local.tags
}

# --- Buckets S3 privados, versionados y cifrados ---
resource "aws_s3_bucket" "this" {
  for_each      = local.buckets
  bucket        = "${var.name}-${each.value}-${data.aws_caller_identity.current.account_id}"
  force_destroy = !var.protect_from_destroy
  tags          = merge(local.tags, { Proposito = each.key })
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each                = aws_s3_bucket.this
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id
  rule {
    id     = "versiones-7-dias"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
  depends_on = [aws_s3_bucket_versioning.this]
}

data "aws_iam_policy_document" "tls_only" {
  for_each = aws_s3_bucket.this
  statement {
    sid       = "SoloTLS"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tls_only" {
  for_each   = aws_s3_bucket.this
  bucket     = each.value.id
  policy     = data.aws_iam_policy_document.tls_only[each.key].json
  depends_on = [aws_s3_bucket_public_access_block.this]
}

# --- AWS Backup (RDS) ---
data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  count              = var.enable_backup ? 1 : 0
  name               = "${var.name}-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.enable_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_vault" "this" {
  count       = var.enable_backup ? 1 : 0
  name        = "${var.name}-vault"
  kms_key_arn = aws_kms_key.this.arn
  tags        = local.tags
}

resource "aws_backup_plan" "this" {
  count = var.enable_backup ? 1 : 0
  name  = "${var.name}-plan"
  rule {
    rule_name         = "diario-7-dias"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = "cron(0 5 * * ? *)"
    lifecycle {
      delete_after = 7
    }
  }
  tags = local.tags
}

resource "aws_backup_selection" "rds" {
  count        = var.enable_backup ? 1 : 0
  name         = "${var.name}-rds"
  plan_id      = aws_backup_plan.this[0].id
  iam_role_arn = aws_iam_role.backup[0].arn
  resources    = [aws_db_instance.this.arn]
}
