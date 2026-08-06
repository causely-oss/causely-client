#!/usr/bin/env bash
# Open-Inspect sandbox setup hook (.openinspect/setup.sh in the target repo).
# Runs once per session, before the OpenCode agent starts — drops the Causely
# MCP server config where OpenCode will pick it up automatically.
#
# Open-Inspect itself has no plugin API; this hook is the supported extension
# point (see ColeMurray/background-agents ADR 0001). OpenCode, the agent
# runtime Open-Inspect wraps, already supports remote MCP servers natively —
# so wiring in Causely is a config drop, not a code change.
set -euo pipefail

cp "$(dirname "$0")/opencode.json" "$PWD/opencode.json"

# Optional: static/machine credentials for the Causely MCP server, if your
# tenant requires them instead of relying on browser OAuth. See
# https://docs.causely.ai/agent-integration/mcp-server/#authentication
if [ -n "${CAUSELY_MCP_CLIENT_BASIC:-}" ]; then
  python3 - "$PWD/opencode.json" <<'EOF'
import json, os, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
cfg["mcp"]["causely"]["headers"] = {
    "X-Causely-Client-Basic": os.environ["CAUSELY_MCP_CLIENT_BASIC"],
}
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
EOF
fi
