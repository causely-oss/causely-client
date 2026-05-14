---
name: causely-health-reporting
description: >
  Use this skill when the user wants a scheduled, proactive, or summary view of system health — not an active incident. Trigger for requests like "give me the morning health report", "what's the state of the system?", "weekly reliability summary", "anything I should know before standup?", "system health overview", "how are our services doing overall?", "what's been flapping this week?", "generate a status update", "what should the on-call team watch out for?", "SLO status report", "environment health check", "namespace health", "full service report", "is X healthy?", or "are any SLOs at risk?". Also trigger when someone asks for a digest, briefing, or dashboard-style summary rather than asking about a specific incident.
---

# Causely Health Reporting Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for health reporting

| Tool | Use when | What it returns |
|---|---|---|
| `get_service_summary(service=)` | **Primary tool for single-service health by name.** Resolves name automatically. | Status + symptoms + root causes + SLOs + metrics + deps + slow queries + events + errors |
| `get_environment_health()` | Global or scoped health overview | Overall status (HEALTHY/DEGRADED/CRITICAL) + active root causes + remediation |
| `get_root_causes(active_only=true)` | All active issues with evidence | Structured JSON: description, impacted_services, impacted_customers per RC |
| `team_health(team=)` | Team-scoped standup | Degraded/critical services first, healthy grouped at end |
| `get_symptoms()` | **All active symptoms across every entity** — no entity IDs needed | Full signal picture: crash signals, OOM kills, pod failures, latency, errors |
| `name_lookup` → `get_slo(entity_ids=)` | SLO error budget and burn rate for specific services | Per-SLO: budget remaining %, burn rate, at-risk/violated flags |
| `ask_causely(question=)` | System-wide SLO overview (no entity IDs needed) | "Which services have SLOs at risk or violated?" |
| `get_entity_health(entity_id=)` | Non-service entity health (DBs, pods, queues) | Symptoms, root causes, events, logs, metrics for one entity |

---

## Decision tree

**"Is X healthy?" → `get_service_summary` (1 call)**
```
get_service_summary(service="<name>")                      ← 1 call
  → status: HEALTHY / AT_RISK / DEGRADED
  → symptoms, root causes, SLOs, metrics, deps, events, logs
  → done
```

**Morning standup / system sweep:**
```
get_environment_health()                                  ← 1 call
  → overall status + active root causes with remediation
```

Or for all signals including crash/OOM/pod failures:
```
get_symptoms()                                            ← 1 call, no entity IDs needed
  → all active symptoms across every entity
```

**Namespace/cluster/product-scoped health:**
```
get_environment_health(namespaces=["otel-demo"])           ← 1 call
get_environment_health(clusters=["prod-cluster"])          ← 1 call
get_environment_health(products=["payments"])              ← 1 call
```

**Team standup:**
```
team_health(team="<team>")                                 ← 1 call
  → for each degraded: get_service_summary(service=) if full detail needed
```

**SLO-focused report:**
```
ask_causely("Which services have SLOs at risk or violated?")  ← 1 call (no entity IDs needed)
```

**Weekly report / trend analysis:**
```
get_root_causes(active_only=false, lookback_hours=168)     ← 1 call
```

**Historical environment health:**
```
get_environment_health(active_only=false, lookback_hours=24)  ← 1 call
```

---

## Output formats

### Morning briefing

**🟢 / 🟡 / 🔴 System health: [status]** — *[N] active root causes*

| Service | Root cause | Severity | Since | Evidence | Customer impact | Owner |
|---|---|---|---|---|---|---|
| [from response] |

**SLOs at risk:** [from get_slo or ask_causely]
**Watch:** [anything Critical or active >6h]

### On-call handoff

🔴 **Active now:** [severity · service · root cause · started_at]
🟡 **SLOs burning:** [services with burn rate > 1.0]
📋 **Watch list:** [services with recurring root causes in past 24h]
