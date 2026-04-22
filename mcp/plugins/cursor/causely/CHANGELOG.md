# Changelog

## 1.0.0 — 2026-04-22

Initial release of the Causely Cursor Marketplace plugin.

### What's included

- MCP server connection to `https://api.causely.app/mcp` (Streamable HTTP)
- Six packaged skills covering the most common Causely workflows:
  - `causely-alert-triage` — map incoming alerts to root causes
  - `causely-change-impact` — post-deploy regression and blast radius analysis
  - `causely-correlated-incidents` — multi-service failure correlation
  - `causely-health-reporting` — scheduled and on-demand health summaries
  - `causely-k8s-investigation` — Kubernetes infrastructure deep-dives
  - `causely-postmortem` — structured post-mortems and ticket drafts
- OAuth 2.0 authorization code flow (browser sign-in via Causely)
- API credentials fallback (`X-Causely-Client-Basic` header for non-interactive environments)
