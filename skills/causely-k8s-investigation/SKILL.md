---
name: causely-k8s-investigation
description: >
  Use this skill when the user asks about Kubernetes infrastructure health: nodes, pods, namespaces, deployments, DaemonSets, containers, or infra-level issues like OOMKills, node pressure, pod restarts, scheduling failures, resource exhaustion, CrashLoopBackOff, or evictions. Trigger for questions like "why did my pod restart?", "is node X under pressure?", "what's wrong with the chaos namespace?", "are any nodes unhealthy?", "show me container resource usage", "what events happened on this pod?", or "show me the config for this deployment".
---

# Causely K8s Investigation Skill

Read `references/complete-investigation.md` for the full 28-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names. Use `name_mention_type` to narrow: `"Entity"` for pods/containers, `"Namespace"` for namespaces, `"Cluster"` for clusters.

---

## Core tools

| Tool | Use when | What it returns |
|---|---|---|
| `get_service_summary(service=)` | Service-level health check | Status + symptoms + RCs + metrics + deps + events |
| `get_environment_health(namespaces=)` | Namespace-level sweep | Status + root causes |
| `get_symptoms()` | All active symptoms — crash signals, OOM kills, pod failures | Full signal picture, no IDs needed |
| `get_incident_impact(root_cause_id=)` | Deep investigation for a known root cause | Responsible entity + business context |
| `name_lookup` → `get_entity_health(entity_id=)` | Non-service entity health (pods, nodes, containers) | Symptoms, RCs, events, logs, metrics |
| `name_lookup` → `get_events(entity_id=)` | Lifecycle events | OOMKill, CrashLoopBackOff, eviction |
| `name_lookup` → `get_config(entity_id=)` | K8s manifests | Resource limits, HPA config |
| `name_lookup` → `get_metrics(entity_ids=, metrics=)` | Resource utilisation. Use `entity_aggregate` for fleet averages. | CPU, memory, network I/O |
| `name_lookup` → `get_potential_diagnoses(entity_id=)` | What root causes could this entity have? (causality hypotheses) | Active + causality-only diagnoses |

---

## Decision tree

- **Service name known** → `get_service_summary(service=)`
- **Pod/container detail** → `name_lookup` → `get_entity_health(entity_id=)`
- **Why did my pod restart?** → `name_lookup` → `get_events(entity_id=, severity_filter=WARNING)`
- **Namespace sweep** → `get_environment_health(namespaces=["<ns>"])`
- **Average CPU across pods** → `get_metrics(entity_ids=, metrics=["cpu_usage_cores"], entity_aggregate="mean")`
- **What could be wrong with this entity?** → `name_lookup` → `get_potential_diagnoses(entity_id=)`

---

## Output format

### 🔴 / 🟡 / 🟢 [Service/Entity] — [Status]

**Root cause:** [name + portal link]
**Responsible:** [from get_incident_impact or causely.ai/team label]
**Evidence:** [from description field]
**Resource state:** [from get_metrics if called]
**Recent events:** [from get_events if called]
**Recommended actions:** [from remediation + k8s steps]
**Links:** [portal links]
