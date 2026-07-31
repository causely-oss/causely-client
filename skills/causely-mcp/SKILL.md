---
name: causely-mcp
description: >
  Use this skill whenever the user asks about service health, incidents, errors, latency, SLOs, diagnoses, symptoms, dependencies, blast radius, slow queries, alerts, metrics, topology, or anything related to observability and reliability. Also trigger for questions about Causely's methodology: "how does Causely work?", "how did Causely find this?", "what is Causely's causal reasoning?". This skill guides Claude to use 33 Causely MCP tools for structured investigations. Trigger for "what's wrong with X", "why is X slow", "what's the diagnosis", "is X healthy", "what services are affected", "what's burning our error budget", "show me the topology", "what alerts are firing", or any on-call / incident triage scenario. Always use when the topic is service reliability or system health.
---

# Causely MCP Skill

You have access to 33 structured Causely tools. Use as few calls as possible.

Read `references/complete-investigation.md` for the full tool inventory, evidence strategy, owner resolution, and fallback guidance.

Read `references/how-causely-works.md` when the user asks how Causely works, how it detected a diagnosis, or what methodology it uses.

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
| "What's the impact? Who is responsible?" | `get_incident_impact(diagnosis_id=)` |
| "What issues are active?" / incident-level | `get_issues(active_only=true)` |
| "What issues on entity X?" | `name_lookup` → `get_issues(entity_ids=[id])` |
| "Full detail for this issue" | `get_issue_details(issue_id=)` |
| "What's breaking right now?" / all signals | `get_symptoms()` (no entity_ids) |
| "What diagnoses are active?" | `get_diagnoses(active_only=true)` |
| "Explain why Causely diagnosed this diagnosis" | `get_diagnosis_details(diagnosis_id=)` → read causal_chain |
| "Full evidence for this diagnosis" | `get_diagnosis_details(diagnosis_id=)` |
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
| "What diagnoses could this entity have?" | `name_lookup` → `get_potential_diagnoses(entity_id=)` |
| "What signals could this diagnosis cause?" | `name_lookup` → `get_diagnosis_observable_signals(entity_id=, diagnosis_name=)` |
| "All signals on this entity (active + potential)?" | `name_lookup` → `get_potential_observable_signals(entity_id=)` |
| "How's the team doing?" | `team_health(team=)` |
| "Did our deploy break anything?" | `reliability_delta(service=)` |
| "Post-deploy check across services" | `fleet_reliability_delta(team= or namespace=)` |
| "Write a postmortem" | `postmortem(diagnosis_id=)` |
| "Create a ticket for this" | `generate_ticket(task=)` |
| "What pods/DBs/queues are unhealthy?" | `name_lookup` → `get_entity_health(entity_id=)` |
| "What teams do we have?" | `get_label_values(label_key="causely.ai/team")` |
| "How many services per namespace?" | `count_entities(group_by="namespace", entity_types=["Service"])` |
| "How many entities per cluster?" | `count_entities(group_by="cluster")` |
| "What entity types exist?" | `count_entities(group_by="type")` |
| "List all services in namespace X" | `get_entities(entity_types=["Service"], namespace_names=["X"])` |
| "List all databases in cluster Y" | `get_entities(entity_types=["Database"], cluster_names=["Y"])` |
| "Show me the config for X" | `name_lookup` → `get_config(entity_id=)` |
| "Why did X restart?" | `name_lookup` → `get_events(entity_id=)` |
| "What deployments happened?" | `get_symptoms(symptom_name="VersionChanged", entity_types=["ComputeSpec"])` |
| "Which DB queries are slow?" | `name_lookup` → `get_slow_queries(entity_ids=)` |
| "What is <name>?" | `name_lookup(name_mention=)` |

---

## Playbooks

### 🚨 Incident triage ("what's wrong with X?")
1. `get_service_summary(service="<name>")` for health check + full context
2. If degraded: `get_diagnosis_details(diagnosis_id=<from step 1>)` for full evidence + causal_chain
3. `get_incident_impact(diagnosis_id=)` for responsibility + business context

