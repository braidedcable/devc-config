# devc-config

Source-controlled customizations of [trailofbits/claude-code-devcontainer][tob]
for use on `docker-01`, plus a wrapper script (`devc-up`) that coordinates
variant selection, host-side project init, and container build into a single
command.

## What this is

The Trail of Bits `devc` tool lives at `~/.local/bin/devc` and reads
templates from `~/.claude-devcontainer/`. Each new project gets a
`.devcontainer/` directory populated from there when devc runs.

This repo holds:

- Three **variants** of the upstream template, each in its own directory.
  Each variant is `~/.claude-devcontainer-<variant>/` on the host.
- The **host-side setup** (Docker network, firewall, `devc-up` wrapper)
  that the sandboxed devcontainer depends on.
- An [UPSTREAM.md](UPSTREAM.md) tracking which Trail of Bits commit each
  variant is forked from.

`~/.claude-devcontainer` itself is a **symlink** that points at whichever
variant directory you want active. The `devc-up` wrapper flips it for you.

## Variants

- **default/** — upstream Trail of Bits sandbox plus the `sandbox-net`
  Docker network. Plain Claude Code in a sandbox, nothing more.
- **beads/** — adds Dolt and beads (`bd`) for persistent agent memory
  via the issue tracker. One agent, sit-down work.
- **gastown/** — adds Go, Dolt, beads, and Gas Town (`gt`) for the full
  multi-agent orchestration toolchain. Currently the toolchain only;
  the full Gas Town HQ (`gt install ~/gt`) is a deliberate next step,
  not auto-configured. See [devcontainer-to-swarm-plan.md][plan] for
  the staged roadmap toward an autonomous swarm setup.

## Layout

```
default/                # files for ~/.claude-devcontainer-default/
beads/                  # files for ~/.claude-devcontainer-beads/
gastown/                # files for ~/.claude-devcontainer-gastown/
host/                   # files that live on docker-01 itself
├── devc-up             # wrapper script (symlink to ~/.local/bin/devc-up)
├── sandbox-firewall.sh # iptables rules for sandbox-net egress
├── sandbox-network.sh  # creates the sandbox-net Docker network
├── docker-user-rules.txt   # snapshot of current iptables for reference
└── README.md           # host setup, prerequisites, devc-up docs
UPSTREAM.md             # which upstream commit each variant is from
```

## Architecture decisions worth knowing

A few things that aren't obvious from the layout:

**Host-side beads init.** The Trail of Bits devcontainer read-only-mounts
`.git/config` and `.git/hooks` into the container as a security boundary.
beads needs to write to both at init time (setting `core.hooksPath`,
installing git hooks). The conflict is resolved by running `bd init` and
`bd hooks install` **on the host**, before starting the container. The
`devc-up` wrapper handles this; you don't have to remember.

**Relative `core.hooksPath`.** `bd hooks install` defaults to an absolute
path that breaks inside the container (workspace path differs between
host and sandbox). The wrapper rewrites it to `.beads/hooks` (repo-
relative), so the same setting works in both environments. Git hooks
fire correctly whether you commit on the host or inside the container.

**Workspace as bind mount.** The project directory is bind-mounted from
the host into the container at `/workspace`. Beads state lives in
`.beads/` inside the workspace — host-backed, survives container
rebuilds. (Does *not* survive losing `docker-01`. For VM-loss durability,
configure a Dolt remote.)

**Symlink-based variant switching.** No flag on `devc` lets you pick a
template directory at invocation time. We work around this by keeping
each variant as `~/.claude-devcontainer-<variant>/` and making
`~/.claude-devcontainer` a symlink the wrapper flips.

## Quick start on a fresh docker-01

```bash
# Clone this repo and the upstream variants.
git clone https://github.com/braidedcable/devc-config ~/devc-config

for v in default beads gastown; do
  git clone https://github.com/trailofbits/claude-code-devcontainer ~/.claude-devcontainer-$v
  # Overlay our variant-specific files
  cp ~/devc-config/$v/Dockerfile        ~/.claude-devcontainer-$v/
  cp ~/devc-config/$v/devcontainer.json ~/.claude-devcontainer-$v/
  # Init scripts only exist for non-default variants
  [[ -f ~/devc-config/$v/$v-init.sh ]] && \
    cp ~/devc-config/$v/$v-init.sh ~/.claude-devcontainer-$v/ && \
    chmod +x ~/.claude-devcontainer-$v/$v-init.sh
done

# Symlink to active variant (start with default)
ln -sfn ~/.claude-devcontainer-default ~/.claude-devcontainer

# Host-side setup (Docker network, firewall, wrapper)
sudo bash ~/devc-config/host/sandbox-network.sh
sudo bash ~/devc-config/host/sandbox-firewall.sh
mkdir -p ~/.local/bin
ln -sfn ~/devc-config/host/devc-up ~/.local/bin/devc-up

# For beads/gastown variants, bd must be on the host too
curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash

# Verify
devc-up --help
```

See `host/README.md` for full details, including OAuth token setup and
iptables-persistent.

## Day-to-day use

```bash
# In any project directory, pick a variant
devc-up beads                      # current directory
devc-up gastown ~/projects/foo     # specific project
devc-up default                    # plain sandboxed Claude Code

# Then drop into the running container
devc shell
```

The wrapper handles symlink-flipping, host-side beads init (where
applicable), staging variant-specific files into `.devcontainer/`, and
calling `devc up`. Idempotent — re-running it on an already-set-up
project is safe.

## Updating from upstream

Trail of Bits updates their devcontainer periodically (security patches,
dependency bumps). To pull those in:

```bash
cd ~/.claude-devcontainer-default
git pull
# Diff against the variant Dockerfiles to see what changed
diff Dockerfile ~/devc-config/default/Dockerfile

# Apply equivalent changes to each variant's Dockerfile in this repo,
# then update UPSTREAM.md with the new commit SHA.
```

The customizations on top of upstream are intentionally minimal so this
merge is usually painless. See `UPSTREAM.md` for the current pinned
commit.

[tob]: https://github.com/trailofbits/claude-code-devcontainer
[plan]: ./devcontainer-to-swarm-plan.md
