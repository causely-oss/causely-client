---
name: causely-change-impact
description: >
  Use this skill when the user asks about the impact of a recent deployment, configuration change, rollout, or infrastructure update. Trigger for questions like "did our deployment break anything?", "what changed before this incident started?", "validate that the rollout didn't introduce regressions", "is this incident caused by our recent release?", "we just deployed — is everything OK?", "post-deploy health check", "pre/post comparison for our rollout", "check for regressions after deploy", "fleet-wide deploy validation", or "compare metrics before and after release". Also trigger for canary analysis, blue/green switches, or feature flag rollouts.
---

# Causely Change Impact Skill

Read `references/complete-investigation.md` for the full 30-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names.

---

## Core tools

| Tool | Use when |
|---|---|
| `reliability_delta(service=)` | Metric regression check for one service |
| `fleet_reliability_delta(team= or namespace=)` | Batch regression check |
| `get_service_summary(service=)` | Post-deploy health check |
| `get_root_cause_details(root_cause_id=)` | Full evidence when regression detected |
| `get_incident_impact(root_cause_id=)` | Responsibility + business context |

---

## Decision tree

**Single-service:** `reliability_delta(service=)` → if REGRESSION: `get_root_cause_details` then `get_incident_impact`

**Fleet-wide:** `fleet_reliability_delta(team= or namespace=)` → detail per REGRESSION service

**Quick health check:** `get_service_summary(service=)`

---

## Output format

### 🚀 Deployment validation report

**Service:** [name] · **Deploy time:** [from reliability_delta or get_events] · **Report:** [now]
**Verdict:** ✅ Safe / ⚠️ Monitor / 🔴 Rollback recommended / ⏳ Too early
**Metric deltas:**
| Metric | Before (avg) | After (avg) | Delta | Status |
|---|---|---|---|---|
| [from reliability_delta response] |
**New root causes since deploy:** [name + started_at, or "None detected"]
**Evidence:** [from description field; from get_root_cause_details causal_chain if called]
**Blast radius:** [from get_root_cause_details impact_service_graph or impacted_services]
**Customer impact:** [from impacted_customers or get_incident_impact impacted_context]
**Responsible:** [from get_incident_impact responsible_context or causely.ai/team label]
**Recommended actions:** [from remediation field; rollback recommendation if 🔴]
**Links:** [portal links]
