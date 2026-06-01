---
name: causely-correlated-incidents
description: >
  Use this skill when the user reports that multiple services are broken at the same time, suspects a shared root cause, or asks about cascading failures, blast radius, dependency chains, or "what else is this affecting". Trigger for questions like "multiple things are broken", "is this a widespread outage?", "what's the common cause across these services?", "are these incidents related?", "show me the blast radius", "what depends on X?", "what's the dependency chain?", or "trace the impact path".
---

# Causely Correlated Incidents Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for correlation analysis

| Tool | Use when | What it returns |
|---|---|---|
| `get_root_causes(active_only=true)` | All active issues — primary correlation tool | All RCs with `impact_service_graph` edges |
| `get_incident_impact(root_cause_id=)` | Responsibility + business context for a specific root cause | Responsible entity, impacted services, team/product/customer context |
| `get_symptoms()` | Full signal scan — best first step | All active symptoms, no IDs needed |
| `get_service_summary(service=)` | Per-service health when name known | Full picture for one service |
| `name_lookup` → `get_topology(entity_id=, mode=)` | Full dependency/dependent graph | Nodes + edges |
| `get_alerts(alert_name_expr=)` | Alert correlation across entities | Firing alerts with mapping state |

---

## Decision tree

**Widespread outage:**
```
get_root_causes(active_only=true)                          ← 1 call
  → shared node IDs across impact_service_graphs = correlation origin
  → get_incident_impact(root_cause_id=) for responsibility + business impact
```

**Full dependency graph:**
```
name_lookup(name_mention="<service>", name_mention_type="Entity")  ← 1 call
get_topology(entity_id=<id>, mode=dependents, levels=3)             ← 1 call
```

**Alert-level correlation:**
```
get_alerts(alert_name_expr="<pattern>", active_only=true)  ← 1 call
  → mapped alerts → get_root_causes(symptom_ids=) for cause
```

---

## Output format

### 🔴 Multi-service incident summary

**Affected services:** [from impacted_services across root causes]
**Correlation:** ✅ Correlated / ⚠️ Partial / ❓ Unconfirmed — [origin entity]
**Root cause:** [name + entity + portal link]
**Responsible:** [from get_incident_impact responsible_context]
**Propagation path:** [from impact_service_graph edges]
**Evidence:** [from description field]
**Customer impact:** [from impacted_customers or impacted_context]
**Recommended action:** [from remediation]
**Links:** [portal links]
