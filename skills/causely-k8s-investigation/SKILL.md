---
name: causely-k8s-investigation
description: >
  Use this skill when the user asks about Kubernetes infrastructure health: nodes, pods, namespaces, deployments, DaemonSets, containers, or infra-level issues like OOMKills, node pressure, pod restarts, scheduling failures, resource exhaustion, CrashLoopBackOff, or evictions. Trigger for questions like "why did my pod restart?", "is node X under pressure?", "what's wrong with the chaos namespace?", "are any nodes unhealthy?", "show me container resource usage", "what events happened on this pod?", or "show me the config for this deployment".
---

# Causely K8s Investigation Skill

Read `references/complete-investigation.md` for the full 33-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names. Use `name_mention_type` to narrow: `"Entity"` for pods/containers, `"Namespace"` for namespaces, `"Cluster"` for clusters.

---

## Core tools

| Tool | Use when |
|---|---|
| `get_service_summary(service=)` | Service-level health check — resolves name |
| `get_environment_health(namespaces=)` | Namespace-level sweep |
| `get_symptoms()` | All active symptoms — crash signals, OOM kills, pod failures |
| `get_diagnosis_details(diagnosis_id=)` | Full evidence for a diagnosis |
| `get_incident_impact(diagnosis_id=)` | Responsibility + business context |
| `name_lookup` → `get_entity_health(entity_id=)` | Pod/node/container health |
| `name_lookup` → `get_events(entity_id=)` | OOMKill, CrashLoopBackOff, eviction events |
| `name_lookup` → `get_config(entity_id=)` | Resource limits, HPA config |
| `name_lookup` → `get_metrics(entity_ids=, metrics=)` | CPU, memory, network I/O |
| `name_lookup` → `get_potential_diagnoses(entity_id=)` | Causality hypotheses |

---

## Decision tree

- **Service name known** → `get_service_summary(service=)`
- **Pod/container detail** → `name_lookup` → `get_entity_health(entity_id=)`
- **Why did my pod restart?** → `name_lookup` → `get_events(entity_id=, severity_filter=WARNING)`
- **Namespace sweep** → `get_environment_health(namespaces=["<ns>"])`
- **Full RC evidence** → `get_diagnosis_details(diagnosis_id=)` → read causal_chain
- **What could be wrong with this entity?** → `name_lookup` → `get_potential_diagnoses(entity_id=)` → compare active vs causality-only hypotheses
- **What could explain this symptom?** → `name_lookup` → `get_signal_potential_diagnoses(entity_id=, signal_name=)`

---

## Output format

### 🔴 / 🟡 / 🟢 [Service/Entity] — [Status]

**Diagnosis:** [name + entity + portal link]
**Evidence:** [from description field; from get_diagnosis_details causal_chain for WHY Causely diagnosed this]
**Resource state:** [from get_metrics if called — CPU/memory usage vs limits]
**Configuration:** [from get_config if called — relevant resource limits, HPA settings]
**Recent events:** [from get_events if called — OOMKill, restarts, scaling events with timestamps]
**Blast radius:** [from get_diagnosis_details impact_service_graph or impacted_services]
**Customer impact:** [from impacted_customers or get_incident_impact impacted_context]
**Responsible:** [from get_incident_impact responsible_context or causely.ai/team label]
**Recommended actions:** [from remediation field + k8s-specific steps: adjust resource limits, cordon/drain node, review HPA, check liveness probes]
**Links:** [portal links from response]
