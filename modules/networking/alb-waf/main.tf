data "aws_caller_identity" "current" {}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Public ALB security group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  description       = "Allow HTTPS ingress to the ALB"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "all" {
  description       = "Allow all outbound traffic from the ALB security group"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_s3_bucket" "alb_access_logs" {
  #checkov:skip=CKV_AWS_145:ALB access log delivery supports SSE-S3 for this log bucket.
  bucket        = "${var.name_prefix}-alb-access-logs"
  force_destroy = true

  tags = {
    Name = "${var.name_prefix}-alb-access-logs"
  }
}

resource "aws_sns_topic" "alb_access_logs_events" {
  name              = "${var.name_prefix}-alb-access-logs-events"
  kms_master_key_id = var.kms_key_arn
}

data "aws_iam_policy_document" "alb_access_logs_events" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alb_access_logs_events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.alb_access_logs.arn]
    }
  }
}

resource "aws_sns_topic_policy" "alb_access_logs_events" {
  arn    = aws_sns_topic.alb_access_logs_events.arn
  policy = data.aws_iam_policy_document.alb_access_logs_events.json
}

resource "aws_s3_bucket_versioning" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    id     = "expire-alb-access-logs"
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

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "alb_access_logs" {
  statement {
    sid    = "AllowLoadBalancerAccessLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_access_logs.arn}/${var.name_prefix}-alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }

  statement {
    sid    = "AllowLoadBalancerAccessLogAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.alb_access_logs.arn]
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = data.aws_iam_policy_document.alb_access_logs.json
}

resource "aws_s3_bucket_notification" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  topic {
    topic_arn = aws_sns_topic.alb_access_logs_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.alb_access_logs_events]
}

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_150:Dev environment must be destroyable for cost-controlled teardown.
  name               = "${var.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.bucket
    prefix  = "${var.name_prefix}-alb"
    enabled = true
  }
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  depends_on = [aws_s3_bucket_policy.alb_access_logs]
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name_prefix}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.name_prefix}-waf"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
}

resource "aws_iam_role" "waf_logging" {
  name = "${var.name_prefix}-waf-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "wafv2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "waf_logging" {
  name = "${var.name_prefix}-waf-logging-policy"
  role = aws_iam_role.waf_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups"
      ]
      Resource = aws_cloudwatch_log_group.waf.arn
    }]
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}
