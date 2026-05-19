# Security Model

- GitHub Actions uses OIDC, no long-lived AWS credentials.
- Terraform state is stored in S3 with versioning, encryption, public access block and native lockfile.
- Workloads use private subnets.
- RDS is private and encrypted.
- EKS uses IRSA and cluster logging.
- WAF is associated with ALB.
- CloudTrail, Config, GuardDuty and Security Hub provide detective controls.
