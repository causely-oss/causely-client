---
name: causely-change-impact
description: >
  Use this skill when the user asks about the impact of a recent deployment, configuration change, rollout, or infrastructure update. Trigger for questions like "did our deployment break anything?", "what changed before this incident started?", "validate that the rollout didn't introduce regressions", "is this incident caused by our recent release?", "what's the impact of this config change?", "we just deployed — is everything OK?", "post-deploy health check", "pre/post comparison for our rollout", "check for regressions after deploy", "fleet-wide deploy validation", or "compare metrics before and after release". Also trigger when someone is doing a canary analysis, blue/green switch, or feature flag rollout and wants to know if health metrics changed. Use this skill over generic causely-mcp when the question is specifically change-driven.
---

# Causely Change Impact Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for change impact

| Tool | Use when | What it returns |
|---|---|---|
| `reliability_delta(service=)` | Metric regression check for one service | Before/after avg+max for CPU, memory, latency, error rate + verdict |
| `fleet_reliability_delta(team= or namespace= or services=)` | Batch regression check across multiple services | Summary table with per-service verdicts |
| `get_service_summary(service=)` | Post-deploy health check with full context | Status + symptoms + root causes + SLOs + metrics + deps + events |
| `triage(entity_name=)` | Deep investigation when regression detected | Structured narrative with portal links for degraded services |
| `name_lookup` → `get_events(entity_id=)` | Find the deploy event / correlate changes | Lifecycle events with timestamps |
| `name_lookup` → `get_config(entity_id=)` | Inspect config drift | Raw config files |
| `name_lookup` → `get_metrics(entity_ids=, metrics=, window_minutes=)` | Custom metric comparison over time window | Time-series data |

---

## Decision tree

**Single-service post-deploy check (recommended path):**
```
reliability_delta(service="<service>")                    ← 1 call
  → verdict: PASS / WARNING / REGRESSION / WAIT
  → if REGRESSION → triage(entity_name=) for deep investigation
  → if PASS → deploy is clean
```

**Fleet-wide post-deploy validation:**
```
fleet_reliability_delta(team="<team>" or namespace="<ns>")  ← 1 call
  → per-service verdicts
  → triage only REGRESSION services for detail
```

**Quick post-deploy health check (alternative):**
```
get_service_summary(service="<service>")                   ← 1 call
  → full picture including recent events (will show the deploy)
  → root causes with started_at to compare against deploy time
```

**Deep investigation after regression detected:**
```
triage(entity_name="<service>")                            ← 1 call
  → root cause started_at vs deploy time = causal correlation
  → description = evidence of what broke
```

---

## Output format

### 🚀 Deployment validation report

**Service:** [name] · **Deploy time:** [from reliability_delta or get_events] · **Verdict:** ✅ Safe / ⚠️ Monitor / 🔴 Rollback recommended / ⏳ Too early

**Metric deltas:** [from reliability_delta]
**New root causes since deploy:** [name + started_at, or "None"]
**Evidence:** [from description field]
**Blast radius:** [from impacted_services]
**Recommended actions:** [from remediation; rollback if 🔴]
**Links:** [portal links]
