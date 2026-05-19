resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} platform key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.name_prefix}-kms"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-platform"
  target_key_id = aws_kms_key.this.key_id
}
