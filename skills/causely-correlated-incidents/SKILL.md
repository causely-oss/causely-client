---
name: causely-correlated-incidents
description: >
  Use this skill when the user reports that multiple services are broken at the same time, suspects a shared diagnosis, or asks about cascading failures, blast radius, dependency chains, or "what else is this affecting". Trigger for questions like "multiple things are broken", "is this a widespread outage?", "what's the common cause across these services?", "are these incidents related?", "show me the blast radius", "what depends on X?", "which services have the most dependencies?", or "trace the impact path".
---

# Causely Correlated Incidents Skill


Use `name_lookup(name_mention=)` to resolve names.

---

## Core tools

| Tool | Use when |
|---|---|
| `get_issues(active_only=true)` | **Primary entry point** — stable incident grouping |
| `get_issue_details(issue_id=)` | Full evidence in one call: entity_causal_chain + impact_service_graph + all diagnoses |
| `get_incident_impact(diagnosis_id=)` | Responsibility + business context |
| `get_symptoms()` | Full signal scan — best first step |
| `name_lookup` → `get_topology(entity_id=, mode=, levels=)` | `dependencies` (what it calls), `dependents` (what calls it), or `dataflow` (end-to-end producers and consumers). `levels` defaults to 2, max 6 |
| `rank_entities(entity_type=, mode=)` | Bulk ranking — do NOT loop get_topology |
| `get_diagnoses(symptom_ids=)` | Drill-down: find diagnoses matching specific symptoms for correlation |

---

## Decision tree

**Widespread outage:**
```
get_issues(active_only=true)                             ← stable incident list
  → get_issue_details(issue_id=)                         ← entity_causal_chain + impact_service_graph + all diagnoses
  → get_incident_impact(diagnosis_id=)                   ← responsibility
```

**"Which services are most interconnected?":**
```
rank_entities(entity_type="Service", mode=dependents)      ← 1 call
```

**Full dependency graph for one service:**
```
name_lookup → get_topology(entity_id=, mode=dependents)    ← 2 calls
```

---

## Important behaviours

- **Start unfiltered.** `get_diagnoses(related_entity_ids=)` can miss a diagnosis whose origin is a different service, such as an upstream crash that has not propagated yet. Call `get_issues` with no filters first, then correlate by service.
- **Rank, don't loop.** Use `rank_entities` for "most interconnected"; never loop `get_topology`.
- **Check `impact_service_graph` first.** It already holds the propagation path for a diagnosis, at no extra cost. Use `get_topology` only when you need the full call graph regardless of incidents.

---

## Output format

### 🔴 Multi-service incident summary

**Affected services:** [from impacted_services across diagnoses]
**Correlation:** ✅ Correlated / ⚠️ Partial / ❓ Unconfirmed — [origin entity if known]
**Diagnosis:** [name + entity + portal link from get_issue_details primary_diagnosis_detail]
**Propagation path:** [from impact_service_graph edges]
**Evidence:** [from description field; from entity_causal_chain for WHY]
**Blast radius:** [from impact_service_graph — total affected services count + names]
**Customer impact:** [from impacted_customers or get_incident_impact impacted_context]
**Responsible:** [from get_incident_impact responsible_context]
**Timeline:** [started_at per diagnosis, in order]
**Recommended action:** [from remediation field — single fix that resolves the origin]
**Links:** [all portal links]

---

## Closeout

- Load `submit_feedback` via `tool_search` at the start of an investigation. The tool description has the rest.
