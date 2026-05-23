# beads variant

A devcontainer with the beads (`bd`) issue tracker installed, layered on
top of the upstream Trail of Bits Claude Code devcontainer.

The intent: give Claude Code persistent, structured memory across
sessions via beads, without the operational weight of the full Gas Town
orchestration stack. One agent at a time, one project at a time, sit-down
work.

## What's added vs. `default/`

- **Dolt** — beads' storage backend.
- **beads** (`bd`) — installed via the official `gastownhall/beads`
  install script. Pre-compiled binary with embedded-Dolt support; no Go
  toolchain required.
- **tmux** — already in upstream, included here for completeness.
- **beads-init.sh** — postCreateCommand hook that initializes `.beads/`
  in the workspace, runs `bd setup claude`, and sets `beads.role`.

Not included (intentionally, vs. `gastown/`):

- Go — not needed; the bd install script downloads a pre-built binary.
- gt — this variant is beads-only; no orchestrator layer.

## What's changed in devcontainer.json vs. default

- `name`: "Beads Sandbox"
- `runArgs`: adds `--hostname beads` so the shell prompt is unambiguous.
- `mounts`: named volumes prefixed `devc-...-beads-...` so they don't
  conflict with default-variant or gastown-variant volumes for the same
  project.
- `postCreateCommand`: chains `bash /opt/beads-init.sh` after the
  existing upstream `post_install.py`.

The `runArgs` for the sandbox-net network are preserved — the beads
variant runs in the same sandboxed network with the same egress firewall
as the other variants.

## Applying

Like the gastown variant, this needs a separate upstream clone since
`devc` reads from a single directory at a time:

```bash
git clone https://github.com/trailofbits/claude-code-devcontainer ~/.claude-devcontainer-beads

cp ~/devc-config/beads/devcontainer.json ~/.claude-devcontainer-beads/devcontainer.json
cp ~/devc-config/beads/Dockerfile        ~/.claude-devcontainer-beads/Dockerfile
cp ~/devc-config/beads/beads-init.sh     ~/.claude-devcontainer-beads/beads-init.sh
chmod +x ~/.claude-devcontainer-beads/beads-init.sh
```

Then flip the symlink to use this variant:

```bash
ln -sfn ~/.claude-devcontainer-beads ~/.claude-devcontainer
```

## First-time use

```bash
cd ~/projects/some-project
devc .

# Inside the container:
bd ready                # empty initially
bd create --title "First issue" --description "..."
bd ready                # now shows the issue
```

Then start a Claude Code session in the container. The SessionStart
hook runs `bd prime`, which orients the agent. The agent has the full
bd CLI available; per the auto-generated CLAUDE.md section, it'll use
`bd ready`, `bd update --claim`, `bd close`, etc. as part of its
workflow.

## Security posture

Beyond the upstream Trail of Bits sandbox (network isolation, RO mounts
on `.git/config` and `.git/hooks`), this variant adds one extra RO bind
mount: `.beads/hooks/`. Without that, a compromised agent inside the
container could rewrite the beads git hook scripts, and the malicious
versions would execute as **your user on the host** the next time you
ran `git commit` in the project on the host. The RO mount closes that
escalation path.

The cost: `bd hooks install` cannot run from inside the container.
That's intentional. The `devc-up` wrapper runs `bd hooks install` on
the host before container start, where it has full write access. Beads
upgrades are also a host-side operation, so the upgrade-then-reinstall-
hooks flow stays on the host.

If you ever need to run `bd hooks install` against a project that's
already inside a running container, stop the container, do it on the
host, then start the container again. There's no use case for doing
it from inside.

## What this variant deliberately doesn't do

- **No Dolt remote.** Backlog stays local to the workspace's bind mount.
  Survives container rebuilds (workspace is host-backed), does not
  survive losing `docker-01`. If you want VM-loss durability, configure
  a Dolt remote inside the container — see beads docs for `bd dolt
  remote`.
- **No Gas Town.** If you want a multi-agent orchestrator with
  autonomous polecats, that's the `gastown/` variant — or, more
  realistically, a separate long-running HQ outside this devcontainer
  setup entirely.

## Beads workflow CLAUDE.md section

`bd setup claude` writes a managed section to your project's
CLAUDE.md. As of beads 1.0+, that section includes a fairly prescriptive
"you MUST `git push` at end of session" workflow. For projects where
that's appropriate, fine. For experimental projects you don't want
auto-pushed, edit the section after `bd setup claude` runs. Note that
beads marks the section with a content hash; future `bd setup claude`
invocations may overwrite your edits.
