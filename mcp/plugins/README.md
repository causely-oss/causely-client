# Causely MCP — agent configuration

This folder contains **starter snippets** for connecting AI agents to the hosted Causely MCP server at `https://api.causely.app/mcp`. Copy the relevant block into your tool’s real config file (paths differ per product).

For authentication details (browser OAuth vs client ID/secret), encoding rules for `X-Causely-Client-Basic`, and troubleshooting, see the [MCP Server Integration](https://docs.causely.ai/agent-integration/mcp-server/) documentation.

## Layout

| Path | Agent / product | Typical destination |
|------|-----------------|---------------------|
| `claude/causely/claude_desktop_config.json` | **Claude Desktop** | macOS: `~/Library/Application Support/Claude/claude_desktop_config.json` (merge the `mcpServers` object) |
| `claude/causely/.mcp.json` | **Claude Code** (and other tools that read project-level MCP JSON) | Repository `.mcp.json` or tool-specific location per their docs |
| `cursor/causely/mcp.json` | **Cursor** | Project `.cursor/mcp.json`, or merge into user MCP config from **Settings → MCP** |
| `codex/causely/config.toml` | **OpenAI Codex** | `~/.codex/config.toml` or project `.codex/config.toml` (merge the `[mcp_servers.causely]` table) |
| `vscode/causely/mcp.json` | **GitHub Copilot in VS Code** | Workspace `.vscode/mcp.json`, or user MCP config via **MCP: Open User Configuration** |
| `opencode/causely/opencode.json` | **OpenCode** | Project `opencode.json` at the repo root, or global `~/.config/opencode/opencode.json` (merge the `mcp` object) |

After any change, **restart the agent or IDE** so it reloads MCP settings.

---

## Claude Desktop (`stdio` + `mcp-remote`)

Claude Desktop often uses **stdio** with [`mcp-remote`](https://www.npmjs.com/package/mcp-remote) so OAuth and streamable HTTP work without native HTTP MCP support.

**Default (browser OAuth via `mcp-remote`):** see `claude/causely/claude_desktop_config.json`.

**Optional headers on the outbound HTTP connection** use repeated `--header` arguments. `mcp-remote` can expand `${ENV_VAR}` inside header values, which avoids putting secrets directly in JSON:

```json
{
  "mcpServers": {
    "causely": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://api.causely.app/mcp/",
        "--header",
        "X-Causely-Client-Basic: Basic ${CAUSELY_MCP_CLIENT_BASIC}"
      ]
    }
  }
}
```

Set `CAUSELY_MCP_CLIENT_BASIC` to the Base64 encoding of `client_id:client_secret` (without a `Basic ` prefix in the variable—the example adds the prefix in the header). See the [authentication section](https://docs.causely.ai/agent-integration/mcp-server/#authentication) of the docs for when this applies versus Bearer tokens from OAuth.

---

## Claude Code / `.mcp.json`

Project-level MCP for Claude Code is often a `.mcp.json` with the same `mcpServers` shape as above. The included `claude/causely/.mcp.json` uses HTTP transport; **add a `headers` object** beside `url` when you need static or machine credentials, using the same HTTP examples as in the **Cursor** section below.

---

## Cursor and other JSON `mcpServers` clients

Many editors use a top-level `mcpServers` object. For a **remote HTTP** transport you can set `"type": "http"`, the `url`, and optional **`headers`** sent on every MCP request.

**Minimal (interactive OAuth is handled by the client when supported):**

```json
{
  "mcpServers": {
    "causely": {
      "type": "http",
      "url": "https://api.causely.app/mcp"
    }
  }
}
```

**With optional custom headers** (for example [tenant API client credentials](https://auth.causely.app/oauth/portal/api-tokens) when your stack must not rely on browser OAuth alone):

```json
{
  "mcpServers": {
    "causely": {
      "type": "http",
      "url": "https://api.causely.app/mcp",
      "headers": {
        "X-Causely-Client-Basic": "<Base64(client_id:client_secret)>"
      }
    }
  }
}
```

The value for `X-Causely-Client-Basic` is either the **raw Base64** string for `client_id:client_secret`, or the same prefixed as `Basic <Base64(...)>`. Do not commit real secrets; use your tool’s secret or env substitution if it supports it.

**Another optional header** (same `headers` map—add any name/value your proxy or policy requires):

```json
{
  "mcpServers": {
    "causely": {
      "type": "http",
      "url": "https://api.causely.app/mcp",
      "headers": {
        "X-Causely-Client-Basic": "Basic <Base64(client_id:client_secret)>"
      }
    }
  }
}
```

Some clients also accept a **URL-only** shorthand (no `"type"`); see `cursor/causely/mcp.json` in this repo for that variant.

---

## OpenAI Codex (`config.toml`)

Codex configures MCP under `[mcp_servers.<name>]`. The sample `codex/causely/config.toml` enables the Causely URL only.

For **optional HTTP headers** on streamable HTTP servers, Codex uses the fields **`http_headers`** (static values) and **`env_http_headers`** (values read from environment variables at runtime). In TOML you can write each map as a **nested subtable** under the server name (equivalent to an inline `http_headers = { ... }` map).

**Static header example:**

```toml
[mcp_servers.causely]
url = "https://api.causely.app/mcp"
enabled = true

[mcp_servers.causely.http_headers]
"X-Causely-Client-Basic" = "Basic <Base64(client_id:client_secret)>"
```

**Header value from an environment variable:**

```toml
[mcp_servers.causely]
url = "https://api.causely.app/mcp"
enabled = true

[mcp_servers.causely.env_http_headers]
"X-Causely-Client-Basic" = "CAUSELY_MCP_CLIENT_BASIC"
```

Export `CAUSELY_MCP_CLIENT_BASIC` in your shell (or secret manager integration) to the Base64 string or full `Basic …` value, per the product docs above.

---

## GitHub Copilot (Visual Studio Code)

Copilot’s MCP integration uses a dedicated **`mcp.json`** file whose top-level key is **`servers`** (not `mcpServers`). See Microsoft’s [MCP configuration reference](https://code.visualstudio.com/docs/copilot/reference/mcp-configuration) and [Add and manage MCP servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers).

**Where to put it**

- **Workspace:** `.vscode/mcp.json` (good for team sharing; commit only non-secret defaults).
- **User:** Command Palette → **MCP: Open User Configuration** (available in all workspaces for that VS Code profile).

**Minimal HTTP server** (starter file: `vscode/causely/mcp.json`):

```json
{
  "servers": {
    "causely": {
      "type": "http",
      "url": "https://api.causely.app/mcp"
    }
  }
}
```

**Optional `headers`** on the HTTP transport (machine / client-credentials flow, or extra proxy headers). VS Code documents an optional `headers` map on HTTP MCP servers:

```json
{
  "servers": {
    "causely": {
      "type": "http",
      "url": "https://api.causely.app/mcp",
      "headers": {
        "X-Causely-Client-Basic": "Basic <Base64(client_id:client_secret)>"
      }
    }
  }
}
```

**Secrets:** Prefer **`inputs`** and `${input:…}` in `headers` (or `env` for stdio) so API values are prompted once and stored securely—see the [input variables](https://code.visualstudio.com/docs/copilot/reference/mcp-configuration#_input-variables-for-sensitive-data) section of the same reference.

**Org policy:** If you use Copilot Business / Enterprise, an admin may need to allow MCP servers (“MCP servers in Copilot”). See GitHub’s Copilot documentation for your plan.

---

## OpenCode

[OpenCode](https://opencode.ai/docs/mcp-servers/) loads MCP definitions from **`opencode.json`**: project root, or globally under **`~/.config/opencode/opencode.json`**. Remote servers use **`"type": "remote"`**, a **`url`**, and an optional **`headers`** object.

**Minimal** (starter: `opencode/causely/opencode.json`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "causely": {
      "type": "remote",
      "url": "https://api.causely.app/mcp",
      "enabled": true
    }
  }
}
```

**With optional headers** (same semantics as Causely’s other HTTP clients; avoid committing secrets):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "causely": {
      "type": "remote",
      "url": "https://api.causely.app/mcp",
      "enabled": true,
      "headers": {
        "X-Causely-Client-Basic": "<Base64(client_id:client_secret)>"
      }
    }
  }
}
```

**Local stdio alternative:** If you prefer `mcp-remote` (browser OAuth, Node on PATH), OpenCode also supports **`"type": "local"`** with a **`command`** array—mirror the Claude Desktop `npx` + `mcp-remote` example but under `mcp.causely` per [OpenCode MCP docs](https://opencode.ai/docs/mcp-servers/).

---

## Quick verification

After configuration, ask the agent something concrete, for example: *“Ask Causely: what defects are currently active?”* If nothing returns, confirm you completed OAuth where required, that **Ask Causely** is enabled for your tenant, and that Node/npm are on `PATH` when using `npx mcp-remote`.
