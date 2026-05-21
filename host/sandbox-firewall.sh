#!/usr/bin/env bash
# Sandbox egress firewall rules for the sandbox-net Docker bridge.
#
# Applies to traffic egressing containers on the `sandbox-net` Docker network
# (whose host-side bridge interface is `br-sandbox`). Blocks all RFC1918,
# link-local, and CGNAT destinations while leaving public internet open.
#
# Assumes the sandbox-net network has been created with a fixed bridge name:
#   docker network create \
#     --opt com.docker.network.bridge.name=br-sandbox \
#     sandbox-net
#
# To make persistent across reboots:
#   sudo apt install -y iptables-persistent
#   sudo bash sandbox-firewall.sh
#   sudo netfilter-persistent save

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "must be run as root" >&2
  exit 1
fi

# Ensure the DOCKER-USER chain exists. Docker creates it, but if iptables was
# flushed since the daemon started, it may be missing.
iptables -N DOCKER-USER 2>/dev/null || true

# Idempotency: flush any prior rules in this chain before re-adding.
iptables -F DOCKER-USER

# Block egress from sandbox containers to all private address space.
iptables -A DOCKER-USER -i br-sandbox -d 10.0.0.0/8       -j DROP
iptables -A DOCKER-USER -i br-sandbox -d 172.16.0.0/12    -j DROP
iptables -A DOCKER-USER -i br-sandbox -d 192.168.0.0/16   -j DROP
iptables -A DOCKER-USER -i br-sandbox -d 169.254.0.0/16   -j DROP  # link-local
iptables -A DOCKER-USER -i br-sandbox -d 100.64.0.0/10    -j DROP  # CGNAT

echo "DOCKER-USER chain configured:"
iptables -S DOCKER-USER
