# Open-Inspect + Causely MCP

[Open-Inspect](https://github.com/ColeMurray/background-agents) is a self-hosted background
coding agent (Cloudflare Workers + Durable Objects + D1, sandboxed execution via Modal / Daytona /
Vercel Sandbox / OpenComputer). Its agent runtime is **OpenCode**, which supports remote MCP
servers via config — so pointing an Open-Inspect automation at Causely's MCP tools is a config
change, not a code contribution to Open-Inspect itself.

This unlocks root-cause, topology, and log evidence for the agent's investigation, instead of it
guessing a fix from source code alone. A real end-to-end run looks like this — Causely's MCP
evidence cited directly in the resulting PR:

![A real GitHub PR opened by Open-Inspect, citing the Causely root-cause ID and evidence](screenshots/githubpr.png)

See [`DEPLOYMENT.md`](DEPLOYMENT.md#12-verify-with-a-real-root-cause) for the full session
transcript this came from.

**Don't have Open-Inspect running yet?** See [`DEPLOYMENT.md`](DEPLOYMENT.md) for a full,
from-scratch walkthrough (Cloudflare, sandbox provider, GitHub App, Terraform deploy) before
coming back here. This page assumes an existing instance and covers only the Causely-specific
wiring.

## What's here

| File | Purpose |
|------|---------|
| [`opencode.json`](opencode.json) | Remote MCP config pointing OpenCode at `https://api.causely.app/mcp` |
| [`setup.sh`](setup.sh) | Example `.openinspect/setup.sh` sandbox hook that drops `opencode.json` in place, with optional header-based auth |
| [`automation-instructions.md`](automation-instructions.md) | Automation `instructions` template, trigger payload shape, and idempotency-key guidance |

## Setup

1. **Create an automation** in your self-hosted Open-Inspect instance, bound to the repo you want
   Causely-triggered investigations to open PRs against.
2. **Copy `opencode.json`** into that repo's root (OpenCode auto-loads project-root config), *or*
   copy `setup.sh` into the repo's `.openinspect/setup.sh` so it's dropped into the sandbox at
   session start — use the hook if you need the optional auth-header logic.
3. **Set the automation's `instructions`** using the template in
   [`automation-instructions.md`](automation-instructions.md).
4. **Point Causely's webhook** at your automation's `POST /webhooks/automation/:id` endpoint with
   its per-automation Bearer API key, using the trigger payload shape documented there — pay
   attention to the idempotency-key section, it has a sharp edge with recurring root causes.
5. If your Causely tenant requires machine credentials rather than browser OAuth for MCP, set
   `CAUSELY_MCP_CLIENT_BASIC` as a secret in the sandbox environment — see
   [MCP Server Integration](https://docs.causely.ai/agent-integration/mcp-server/#authentication).

## Verify

Trigger a test root cause (or manually POST the webhook) and confirm the automation's session
calls `causely__get_root_cause_details` / `causely__get_logs` before it touches source — check the
session transcript in the Open-Inspect UI. If the agent falls back to source-only investigation,
confirm the MCP config actually landed in the sandbox (step 2) before assuming the tools aren't
loading.
