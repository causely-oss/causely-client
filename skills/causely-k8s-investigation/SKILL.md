---
name: causely-k8s-investigation
description: >
  Use this skill when the user asks about Kubernetes infrastructure health: nodes, pods, namespaces, deployments, DaemonSets, containers, or infra-level issues like OOMKills, node pressure, pod restarts, scheduling failures, resource exhaustion, CrashLoopBackOff, or evictions. Trigger for questions like "why did my pod restart?", "is node X under pressure?", "what's wrong with the chaos namespace?", "are any nodes unhealthy?", "why is my deployment not scaling?", "show me container resource usage", "what events happened on this pod?", "show me the config for this deployment", or any question involving k8s primitives rather than application-level services. Always use this skill — not just the generic causely-mcp skill — when the question is clearly about infrastructure or workload scheduling rather than application SLOs or business metrics.
---

# Causely K8s Investigation Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

---

## Core tools for K8s investigation

| Tool | Use when | What it returns |
|---|---|---|
| `triage(entity_name=)` | Service-level health check — always start here | Root causes with infra-layer evidence (OOMKill, pod failure, memory pressure) |
| `get_entities(query=, entity_types=)` | Resolve K8s entities to IDs | Entity IDs for pods, containers, nodes, databases |
| `get_entity_health(entity_id=)` | Non-service entity health (pods, nodes, DBs, containers) | Symptoms, root causes, events, logs, metrics for one entity |
| `get_events(entity_id=)` | Lifecycle events (restarts, scaling, scheduling) | Timestamped events: OOMKill, CrashLoopBackOff, eviction, deploy, config change |
| `get_config(entity_id=)` | Inspect K8s manifests and resource specs | Raw config files: deployment spec, resource limits, HPA config |
| `get_metrics(entity_ids=, metrics=)` | Container/pod resource utilisation | CPU, memory, network I/O snapshots or time-series |
| `get_logs(entity_id=)` | Live container/pod logs | Real-time log stream for a running entity |
| `get_root_causes(active_only=true)` | System-wide infra sweep | All active RCs — filter for K8s-related root causes |
| `list_namespaces()` | Discover valid namespaces | Namespace names for scoping investigations |
| `list_clusters()` | Discover valid clusters | Cluster names for multi-cluster queries |

---

## Entity name format

| Type | Format | Example |
|---|---|---|
| K8s service | `namespace/service-name` | `default/animal-service` |
| ECS task / VM | `cluster/task-name-hash` | `chaos/quarkus-workshop-hero-service-2b62b3ef` |
| Node | AWS/GCP hostname | `ip-192-168-12-32.us-east-2.compute.internal` |

---

## Decision tree

**Service name known — start at service level:**
```
triage(entity_name="<namespace/service>")                  ← 1 call
  → infra root causes: "Memory congestion", "Pod Failure", "OOMKill", "Node pressure"
  → description = evidence (memory %, restart counts, disk errors)
  → impacted_services = blast radius
  → done
```

**Need pod/container-level detail:**
```
get_entities(query="<pod-name>", entity_types=["Container","Pod"])  ← 1 call
get_entity_health(entity_id=<id>)                          ← 1 call
  → symptoms, root causes, events, logs, metrics for that specific entity
```

**Why did my pod restart?**
```
get_entities(query="<pod-name>")                           ← 1 call
get_events(entity_id=<id>, severity_filter=WARNING)         ← 1 call
  → look for OOMKill, CrashLoopBackOff, Evicted events with timestamps
  → if OOMKill: get_config(entity_id=) to check resource limits
  → if CrashLoopBackOff: get_logs(entity_id=, limit=20, severity_filter=ERROR)
```

**Resource utilisation check:**
```
get_entities(query="<service>", entity_types=["Service"])   ← 1 call
get_metrics(entity_ids=[id], metrics=["cpu_usage", "memory_usage", "memory_limit"])  ← 1 call
  → compare usage vs limits
  → if near limit: check get_config for resource requests/limits
```

**Inspect K8s config / resource limits:**
```
get_entities(query="<service>")                            ← 1 call
get_config(entity_id=<id>)                                  ← 1 call
  → deployment spec, resource limits, HPA config, environment variables
```

**Service name unknown / namespace sweep:**
```
get_environment_health(namespaces=["<namespace>"])           ← 1 call
  → overall namespace status + active root causes
  → or:
get_root_causes(active_only=true)                           ← 1 call
  → filter for namespace/entity names matching the namespace
  → description = evidence for each RC
  → only triage the single highest-severity hit for detail
```

**Triage returns "No Incident Data Found":**
- Service is healthy at the service level — the infra issue may be at pod/container level
- Try `get_entities(query="<name>")` → `get_entity_health(entity_id=)` for pod-level health
- Or `get_root_causes(active_only=true)` and filter for the entity name pattern

---

## Output format

### 🔴 / 🟡 / 🟢 [Service/Entity] — [Status]

**Root cause (infra layer):** [name + entity + portal link]

**Evidence:** [from description field — specific metrics, counts, log patterns; supplement with get_logs only if description is generic AND has_stored_logs=true]

**Resource state:** [from get_metrics if called — CPU/memory usage vs limits]

**Configuration:** [from get_config if called — relevant resource limits, HPA settings]

**Recent events:** [from get_events if called — OOMKill, restarts, scaling events with timestamps]

**Blast radius:** [from impacted_services, or "None identified"]

**Customer impact:** [from impacted_customers, or "None identified"]

**Owner / team:** [from causely.ai/team label or team_health, or "Not registered"]

**Recommended actions:** [from remediation field + k8s-specific steps: adjust resource limits, cordon/drain node, review HPA, check liveness probes]

**Links:** [portal links from response]
