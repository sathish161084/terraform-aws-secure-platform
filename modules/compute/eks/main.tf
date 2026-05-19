module "eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=8a0efdbbc84180a26e0bacfd2b6fcfceac53b3b6"

  cluster_name    = "${var.name_prefix}-eks"
  cluster_version = "1.31"
  create_kms_key  = false

  cluster_endpoint_public_access         = false
  cluster_endpoint_private_access        = true
  cloudwatch_log_group_retention_in_days = 365
  cloudwatch_log_group_kms_key_id        = var.kms_key_arn

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa = true

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = var.kms_key_arn
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      subnet_ids     = var.private_subnet_ids
    }
  }
}
