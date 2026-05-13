---
name: causely-correlated-incidents
description: >
  Use this skill when the user reports that multiple services are broken at the same time, suspects a shared root cause, or asks about cascading failures, blast radius, dependency chains, or "what else is this affecting". Trigger for questions like "multiple things are broken", "is this a widespread outage?", "what's the common cause across these services?", "which services are affected by the same root cause?", "is this a network issue hitting everything?", "are these incidents related?", "show me the blast radius", "what depends on X?", "what's the dependency chain?", or "trace the impact path". Also trigger when initial investigation reveals multiple services have active root causes.
---

# Causely Correlated Incidents Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for correlation analysis

| Tool | Use when | What it returns |
|---|---|---|
| `get_root_causes(active_only=true)` | All active issues — primary correlation tool | All RCs with `impact_service_graph` edges showing propagation paths |
| `get_symptoms()` | Full signal scan — best first step | All active symptoms across every entity, no IDs needed |
| `get_service_summary(service=)` | Per-service health when name known | Full picture for one service |
| `triage(entity_name=)` | Deep investigation of a known-degraded service | Structured narrative with impact graph |
| `name_lookup` → `get_topology(entity_id=, mode=)` | Full dependency/dependent graph | Nodes + edges: dependencies, dependents, or dataflow |
| `get_alerts(alert_name_expr=)` | Alert correlation across entities | Firing alerts with mapping state |
| `get_environment_health(namespaces=)` | Scoped health check for affected namespace | Overall status + active root causes in scope |

---

## Core rule: one sweep, read the graphs

**`get_root_causes(active_only=true)` returns everything for correlation in one call:**
- `impact_service_graph.edges` — a shared node across multiple graphs is the correlation origin
- `impacted_services` shows blast radius per root cause
- `description` is the synthesised evidence — read it, don't re-fetch

**`get_symptoms()` with no entity_ids** gives the full signal picture across all entities — useful as the first step when you don't know what's affected.

---

## Decision tree

**Widespread outage:**
```
get_root_causes(active_only=true)                          ← 1 call
  → shared node IDs across impact_service_graphs = correlation origin
  → done
```

Or start with signals:
```
get_symptoms()                                             ← 1 call
  → all active symptoms across every entity
  → pass symptom_ids to get_root_causes for diagnosis
```

**Full dependency graph:**
```
name_lookup(name_mention="<service>", name_mention_type="Entity")  ← 1 call
get_topology(entity_id=<id>, mode=dependents, levels=3)             ← 1 call
```

**Alert-level correlation:**
```
get_alerts(alert_name_expr="<pattern>", active_only=true)  ← 1 call (no entity IDs needed)
  → mapped alerts → get_root_causes(symptom_ids=) for cause
```

---

## Output format

### 🔴 Multi-service incident summary

**Affected services:** [from impacted_services across root causes]
**Correlation:** ✅ Correlated / ⚠️ Partial / ❓ Unconfirmed — [origin entity]
**Root cause:** [name + entity + portal link]
**Propagation path:** [from impact_service_graph edges]
**Evidence:** [from description field]
**Blast radius:** [total affected services count + names]
**Customer impact:** [from impacted_customers]
**Timeline:** [started_at per root cause, in order]
**Recommended action:** [from remediation — single fix that resolves origin]
**Links:** [all portal links]
