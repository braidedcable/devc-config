#!/usr/bin/env bash
# Per-container Gas Town initialization. Runs once at container creation
# via postCreateCommand.
#
# Responsibilities:
#   1. Verify the toolchain is on PATH.
#   2. Run `bd setup claude` — installs SessionStart/PreCompact hooks
#      into the project's .claude/settings.json and adds a beads section
#      to CLAUDE.md. Project-scoped (lives in /workspace), so this runs
#      on every container create — not idempotent at the "already done"
#      level, but safe to re-run since bd handles dedup internally.
#   3. Run `bd init` in the workspace if not already initialized.
#      This creates `.beads/` in the project. Per-project state, lives
#      in the workspace bind mount, persists across container rebuilds.
#   4. Set `beads.role` git config for this workspace if not yet set.
#      Suppresses the "beads.role not configured" warning. Solo user
#      default: maintainer.
#
# Notes:
#   - `gt` is installed in the image but no gt-specific init runs here.
#     The current `gt` (1.x) requires a full Gas Town HQ (`gt install
#     ~/gt`) before its hook/sync subsystem is meaningful. For
#     experimentation with `gt` as a CLI, you have everything you need.
#     When you decide to commit to a full HQ, run `gt install ~/gt` and
#     follow up with `gt hooks init && gt hooks sync` per the docs.
#   - We do NOT push to any Dolt remote. Set that up manually if/when
#     you want VM-loss durability for the backlog.

set -euo pipefail

echo "[gastown-init] Starting..."

# 1. Sanity-check the toolchain.
for cmd in go dolt bd gt tmux; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[gastown-init] ERROR: $cmd not found on PATH" >&2
    exit 1
  fi
done
echo "[gastown-init] Toolchain present:"
echo "  go:   $(go version | awk '{print $3}')"
echo "  dolt: $(dolt version 2>&1 | head -n1 | awk '{print $NF}')"
echo "  bd:   $(bd --version 2>&1 | head -n1)"
echo "  gt:   $(gt --version 2>&1 | head -n1)"

# 2. Beads init for this project. Must come BEFORE `bd setup claude`,
#    since the setup writes to .claude/settings.json in the project and
#    expects the project to be a beads workspace.
if [[ -d /workspace/.beads ]]; then
  echo "[gastown-init] bd init: workspace already initialized (.beads/ exists)"
else
  echo "[gastown-init] bd init: initializing in /workspace"
  cd /workspace && bd init || echo "[gastown-init] WARN: bd init failed; continuing"
fi

# 3. Beads -> Claude Code integration. Writes to /workspace/.claude/settings.json
#    (hooks) and /workspace/CLAUDE.md (workflow instructions section).
#    Run unconditionally; bd handles dedup internally.
echo "[gastown-init] bd setup claude: configuring..."
bd setup claude || echo "[gastown-init] WARN: bd setup claude failed; continuing"

# 4. Set beads.role to suppress the warning. Solo user => maintainer.
#    Per-repo config, written to /workspace/.git/config (which is bind
#    -mounted RO from the host... so this may fail. If so, just note it
#    and continue; the warning is non-blocking.)
if [[ -d /workspace/.git ]]; then
  if ! git -C /workspace config beads.role >/dev/null 2>&1; then
    if git -C /workspace config beads.role maintainer 2>/dev/null; then
      echo "[gastown-init] beads.role set to maintainer"
    else
      echo "[gastown-init] NOTE: could not set beads.role (likely RO .git/config); set manually on host with:"
      echo "  git -C <workspace> config beads.role maintainer"
    fi
  fi
fi

echo "[gastown-init] Done."
echo
echo "Next steps:"
echo "  - bd ready                       # see what's available to work on"
echo "  - bd create --title \"...\"        # create the first issue"
echo "  - bd --help                      # explore beads commands"
echo "  - gt --help                      # explore Gas Town (no HQ set up yet)"
echo
echo "For a full Gas Town HQ (multi-agent orchestration):"
echo "  - gt install ~/gt && gt hooks init && gt hooks sync"
echo "  - Consult docs first: https://docs.gastownhall.ai/installing/"
