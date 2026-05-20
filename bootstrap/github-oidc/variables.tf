variable "github_org" {
  description = "GitHub organisation or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "Allowed GitHub branch"
  type        = string
  default     = "main"
}

variable "github_environment" {
  description = "Allowed GitHub Actions environment for protected applies"
  type        = string
  default     = "dev"
}

variable "terraform_state_bucket" {
  description = "Terraform remote state bucket"
  type        = string
}