### 🌐 System sweep ("what's broken right now?")
1. `get_issues(active_only=true)` — incident-level view, groups related RCs per entity
2. Or `get_symptoms()` — all active symptoms, no IDs needed
3. Or `get_environment_health()` — overall status + diagnoses (no SLOs)
4. Or `get_diagnoses(active_only=true)` — individual RC detail
5. For full issue evidence: `get_issue_details(issue_id=)` → primary_diagnosis_detail + RC breakdown

### 📊 SLO check
1. `get_slo(only_at_risk=true)` — fleet-wide, no entity IDs needed
2. Or `get_slo(cluster_names=["X"], only_violated=true)` — cluster-scoped
3. Or `name_lookup` → `get_slo(entity_ids=[id])` — specific service

### 🔍 "How does Causely work?" / "Why did Causely diagnose this?"
1. `get_diagnosis_details(diagnosis_id=)` — `causal_chain` explains WHY (observed graph)
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
2. `get_incident_impact` per degraded service's diagnosis

### 🔔 Alert-driven triage
1. `get_alerts(alert_name_expr="<alert-name>")` — search by name
2. `investigate_alert(alert=)` — one-step entity health
3. For mapped alerts: `get_diagnoses(symptom_ids=[...])` → `get_diagnosis_details` for evidence

---

## Important behaviours

- **Issues are stable, Diagnoses evolve.** An Issue is the persistent incident identity — it doesn't change. The Diagnosis (diagnosis) is the current best explanation and updates as signals change. If two Diagnoses share even one Signal, they're the same Issue. Use `get_issues` for the stable incident view; use `get_diagnoses` for the current diagnosis.
- **`get_service_summary` for health checks, `get_incident_impact` for incident investigation.**
- **`get_diagnoses` is lightweight.** Does NOT include causal_chain, symptoms, or impact_service_graph. Always follow up with `get_diagnosis_details(diagnosis_id=)` for full evidence.
- **`get_diagnosis_details` causal_chain explains WHY** Causely identified the diagnosis. Do NOT use logs to explain the diagnosis — logs describe WHAT the defect is, not WHY it was identified.
- **Causality model tools for hypothesis exploration.** `get_potential_diagnoses`, `get_potential_observable_signals`, `get_signal_potential_diagnoses`, `get_diagnosis_observable_signals` explore the theoretical causality model — they return hypotheses and signal relationships, not just observed state. Use them for "what could go wrong?", "what could explain this?", and causality model exploration.
- **`get_environment_health` does NOT report SLO state.** Use `get_slo` for all SLO questions.
- **`get_slo` supports fleet-wide queries** with `cluster_names` and `namespace_names` — no entity IDs needed.
- **`rank_entities` for "which services have the most..." questions.** Do NOT loop `get_topology`.
- **`get_symptoms()` with no entity_ids is the fastest incident signal scan.**
- **`description` is pre-synthesised evidence.** Only call `get_logs` if description is generic AND `has_stored_logs=true`.
- **`get_events` does NOT cover deployments.** For "what deployments happened?" or "recent config changes?", use `get_symptoms(symptom_name="VersionChanged", entity_types=["ComputeSpec"])`. `get_events` only covers restarts, scaling, and crash/OOM.
- **`count_entities` for counting, not `get_entities`.** `get_entities` caps at 200 results — counting from its output silently undercounts. `count_entities` runs a single SQL GROUP BY with no cap.
- **`get_symptoms` time window caveat.** When using `lookback_hours`, set `active_only=false`. Cross-check each symptom's `started_at` against the stated window — `lookback_hours` is an interval-overlap filter, not a strict "started within N hours" filter.
- **Alert mapping states.** Five values: `mapped_entity_symptom`, `mapped_entity_only`, `unmapped_insufficient_labels`, `unmapped_entity_not_found`, `unmapped`.
- **Surface portal links** from every response.
