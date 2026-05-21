# host-side setup

Things that live on `docker-01` itself, not inside any container, that
the sandboxed devcontainer depends on.

## What's required

1. **Docker, with the `sandbox-net` network created.**
2. **iptables rules in the `DOCKER-USER` chain** blocking egress from
   `sandbox-net` containers to RFC1918 / link-local / CGNAT space.
3. **The `devc` tool** installed at `~/.local/bin/devc` per upstream.
4. **`CLAUDE_CODE_OAUTH_TOKEN`** exported in the host shell so `devc .`
   picks it up via `localEnv`.

## sandbox-net

```bash
sudo bash sandbox-network.sh
```

Created with a fixed bridge name (`br-sandbox`) so the firewall rules
can reliably match on it. See `sandbox-network.sh`.

## Firewall

See `sandbox-firewall.sh` for the iptables rules. Apply with:

```bash
sudo bash sandbox-firewall.sh
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

The script blocks egress from `sandbox-net` to all RFC1918 space,
link-local (`169.254.0.0/16`), and CGNAT (`100.64.0.0/10`). Public
internet access remains open.

## devc tool

Per upstream:

```bash
git clone https://github.com/trailofbits/claude-code-devcontainer ~/.claude-devcontainer
~/.claude-devcontainer/install.sh self-install
```

Then overlay one of this repo's variants onto `~/.claude-devcontainer/`.

## OAuth token

```bash
echo 'export CLAUDE_CODE_OAUTH_TOKEN="..."' >> ~/.bashrc
```

The devcontainer reads this via `${localEnv:CLAUDE_CODE_OAUTH_TOKEN:}`.
