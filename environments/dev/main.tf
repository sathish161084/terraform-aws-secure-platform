module "kms" {
  source = "../../modules/security/kms"

  name_prefix = local.name_prefix
}

module "vpc" {
  source = "../../modules/networking/vpc"

  name_prefix = local.name_prefix
  vpc_cidr    = "10.20.0.0/16"
  kms_key_arn = module.kms.key_arn

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.20.1.0/24",
    "10.20.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.20.11.0/24",
    "10.20.12.0/24"
  ]

  database_subnet_cidrs = [
    "10.20.21.0/24",
    "10.20.22.0/24"
  ]
}

module "vpc_endpoints" {
  source = "../../modules/networking/vpc-endpoints"

  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = "10.20.0.0/16"
  private_subnet_ids = module.vpc.private_subnet_ids
  route_table_ids    = module.vpc.private_route_table_ids
}

module "app_bucket" {
  source = "../../modules/storage/s3"

  bucket_name = "sathish-secure-app-dev-us-east-1"
  kms_key_arn = module.kms.key_arn
}

module "ecr" {
  source = "../../modules/compute/ecr"

  repositories = [
    "frontend",
    "backend",
    "worker"
  ]
  kms_key_arn = module.kms.key_arn
}

module "secrets_manager" {
  source = "../../modules/security/secrets-manager"

  name_prefix = local.name_prefix
  kms_key_arn = module.kms.key_arn
}

module "eks" {
  source = "../../modules/compute/eks"

  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  kms_key_arn        = module.kms.key_arn
}

module "rds" {
  source = "../../modules/database/rds"

  name_prefix            = local.name_prefix
  vpc_id                 = module.vpc.vpc_id
  database_subnet_ids    = module.vpc.database_subnet_ids
  app_security_group_id  = module.eks.node_security_group_id
  kms_key_arn            = module.kms.key_arn
  db_password_secret_arn = module.secrets_manager.db_password_secret_arn
}

module "alb_waf" {
  source = "../../modules/networking/alb-waf"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  kms_key_arn       = module.kms.key_arn
}

module "security_baseline" {
  source = "../../modules/security/security-baseline"

  name_prefix            = local.name_prefix
  kms_key_arn            = module.kms.key_arn
  create_config_recorder = false
}

module "cloudwatch" {
  source = "../../modules/observability/cloudwatch"

  name_prefix           = local.name_prefix
  billing_threshold_usd = 25
}
