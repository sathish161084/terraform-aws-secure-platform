package terraform.security

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_vpc_security_group_ingress_rule"
  resource.change.after.cidr_ipv4 == "0.0.0.0/0"
  resource.change.after.from_port == 22
  msg = "SSH must not be open to the internet"
}
