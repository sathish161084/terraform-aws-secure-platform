resource "random_password" "db" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.name_prefix}/rds/master-password"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id

  secret_string = jsonencode({
    username = "appadmin"
    password = random_password.db.result
  })
}
