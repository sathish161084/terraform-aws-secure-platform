variable "name_prefix" { type = string }
variable "kms_key_arn" { type = string }

variable "create_config_recorder" {
  type    = bool
  default = true
}
