# Background agent integrations

This directory shows how to point a self-hosted **background coding agent** (a harness that
watches for triggers — webhooks, alerts, tickets — and autonomously investigates + proposes a
fix) at Causely's MCP server, so its investigation is grounded in real root-cause, topology, and
blast-radius evidence instead of guessing from source code alone.

Each subfolder is a thin, harness-specific integration on top of the same two stable pieces:

- **The trigger payload** — a generic root-cause alert shape (`root_cause_id`, `entity`,
  `severity`, `description`, `remediation`, repo/namespace labels) that Causely's mediator can
  POST to any harness's webhook endpoint.
- **The Causely MCP server** (`https://api.causely.app/mcp`, see [`../mcp/`](../mcp/)) — the same
  hosted MCP server used by Claude Desktop, Cursor, Codex, VS Code, and OpenCode, wired in here as
  a tool source for the agent's investigation loop.

Neither piece is specific to any one harness — the goal is "one stable port, many devices," not a
single blessed background-agent product.

| Harness | Path | Status |
|---------|------|--------|
| [Open-Inspect](https://github.com/ColeMurray/background-agents) | [`open-inspect/`](open-inspect/) | Documented |
| Open SWE (LangChain) | — | Planned |
| AWS DevOps Agent | — | Planned |


More harnesses will be added here over time as they're validated. See each subfolder's own
README for harness-specific setup.
