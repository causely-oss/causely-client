# Causely for Cursor

Use Causely directly in Cursor through a preconfigured MCP server. Query service health, root causes, SLOs, metrics, and topology through natural conversation — grounded in system ontology and live causal intelligence.

## Prerequisites

- A [Causely](https://causely.ai) account. Contact support@causely.ai if you need access.
- Cursor with MCP support.

## Installation

Install via **Cursor Settings → Plugins**, search for **Causely**, and click **Install**. Cursor will prompt you to sign in to Causely and grant access.

## Authentication

### OAuth (recommended)

Cursor initiates the OAuth flow automatically on install. Sign in to Causely once — Cursor manages token refresh from that point on.

### API credentials

For non-interactive or CI environments, generate API credentials at [auth.causely.app/oauth/portal/api-tokens](https://auth.causely.app/oauth/portal/api-tokens) and configure the server manually:

```json
{
  "mcpServers": {
    "causely": {
      "url": "https://api.causely.app/mcp",
      "transport": "Streamable HTTP",
      "headers": {
        "X-Causely-Client-Basic": "Basic <base64(client_id:client_secret)>"
      }
    }
  }
}
```

## What you can ask

- "What's the root cause of the checkout service degradation?"
- "Which services are burning their error budget?"
- "What changed before this incident started?"
- "Show me the blast radius of the database slowdown."
- "Are there correlated failures across namespaces?"
- "Write a post-mortem for the incident that resolved an hour ago."
- "What are the top slow queries on the orders database?"
- "Give me a morning health report for the production namespace."

## Packaged skills

This plugin includes six skills that activate automatically for the right type of question:

- `causely-alert-triage` — incoming alerts from PagerDuty, Datadog, Prometheus, OpsGenie
- `causely-change-impact` — post-deploy regression checks and rollout validation
- `causely-correlated-incidents` — multi-service failures and blast radius analysis
- `causely-health-reporting` — health summaries, SLO status, morning briefings
- `causely-k8s-investigation` — Kubernetes infrastructure: pods, nodes, namespaces
- `causely-postmortem` — post-mortems, incident reports, and ticket drafts

## Support

Email: support@causely.ai
Website: https://causely.ai
Docs: https://docs.causely.ai/agent-integration/mcp-server
