# Changelog

## 1.0.0 — 2026-04-22

Initial release of the Causely Cursor Marketplace plugin.

### What's included

- MCP server connection to `https://api.causely.app/mcp` (Streamable HTTP)
- Seven packaged skills (master router plus leaf skills), matching [`mcp/README.md`](../../../README.md):
  - `causely-mcp` — master router for general observability and reliability questions
  - `causely-change-impact` — post-deploy regression and rollout validation
  - `causely-health-reporting` — scheduled and on-demand health summaries
  - `causely-correlated-incidents` — multi-service failure correlation and blast radius
  - `causely-k8s-investigation` — Kubernetes infrastructure deep-dives
  - `causely-postmortem` — structured post-mortems and ticket drafts
  - `causely-alert-triage` — map incoming alerts to root causes
- OAuth 2.0 authorization code flow (browser sign-in via Causely)
- API credentials fallback (`X-Causely-Client-Basic` header for non-interactive environments)
