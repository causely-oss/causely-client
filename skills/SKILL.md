---
name: causely-mcp
description: >
  Use this skill whenever the user asks about service health, incidents, errors, latency, SLOs, root causes, symptoms, dependencies, blast radius, slow queries, alerts, metrics, topology, or anything related to observability and reliability. This skill guides Claude to use the Causely MCP tools (25 tools total) to conduct structured, multi-step investigations — not just single lookups. Trigger it for any question like "what's wrong with X", "why is X slow", "what's the root cause", "is X healthy", "what services are affected", "what's burning our error budget", "show me the topology", "what alerts are firing", or any on-call / incident triage scenario. Do NOT skip this skill just because the user's question seems simple — always use it when the topic is service reliability or system health.
---

# Causely MCP Skill

You have access to 25 structured Causely tools. Use as few calls as possible — the goal is a fast, complete answer, not a thorough chain of redundant lookups.

Read `complete-investigation.md` for the full tool inventory, evidence strategy, owner resolution, and fallback guidance.

---

## Core rule: triage is the complete answer

`triage(entity_name=)` returns root cause, symptoms, blast radius, customer impact, and remediation in **one call**. Everything needed for a full six-dimension answer is already there. Do not follow it with separate `get_symptoms`, `get_root_causes`, or blast-radius calls — that data is already inside the triage response.

**`description` is pre-synthesised evidence.** When the root cause `description` field contains specific log patterns, error messages, or metrics, that IS the evidence. Do not call `get_logs` to regenerate it. Only call `get_logs` when description is generic ("Inspect the application logs...") AND `has_stored_logs=true`.

---

## Tool routing — pick the right tool first time

| User intent | Primary tool | Follow-up if needed |
|---|---|---|
| "What's wrong with X?" / single service triage | `triage(entity_name=)` | `get_logs` if description generic |
| "Is the system healthy?" / global sweep | `get_environment_health()` | `get_root_causes(active_only=true)` for detail |
| "Full picture of service X" (metrics, SLOs, deps, logs, events) | `get_service_summary(service=)` | — |
| "What's breaking?" / all active root causes | `get_root_causes(active_only=true)` | — |
| "What alerts are firing on X?" | `get_entities` → `get_alerts(entity_ids=)` | `get_root_causes(symptom_ids=)` |
| "Show me metrics for X" | `get_entities` → `get_metrics(entity_ids=, metrics=)` | — |
| "What are X's SLOs?" | `get_entities` → `get_slo(entity_ids=)` | — |
| "What depends on X?" / blast radius | `get_entities` → `get_topology(entity_id=, mode=dependents)` | — |
| "What does X depend on?" | `get_entities` → `get_topology(entity_id=, mode=dependencies)` | — |
| "How's the team doing?" | `team_health(team=)` | `triage` per degraded service |
| "Did our deploy break anything?" | `reliability_delta(service=)` | `triage` if regression detected |
| "Post-deploy check across services" | `fleet_reliability_delta(team= or namespace=)` | — |
| "Write a postmortem" | `postmortem(root_cause_id=)` | `get_root_causes` first if ID unknown |
| "Create a ticket for this" | `generate_ticket(task=)` | — |
| "What pods/DBs/queues are unhealthy?" | `get_entities` → `get_entity_health(entity_id=)` | — |
| "What teams do we have?" | `get_label_values(label_key="causely.ai/team")` | — |
| "Show me the config for X" | `get_entities` → `get_config(entity_id=)` | — |
| "Why did X restart?" / events | `get_entities` → `get_events(entity_id=)` | — |
| "Which DB queries are slow?" | `get_entities` → `get_slow_queries(entity_ids=)` | — |
| Free-form / cross-entity synthesis | `ask_causely(question=)` | — |

---

## Decision tree

**Named service → `triage` only (1 call)**
```
triage(entity_name="<service>")
  → read: root cause, description, symptoms, impacted_services,
          impacted_customers, remediation, has_stored_logs
  → evidence = description field (if specific)
  → owner = entity.labels["causely.ai/team"] (if present)
  → done — answer the user
```

**Only add a second call if:**
- `has_stored_logs=true` AND description is generic → `get_logs(root_cause_id=, limit=10, severity_filter=ERROR)`
- `causely.ai/team` label absent → `team_health(team="<partial-name>")`

**No service name → `get_environment_health` or `get_root_causes` (1 call)**
```
get_environment_health()
  → overall status: HEALTHY / DEGRADED / CRITICAL
  → active root causes with remediation
  → done for overview

get_root_causes(active_only=true)
  → all active RCs with description, impacted_services, impacted_customers
  → evidence = description field
  → no follow-up get_symptoms needed
```

**Need entity IDs for metric/SLO/topology tools:**
```
get_entities(query="<name>", entity_types=["Service"])
  → returns [{id, name, type, severity, labels}]
  → pass id to get_metrics, get_slo, get_topology, get_alerts, etc.
```

---

## Playbooks

### 🚨 Incident triage ("what's wrong with X?")
1. `triage(entity_name="<service>")` — that's it unless conditions below apply
2. If description generic AND `has_stored_logs=true` → `get_logs(root_cause_id=, limit=10, severity_filter=ERROR)`
3. If `causely.ai/team` absent → `team_health(team="<partial>")`

### 🌐 System sweep ("what's broken right now?")
1. `get_environment_health()` — overall status + active root causes
2. Or `get_root_causes(active_only=true)` — full structured detail per RC
3. For the single most critical RC only: `get_logs` if `has_stored_logs=true` AND description is generic

### 🏢 Team standup
1. `team_health(team="<team>")` — returns degraded services first
2. For each degraded service: `triage(entity_name=)` if detail is needed

### 📊 Deep dive (metrics, SLOs, topology)
1. `get_entities(query="<name>")` → resolve entity ID
2. `get_metrics(entity_ids=[id], metrics=["error_rate", "p99_latency", ...])` for metric data
3. `get_slo(entity_ids=[id])` for SLO status
4. `get_topology(entity_id=id, mode=dependents)` for blast radius graph

### 🔔 Alert-driven triage
1. `get_entities(query="<service>")` → resolve entity ID
2. `get_alerts(entity_ids=[id], active_only=true)` → see what's firing + mapping state
3. For mapped alerts: `get_root_causes(symptom_ids=[...])` to find the diagnosed cause

---

## Important behaviours

- **`owner-scraper` is not a team.**. Always check `causely.ai/team` in entity.labels first.
- **`impacted_customers` is in the root cause response.** Read it directly — never make an extra call to find customer impact.
- **`get_service_summary` is the all-in-one tool.** When the user wants the full picture (symptoms + root causes + SLOs + metrics + deps + events + logs), call `get_service_summary(service=)` instead of chaining 5 separate tools.
- **`ask_causely` is the fallback for free-form questions.** Use it when you don't have a service name, need cross-entity synthesis, or the question doesn't map cleanly to a structured tool.
- **Surface portal links** from every response so engineers can drill in.
- **Be direct.** Lead with severity and the most critical finding. One call should usually be enough.
