data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid    = "Allow administration of the key"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
    actions = [
      "kms:*"
    ]
    resources = ["arn:aws:kms:*:*:key/*"]
  }

  statement {
    sid    = "Allow use by AWS services"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.name}.amazonaws.com",
        "cloudtrail.amazonaws.com",
        "events.amazonaws.com",
        "s3.amazonaws.com",
        "sns.amazonaws.com",
        "secretsmanager.amazonaws.com"
      ]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:*:*:key/*"]
  }
}

resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} platform key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = {
    Name = "${var.name_prefix}-kms"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-platform"
  target_key_id = aws_kms_key.this.key_id
}
