---
name: causely-change-impact
description: >
  Use this skill when the user asks about the impact of a recent deployment, configuration change, rollout, or infrastructure update. Trigger for questions like "did our deployment break anything?", "what changed before this incident started?", "validate that the rollout didn't introduce regressions", "is this incident caused by our recent release?", "what's the impact of this config change?", "we just deployed — is everything OK?", "post-deploy health check", "pre/post comparison for our rollout", "check for regressions after deploy", "fleet-wide deploy validation", or "compare metrics before and after release". Also trigger when someone is doing a canary analysis, blue/green switch, or feature flag rollout and wants to know if health metrics changed. Use this skill over generic causely-mcp when the question is specifically change-driven.
---

# Causely Change Impact Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

---

## Core tools for change impact

| Tool | Use when | What it returns |
|---|---|---|
| `triage(entity_name=)` | Quick post-deploy check for one service | Root causes with `started_at` timestamps to compare against deploy time |
| `reliability_delta(service=)` | Metric regression check for one service | Before/after avg+max for CPU, memory, latency, error rate + verdict (PASS/WARNING/REGRESSION/WAIT) |
| `fleet_reliability_delta(team= or namespace= or services=)` | Batch regression check across multiple services | Summary table with per-service verdicts |
| `get_events(entity_id=)` | Find the deploy event / correlate changes | Lifecycle events (deploys, restarts, scaling, config changes) with timestamps |
| `get_config(entity_id=)` | Inspect config drift | Raw config files (manifests, specs) to compare |
| `get_metrics(entity_ids=, metrics=, window_minutes=)` | Custom metric comparison over time window | Time-series data for specific metrics |
| `get_root_causes(active_only=true)` | System-wide post-deploy sweep | All active RCs with `started_at` to filter by deploy time |

---

## Decision tree

**Single-service post-deploy check (recommended path):**
```
reliability_delta(service="<service>")                    ← 1 call
  → verdict: PASS / WARNING / REGRESSION / WAIT
  → per-metric delta: CPU, memory, latency, error rate before vs after
  → if REGRESSION → recommend rollback
  → if WAIT → deploy too recent, re-run later
  → if PASS → deploy is clean
```

If `reliability_delta` returns REGRESSION or WARNING, add context:
```
triage(entity_name="<service>")                           ← 2nd call
  → root cause started_at vs deploy time = causal correlation
  → description = evidence of what broke
  → remediation = what to do next
```

**Fleet-wide post-deploy validation:**
```
fleet_reliability_delta(team="<team>" or namespace="<ns>")  ← 1 call
  → summary table: service | verdict | release time | per-metric delta
  → verdict counts: REGRESSION / WARNING / PASS / WAIT
  → triage only REGRESSION services for detail
```

**Triage-only path (when reliability_delta not needed):**
```
triage(entity_name="<service>")                            ← 1 call
  → root cause started_at before deploy? → change not the cause
  → root cause started_at after deploy? → change is suspect
  → description = evidence of what broke
  → impacted_services = downstream blast radius
  → impacted_customers = customer impact
  → done
```

Only add extra calls if:
- Need to see the actual deploy event → `get_entities` → `get_events(entity_id=, message_contains="version")`
- Need config comparison → `get_entities` → `get_config(entity_id=)`
- Need custom metric time-series → `get_entities` → `get_metrics(entity_ids=, metrics=[...], window_minutes=60)`
- `has_stored_logs=true` AND description generic → `get_logs(root_cause_id=, limit=10, severity_filter=ERROR)`

**Canary / blue-green:**
```
reliability_delta(service="<service-v1>")                  ← 1 call
reliability_delta(service="<service-v2>")                  ← 1 call
  → compare verdicts: regression on v2 only = canary failure
```

---

## Verdict logic

| Signal | Verdict | Action |
|---|---|---|
| `reliability_delta` → PASS, no new root causes | ✅ Safe | Deploy is clean |
| `reliability_delta` → WARNING | ⚠️ Monitor | Watch for escalation; re-check in 30 min |
| `reliability_delta` → REGRESSION | 🔴 Rollback recommended | New root cause correlates with deploy |
| `reliability_delta` → WAIT | ⏳ Too early | Re-run after more post-deploy data accumulates |
| Root cause `started_at` before deploy | ✅ Pre-existing | Change not the cause |
| Root cause `started_at` after deploy | 🔴 Suspect | Check description for confirmation |
| No root causes at all | ✅ Safe | Service is healthy |

---

## Output format

### 🚀 Deployment validation report

**Service:** [service-name] · **Deploy time:** [from reliability_delta or get_events] · **Report:** [now]

**Verdict:** ✅ Safe / ⚠️ Monitor / 🔴 Rollback recommended / ⏳ Too early

**Metric deltas:**
| Metric | Before (avg) | After (avg) | Delta | Status |
|---|---|---|---|---|
| [from reliability_delta response] |

**New root causes since deploy:** [name + started_at, or "None detected"]

**Evidence:** [from description field; supplement with get_logs only if generic AND has_stored_logs=true]

**Blast radius:** [from impacted_services]

**Customer impact:** [from impacted_customers]

**Owner:** [from causely.ai/team label or team_health]

**Recommended actions:** [from remediation field; rollback recommendation if 🔴]

**Links:** [portal links]
