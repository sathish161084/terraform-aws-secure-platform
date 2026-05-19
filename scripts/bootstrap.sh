#!/usr/bin/env bash
set -euo pipefail

cd bootstrap/remote-state
terraform init
terraform apply

cd ../github-oidc
terraform init
terraform apply
