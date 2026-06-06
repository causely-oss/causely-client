---
name: causely-mcp
description: >
  Use this skill whenever the user asks about service health, incidents, errors, latency, SLOs, root causes, symptoms, dependencies, blast radius, slow queries, alerts, metrics, topology, or anything related to observability and reliability. Also trigger for questions about Causely's methodology: "how does Causely work?", "how did Causely find this?", "what is Causely's causal reasoning?". This skill guides Claude to use 23 Causely MCP tools for structured investigations. Trigger for "what's wrong with X", "why is X slow", "what's the root cause", "is X healthy", "what services are affected", "what's burning our error budget", "show me the topology", "what alerts are firing", or any on-call / incident triage scenario. Always use when the topic is service reliability or system health.
---

# Causely MCP Skill

You have access to 23 structured Causely tools. Use as few calls as possible.

Read `references/complete-investigation.md` for the full tool inventory, evidence strategy, owner resolution, and fallback guidance.

Read `references/how-causely-works.md` when the user asks how Causely works, how it detected a root cause, or what methodology it uses. Answer directly from the reference — no MCP tool calls are needed.

---

## Name resolution with name_lookup

**When a user mentions a name, call `name_lookup` first.** It resolves names to typed objects (Entity, Cluster, Namespace, RootCause, Symptom, EntityType) with IDs for downstream tools.

```
name_lookup(name_mention="checkout")
  → Entity → pass id to get_metrics, get_slo, get_topology, get_alerts, get_events, get_config
  → Entity → pass id to get_root_causes(related_entity_ids=[id])
  → Entity → pass id to get_incident_impact(entity_id=id)
```

---

## Tool selection: health checks vs investigation

| Question type | Primary tool | Why |
|---|---|---|
| "Is X healthy?" / simple health check | `get_service_summary(service=)` | Full picture in 1 call, resolves name automatically |
| "Is the system healthy?" / global sweep | `get_environment_health()` | Global or scoped overview |
| "Which SLOs are at risk?" / system-wide SLO | `get_environment_health()` | Returns at-risk SLOs without entity IDs |
| "What's the impact?" / "Who is responsible?" | `get_incident_impact(root_cause_id=)` | Responsible service + business context |
| "Full picture of X" | `get_service_summary(service=)` | All-in-one |

**`get_incident_impact` is for incident investigation, not simple health checks.**

---

## Tool routing — pick the right tool first time

| User intent | Primary tool |
|---|---|
| "Is X healthy?" / single service health | `get_service_summary(service=)` |
| "What's the impact of this incident?" / "Who owns this?" | `get_incident_impact(root_cause_id= or entity_id= + root_cause_name=)` |
| "Is the system healthy?" / global sweep | `get_environment_health()` |
| "Which SLOs are at risk?" | `get_environment_health()` |
| "What's breaking right now?" / all signals | `get_symptoms()` (no entity_ids) |
| "What's breaking?" / all active root causes | `get_root_causes(active_only=true)` |
| "What's wrong in namespace X?" | `get_environment_health(namespaces=["X"])` |
| "What alerts are firing?" | `get_alerts(active_only=true)` |
| "What alerts are firing on X?" | `get_alerts(alert_name_expr="<name>")` |
| "Show me metrics for X" | `name_lookup` → `get_metrics(entity_ids=, metrics=)` |
| "Average CPU across all pods?" | `get_metrics(entity_ids=, metrics=, entity_aggregate="mean")` |
| "What are X's SLOs?" | `name_lookup` → `get_slo(entity_ids=)` |
| "What depends on X?" | `name_lookup` → `get_topology(entity_id=, mode=dependents)` |
| "How's the team doing?" | `team_health(team=)` |
| "Did our deploy break anything?" | `reliability_delta(service=)` |
| "Post-deploy check across services" | `fleet_reliability_delta(team= or namespace=)` |
| "Write a postmortem" | `postmortem(root_cause_id=)` |
| "Create a ticket for this" | `generate_ticket(task=)` |
| "What pods/DBs/queues are unhealthy?" | `name_lookup` → `get_entity_health(entity_id=)` |
| "What teams do we have?" | `get_label_values(label_key="causely.ai/team")` |
| "Show me the config for X" | `name_lookup` → `get_config(entity_id=)` |
| "Why did X restart?" | `name_lookup` → `get_events(entity_id=)` |
| "Which DB queries are slow?" | `name_lookup` → `get_slow_queries(entity_ids=)` |
| "What is <name>?" | `name_lookup(name_mention="<name>")` |

