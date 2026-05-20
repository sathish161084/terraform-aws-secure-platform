resource "aws_s3_bucket" "remote_state" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = var.bucket_name
    Purpose     = "Terraform remote state"
    ManagedBy   = "Terraform"
    Environment = "bootstrap"
  }
}

resource "aws_sns_topic" "remote_state_events" {
  #checkov:skip=CKV_AWS_26:Bootstrap S3 event topic is intentionally unencrypted so S3 can validate notifications without a customer-managed KMS key.
  name = "${var.bucket_name}-events"
}

data "aws_iam_policy_document" "remote_state_events" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.remote_state_events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.remote_state.arn]
    }
  }
}

resource "aws_sns_topic_policy" "remote_state_events" {
  arn    = aws_sns_topic.remote_state_events.arn
  policy = data.aws_iam_policy_document.remote_state_events.json
}

resource "aws_s3_bucket_notification" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  topic {
    topic_arn = aws_sns_topic.remote_state_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.remote_state_events]
}

resource "aws_s3_bucket_public_access_block" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  rule {
    id     = "expire-remote-state"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }

    bucket_key_enabled = true
  }
}
