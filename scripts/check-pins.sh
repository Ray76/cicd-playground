#!/usr/bin/env bash
# usage: scripts/check-pins.sh <env>
set -euo pipefail
ENV=$1
WANT="v$(yq '.platform' "live/$ENV/release.yaml")"
rc=0
for C in live/$ENV/clusters/*/; do
  grep -q "?ref=$WANT\"" "$C/terraform/main.tf" \
    || { echo "$C terraform ref != $WANT"; rc=1; }
  [ "$(yq '.collections[0].version' "$C/ansible/requirements.yml")" = "$WANT" ] \
    || { echo "$C ansible version != $WANT"; rc=1; }
done
[ $rc = 0 ] && echo "pins OK for $ENV ($WANT)"
exit $rc
