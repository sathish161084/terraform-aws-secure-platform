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
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}",
        "repo:${var.github_org}/${var.github_repo}:environment:${var.github_environment}",
        "repo:${var.github_org}/${var.github_repo}:pull_request"
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

    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:subnet/*",
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:route-table/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/*",
      "arn:aws:elasticloadbalancing:*:*:listener/*",
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*",
      "arn:aws:autoscaling:*:*:*",
      "arn:aws:eks:*:*:cluster/*",
      "arn:aws:eks:*:*:nodegroup/*",
      "arn:aws:eks:*:*:fargateprofile/*",
      "arn:aws:ecr:*:*:repository/*",
      "arn:aws:rds:*:*:db/*",
      "arn:aws:rds:*:*:dbcluster/*",
      "arn:aws:s3:::${var.terraform_state_bucket}",
      "arn:aws:s3:::${var.terraform_state_bucket}/*",
      "arn:aws:kms:*:*:key/*",
      "arn:aws:logs:*:*:*",
      "arn:aws:cloudwatch:*:*:*",
      "arn:aws:events:*:*:rule/*",
      "arn:aws:acm:*:*:certificate/*",
      "arn:aws:route53:::hostedzone/*",
      "arn:aws:wafv2:*:*:regional/webacl/*",
      "arn:aws:secretsmanager:*:*:secret:*",
      "arn:aws:ssm:*:*:parameter/*",
      "arn:aws:cloudtrail:*:*:trail/*",
      "arn:aws:config:*:*:config-rule/*",
      "arn:aws:config:*:*:configuration-recorder/*",
      "arn:aws:config:*:*:delivery-channel/*",
      "arn:aws:guardduty:*:*:detector/*",
      "arn:aws:securityhub:*:*:product/*",
      "arn:aws:securityhub:*:*:hub/*",
      "arn:aws:access-analyzer:*:*:analyzer/*",
      "arn:aws:iam::*:role/*",
      "arn:aws:iam::*:policy/*",
      "arn:aws:iam::*:instance-profile/*"
    ]
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
