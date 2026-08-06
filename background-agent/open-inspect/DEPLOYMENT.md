# Deploying Open-Inspect for automated remediation with Causely

This walks through standing up a **self-hosted Open-Inspect instance** from scratch and wiring it
to Causely, so that a real Kubernetes root cause automatically triggers an investigation grounded
in Causely's MCP evidence and — where warranted — opens a GitHub PR with the fix.

If you already have Open-Inspect running, skip to [`README.md`](README.md) instead — that's the
short version covering only the Causely-specific wiring.

## What you end up with

```
Causely root cause  →  webhook  →  Open-Inspect control plane  →  sandboxed agent session
                                                                        │
                                                                        ├─ Causely MCP tools
                                                                        │  (root cause, logs,
                                                                        │   topology, evidence)
                                                                        └─ GitHub PR with the fix
```

Open-Inspect ([`ColeMurray/background-agents`](https://github.com/ColeMurray/background-agents))
is self-hosted on Cloudflare Workers + Durable Objects + D1, with sandboxed agent execution on a
provider of your choice (Modal, Daytona, Vercel Sandbox, or OpenComputer — this guide uses Modal).
Its agent runtime, OpenCode, already supports remote MCP servers via config, so pointing it at
Causely's MCP server is a config change, not a fork or code contribution.

## Prerequisites

You'll need accounts / access for:

- **Cloudflare** — hosts the control plane and (optionally) the web UI
- **Modal** (or your chosen sandbox provider) — runs the ephemeral agent sessions
- **GitHub** — a GitHub App with write access to the repo(s) you want investigated
- **Anthropic** — an API key for the agent's model calls
- **Terraform** ≥ v1.14.0 — deploys everything above
- A **Causely** tenant with MCP access (see [`../../mcp/`](../../mcp/) for the MCP server itself)

## 1. Cloudflare

1. Sign up at [dash.cloudflare.com](https://dash.cloudflare.com).
2. Note your **Account ID** and **Workers subdomain** (Workers & Pages → Overview → Account
   Details panel).
3. Enable R2 (Storage & databases → R2 → Enable R2 — the first 10GB/month is free, but this
   requires adding billing info). Create a bucket to hold Terraform's remote state, e.g.
   `open-inspect-terraform-state`.
4. Create two API tokens:
   - An **account-scoped token** for R2 (Object Read & Write) — this is the access key / secret
     pair Terraform's S3-compatible backend uses.
   - A **main token** from the "Edit Cloudflare Workers" template, with Workers Scripts, Workers
     KV Storage, Workers R2 Storage, and D1 all set to Edit.

At real-world request volumes for a single team, expect this to stay within Cloudflare Workers'
free tier (100,000 requests/day) — the request counter includes the web UI's own dashboard
polling, which can look higher than actual traffic at a glance.

## 2. Modal

1. Sign up at [modal.com](https://modal.com) (GitHub OAuth is the fastest path).
2. `pip3 install modal && modal setup` — this authorizes via browser and writes your workspace
   name + token pair to `~/.modal.toml`.

## 3. GitHub App

1. Create one at `github.com/settings/apps/new`.
2. **Homepage URL** and **Callback URL**: Open-Inspect deploys the web UI and the control plane
   as *two separate Cloudflare Workers*. The callback needs to point at the **web** worker, not
   the control plane:
   ```
   https://open-inspect-web-<deployment_name>.<workers-subdomain>.workers.dev/api/auth/callback/github
   ```
   A placeholder is fine before your first deploy — Terraform's plan output will confirm the real
   URL; double-check and correct it afterward if you guessed wrong.
3. **Repository permissions**: Contents (Read & write), Pull requests (Read & write).
4. Generate a **Client Secret** and a **private key**, then install the app on the target
   repo(s) — note the **Installation ID** from the post-install URL.
5. Convert the downloaded private key from PKCS#1 to PKCS#8 (Terraform requires PKCS#8):
   ```
   openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in <downloaded>.pem -out <converted>.pem
   ```

## 4. Anthropic

Create an API key at [console.anthropic.com](https://console.anthropic.com).

## 5. Terraform CLI

Check `terraform/environments/production/versions.tf` in the Open-Inspect repo for the minimum
required version (≥ v1.14.0 at time of writing). If your package manager's version is older or
policy-restricted, install directly from HashiCorp's signed release and verify the checksum:

```bash
curl -sSL -o terraform.zip https://releases.hashicorp.com/terraform/<version>/terraform_<version>_darwin_arm64.zip
curl -sSL -o terraform_SHA256SUMS https://releases.hashicorp.com/terraform/<version>/terraform_<version>_SHA256SUMS
grep darwin_arm64 terraform_SHA256SUMS   # compare against: shasum -a 256 terraform.zip
unzip terraform.zip -d ~/bin && chmod +x ~/bin/terraform
```

## 6. Clone and configure Terraform

```bash
git clone https://github.com/ColeMurray/background-agents.git
cd background-agents/terraform/environments/production
cp terraform.tfvars.example terraform.tfvars
cp backend.tfvars.example backend.tfvars
```

Fill in both files with the values gathered above. Generate the required security secrets:

```bash
openssl rand -base64 32   # token_encryption_key, repo_secrets_encryption_key,
                          # internal_callback_secret, nextauth_secret
openssl rand -hex 32      # modal_api_secret, github_webhook_secret
```

Decide:
- `web_platform = "cloudflare"` (keeps everything on Cloudflare; use `"vercel"` if you'd rather
  host the web UI there)
- `sandbox_provider = "modal"` (or your chosen provider)
- a unique `deployment_name`
- at least one allowlist entry (`allowed_users`, `allowed_email_domains`, `allowed_emails`, or
  `allowed_github_orgs`) — controls who can sign into the web UI

Leave `enable_durable_object_bindings = false` and `enable_service_bindings = false` for the first
deploy — these are enabled in a second pass, below.

## 7. Prerequisite builds

From the repo root:

```bash
npm install -g wrangler   # plus Python 3.12+ and uv, if not already present
npm install
npm run build -w @open-inspect/shared
cd packages/modal-infra && uv sync --frozen && cd -
npm run build -w @open-inspect/control-plane -w @open-inspect/slack-bot \
  -w @open-inspect/github-bot -w @open-inspect/linear-bot
```

(The web app's own build runs automatically during `terraform apply` via a `local-exec`
provisioner — no separate manual step.)

## 8. Deploy (two phases)

```bash
terraform init -backend-config=backend.tfvars
terraform plan -out=phase1.tfplan   # review before applying
terraform apply phase1.tfplan       # phase 1: bindings disabled
```

Verify with the health-check URLs from the plan output (control plane `/health`, Modal
`/api_health`, and the web app root should all return 200). Then flip both binding flags to
`true` in `terraform.tfvars` and repeat:

```bash
terraform plan -out=phase2.tfplan
terraform apply phase2.tfplan       # phase 2: bindings enabled
```

Re-verify the same health checks, and confirm `/sessions` now returns 401 unauthenticated
(confirms auth is actually live).

> **Note**: the `cloudflare_workers_cron_trigger` resource cannot be destroyed via Terraform —
> expect a warning on every apply/destroy; delete it manually via the Cloudflare dashboard if you
> ever tear this down.

## 9. Wire in Causely's MCP server

Add [`opencode.json`](opencode.json) to the root of the repo you want investigated (OpenCode
auto-loads project-root config), pointed at your Causely tenant's MCP endpoint
(`https://api.causely.app/mcp` for the hosted service). If your tenant needs a sandbox-injected
auth header instead of static config, use [`setup.sh`](setup.sh) as a `.openinspect/setup.sh`
hook instead — see [`README.md`](README.md) for details on both options.

## 10. Create the automation

In the Open-Inspect web UI:

1. Sign in via GitHub OAuth — you'll land on the repo/branch/model selector:

   ![Open-Inspect web UI landing page](screenshots/OpenInspect_webui.png)

2. **Create Automation** → **Trigger Type: Inbound Webhook**:

   ![Blank Create Automation form, trigger-type picker](screenshots/CreateAutomation.png)

3. **Repository Configuration** → bind to your target repo.
4. **Instructions** → use the template in
   [`automation-instructions.md`](automation-instructions.md).
5. Save — the UI reveals the automation's **Webhook URL** and a per-automation **API Key**
   exactly once. Store both; you'll need the API key as a Bearer token on every trigger call.

   ![Post-creation reveal of the webhook URL and API key](screenshots/AutomationCreated.png)

Once saved, the automation's detail page shows its configuration, the full instructions text, and
run history:

![Saved automation detail page — trigger type, model, instructions, run history](screenshots/ActualAutomationTrigger.png)

## 11. Connect Causely's alerts to the automation

Point Causely's root-cause notifications at the automation's webhook
(`POST <control-plane-url>/webhooks/automation/<id>`) with `Authorization: Bearer <api-key>`,
using the trigger payload shape and idempotency-key guidance in
[`automation-instructions.md`](automation-instructions.md).

**Known limitation as of this writing**: if you're using Causely's own mediator component to
deliver alerts, its trigger-webhook configuration supports exactly one destination URL with no
custom-header support — so it can't attach the automation's Bearer token directly. Until that's
resolved, either add a small relay that injects the header, or trigger the webhook manually /
via your own alerting glue for now. This does not affect anything else in this guide — the
agent investigation and MCP evidence gathering work identically either way.

## 12. Verify with a real root cause

Don't fabricate a test payload if you can help it — reintroduce a real, known-fixable bug (e.g. a
bad image tag in a manifest) and let Causely's analysis engine detect and fire the root cause
naturally (this can take several minutes, not instant). Pull the real root cause's details via
Causely's MCP tools (`get_root_causes` / `get_root_cause_details`) rather than inventing IDs or
evidence, then trigger the automation with that real data.

Confirm in the Open-Inspect UI's session transcript that the agent calls
`causely__get_root_cause_details` / `causely__get_logs` (or similar) **before** it touches
source — that's the signal the MCP wiring is actually influencing the investigation, not just
loaded and ignored.

Right after triggering, the session transcript shows the raw webhook payload injected as
untrusted context, and the sandbox spinning up:

![Session transcript: webhook JSON injected, sandbox spawning](screenshots/WebhookTriggered_SandboxSpawning.png)

You can independently cross-check that real infrastructure is doing the work — not just the UI
claiming so — on your sandbox provider's own dashboard:

![Modal dashboard: sandbox creation in progress](screenshots/ModalSandboxSpawning.png)
![Modal dashboard: sandbox creation succeeded](screenshots/ModalSandboxSucceeded.png)

The money shot is the agent actually calling Causely's MCP tools with real arguments before
touching source — this is what distinguishes "grounded in real evidence" from "guessed from the
manifest":

![Session transcript: real causely__get_root_cause_details / get_entity_health / get_logs calls](screenshots/CauselyMCP.png)
![Expanded tool-call detail: real root cause ID, causal chain, entity health](screenshots/mcpdetails.png)

And the result — a real PR, citing the real root-cause ID and the actual evidence that led to the
diagnosis:

![Final session summary card: cost, files changed, PR link](screenshots/OpenPR.png)
![The resulting GitHub PR](screenshots/githubpr.png)

## Troubleshooting

- **Session shows "Sandbox: failed" even though your sandbox provider's own dashboard shows the
  underlying job succeeded.**

  ![Session view showing "Sandbox: failed" despite the underlying job succeeding](screenshots/sandboxFailed.png)

  This can happen as a one-off timing issue right after a fresh
  deploy or after flipping the binding flags — before assuming real misconfiguration, retry once
  and check both sides' logs: `modal app logs <app-name>` (from `packages/modal-infra`, via
  `uv run modal app logs <app-name>`) for the sandbox side, and
  `wrangler tail <control-plane-worker-name>` (needs `CLOUDFLARE_API_TOKEN` set for
  non-interactive auth) for the control-plane side.
- **Git clone inside the sandbox fails with a 401 from the control plane.** Same class of issue
  as above — the sandbox's per-session token is generated at session-creation time and can
  occasionally fail to propagate on the very first session after a redeploy. Retry with a fresh
  `idempotency_key` before concluding the GitHub App or token config is wrong.
- **OAuth callback fails after your first deploy.** Double-check the GitHub App's Homepage/
  Callback URLs actually match the `-web-` worker's real URL from `terraform plan` output, not
  the control-plane worker's URL — this is the single easiest thing to get wrong before your
  first apply.

## Tearing down

```bash
terraform destroy   # from terraform/environments/production/
```

This removes the Workers, Durable Objects, D1 database, and any Cloudflare-managed R2 media
bucket. It does **not** remove the Terraform-state R2 bucket, or anything in Modal / GitHub /
Anthropic — clean those up separately:

- Delete the state R2 bucket if no longer needed.
- Revoke both Cloudflare API tokens.
- Revoke your sandbox provider's token if the workspace won't be reused.
- Uninstall (and optionally delete) the GitHub App.
- Revoke the Anthropic API key if it was created solely for this deployment.
- Delete `terraform.tfvars` / `backend.tfvars` locally if the credentials inside should no longer
  exist anywhere.
