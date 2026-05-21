# devc-config

Source-controlled customizations of [trailofbits/claude-code-devcontainer][tob]
for use on `docker-01`.

The `devc` tool is installed per the upstream instructions to
`~/.local/bin/devc`, with the upstream repo cloned to
`~/.claude-devcontainer/`. The contents of that clone — specifically
`devcontainer.json` and any sibling files `devc` reads at project
creation time — are what determine what every new `devc .` produces.

This repo tracks the customizations applied on top of upstream, plus the
host-side bits (Docker network, firewall) that the sandbox depends on.

## Variants

- **default/** — what every `devc .` currently produces. Sandboxed Claude Code
  on the `sandbox-net` Docker network.
- **gastown/** — variant that adds Gas Town (`gt`), beads (`bd`), Dolt,
  and the toolchain to run them. Not yet built.

## Layout

```
default/                # files that go into ~/.claude-devcontainer/
gastown/                # files that go into ~/.claude-devcontainer/ for the gastown variant
host/                   # files that live on docker-01 itself (firewall, network)
UPSTREAM.md             # which upstream commit we're forked from
install.sh              # (optional) helper to copy a variant into place
```

## Applying a variant on docker-01

Manual:

```bash
cp -i ~/path/to/devc-config/default/devcontainer.json ~/.claude-devcontainer/devcontainer.json
```

Or via the helper script (when written):

```bash
./install.sh default
./install.sh gastown
```

## Bootstrapping a fresh docker-01

See `host/README.md` for the host-side setup (sandbox network, firewall,
`devc` installation).

[tob]: https://github.com/trailofbits/claude-code-devcontainer
