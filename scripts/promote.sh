#!/usr/bin/env bash
# usage: scripts/promote.sh <from-env> <to-env>
set -euo pipefail
FROM=$1 TO=$2
SRC=$(ls -d live/$FROM/clusters/*/ | head -1)
cp "live/$FROM/release.yaml" "live/$TO/release.yaml"
for DST in live/$TO/clusters/*/; do
  cp "$SRC/terraform/main.tf"        "$DST/terraform/main.tf"
  cp "$SRC/ansible/requirements.yml" "$DST/ansible/requirements.yml"
done
scripts/check-pins.sh "$TO"
git diff --stat
