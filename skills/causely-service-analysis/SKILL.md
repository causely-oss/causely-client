---
name: causely-service-analysis
description: >
  Use this skill when the user asks about a service's health, whether during an active incident or a routine check. Trigger for: "what's wrong with X?", "is X healthy?", "why is X slow?", "what's happening with checkout?", "is the system healthy?", "what incidents are active?", "what's the state of the system?", "morning standup", "team health", "SLO status", "which SLOs are at risk?", "environment health check", "full service report", "weekly reliability summary", "how was X last week?", "what's the error rate on X?", "is anything degraded?", "namespace health", "which services are most critical?", "how many services per cluster?", "is the checkout journey healthy?", "what teams do we have?", "which database queries are slowest?", or any question about current or historical service health, active incidents, SLOs, or system overview. This is the primary skill for single-service investigation AND fleet-wide health.
---

# Causely Service Analysis Skill


Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs.

---

## Core tools

| Tool | Use when | What it returns |
|---|---|---|
| `get_service_summary(service=)` | **Primary single-service health — active incidents and routine checks alike.** Use `cluster_name`/`namespace_name`/`service_type` to disambiguate. | Status + symptoms + issues + SLOs + metrics + deps + events + errors |
| `get_business_transaction_summary(business_transaction=)` | **Primary business transaction / user journey health.** | Aggregated health across all routes |
| `get_environment_health()` | Global or scoped overview. **Does NOT report SLOs.** | Overall status + active issues |
| `get_slo()` | **All SLO questions.** Fleet-wide with `cluster_names`/`namespace_names` or per-service with `entity_ids`. Add `include_operations=true` for endpoint SLOs. | Error budget, burn rate, at-risk, violated |
| `get_issues(active_only=true)` | **All active incidents — primary entry point.** | Stable identity; follow up with `get_issue_details` for full evidence |
| `get_issue_details(issue_id=)` | **Full incident detail in one call.** | entity_causal_chain + impact_service_graph + all diagnoses |
| `get_incident_impact(diagnosis_id=)` | Responsibility + business context | Responsible team, impacted customers/products |
| `team_health(team=)` | Team-scoped health | Degraded first, healthy grouped at end |
| `get_symptoms()` | All active symptoms — no IDs needed | Full signal picture |
| `get_entity_health(entity_id=)` | Health for any entity type (pod, queue, table, etc.) | Structured JSON with `active_issues` (each with its issue id and a direct / aggregated / impacting relationship). Use when you have an entity_id, not a name |
| `rank_entities(entity_type=, mode=)` | "Which services are most critical?" | Ranked list |
| `get_label_values(label_key=)` | Discover valid teams, products, clusters, namespaces (e.g. `causely.ai/team`). Optional `query` substring filter. | Sorted distinct values |
| `name_lookup` → `get_slow_queries(entity_ids=)` | Slowest database queries on a database or on a service that calls one | Queries by total execution time, highest impact first |
| `count_entities(group_by=)` | "How many services per namespace?" | Accurate counts (no 200 cap) |
| `get_metrics(entity_ids=, metrics=)` | Specific metric values (CPU, error rate, latency) | Time-series or aggregated scalars |
| `get_diagnoses()` | Drill-down: filter by symptom_ids, diagnosis_name, entity_types | Lightweight; for non-primary diagnosis details use `get_diagnosis_details` |

---

## Decision tree

### Active incident investigation
- **"What's wrong with X?"** → `get_service_summary(service=)` → if degraded: `get_issue_details(issue_id=<from response>)` → `get_incident_impact(diagnosis_id=)`
- **"What incidents are active?"** → `get_issues(active_only=true)` → `get_issue_details` for the critical ones
- **"What's wrong right now?"** → `get_environment_health()` → drill into critical issues with `get_issue_details`
- **"Checkout and payment both down"** → defer to **causely-correlated-incidents** skill

