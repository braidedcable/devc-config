# gastown variant

A devcontainer with the Gas Town / beads toolchain installed, layered on
top of the upstream Trail of Bits Claude Code devcontainer.

## What's added vs. `default/`

- **Go** (latest stable at build time) — required by `gt` and `bd`.
- **Dolt** — beads is Dolt-native now; required.
- **beads** (`bd`) — installed via the official gastownhall install script.
- **gt** (Gas Town CLI) — installed via the official install script.
- **tmux** — already in upstream, included here for completeness.
- **gastown-init.sh** — postCreateCommand hook that initializes `bd`,
  runs `bd setup claude`, and runs `gt setup claude` on first container
  creation. Idempotent.

## What's changed in devcontainer.json

- `name`: "Gas Town Sandbox"
- `runArgs`: adds `--hostname gastown` so the shell prompt is unambiguous.
- `mounts`: named volumes prefixed `devc-...-gt-...` instead of
  `devc-...-...` so they don't conflict with default-variant volumes
  for the same project.
- `postCreateCommand`: chains `bash /opt/gastown-init.sh` after the
  existing upstream `post_install.py`.

The `runArgs` for the sandbox-net network are preserved — the gastown
variant runs in the same sandboxed network with the same egress firewall
as the default variant.

## Applying

Because the gastown variant uses a different *upstream clone directory*,
it doesn't overwrite the default. Set it up once on the host:

```bash
# Clone upstream into a separate directory
git clone https://github.com/trailofbits/claude-code-devcontainer ~/.claude-devcontainer-gastown

# Overlay this variant's files
cp ~/devc-config/gastown/devcontainer.json   ~/.claude-devcontainer-gastown/devcontainer.json
cp ~/devc-config/gastown/Dockerfile          ~/.claude-devcontainer-gastown/Dockerfile
cp ~/devc-config/gastown/gastown-init.sh     ~/.claude-devcontainer-gastown/gastown-init.sh
```

The standard `devc` binary points at `~/.claude-devcontainer/`. To use
this variant, either:

- **Symlink-swap before invoking `devc .`** (quick and dirty):
  ```bash
  mv ~/.claude-devcontainer ~/.claude-devcontainer-default
  ln -s ~/.claude-devcontainer-gastown ~/.claude-devcontainer
  devc .
  # ...later, swap back:
  rm ~/.claude-devcontainer
  mv ~/.claude-devcontainer-default ~/.claude-devcontainer
  ```

- **Or wrap it in a shell function/alias** that does the swap before
  running `devc .` and restores afterward. See `install.sh` if/when we
  write one.

Neither approach is elegant; `devc` doesn't have a `--config` flag for
this. For a hobby project this is fine.

## First-time use

```bash
cd ~/projects/some-project
devc .          # uses gastown variant if you swapped, otherwise default
# Inside the container:
bd ready        # see what's available to work on (empty initially)
bd create --title "First issue" --description "..."
```

Then start a Claude Code session in the container. The SessionStart hook
will run `bd prime` and orient the agent automatically.

## What this variant deliberately doesn't do

- **No `gt install` (full HQ).** The init script only wires up beads
  and the hooks. Setting up a Gas Town HQ workspace with rigs and
  polecats is a deliberate step you take when you want multi-agent
  orchestration. For "just beads + Claude Code", what this gives you
  is sufficient.
- **No Dolt remote.** Backlog stays local to the workspace's bind mount.
  If you want VM-loss durability for the backlog, configure a Dolt
  remote manually inside the container.
