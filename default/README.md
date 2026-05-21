# default variant

What `devc .` currently produces on `docker-01`. Sandboxed Claude Code
on a Docker network with restricted egress.

## Files in this directory

- `devcontainer.json` — the customized template. **One line differs from
  upstream:** the `runArgs` block adding `--network sandbox-net`.
- `Dockerfile` — unmodified upstream snapshot, included so we have a
  reference for what was current at the fork point.

## Applying

```bash
cp devcontainer.json ~/.claude-devcontainer/devcontainer.json
# Dockerfile is unchanged; no need to copy unless verifying.
```

## Host prerequisites

The `sandbox-net` Docker network and the `DOCKER-USER` iptables rules
must exist on the host. See `../host/README.md`.

If you spin up a project with this variant on a host that doesn't have
`sandbox-net`, `devc .` will fail with a network-not-found error.

## Decisions worth revisiting

- **No `--cap-drop NET_ADMIN` / `--cap-drop NET_RAW` in `runArgs`.**
  These were recommended in an earlier design discussion but aren't
  currently applied. They would prevent root inside the container from
  manipulating its own network stack, which the ToB image's passwordless
  sudo otherwise permits. Worth deciding whether to add them.
