---
name: causely-mcp
description: >
  Use this skill whenever the user asks about service health, incidents, errors, latency, SLOs, diagnoses, symptoms, dependencies, blast radius, slow queries, alerts, metrics, topology, or anything related to observability and reliability. Also trigger for questions about Causely's methodology: "how does Causely work?", "how did Causely find this?", "what is Causely's causal reasoning?". This is the routing guide to 8 specialized Causely skills covering 50 MCP tools. Trigger for "what's wrong with X", "why is X slow", "what's the diagnosis", "is X healthy", "what services are affected", "what's burning our error budget", "show me the topology", "what alerts are firing", or any on-call / incident triage scenario. Always use when the topic is service reliability or system health.
---

# Causely MCP — Skill Routing Guide

You have access to 50 Causely MCP tools organized into 8 specialized skills. This guide routes you to the right skill. Each skill has its own tool routing, decision trees, and output formats.

Read `references/complete-investigation.md` for the full 50-tool inventory and shared investigation protocol.

---

## Skill routing — pick the right skill first time

| User intent | Skill | What it does |
|---|---|---|
| "Is X healthy?" / "What's wrong with X?" / "What's the diagnosis?" | **causely-health-reporting** | Service health, environment health, SLO checks, team standups, entity counts, rankings |
| "I got paged" / "What alerts are firing?" / "Investigate this alert" | **causely-alert-triage** | Alert search → investigate_alert (full issue details in 2 calls) |
| "Did the deploy break anything?" / "Post-deploy check" / "Take a snapshot" / "Compare before and after" | **causely-change-impact** | Quick metric deltas (reliability_delta) + full snapshot comparisons (ACCEPTED/REJECTED) |
| "Checkout and payment both down, related?" / "What services are affected?" | **causely-correlated-incidents** | Multi-service outage correlation via shared diagnoses and impact graphs |
| "Why is my pod restarting?" / "Container crash loop" / "Node pressure" | **causely-k8s-investigation** | Kubernetes-specific: pod/container/node health, events, configs, potential diagnoses |
| "Write a postmortem" / "Create a Jira ticket" | **causely-postmortem** | Postmortem generation, ticket drafts (Jira/GitHub/Linear) |
| "Set the error rate threshold" / "Make X a critical service" / "Snooze this issue" / "Hide this service" | **causely-admin** | Thresholds, service tiers, issue snoozing — configuration and tuning |
| "How does Causely work?" / "What could go wrong with X?" / "What could explain this signal?" | **causely-mcp** (this skill) | Causality model exploration, conceptual model, methodology |

---

## When multiple skills apply

Some scenarios span skills. Start with the primary skill, then chain:

| Scenario | Start with | Then chain |
|---|---|---|
| "Alert firing, fix it and write a postmortem" | **causely-alert-triage** → investigate | **causely-postmortem** → write postmortem |
| "Deploy broke checkout, what happened?" | **causely-change-impact** → reliability_delta | **causely-health-reporting** → get_service_summary for full picture |
| "Multiple services down after deploy" | **causely-change-impact** → fleet check | **causely-correlated-incidents** → correlation analysis |
| "Pod crashing, is it affecting SLOs?" | **causely-k8s-investigation** → pod health | **causely-health-reporting** → get_slo |
| "Set threshold to stop false positives on X" | **causely-health-reporting** → get_service_summary to understand current state | **causely-admin** → set threshold |

---

## Cross-cutting concepts (all skills share these)

### Name resolution

**When a user mentions a name, call `name_lookup` first.** It resolves names to typed objects with IDs for downstream tools. All skills use it.

### Issues vs Diagnoses vs Signals

- **Issue** = persistent incident identity. Stable — doesn't change. One thing to acknowledge, share, resolve.
- **Diagnosis** = current best explanation. Evolves as signals change.
- **Signal** (symptom/alert/event) = observable anomaly. Comes and goes.
- **Linking rule:** if two Diagnoses share even one Signal, they're the same Issue.
- Use `get_issues` for the stable incident view; use `get_diagnoses` for the current diagnosis.

### Disambiguation params

`get_service_summary`, `reliability_delta`, and `fleet_reliability_delta` all support `cluster_name`/`namespace_name`/`service_type`/`entity_id` for disambiguation. Pass them whenever the user mentions a cluster, namespace, or service type.

### Feedback protocol

After investigation-terminal tools (`get_issue_details`, `get_diagnosis_details`, `investigate_alert`, `get_incident_impact`, `compare_snapshots`, `postmortem`):
- **Load first:** `tool_search("Causely submit_feedback")` at investigation start
- **Agent mode:** `submit_feedback(source="agent", rating=, message=<what the result showed>)` — no user needed
- **User mode:** `ask_user_input` for clickable Yes/No if available, otherwise plain text → `submit_feedback(source="user", rating=<from yes/no>, message=<their words>)`
- **Rating from yes/no ONLY.** "Yes, X was a problem" = positive (Causely correctly found X)
- **Skip** on single-tool fast paths

---

## Anti-patterns (apply across all skills)

- **`get_diagnoses` is lightweight.** Does NOT include entity_causal_chain. Always follow up with `get_diagnosis_details`.
- **`get_environment_health` does NOT report SLOs.** Use `get_slo` for all SLO questions.
- **`get_events` does NOT cover deployments.** Use `get_symptoms(symptom_name="VersionChanged", entity_types=["ComputeSpec"])`.
- **`count_entities` for counting, not `get_entities`.** `get_entities` caps at 200 — silently undercounts.
- **`rank_entities` for "which has the most..." questions.** Do NOT loop `get_topology`.
- **`description` is pre-synthesised evidence.** Only call `get_logs` if description is generic AND `has_stored_logs=true`.
- **`get_symptoms` `lookback_hours` is an interval-overlap filter.** Cross-check `started_at` against stated window.

---

## Causality model exploration (this skill handles directly)

These tools explore the **theoretical** causality model — hypotheses and signal relationships, not just observed state.

### Forward: entity → diagnoses → signals
1. `name_lookup` → `get_potential_diagnoses(entity_id=)` — all hypotheses (active + causality-only)
2. `get_diagnosis_observable_signals(entity_id=, diagnosis_name=)` — what signals this diagnosis could cause
3. Compare to `get_symptoms(entity_ids=[id])` to see which are actually active

### Reverse: signal → diagnoses
1. `name_lookup` → `get_potential_observable_signals(entity_id=)` — all signals (active + inactive + potential)
2. `get_signal_potential_diagnoses(entity_id=, signal_name=)` — which diagnoses could explain this signal

### "How does Causely work?"
1. `get_diagnosis_details(diagnosis_id=)` — `entity_causal_chain` explains WHY Causely identified the diagnosis
2. Walk edges from leaf symptoms toward root_entity_id — probabilities show causal confidence
3. Also read `references/how-causely-works.md` for methodology
