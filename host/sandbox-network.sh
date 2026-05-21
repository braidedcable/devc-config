#!/usr/bin/env bash
# Create the `sandbox-net` Docker network with a deterministic bridge name.
#
# The fixed bridge name (`br-sandbox`) is what `sandbox-firewall.sh` keys its
# iptables rules off of. Without this, Docker would assign a random name like
# `br-a1b2c3d4e5f6` and the firewall rules would fail to match.
#
# Idempotent: skips creation if the network already exists.

set -euo pipefail

if docker network inspect sandbox-net >/dev/null 2>&1; then
  echo "sandbox-net already exists, skipping"
  exit 0
fi

docker network create \
  --opt com.docker.network.bridge.name=br-sandbox \
  sandbox-net

echo "Created sandbox-net (bridge: br-sandbox)"
