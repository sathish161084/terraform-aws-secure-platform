output "db_password_secret_arn" { value = aws_secretsmanager_secret.db_password.arn }
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
