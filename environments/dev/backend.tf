terraform {
  backend "s3" {
    bucket       = "sathish-secure-tfstate-2-us-east-1"
    key          = "dev/platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
