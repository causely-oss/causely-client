---
name: causely-change-impact
description: >
  Use this skill when the user asks about the impact of a recent deployment, configuration change, rollout, or infrastructure update. Trigger for questions like "did our deployment break anything?", "what changed before this incident started?", "validate that the rollout didn't introduce regressions", "is this incident caused by our recent release?", "we just deployed — is everything OK?", "post-deploy health check", "pre/post comparison for our rollout", "check for regressions after deploy", "fleet-wide deploy validation", or "compare metrics before and after release". Also trigger for canary analysis, blue/green switches, or feature flag rollouts.
---

# Causely Change Impact Skill

Read `references/complete-investigation.md` for the full 28-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs.

---

## Core tools for change impact

| Tool | Use when | What it returns |
|---|---|---|
| `reliability_delta(service=)` | Metric regression check for one service | Before/after metric comparison + verdict |
| `fleet_reliability_delta(team= or namespace= or services=)` | Batch regression check across services | Per-service verdicts |
| `get_service_summary(service=)` | Post-deploy health check with full context | Status + symptoms + RCs + SLOs + metrics + deps + events |
| `get_incident_impact(root_cause_id=)` | Deep investigation when regression detected | Responsible service + business context + blast radius |
| `name_lookup` → `get_events(entity_id=)` | Find the deploy event | Lifecycle events with timestamps |
| `name_lookup` → `get_config(entity_id=)` | Inspect config drift | Raw config files |
| `name_lookup` → `get_metrics(entity_ids=, metrics=, window_minutes=)` | Custom metric comparison | Time-series or aggregated data |

---

## Decision tree

**Single-service:** `reliability_delta(service=)` → if REGRESSION: `get_incident_impact(root_cause_id=)`

**Fleet-wide:** `fleet_reliability_delta(team= or namespace=)` → `get_incident_impact` for REGRESSION services

**Quick health check:** `get_service_summary(service=)`

---

## Output format

### 🚀 Deployment validation report

**Service:** [name] · **Verdict:** ✅ Safe / ⚠️ Monitor / 🔴 Rollback recommended / ⏳ Too early
**Metric deltas:** [from reliability_delta]
**Responsible:** [from get_incident_impact]
**Blast radius:** [from impacted_services]
**Links:** [portal links]
