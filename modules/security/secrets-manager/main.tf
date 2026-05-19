resource "random_password" "db" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name       = "${var.name_prefix}/rds/master-password"
  kms_key_id = var.kms_key_arn

  rotation_rules {
    automatically_after_days = 10
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id

  secret_string = jsonencode({
    username = "appadmin"
    password = random_password.db.result
  })
}
