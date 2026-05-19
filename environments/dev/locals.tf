locals {
  environment = "dev"
  aws_region  = "us-east-1"
  name_prefix = "secure-${local.environment}"

  common_tags = {
    Project     = "secure-terraform-platform"
    Environment = local.environment
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}
