# Secure AWS Terraform Platform

Enterprise-style Terraform practice project for AWS using:

- Terraform >= 1.10
- S3 remote backend with native `use_lockfile = true`
- GitHub Actions OIDC, no static AWS access keys
- Least-privilege Terraform role pattern
- Modular AWS services
- Security guardrails with Checkov and OPA
- Dev environment in `us-east-1`

## Architecture

```text
GitHub Actions
  -> OIDC AssumeRoleWithWebIdentity
  -> AWS IAM Terraform Role
  -> Terraform S3 Backend with native lockfile
  -> VPC, KMS, S3, ECR, EKS, RDS, ALB/WAF, CloudTrail, GuardDuty, Security Hub, Config, CloudWatch
```

## Run order

### 1. Bootstrap remote state

```bash
cd bootstrap/remote-state
terraform init
terraform plan
terraform apply
```

### 2. Bootstrap GitHub OIDC role

Edit `bootstrap/github-oidc/terraform.tfvars` first.

```bash
cd ../github-oidc
terraform init
terraform plan
terraform apply
```

Copy the output `github_role_arn` into GitHub Actions workflow files.

### 3. Deploy dev platform

```bash
cd ../../environments/dev
terraform init
terraform plan
terraform apply
```

## Cost warning

EKS, NAT Gateway, RDS, ALB and VPC endpoints can create AWS charges. Destroy dev resources when not practising:

```bash
cd environments/dev
terraform destroy
```

Do not destroy the remote-state bucket unless you intentionally remove `prevent_destroy`.

## Interview points

- No long-lived AWS access keys in CI/CD.
- S3 backend uses native lockfile instead of DynamoDB.
- Bootstrap layer is separate from workload environments.
- Environment state paths are isolated, e.g. `dev/platform/terraform.tfstate`.
- Security defaults: private subnets, KMS encryption, public access block, CloudTrail, GuardDuty, Security Hub, Config.
- Policy-as-code checks block unsafe changes before apply.
