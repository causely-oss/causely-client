---
name: causely-k8s-investigation
description: >
  Use this skill when the user asks about Kubernetes infrastructure health: nodes, pods, namespaces, deployments, DaemonSets, containers, or infra-level issues like OOMKills, node pressure, pod restarts, scheduling failures, resource exhaustion, CrashLoopBackOff, or evictions. Trigger for questions like "why did my pod restart?", "is node X under pressure?", "what's wrong with the chaos namespace?", "are any nodes unhealthy?", "show me container resource usage", "what events happened on this pod?", or "show me the config for this deployment".
---

# Causely K8s Investigation Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs. Use `name_mention_type` to narrow: `"Entity"` for pods/containers, `"Namespace"` for namespaces, `"Cluster"` for clusters.

---

## Core tools for K8s investigation

| Tool | Use when | What it returns |
|---|---|---|
| `get_service_summary(service=)` | Service-level health check — resolves name automatically | Status + symptoms + RCs + SLOs + metrics + deps + events + errors |
| `get_environment_health(namespaces=)` | Namespace-level health sweep | Status + root causes for that namespace |
| `get_symptoms()` | All active symptoms — includes crash signals, OOM kills, pod failures | Full signal picture, no IDs needed |
| `get_incident_impact(root_cause_id=)` | Deep investigation for a known root cause — responsibility + business context | Responsible entity + impacted services + team/product/customer |
| `name_lookup` → `get_entity_health(entity_id=)` | Non-service entity health (pods, nodes, DBs, containers) | Symptoms, RCs, events, logs, metrics |
| `name_lookup` → `get_events(entity_id=)` | Lifecycle events (restarts, scaling, scheduling) | OOMKill, CrashLoopBackOff, eviction events |
| `name_lookup` → `get_config(entity_id=)` | Inspect K8s manifests and resource specs | Deployment spec, resource limits, HPA config |
| `name_lookup` → `get_metrics(entity_ids=, metrics=)` | Container/pod resource utilisation | CPU, memory, network I/O |
| `name_lookup` → `get_logs(entity_id=)` | Live container/pod logs | Real-time log stream |

---

## Decision tree

**Service name known:**
```
get_service_summary(service="<namespace/service>")          ← 1 call, resolves name
```

If degraded and need responsibility:
```
get_incident_impact(root_cause_id=<from service summary>)   ← 1 call
```

**Pod/container-level detail:**
```
name_lookup(name_mention="<pod-name>", name_mention_type="Entity")  ← 1 call
get_entity_health(entity_id=<id>)                                    ← 1 call
```

**Why did my pod restart?**
```
name_lookup(name_mention="<pod-name>", name_mention_type="Entity")  ← 1 call
get_events(entity_id=<id>, severity_filter=WARNING)                  ← 1 call
  → OOMKill → get_config(entity_id=) to check resource limits
  → CrashLoopBackOff → get_logs(entity_id=, limit=20, severity_filter=ERROR)
```

**Namespace sweep (no service name):**
```
get_environment_health(namespaces=["<namespace>"])                    ← 1 call
```

---

## Output format

### 🔴 / 🟡 / 🟢 [Service/Entity] — [Status]

**Root cause (infra layer):** [name + entity + portal link]
**Responsible:** [from get_incident_impact or causely.ai/team label]
**Evidence:** [from description field]
**Resource state:** [from get_metrics if called]
**Recent events:** [from get_events if called]
**Blast radius:** [from impacted_services]
**Recommended actions:** [from remediation + k8s steps]
**Links:** [portal links]
