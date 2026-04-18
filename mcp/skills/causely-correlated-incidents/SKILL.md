---
name: causely-correlated-incidents
description: >
  Use this skill when the user reports that multiple services are broken at the same time, suspects a shared root cause, or asks about cascading failures, blast radius, dependency chains, or "what else is this affecting". Trigger for questions like "multiple things are broken", "is this a widespread outage?", "what's the common cause across these services?", "which services are affected by the same root cause?", "is this a network issue hitting everything?", "are these incidents related?", "show me the blast radius", "what depends on X?", "what's the dependency chain?", or "trace the impact path". Also trigger when the initial incident triage reveals that more than one service has active root causes — treat that as a signal to pivot to correlation analysis. Do NOT skip this skill just because the user mentions only one service; if investigation reveals a broader pattern, switch to this skill.
---

# Causely Correlated Incidents Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

---

## Core tools for correlation analysis

| Tool | Use when | What it returns |
|---|---|---|
| `get_root_causes(active_only=true)` | All active issues — primary correlation tool | All RCs with `impact_service_graph` edges showing propagation paths |
| `triage(entity_name=)` | Named service cascade investigation | Per-entity root causes with impact graph |
| `get_topology(entity_id=, mode=)` | Full dependency/dependent graph (beyond active incidents) | Node + edge graph: dependencies, dependents, or dataflow |
| `get_alerts(entity_ids=)` | Alert correlation across entities | Firing alerts with mapping state — find unmapped shared alerts |
| `get_environment_health(namespaces=)` | Scoped health check for affected namespace | Overall status + active root causes in scope |
| `ask_causely(question=)` | Cross-entity synthesis when names aren't clear | Free-form NL query for broad pattern detection |

---

## Core rule: one sweep, read the graphs

**`get_root_causes(active_only=true)` returns everything needed for correlation in one call:**
- Each root cause includes `impact_service_graph.edges` — a node appearing as source in multiple graphs is the shared origin
- `impacted_services` shows blast radius per root cause
- `impacted_customers` shows customer-facing impact
- `description` is the synthesised evidence — read it, don't re-fetch it

Do not follow up with `get_symptoms` — symptoms are already included in the root cause response.

---

## Decision tree

**Widespread outage:**
```
get_root_causes(active_only=true)                          ← 1 call
  → look for shared node IDs across impact_service_graphs
  → shared node = correlation origin
  → description on that root cause = evidence
  → impacted_customers across all RCs = customer impact
  → done, unless description generic AND has_stored_logs=true:
       → get_logs(root_cause_id=, limit=10, severity_filter=ERROR)   ← optional 2nd call
```

**"Are these two incidents related?":**
```
get_root_causes(active_only=true)                          ← 1 call (covers both services)
  → compare impact_service_graph.nodes for shared IDs
  → compare started_at — simultaneous = correlated
  → done
```

**Named service, cascade suspected:**
```
triage(entity_name="<service>")                            ← 1 call
  → read impact_service_graph: trace edges from root to leaves
  → impacted_services = confirmed downstream blast radius
  → done
```

**Full dependency graph (beyond active incidents):**
```
get_entities(query="<service>", entity_types=["Service"])   ← 1 call
get_topology(entity_id=<id>, mode=dependents, levels=3)     ← 1 call
  → all services that call this entity (upstream blast radius victims)
  → or mode=dependencies for what this entity calls (downstream risk)
  → or mode=dataflow for full end-to-end data movement
```

**Alert-level correlation (shared alert patterns across services):**
```
get_entities(query="<service-a>")                           ← 1 call
get_entities(query="<service-b>")                           ← 1 call
get_alerts(entity_ids=[id_a, id_b], active_only=true)       ← 1 call
  → shared alert_names across entities = correlated signals
  → mapped alerts → get_root_causes(symptom_ids=) for cause
```

---

## Correlation methods

1. **Impact graph overlap**: shared node IDs in `impact_service_graph` across multiple root causes → same origin
2. **Temporal correlation**: root causes with `started_at` within minutes of each other → likely same trigger
3. **Topology correlation**: `get_topology(mode=dependents)` shows all upstream callers — if the degraded entity is a shared dependency, all dependents are at risk
4. **Alert pattern correlation**: same `alert_name` firing across multiple entities simultaneously → shared infrastructure cause

---

## Output format

### 🔴 Multi-service incident summary

**Affected services:** [from impacted_services across root causes]

**Correlation:** ✅ Correlated / ⚠️ Partial / ❓ Unconfirmed — [origin entity if known]

**Root cause:** [name + entity + portal link from get_root_causes]

**Propagation path:** [from impact_service_graph edges, or get_topology if called]

**Evidence:** [from description field; supplement with get_logs if generic AND has_stored_logs=true]

**Blast radius:** [from impact_service_graph — total affected services count + names]

**Customer impact:** [from impacted_customers]

**Owner:** [from causely.ai/team label or team_health]

**Timeline:** [started_at per root cause, in order]

**Recommended action:** [from remediation field — single fix that resolves the origin]

**Links:** [all portal links]
