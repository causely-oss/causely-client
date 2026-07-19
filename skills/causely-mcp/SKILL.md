---
name: causely-mcp
description: >
  Use this skill whenever the user asks about service health, incidents, errors, latency, SLOs, root causes, symptoms, dependencies, blast radius, slow queries, alerts, metrics, topology, or anything related to observability and reliability. Also trigger for questions about Causely's methodology: "how does Causely work?", "how did Causely find this?", "what is Causely's causal reasoning?". This skill guides Claude to use 30 Causely MCP tools for structured investigations. Trigger for "what's wrong with X", "why is X slow", "what's the root cause", "is X healthy", "what services are affected", "what's burning our error budget", "show me the topology", "what alerts are firing", or any on-call / incident triage scenario. Always use when the topic is service reliability or system health.
---

# Causely MCP Skill

You have access to 30 structured Causely tools. Use as few calls as possible.

Read `references/complete-investigation.md` for the full tool inventory, evidence strategy, owner resolution, and fallback guidance.

Read `references/how-causely-works.md` when the user asks how Causely works, how it detected a root cause, or what methodology it uses.

---

## Name resolution with name_lookup

**When a user mentions a name, call `name_lookup` first.** It resolves names to typed objects with IDs for downstream tools.

---

## Tool routing — pick the right tool first time

| User intent | Primary tool |
|---|---|
| "Is X healthy?" | `get_service_summary(service=)` |
| "Is the system healthy?" | `get_environment_health()` |
| "Which SLOs are at risk?" | `get_slo(only_at_risk=true)` |
| "Which SLOs are violated in cluster X?" | `get_slo(cluster_names=["X"], only_violated=true)` |
| "What's the impact? Who is responsible?" | `get_incident_impact(root_cause_id=)` |
| "What's breaking right now?" / all signals | `get_symptoms()` (no entity_ids) |
| "What root causes are active?" | `get_root_causes(active_only=true)` |
| "Explain why Causely diagnosed this root cause" | `get_root_cause_details(root_cause_id=)` → read causal_chain |
| "Full evidence for this root cause" | `get_root_cause_details(root_cause_id=)` |
| "What's wrong in namespace X?" | `get_environment_health(namespaces=["X"])` |
| "What's wrong in cluster X?" | `get_environment_health(clusters=["X"])` |
| "What alerts are firing?" | `get_alerts(active_only=true)` |
| "What alerts are firing on X?" | `get_alerts(alert_name_expr="<name>")` |
| "Which services have the most dependencies?" | `rank_entities(entity_type="Service", mode=dependencies)` |
| "Most-called endpoints?" | `rank_entities(entity_type="HTTPPath", mode=dependents)` |
| "Which topics have the most consumers?" | `rank_entities(entity_type="Topic", mode=dependents)` |
| "Show me metrics for X" | `name_lookup` → `get_metrics(entity_ids=, metrics=)` |
| "Average CPU across all pods?" | `get_metrics(entity_ids=, metrics=, entity_aggregate="mean")` |
| "What are X's SLOs?" | `name_lookup` → `get_slo(entity_ids=)` |
| "What depends on X?" | `name_lookup` → `get_topology(entity_id=, mode=dependents)` |
| "What could explain this symptom?" | `name_lookup` → `get_signal_potential_diagnoses(entity_id=, signal_name=)` |
| "What root causes could this entity have?" | `name_lookup` → `get_potential_diagnoses(entity_id=)` |
| "What signals could this diagnosis cause?" | `name_lookup` → `get_diagnosis_observable_signals(entity_id=, diagnosis_name=)` |
| "All signals on this entity (active + potential)?" | `name_lookup` → `get_potential_observable_signals(entity_id=)` |
| "How's the team doing?" | `team_health(team=)` |
| "Did our deploy break anything?" | `reliability_delta(service=)` |
| "Post-deploy check across services" | `fleet_reliability_delta(team= or namespace=)` |
| "Write a postmortem" | `postmortem(root_cause_id=)` |
| "Create a ticket for this" | `generate_ticket(task=)` |
| "What pods/DBs/queues are unhealthy?" | `name_lookup` → `get_entity_health(entity_id=)` |
| "What teams do we have?" | `get_label_values(label_key="causely.ai/team")` |
| "List all services in namespace X" | `get_entities(entity_types=["Service"], namespace_names=["X"])` |
| "List all databases in cluster Y" | `get_entities(entity_types=["Database"], cluster_names=["Y"])` |
| "Show me the config for X" | `name_lookup` → `get_config(entity_id=)` |
| "Why did X restart?" | `name_lookup` → `get_events(entity_id=)` |
| "Which DB queries are slow?" | `name_lookup` → `get_slow_queries(entity_ids=)` |
| "What is <name>?" | `name_lookup(name_mention=)` |

