#!/usr/bin/env bash
# Per-container Gas Town initialization. Runs once at container creation
# via postCreateCommand. Idempotent: safe to re-run if invoked again
# (e.g. after a rebuild).
#
# Responsibilities:
#   1. Verify the toolchain is on PATH.
#   2. Run `bd setup claude` — installs SessionStart/PreCompact hooks
#      into ~/.claude/settings.json so Claude Code calls `bd prime` at
#      session start. This is a global, per-user setup (writes to the
#      .claude config volume, not the workspace).
#   3. Run `bd init` in the workspace if not already initialized.
#      This creates `.beads/` in the project. Per-project state, lives
#      in the workspace bind mount, persists across container rebuilds.
#   4. Run `gt setup claude` similarly — installs Gas Town's own hook
#      additions on top of beads'.
#
# Notes:
#   - We do NOT run `gt install` here. That sets up a full Gas Town HQ
#     workspace (rigs, polecats, etc.), which is a deliberate step the
#     user should take when they're ready to use the orchestration
#     features. For experimentation with just beads + Claude Code, this
#     init is enough.
#   - We do NOT push to any Dolt remote. Set that up manually if/when
#     you want VM-loss durability for the backlog.

set -euo pipefail

echo "[gastown-init] Starting..."

# 1. Sanity-check the toolchain. If something's missing, fail loudly so the
#    container-create surfaces the problem rather than silently leaving the
#    user with a broken setup.
for cmd in go dolt bd gt tmux; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[gastown-init] ERROR: $cmd not found on PATH" >&2
    exit 1
  fi
done
echo "[gastown-init] Toolchain present: $(go version | awk '{print $3}'), dolt $(dolt version | head -n1 | awk '{print $NF}'), bd $(bd --version 2>&1 | head -n1), gt $(gt --version 2>&1 | head -n1)"

# 2. Beads hooks into Claude Code.
if bd setup claude --check >/dev/null 2>&1; then
  echo "[gastown-init] bd setup claude: already configured"
else
  echo "[gastown-init] bd setup claude: configuring..."
  bd setup claude || echo "[gastown-init] WARN: bd setup claude failed; continuing"
fi

# 3. Beads init for this project.
if [[ -d /workspace/.beads ]]; then
  echo "[gastown-init] bd init: workspace already initialized (.beads/ exists)"
else
  echo "[gastown-init] bd init: initializing in /workspace"
  cd /workspace && bd init || echo "[gastown-init] WARN: bd init failed; continuing"
fi

# 4. Gas Town hooks into Claude Code.
if gt setup claude --check >/dev/null 2>&1; then
  echo "[gastown-init] gt setup claude: already configured"
else
  echo "[gastown-init] gt setup claude: configuring..."
  gt setup claude || echo "[gastown-init] WARN: gt setup claude failed; continuing"
fi

echo "[gastown-init] Done."
echo
echo "Next steps:"
echo "  - Inside this container, try: bd ready"
echo "  - To set up a full Gas Town HQ: gt install ~/gt (consult docs first)"
echo "  - To enable backlog sync to a remote: see Gas Town docs on Dolt remotes"
