---
name: causely-mcp
description: >
  Use this skill whenever the user asks about service health, incidents, errors, latency, SLOs, root causes, symptoms, dependencies, blast radius, slow queries, alerts, metrics, topology, or anything related to observability and reliability. Also trigger for questions about Causely's methodology: "how does Causely work?", "how did Causely find this?", "what is Causely's causal reasoning?". This skill guides Claude to use 28 Causely MCP tools for structured investigations. Trigger for "what's wrong with X", "why is X slow", "what's the root cause", "is X healthy", "what services are affected", "what's burning our error budget", "show me the topology", "what alerts are firing", or any on-call / incident triage scenario. Always use when the topic is service reliability or system health.
---

# Causely MCP Skill

You have access to 28 structured Causely tools. Use as few calls as possible.

Read `references/complete-investigation.md` for the full tool inventory, evidence strategy, owner resolution, and fallback guidance.

Read `references/how-causely-works.md` when the user asks how Causely works, how it detected a root cause, or what methodology it uses. Answer directly from the reference — no MCP tool calls are needed.

---

## Name resolution with name_lookup

**When a user mentions a name, call `name_lookup` first.** It resolves names to typed objects (Entity, Cluster, Namespace, RootCause, Symptom, EntityType) with IDs for downstream tools.

---

## Tool routing — pick the right tool first time

| User intent | Primary tool |
|---|---|
| "Is X healthy?" | `get_service_summary(service=)` |
| "Is the system healthy?" | `get_environment_health()` |
| "Which SLOs are at risk?" | `get_environment_health()` |
| "What's the impact? Who is responsible?" | `get_incident_impact(root_cause_id=)` |
| "What's breaking right now?" / all signals | `get_symptoms()` (no entity_ids) |
| "What's breaking?" / all root causes | `get_root_causes(active_only=true)` |
| "What's wrong in namespace X?" | `get_environment_health(namespaces=["X"])` |
| "What alerts are firing?" | `get_alerts(active_only=true)` |
| "What alerts are firing on X?" | `get_alerts(alert_name_expr="<name>")` |
| "Which services have the most dependencies?" | `rank_entities(entity_type="Service", mode=dependencies)` |
| "Which topics have the most consumers?" | `rank_entities(entity_type="Topic", mode=dependents)` |
| "Most-called endpoints?" | `rank_entities(entity_type="HTTPPath", mode=dependents)` |
| "Show me metrics for X" | `name_lookup` → `get_metrics(entity_ids=, metrics=)` |
| "Average CPU across all pods?" | `get_metrics(entity_ids=, metrics=, entity_aggregate="mean")` |
| "What are X's SLOs?" | `name_lookup` → `get_slo(entity_ids=)` |
| "What depends on X?" | `name_lookup` → `get_topology(entity_id=, mode=dependents)` |
| "What could explain this symptom?" | `name_lookup` → `get_signal_potential_diagnoses(entity_id=, signal_name=)` |
| "What root causes could this entity have?" | `name_lookup` → `get_potential_diagnoses(entity_id=)` |
| "What signals could this diagnosis cause?" | `name_lookup` → `get_diagnosis_observable_signals(entity_id=, diagnosis_name=)` |
| "All signals on this entity?" | `name_lookup` → `get_potential_observable_signals(entity_id=)` |
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

## Playbooks

### 🚨 Incident triage ("what's wrong with X?")
1. `get_service_summary(service="<name>")` for health check + full context
2. If degraded: `get_incident_impact(root_cause_id=<from step 1>)` for responsibility
3. If description generic AND `has_stored_logs=true` → `get_logs(root_cause_id=, severity_filter=ERROR)`

### 🌐 System sweep ("what's broken right now?")
1. `get_symptoms()` — all active symptoms, no IDs needed
2. Or `get_environment_health()` — overall status + root causes + SLOs
3. Or `get_root_causes(active_only=true)` — full detail per RC

### 🔍 "How does Causely work?" / hypothesis exploration
1. Read `references/how-causely-works.md` — answer directly
2. For live causality model exploration: `name_lookup` → `get_potential_diagnoses(entity_id=)` → `get_diagnosis_observable_signals(entity_id=, diagnosis_name=)`
3. Reverse: `get_potential_observable_signals(entity_id=)` → `get_signal_potential_diagnoses(entity_id=, signal_name=)`

### 📊 Topology ranking ("which services have the most...")
1. `rank_entities(entity_type="Service", mode=dependents)` — most-called services
2. `rank_entities(entity_type="Topic", mode=dependents)` — most-consumed topics
3. **Do NOT loop `get_topology`** — `rank_entities` is a single SQL query.

### 🏢 Team standup
1. `team_health(team="<team>")` — degraded services first
2. For degraded: `get_incident_impact` for responsibility

### 📈 Fleet-level metrics
1. `name_lookup` → resolve entity IDs
2. `get_metrics(entity_ids=[...], metrics=[...], time_aggregate="mean", entity_aggregate="mean")`

### 🔔 Alert-driven triage
1. `get_alerts(alert_name_expr="<alert-name>")` — search by name
2. `investigate_alert(alert=<alert_object>)` — one-step entity health
3. For mapped alerts: `get_root_causes(symptom_ids=[...])` for diagnosis

---

## Important behaviours

- **`get_service_summary` for health checks, `get_incident_impact` for incident investigation.**
- **`rank_entities` for "which services have the most..." questions.** Do NOT loop `get_topology`.
- **Causality model tools for hypothesis exploration.** `get_potential_diagnoses`, `get_potential_observable_signals`, `get_signal_potential_diagnoses`, `get_diagnosis_observable_signals` explore the causality model — they return theoretical hypotheses, not observed state.
- **`get_root_causes` truncates at >10 results.** Use narrower filters for full detail.
- **`get_symptoms()` with no entity_ids is the fastest incident signal scan.**
- **Alert mapping states.** Five values: `mapped_entity_symptom`, `mapped_entity_only`, `unmapped_insufficient_labels`, `unmapped_entity_not_found`, `unmapped` (legacy).
- **`name_lookup` for name resolution.** Resolve names before calling tools that need entity IDs.
- **`description` is pre-synthesised evidence.** Only call `get_logs` if description is generic AND `has_stored_logs=true`.
- **Surface portal links** from every response.
