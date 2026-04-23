# Causely for Claude

Connect Causely to Claude for root cause analysis, service health, SLOs, metrics, topology, and incident tooling — directly in your conversations.

All tools are read-only. Causely does not execute changes through this connection.

## Claude.ai (browser)

### Pro / Max

1. Go to **claude.ai → Customize → Connectors**
2. Click **+** then **Add custom connector**
3. Enter a name (e.g. `Causely`) and the server URL: `https://api.causely.app/mcp`
4. Click **Add**
5. Sign in to Causely and grant access
6. Return to Claude.ai — the connector is now active

### Team / Enterprise

1. Go to **Organization settings → Connectors**
2. Click **Add → Custom → Web**
3. Enter the server URL: `https://api.causely.app/mcp`
4. Click **Add**
5. Team members authenticate individually at **Customize → Connectors**

## Claude Desktop

Copy `claude_desktop_config.json` and merge the `mcpServers` block into:

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Restart Claude Desktop after saving.

## Claude Code

Copy `.mcp.json` to your repository root, or merge its `mcpServers` block into your existing `.mcp.json`.

## Authentication

### OAuth (recommended)

Claude initiates the OAuth flow automatically. Sign in to Causely once — Claude manages token refresh from that point on.

### API credentials

For non-interactive environments, generate credentials at [auth.causely.app/oauth/portal/api-tokens](https://auth.causely.app/oauth/portal/api-tokens) and add the header:

```
X-Causely-Client-Basic: Basic <base64(client_id:client_secret)>
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Connector failed to connect" | Confirm URL is `https://api.causely.app/mcp`; contact support@causely.ai |
| No data returned | Check integration status in the Causely portal |
| Auth prompt loops | Clear browser cache and try again |

## Support

Email: support@causely.ai
Docs: https://docs.causely.ai/agent-integration/mcp-server
