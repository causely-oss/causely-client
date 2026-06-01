---
name: causely-health-reporting
description: >
  Use this skill when the user wants a scheduled, proactive, or summary view of system health — not an active incident. Trigger for requests like "give me the morning health report", "what's the state of the system?", "weekly reliability summary", "anything I should know before standup?", "system health overview", "how are our services doing overall?", "generate a status update", "SLO status report", "environment health check", "namespace health", "full service report", "is X healthy?", or "are any SLOs at risk?". Also trigger for digests, briefings, or dashboard-style summaries.
---

# Causely Health Reporting Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for health reporting

| Tool | Use when | What it returns |
|---|---|---|
| `get_service_summary(service=)` | **Primary tool for single-service health by name.** Resolves name automatically. | Status + symptoms + RCs + SLOs + metrics + deps + slow queries + events + errors |
| `get_environment_health()` | Global or scoped health overview | Overall status + active root causes + remediation |
| `get_root_causes(active_only=true)` | All active issues with evidence | Structured JSON per RC |
| `team_health(team=)` | Team-scoped standup. Follow up with `get_incident_impact` for degraded services. | Degraded/critical first, healthy grouped at end |
| `get_symptoms()` | **All active symptoms across every entity** — no IDs needed | Full signal picture |
| `name_lookup` → `get_slo(entity_ids=)` | SLO error budget and burn rate | Per-SLO: budget %, burn rate, at-risk/violated |
| `ask_causely(question=)` | System-wide SLO overview (no entity IDs needed) | "Which services have SLOs at risk?" |
| `get_entity_health(entity_id=)` | Non-service entity health (DBs, pods, queues) | Symptoms, RCs, events, logs, metrics |

---

## Decision tree

**"Is X healthy?" → `get_service_summary` (1 call)**
```
get_service_summary(service="<name>")                      ← 1 call, resolves name
```

**Morning standup / system sweep:**
```
get_environment_health()                                  ← 1 call
```

**Namespace/cluster/product-scoped health:**
```
get_environment_health(namespaces=["otel-demo"])           ← 1 call
get_environment_health(clusters=["prod-cluster"])          ← 1 call
```

**Team standup:**
```
team_health(team="<team>")                                 ← 1 call
  → for degraded services: get_incident_impact(root_cause_id=) for responsibility
```

**SLO-focused report:**
```
ask_causely("Which services have SLOs at risk or violated?")  ← 1 call
```

**Weekly report / trend analysis:**
```
get_root_causes(active_only=false, lookback_hours=168)     ← 1 call
```

---

## Output formats

### Morning briefing

**🟢 / 🟡 / 🔴 System health: [status]** — *[N] active root causes*

| Service | Root cause | Severity | Since | Evidence | Customer impact | Owner |
|---|---|---|---|---|---|---|
| [from response] |

**SLOs at risk:** [from get_slo or ask_causely]

### On-call handoff

🔴 **Active now:** [severity · service · root cause · started_at]
🟡 **SLOs burning:** [services with burn rate > 1.0]
📋 **Watch list:** [recurring root causes in past 24h]
