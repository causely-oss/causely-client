---
name: causely-correlated-incidents
description: >
  Use this skill when the user reports that multiple services are broken at the same time, suspects a shared root cause, or asks about cascading failures, blast radius, dependency chains, or "what else is this affecting". Trigger for questions like "multiple things are broken", "is this a widespread outage?", "what's the common cause across these services?", "are these incidents related?", "show me the blast radius", "what depends on X?", "which services have the most dependencies?", or "trace the impact path".
---

# Causely Correlated Incidents Skill

Read `references/complete-investigation.md` for the full 28-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs.

---

## Core tools

| Tool | Use when | What it returns |
|---|---|---|
| `get_root_causes(active_only=true)` | Primary correlation tool. >10 results truncate detail. | All RCs with `impact_service_graph` edges |
| `get_incident_impact(root_cause_id=)` | Responsibility + business context | Responsible entity, impacted services, team/product/customer |
| `get_symptoms()` | Full signal scan — best first step | All active symptoms, no IDs needed |
| `name_lookup` → `get_topology(entity_id=, mode=)` | Full dependency graph for one entity | Nodes + edges |
| `rank_entities(entity_type=, mode=)` | **Bulk ranking** — "which services have the most dependents?" | Ranked list, single SQL query. Do NOT loop get_topology. |
| `get_alerts(alert_name_expr=)` | Alert correlation across entities | Firing alerts with mapping state |

---

## Decision tree

**Widespread outage:**
```
get_root_causes(active_only=true)                          ← 1 call
  → shared nodes in impact_service_graphs = correlation origin
  → get_incident_impact(root_cause_id=) for responsibility
```

**"Which services are most interconnected?":**
```
rank_entities(entity_type="Service", mode=dependents)      ← 1 call, single SQL
```

**Full dependency graph for one service:**
```
name_lookup → get_topology(entity_id=, mode=dependents)    ← 2 calls
```

---

## Output format

### 🔴 Multi-service incident summary

**Affected services:** [from impacted_services]
**Correlation:** ✅ Correlated / ⚠️ Partial / ❓ Unconfirmed
**Root cause:** [name + entity + portal link]
**Responsible:** [from get_incident_impact]
**Propagation path:** [from impact_service_graph]
**Customer impact:** [from impacted_context]
**Links:** [portal links]
