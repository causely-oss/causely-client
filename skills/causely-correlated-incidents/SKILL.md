---
name: causely-correlated-incidents
description: >
  Use this skill when the user reports that multiple services are broken at the same time, suspects a shared diagnosis, or asks about cascading failures, blast radius, dependency chains, or "what else is this affecting". Trigger for questions like "multiple things are broken", "is this a widespread outage?", "what's the common cause across these services?", "are these incidents related?", "show me the blast radius", "what depends on X?", "which services have the most dependencies?", or "trace the impact path".
---

# Causely Correlated Incidents Skill

Read `references/complete-investigation.md` for the full 33-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names.

---

## Core tools

| Tool | Use when |
|---|---|
| `get_diagnoses(active_only=true)` | Primary correlation tool — lightweight summary |
| `get_diagnosis_details(diagnosis_id=)` | Full evidence: causal_chain + impact_service_graph for blast radius |
| `get_incident_impact(diagnosis_id=)` | Responsibility + business context |
| `get_symptoms()` | Full signal scan — best first step |
| `name_lookup` → `get_topology(entity_id=, mode=)` | Full dependency graph |
| `rank_entities(entity_type=, mode=)` | Bulk ranking — do NOT loop get_topology |

---

## Decision tree

**Widespread outage:**
```
get_diagnoses(active_only=true)                          ← lightweight list
  → get_diagnosis_details(diagnosis_id=)                 ← impact_service_graph for blast radius
  → get_incident_impact(diagnosis_id=)                    ← responsibility
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

## Output format

### 🔴 Multi-service incident summary

**Affected services:** [from impacted_services across diagnoses]
**Correlation:** ✅ Correlated / ⚠️ Partial / ❓ Unconfirmed — [origin entity if known]
**Diagnosis:** [name + entity + portal link from get_diagnoses]
**Propagation path:** [from get_diagnosis_details impact_service_graph edges]
**Evidence:** [from description field; from get_diagnosis_details causal_chain for WHY]
**Blast radius:** [from impact_service_graph — total affected services count + names]
**Customer impact:** [from impacted_customers or get_incident_impact impacted_context]
**Responsible:** [from get_incident_impact responsible_context]
**Timeline:** [started_at per diagnosis, in order]
**Recommended action:** [from remediation field — single fix that resolves the origin]
**Links:** [all portal links]
