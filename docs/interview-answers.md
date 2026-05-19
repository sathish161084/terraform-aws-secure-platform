# Interview Answers

## How do you avoid AWS keys in CI/CD?

Use GitHub Actions OIDC to assume a dedicated AWS IAM role via STS. Restrict the trust policy to org, repo and branch.

## How do you secure Terraform state?

Use S3 remote state with encryption, versioning, public access block, restricted IAM, and `use_lockfile = true` for state locking.

## How do you prevent insecure Terraform?

Use secure modules, PR reviews, Checkov, OPA policies, IAM boundaries, SCPs, AWS Config, Security Hub and CloudTrail.
