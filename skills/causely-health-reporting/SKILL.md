---
name: causely-health-reporting
description: >
  Use this skill when the user wants a scheduled, proactive, or summary view of system health — not an active incident. Trigger for requests like "give me the morning health report", "what's the state of the system?", "weekly reliability summary", "anything I should know before standup?", "system health overview", "how are our services doing overall?", "what's been flapping this week?", "generate a status update", "what should the on-call team watch out for?", "SLO status report", "environment health check", "namespace health", "full service report", or "are any SLOs at risk?". Also trigger when someone asks for a digest, briefing, or dashboard-style summary rather than asking about a specific incident. This skill focuses on trend-awareness and proactive risk identification, not reactive triage.
---

# Causely Health Reporting Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

---

## Core tools for health reporting

| Tool | Use when | What it returns |
|---|---|---|
| `get_environment_health()` | Global or namespace-scoped health overview | Overall status (HEALTHY/DEGRADED/CRITICAL) + active root causes + remediation |
| `get_service_summary(service=)` | Comprehensive single-service report | Symptoms, root causes, SLOs, metrics, deps, slow queries, events, error logs — all in one call |
| `get_root_causes(active_only=true)` | All active issues with evidence | Structured JSON: description, impacted_services, impacted_customers per RC |
| `team_health(team=)` | Team-scoped standup | Degraded/critical services first, healthy grouped at end |
| `get_entity_health(entity_id=)` | Non-service entity health (DBs, pods, queues) | Symptoms, root causes, events, logs, metrics for one entity |
| `get_slo(entity_ids=)` | SLO error budget and burn rate | Per-SLO: budget remaining %, burn rate, at-risk/violated flags |
| `ask_causely(question=)` | System-wide SLO overview (no entity IDs needed) | "Which services have SLOs at risk or violated?" |
| `get_symptoms(active_only=false, lookback_hours=N)` | Historical flapping/recurring signals | Timeline of symptom start/end for trend analysis |

---

## Decision tree

**Morning standup / system sweep (recommended path):**
```
get_environment_health()                                  ← 1 call
  → overall status: HEALTHY / DEGRADED / CRITICAL
  → active root causes with severity, remediation
  → done for quick overview
```

For more detail on each root cause:
```
get_root_causes(active_only=true)                         ← 1 call
  → group by severity: Critical → High → Medium → Low
  → description = evidence per issue
  → impacted_customers = customer impact per issue
  → entity.labels["causely.ai/team"] = owner (if set)
  → done
```

**Namespace-scoped health:**
```
get_environment_health(namespaces=["otel-demo"])           ← 1 call
  → scoped status + root causes for that namespace only
```

**Full service report (all dimensions):**
```
get_service_summary(service="<service>")                   ← 1 call
  → status, symptoms, root causes, SLOs, metrics, deps,
    slow queries, events, error logs — everything in one call
  → done — do NOT chain 5 separate tools
```

**SLO-focused report:**
```
ask_causely("Which services have SLOs at risk or violated?")  ← 1 call (no entity IDs needed)
  → or if you have entity IDs:
get_entities(query="<service>") → get_slo(entity_ids=[...], only_at_risk=true)
```

**Team standup:**
```
team_health(team="<team>")                                 ← 1 call
  → degraded/critical services listed first
  → for each degraded: get_service_summary(service=) if full detail needed
```

**Weekly report / trend analysis:**
```
get_root_causes(active_only=false, lookback_hours=168)     ← 1 call
  → count per service to find recurring offenders
  → compare started_at / ended_at for flapping patterns
```

**Non-service entity health (DBs, queues, pods):**
```
get_entities(query="<name>", entity_types=["Database"])     ← 1 call
get_entity_health(entity_id=<id>)                           ← 1 call
  → symptoms, root causes, events, logs, metrics
```

---

## Output formats

### Morning / standup briefing

**🟢 / 🟡 / 🔴 System health: [from get_environment_health status]**
*[N] active root causes as of [time]*

| Service | Root cause | Severity | Since | Evidence | Customer impact | Owner |
|---|---|---|---|---|---|---|
| [from response] | [name] | [sev] | [started_at] | [from description] | [impacted_customers or "none"] | [team label or "unknown"] |

**SLOs at risk:** [from get_slo or ask_causely — list services with burn rate > 1.0 or violated]

**Watch:** [anything Critical or active >6h]

---

### Full service report

**[Service] — [status from get_service_summary]**

**Active issues:** [root causes with severity + remediation]
**SLOs:** [budget remaining + burn rate]
**Key metrics:** [CPU, memory, error rate, p99 latency from resource metrics section]
**Dependencies:** [health of upstream/downstream services]
**Recent events:** [deploys, restarts, config changes]

---

### On-call handoff

🔴 **Active now:** [severity · service · root cause · started_at]
🟡 **SLOs burning:** [services with burn rate > 1.0]
⚠️ **Owner gaps:** [services missing causely.ai/team label]
📋 **Watch list:** [services with recurring root causes in the past 24h]