### Routine health checks
- **"Is X healthy?"** → `get_service_summary(service=)`
- **"Is the checkout journey healthy?"** → `get_business_transaction_summary(business_transaction="checkout")`
- **Morning standup** → `get_environment_health()` + `get_slo(only_at_risk=true)`
- **Team standup** → `team_health(team=)` → `get_issue_details(issue_id=)` for each degraded service (the output includes the issue id), then `get_incident_impact` if you need responsibility
- **"What teams do we have?"** → `get_label_values(label_key="causely.ai/team")`. `team_health` needs a team name, not a service name; an unknown or ambiguous name returns an error listing the known teams
- **Namespace scoped** → `get_environment_health(namespaces=)`

### SLO monitoring
- **"Which SLOs are at risk?"** → `get_slo(only_at_risk=true)`
- **"SLOs violated in robot-shop?"** → `get_slo(namespace_names=["robot-shop"], only_violated=true)`
- **"Error budget for X including endpoints?"** → `name_lookup` → `get_slo(entity_ids=[id], include_operations=true)`

### Historical analysis
- **"How was X last week?"** → `get_service_summary(service=, lookback_hours=168)`
- **"Incidents in the past week?"** → `get_issues(active_only=false, lookback_hours=168)`
- **"Historical diagnoses?"** → `get_diagnoses(active_only=false, lookback_hours=168)`

### Discovery and ranking
- **"Which services are most critical?"** → `rank_entities(entity_type="Service", mode=dependents)`
- **"How many services per namespace?"** → `count_entities(group_by="namespace", entity_types=["Service"])`
- **"What entity types exist?"** → `count_entities(group_by="type")`
- **"Which database queries are slowest?"** → `name_lookup` → `get_slow_queries(entity_ids=[id])`
- **"List all services in otel-demo"** → `get_entities(entity_types=["Service"], namespace_names=["otel-demo"])`

---

## Important behaviours

- **Start with Issues.** `get_issues` → `get_issue_details` returns the full entity_causal_chain, impact_service_graph, and all diagnoses in one call. Use `get_diagnoses` only to filter by symptom, name, or entity type, or to drill into a non-primary diagnosis.
- **`get_environment_health` does not report SLOs.** Use `get_slo` for every SLO question.
- **Count with `count_entities`, not `get_entities`.** `get_entities` caps at 200 and silently undercounts.
- **Rank with `rank_entities`.** For "which has the most dependencies/dependents/routes", never loop `get_topology` or `get_business_transaction_summary`.
- **`description` is pre-synthesised evidence.** Call `get_logs` only if the description is generic AND `has_stored_logs=true`.
- **Use the issue's top-level `id` as `issue_id`.** `primary_diagnosis.id` is a diagnosis ID and only works with the diagnosis tools.
- **`get_slo` with no filters returns only degraded SLOs** (violated or at risk). Pass `entity_ids` to get every SLO for a service. Error budget is based on the trailing 24 hours, not the full SLO window.
- **`get_issues` with `related_entity_ids` ignores cluster, namespace, product and customer filters.** The entity ID is unique, and impacting issues often live elsewhere.

---

## Output formats

### Active incident report

### 🔴 / 🟡 / 🟢 [Service] — [Status]
**Issue:** [name + severity + since + diagnosis_count diagnoses]
**Diagnosis:** [primary_diagnosis name + entity]
**Evidence:** [from description; from entity_causal_chain for WHY]
**Blast radius:** [from impact_service_graph]
**Customer impact:** [from impacted_context]
**Responsible:** [from responsible_context or causely.ai/team label]
**Recommended actions:** [from remediation]
**Links:** [portal links]

### Morning briefing

**🟢 / 🟡 / 🔴 System health: [status]** — *[N] active issues*

| Service | Issue | Severity | Since | Primary diagnosis | Owner |
|---|---|---|---|---|---|

**SLOs at risk:** [from `get_slo(only_at_risk=true)`]

### On-call handoff

🔴 **Active now:** [severity · service · issue · diagnosis]
🟡 **SLOs burning:** [burn rate > 1.0]
📋 **Watch list:** [recurring issues in past 24h]

---

## Closeout

- Load `submit_feedback` via `tool_search` at the start of an investigation. The tool description has the rest.
