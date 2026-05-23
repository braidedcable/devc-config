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
5. **`bd` (beads) on the host PATH** — only needed for the `beads` and
   `gastown` variants. The `devc-up` wrapper runs `bd init` and
   `bd hooks install` on the host *before* starting the container, so
   that privileged operations on `.git/config` and `.git/hooks` happen
   outside the sandbox.

## sandbox-net

```bash
docker network create sandbox-net
```

This is a one-time setup. No subnet specified — Docker picks a free
RFC1918 range and you don't need to pin it.

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

## bd on the host

Required for the `beads` and `gastown` variants. The `devc-up` wrapper
runs `bd init` and `bd hooks install` on the host before starting the
container, so this needs to be present.

```bash
curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash
```

Verify:

```bash
bd --version
```

## devc-up wrapper

The `devc-up` script in this directory is the main entry point for
bringing up a project in any of the variants. It:

- flips the `~/.claude-devcontainer` symlink to the requested variant,
- runs host-side beads setup if the variant needs it,
- populates the project's `.devcontainer/` directory (including the
  variant-specific init scripts that `devc` itself doesn't know about),
- calls `devc up` to build and start the container.

Install it once by symlinking onto your PATH:

```bash
mkdir -p ~/.local/bin
ln -sfn ~/devc-config/host/devc-up ~/.local/bin/devc-up
```

Usage:

```bash
devc-up beads                     # current directory, beads variant
devc-up gastown ~/projects/foo    # specific project, gastown variant
devc-up default                   # plain sandboxed Claude Code
```
