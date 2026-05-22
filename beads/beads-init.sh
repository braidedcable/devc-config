#!/usr/bin/env bash
# Per-container beads initialization. Runs once at container creation
# via postCreateCommand.
#
# Responsibilities:
#   1. Verify the toolchain is on PATH.
#   2. Run `bd init` in the workspace if not already initialized.
#      This creates `.beads/` in the project. Per-project state, lives
#      in the workspace bind mount, persists across container rebuilds.
#   3. Run `bd setup claude` — installs SessionStart/PreCompact hooks
#      into the project's .claude/settings.json and adds a beads section
#      to CLAUDE.md. Project-scoped (lives in /workspace).
#   4. Set `beads.role` git config for this workspace if not yet set.
#      Suppresses the "beads.role not configured" warning. Solo user
#      default: maintainer.
#
# Notes:
#   - We do NOT push to any Dolt remote. The backlog lives in
#     /workspace/.beads/ on the bind-mounted workspace, which means it
#     survives container rebuilds via the host filesystem but does NOT
#     survive losing docker-01. For VM-loss durability, configure a
#     Dolt remote manually (see beads docs).

set -euo pipefail

echo "[beads-init] Starting..."

# 1. Sanity-check the toolchain.
for cmd in dolt bd tmux; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[beads-init] ERROR: $cmd not found on PATH" >&2
    exit 1
  fi
done
echo "[beads-init] Toolchain present:"
echo "  dolt: $(dolt version 2>&1 | head -n1 | awk '{print $NF}')"
echo "  bd:   $(bd --version 2>&1 | head -n1)"

# 2. Beads init for this project. Must come BEFORE `bd setup claude`,
#    since the setup writes to .claude/settings.json in the project and
#    expects the project to be a beads workspace.
if [[ -d /workspace/.beads ]]; then
  echo "[beads-init] bd init: workspace already initialized (.beads/ exists)"
else
  echo "[beads-init] bd init: initializing in /workspace"
  cd /workspace && bd init || echo "[beads-init] WARN: bd init failed; continuing"
fi

# 3. Beads -> Claude Code integration. Writes to /workspace/.claude/settings.json
#    (hooks) and /workspace/CLAUDE.md (workflow instructions section).
#    Run unconditionally; bd handles dedup internally.
echo "[beads-init] bd setup claude: configuring..."
bd setup claude || echo "[beads-init] WARN: bd setup claude failed; continuing"

# 4. Set beads.role to suppress the warning. Solo user => maintainer.
#    Per-repo config, written to /workspace/.git/config (which is bind
#    -mounted RO from the host). Likely to fail; not blocking.
if [[ -d /workspace/.git ]]; then
  if ! git -C /workspace config beads.role >/dev/null 2>&1; then
    if git -C /workspace config beads.role maintainer 2>/dev/null; then
      echo "[beads-init] beads.role set to maintainer"
    else
      echo "[beads-init] NOTE: could not set beads.role (likely RO .git/config); set manually on host with:"
      echo "  git -C <workspace> config beads.role maintainer"
    fi
  fi
fi

echo "[beads-init] Done."
echo
echo "Next steps:"
echo "  - bd ready                       # see what's available to work on"
echo "  - bd create --title \"...\"        # create the first issue"
echo "  - bd --help                      # explore beads commands"
echo
echo "If you eventually want a multi-agent orchestrator on top of this,"
echo "the gastown/ variant is also available."
