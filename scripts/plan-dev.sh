#!/usr/bin/env bash
set -euo pipefail
cd environments/dev
terraform init
terraform plan
