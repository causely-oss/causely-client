---
name: causely-change-impact
description: >
  Use this skill when the user asks about the impact of a recent deployment, configuration change, rollout, or infrastructure update. Trigger for questions like "did our deployment break anything?", "what changed before this incident started?", "validate that the rollout didn't introduce regressions", "is this incident caused by our recent release?", "we just deployed — is everything OK?", "post-deploy health check", "pre/post comparison for our rollout", "check for regressions after deploy", "fleet-wide deploy validation", or "compare metrics before and after release". Also trigger for canary analysis, blue/green switches, or feature flag rollouts.
---

# Causely Change Impact Skill

Read `references/complete-investigation.md` for the full 23-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for change impact

| Tool | Use when | What it returns |
|---|---|---|
| `reliability_delta(service=)` | Metric regression check for one service | Before/after avg+max for CPU, memory, latency, error rate + verdict |
| `fleet_reliability_delta(team= or namespace= or services=)` | Batch regression check across multiple services | Summary table with per-service verdicts |
| `get_service_summary(service=)` | Post-deploy health check with full context | Status + symptoms + root causes + SLOs + metrics + deps + events |
| `get_incident_impact(root_cause_id=)` | Deep investigation when regression detected — who's responsible, what's impacted | Responsible service + business context + blast radius |
| `name_lookup` → `get_events(entity_id=)` | Find the deploy event / correlate changes | Lifecycle events with timestamps |
| `name_lookup` → `get_config(entity_id=)` | Inspect config drift | Raw config files |
| `name_lookup` → `get_metrics(entity_ids=, metrics=, window_minutes=)` | Custom metric comparison over time window | Time-series or aggregated data |

---

## Decision tree

**Single-service post-deploy check (recommended):**
```
reliability_delta(service="<service>")                    ← 1 call
  → verdict: PASS / WARNING / REGRESSION / WAIT
  → if REGRESSION → get_incident_impact(root_cause_id=) for responsibility + impact
  → if PASS → deploy is clean
```

**Fleet-wide post-deploy validation:**
```
fleet_reliability_delta(team="<team>" or namespace="<ns>")  ← 1 call
  → per-service verdicts
  → get_incident_impact only for REGRESSION services
```

**Quick post-deploy health check (alternative):**
```
get_service_summary(service="<service>")                   ← 1 call
```

---

## Output format

### 🚀 Deployment validation report

**Service:** [name] · **Deploy time:** [from reliability_delta] · **Verdict:** ✅ Safe / ⚠️ Monitor / 🔴 Rollback recommended / ⏳ Too early

**Metric deltas:** [from reliability_delta]
**New root causes since deploy:** [name + started_at, or "None"]
**Responsible:** [from get_incident_impact responsible_context]
**Blast radius:** [from impacted_services]
**Recommended actions:** [from remediation; rollback if 🔴]
**Links:** [portal links]
