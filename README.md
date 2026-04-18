# Causely client tooling

This repository bundles **client-side resources** for working with [Causely](https://causely.ai): agent integrations (MCP), a Kubernetes install CLI, and a shell toolkit for the Causely GraphQL API.

| Area | Path | What it is |
|------|------|------------|
| **MCP skills & plugins** | [`mcp/`](mcp/) | Claude (and compatible) **skills** that route work across Causely’s MCP tools, plus **starter configs** for Cursor, Claude, Codex, VS Code Copilot, and OpenCode. |
| **Kubernetes CLI** | [`cli/`](cli/) | Go **CLI** that wraps Helm to install and manage the Causely agent in-cluster. |
| **API shell client** | [`api/`](api/) | **Bash** libraries and scripts for snapshots, comparisons, and CI workflows against the Causely API. |

Product documentation lives at [docs.causely.ai](https://docs.causely.ai/). For MCP authentication, headers, and troubleshooting, start with [MCP Server Integration](https://docs.causely.ai/agent-integration/mcp-server/).

---

## MCP (`mcp/`)

- **[`mcp/README.md`](mcp/README.md)** — Overview of the seven packaged skills (alert triage, change impact, health reporting, K8s investigation, correlated incidents, postmortems, and the master MCP router).
- **[`mcp/plugins/README.md`](mcp/plugins/README.md)** — How to wire the hosted MCP server (`https://api.causely.app/mcp`) into Claude, Cursor, Codex, GitHub Copilot, OpenCode, and related tools, including optional custom headers.
- **Skills** live under [`mcp/skills/`](mcp/skills/) (each folder is a drop-in skill with `SKILL.md` and references).
- **Root skill** — [`mcp/SKILL.md`](mcp/SKILL.md) plus [`mcp/complete-investigation.md`](mcp/complete-investigation.md) for full tool routing and investigation patterns.

---

## CLI (`cli/`)

Install and operate the Causely agent from the terminal. See **[`cli/README.md`](cli/README.md)** for the install script, `causely agent install`, auth, and Helm-oriented flags. Official install guide: [CLI Installation](https://docs.causely.ai/installation/cli/).

```bash
go build -C cli -o causely .
./causely version
```

---

## API client (`api/`)

Shell-based GraphQL client: snapshots, diffing, GitHub Actions examples, and numbered docs. See **[`api/README.md`](api/README.md)** and [`api/docs/`](api/docs/).

---

## Contributing

See **[`CONTRIBUTING.md`](CONTRIBUTING.md)** for project layout, development setup, and how to submit changes.

The Go module for the CLI is declared in [`go.mod`](go.mod) at the repository root (`github.com/Causely/causely-api-client`).
