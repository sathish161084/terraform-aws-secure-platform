data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

data "aws_iam_policy_document" "terraform_permissions" {
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}",
      "arn:aws:s3:::${var.terraform_state_bucket}/*"
    ]
  }

  statement {
    sid    = "TerraformPlatformAccess"
    effect = "Allow"

    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "eks:*",
      "ecr:*",
      "rds:*",
      "s3:*",
      "kms:*",
      "logs:*",
      "cloudwatch:*",
      "events:*",
      "acm:*",
      "route53:*",
      "wafv2:*",
      "secretsmanager:*",
      "ssm:*",
      "cloudtrail:*",
      "config:*",
      "guardduty:*",
      "securityhub:*",
      "access-analyzer:*",
      "iam:Get*",
      "iam:List*",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:PassRole"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_permissions" {
  name        = "github-terraform-secure-platform-policy"
  description = "Scoped permissions for secure Terraform platform lab"
  policy      = data.aws_iam_policy_document.terraform_permissions.json
}

resource "aws_iam_role_policy_attachment" "terraform_permissions" {
  role       = aws_iam_role.github_terraform.name
  policy_arn = aws_iam_policy.terraform_permissions.arn
}
