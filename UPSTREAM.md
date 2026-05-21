# Upstream

We track [trailofbits/claude-code-devcontainer][tob].

Currently forked from commit:

```
5203cb5  Address Potential Container Escape via git (#42)
```

## Updating to a newer upstream

```bash
cd ~/.claude-devcontainer
git fetch origin
git log HEAD..origin/main --oneline    # review what's new
git pull --rebase                       # or merge, your call
```

Then, for each variant in this repo, re-apply the customizations on top
of the new upstream and update this file with the new commit SHA.

## What we customize

The customizations are intentionally minimal. The full list, against upstream:

- `default/devcontainer.json`: adds `"runArgs": ["--network", "sandbox-net"]`.
  Everything else is upstream verbatim.
- `default/Dockerfile`: unmodified — included in the repo as a snapshot for
  reference and so a future upstream-pull doesn't silently change what
  the sandbox is built on.

The `gastown/` variant will document its own deltas in `gastown/README.md`.

[tob]: https://github.com/trailofbits/claude-code-devcontainer