---

## Playbooks

### 🚨 Incident triage ("what's wrong with X?")
1. `get_service_summary(service="<name>")` for health check + full context
2. If degraded: `get_root_cause_details(root_cause_id=<from step 1>)` for full evidence + causal_chain
3. `get_incident_impact(root_cause_id=)` for responsibility + business context

### 🌐 System sweep ("what's broken right now?")
1. `get_symptoms()` — all active symptoms, no IDs needed
2. Or `get_environment_health()` — overall status + root causes (no SLOs)
3. Or `get_root_causes(active_only=true)` — lightweight list, follow up with `get_root_cause_details` per RC

### 📊 SLO check
1. `get_slo(only_at_risk=true)` — fleet-wide, no entity IDs needed
2. Or `get_slo(cluster_names=["X"], only_violated=true)` — cluster-scoped
3. Or `name_lookup` → `get_slo(entity_ids=[id])` — specific service

### 🔍 "How does Causely work?" / "Why did Causely diagnose this?"
1. `get_root_cause_details(root_cause_id=)` — `causal_chain` explains WHY (observed graph)
2. Walk edges from leaf symptoms toward root_node_id — edge probabilities show causal confidence
3. Also read `references/how-causely-works.md` for methodology

### 🧬 Causality model exploration ("what could go wrong?")
**Forward: entity → diagnoses → signals**
1. `name_lookup` → `get_potential_diagnoses(entity_id=)` — all diagnosis hypotheses (active + causality-only)
2. `get_diagnosis_observable_signals(entity_id=, diagnosis_name=)` — causality chain: what signals this diagnosis could cause
3. Compare to `get_symptoms(entity_ids=[id])` to see which are actually active

**Reverse: signal → diagnoses**
1. `name_lookup` → `get_potential_observable_signals(entity_id=)` — all signals (active + inactive + potential)
2. `get_signal_potential_diagnoses(entity_id=, signal_name=)` — which diagnoses could explain this signal

### 🏢 Team standup
1. `team_health(team=)` — degraded services first
2. `get_incident_impact` per degraded service's root cause

### 🔔 Alert-driven triage
1. `get_alerts(alert_name_expr="<alert-name>")` — search by name
2. `investigate_alert(alert=)` — one-step entity health
3. For mapped alerts: `get_root_causes(symptom_ids=[...])` → `get_root_cause_details` for evidence

---

## Important behaviours

- **`get_service_summary` for health checks, `get_incident_impact` for incident investigation.**
- **`get_root_causes` is lightweight.** Does NOT include causal_chain, symptoms, or impact_service_graph. Always follow up with `get_root_cause_details(root_cause_id=)` for full evidence.
- **`get_root_cause_details` causal_chain explains WHY** Causely identified the root cause. Do NOT use logs to explain the diagnosis — logs describe WHAT the defect is, not WHY it was identified.
- **Causality model tools for hypothesis exploration.** `get_potential_diagnoses`, `get_potential_observable_signals`, `get_signal_potential_diagnoses`, `get_diagnosis_observable_signals` explore the theoretical causality model — they return hypotheses and signal relationships, not just observed state. Use them for "what could go wrong?", "what could explain this?", and causality model exploration.
- **`get_environment_health` does NOT report SLO state.** Use `get_slo` for all SLO questions.
- **`get_slo` supports fleet-wide queries** with `cluster_names` and `namespace_names` — no entity IDs needed.
- **`rank_entities` for "which services have the most..." questions.** Do NOT loop `get_topology`.
- **`get_symptoms()` with no entity_ids is the fastest incident signal scan.**
- **`description` is pre-synthesised evidence.** Only call `get_logs` if description is generic AND `has_stored_logs=true`.
- **Alert mapping states.** Five values: `mapped_entity_symptom`, `mapped_entity_only`, `unmapped_insufficient_labels`, `unmapped_entity_not_found`, `unmapped`.
- **Surface portal links** from every response.
