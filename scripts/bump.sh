#!/usr/bin/env bash
# usage: scripts/bump.sh <env> <version>     e.g. scripts/bump.sh dev 0.2.0
set -euo pipefail
ENV=$1 V=$2
yq -i ".platform = \"$V\"" "live/$ENV/release.yaml"
for C in live/$ENV/clusters/*/; do
  sed -i -E "s/\?ref=v[0-9.]+\"/?ref=v$V\"/" "$C/terraform/main.tf"
  yq -i ".collections[0].version = \"v$V\"" "$C/ansible/requirements.yml"
done
scripts/check-pins.sh "$ENV"
