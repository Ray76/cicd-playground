#!/usr/bin/env bash
# usage: ./lab.sh up|down <env> <cluster>
set -euo pipefail
CMD=$1 ENV=$2 CLUSTER=$3
ROOT=$(cd "$(dirname "$0")" && pwd); cd "$ROOT"
CDIR=live/$ENV/clusters/$CLUSTER
WORK=$ROOT/.work/$ENV/$CLUSTER
mkdir -p "$WORK"
export ANSIBLE_COLLECTIONS_PATH=$WORK/collections

# env pins a release tag; the tag carries the BOM
PLATFORM=$(yq '.platform' "live/$ENV/release.yaml")
git fetch -q --tags origin
git show "v$PLATFORM:components/bom.yaml" > "$WORK/bom.yaml"

play() {
  ansible-playbook -i "$WORK/inventory.json" "acme.talos.$1" \
    -e @"$WORK/bom.yaml" -e @"$ROOT/$CDIR/ansible/cluster-vars.yml" \
    -e platform="$PLATFORM" -e cluster_name="$CLUSTER" \
    -e talos_workdir="$WORK" -e live_values_path="$CDIR/argocd/values.yaml"
}

case $CMD in
  up)
    IMAGE=$(scripts/fetch-image.sh "$WORK/bom.yaml")
    tofu -chdir="$CDIR/terraform" init -input=false -upgrade
    tofu -chdir="$CDIR/terraform" apply -auto-approve -var "boot_image=$IMAGE"
    tofu -chdir="$CDIR/terraform" output -json nodes | jq '{all:{children:{
      controlplane:{hosts:(with_entries(select(.value.role=="controlplane"))|map_values({ansible_host:.ip}))},
      workers:{hosts:(with_entries(select(.value.role=="worker"))|map_values({ansible_host:.ip}))}}}}' \
      > "$WORK/inventory.json"
    ansible-galaxy collection install -r "$CDIR/ansible/requirements.yml" \
      -p "$WORK/collections" --force
    play upgrade   # no-op unless the BOM moved Talos or Kubernetes
    play site      # Talos config, bootstrap, Argo CD
    ;;
  down)
    tofu -chdir="$CDIR/terraform" destroy -auto-approve -var "boot_image=unused"
    rm -rf "$WORK"
    ;;
  *) echo "usage: $0 up|down <env> <cluster>"; exit 1 ;;
esac
