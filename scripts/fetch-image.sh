#!/usr/bin/env bash
# usage: scripts/fetch-image.sh <bom.yaml>   -> prints the qcow2 path
set -euo pipefail
V=$(yq '.talosVersion' "$1"); S=$(yq '.talosSchematic' "$1")
DIR=$HOME/.platform-lab/images; OUT=$DIR/talos-$V-${S:0:12}.qcow2
mkdir -p "$DIR"
if [ ! -f "$OUT" ]; then
  URL=https://factory.talos.dev/image/$S/$V
  if curl -fsSL -o "$DIR/tmp.raw.zst" "$URL/metal-amd64.raw.zst"; then
    zstd -q -d -f "$DIR/tmp.raw.zst" -o "$DIR/tmp.raw"
  else
    curl -fsSL -o "$DIR/tmp.raw.xz" "$URL/metal-amd64.raw.xz"
    xz -d -f "$DIR/tmp.raw.xz"
  fi
  qemu-img convert -f raw -O qcow2 "$DIR/tmp.raw" "$OUT"
  rm -f "$DIR"/tmp.raw*
fi
echo "$OUT"