---

## Decision tree

**Simple health check → `get_service_summary` (1 call)**
```
get_service_summary(service="<name>")
  → status, symptoms, root causes, SLOs, metrics, deps, events, logs
```

**Incident investigation → `get_incident_impact` (1 call)**
```
get_incident_impact(root_cause_id="<id>")
  → responsible_entity + responsible_context (team, product, customer, project)
  → impacted_services + impacted_context
  → symptoms, remediation, causal_chain
```

**Incident first response → `get_symptoms` (1 call)**
```
get_symptoms()  ← no entity_ids = all active symptoms across every entity
```

**System sweep → `get_environment_health` (1 call)**
```
get_environment_health()
  → overall status, active root causes, at-risk SLOs
```

---

## Playbooks

### 🚨 Incident triage ("what's wrong with X?")
1. `get_service_summary(service="<name>")` for health check + full context
2. If degraded and need responsibility/business context: `get_incident_impact(root_cause_id=<from step 1>)`
3. If description generic AND `has_stored_logs=true` → `get_logs(root_cause_id=, limit=10, severity_filter=ERROR)`

### 🌐 System sweep ("what's broken right now?")
1. `get_symptoms()` — all active symptoms, no IDs needed
2. Or `get_environment_health()` — overall status + root causes + SLOs
3. Or `get_root_causes(active_only=true)` — full structured detail per RC

### 🔍 "How does Causely work?" / "How did it find this?"
1. Read `references/how-causely-works.md` — answer directly from it
2. No MCP tool calls needed unless the user also wants live data

### 🏢 Team standup
1. `team_health(team="<team>")` — returns degraded services first
2. For each degraded service: `get_incident_impact` for responsibility + business context

### 📊 Deep dive (metrics, SLOs, topology)
1. `name_lookup(name_mention="<name>")` → resolve entity ID
2. `get_metrics(entity_ids=[id], metrics=[...])` for metric data
3. `get_slo(entity_ids=[id])` for SLO status
4. `get_topology(entity_id=id, mode=dependents)` for blast radius graph

### 📈 Fleet-level metrics
1. `name_lookup` → resolve entity IDs
2. `get_metrics(entity_ids=[...], metrics=[...], window_minutes=60, time_aggregate="mean", entity_aggregate="mean")` for aggregated fleet values

### 🔔 Alert-driven triage
1. `get_alerts(alert_name_expr="<alert-name>")` — search by name, no entity ID needed
2. `investigate_alert(alert=<alert_object>)` — one-step: pass the alert, get entity health back
3. Or for mapped alerts: `get_root_causes(symptom_ids=[...])` to find the diagnosed cause

---

## Important behaviours

- **`get_service_summary` for health checks, `get_incident_impact` for incident investigation.**
- **`get_environment_health` for system-wide SLO overview.** Returns at-risk SLOs without requiring entity IDs.
- **`get_metrics` supports aggregation.** Use `time_aggregate` to reduce a window to one scalar, `entity_aggregate` to collapse across entities. Supports AIModel, MCPTool, ServiceAccess entity types.
- **`get_root_causes` truncates at >10 results.** Symptoms, causal_chain, and impact_service_graph are omitted. Use `root_cause_id` or narrower filters for full detail.
- **`get_symptoms()` with no entity_ids is the fastest incident signal scan.**
- **`investigate_alert` simplifies alert triage.** Pass a raw alert object from `get_alerts` to get entity health in one step.
- **`name_lookup` for name resolution.** Resolve names before calling tools that need entity IDs.
- **`description` is pre-synthesised evidence.** Only call `get_logs` if description is generic AND `has_stored_logs=true`.
- **Alert mapping states.** Use `"mapped_entity_symptom"` and `"unmapped"` in `mapping_state_filters`.
- **Surface portal links** from every response.
