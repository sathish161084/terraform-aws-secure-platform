variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "kms_key_arn" { type = string }
variable "availability_zones" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "database_subnet_cidrs" { type = list(string) }
