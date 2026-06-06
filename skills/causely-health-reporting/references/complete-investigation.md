# Complete Investigation Reference

## Efficiency-first principle

**`get_service_summary` or `get_environment_health` for health checks.** `get_service_summary(service=)` resolves names automatically and returns symptoms, root causes, SLOs, metrics, deps, events, and logs in one call. `get_environment_health(services=["X"])` gives a scoped health status.

**`get_incident_impact` is for incident investigation, not health checks.** Use it when health is already known to be degraded and you need to understand who is responsible, what's impacted, and the business context (team, product, customer, project).

**`description` is Causely's pre-synthesised evidence.** When `get_root_causes` returns a `description` field with specific log patterns or error messages, that is the evidence. Do not call `get_logs` to regenerate it.

---

## Complete tool inventory (23 tools)

### Discovery & name resolution
| Tool | Use when | Key params |
|---|---|---|
| `name_lookup` | **Call first when a user mentions a name.** Resolves entity/cluster/namespace/root-cause/symptom names to typed objects with IDs. | `name_mention` (required), `name_mention_type`, `cluster_names`, `namespace_names`, `entity_types` |
| `get_label_values` | Enumerate teams, products, environments, clusters, namespaces. Deterministic — use for discovery questions. | `label_key`, `query` (substring filter) |
| `get_integration_status` | Check scraper/integration coverage per cluster. | `cluster_names` (optional) |

### Health & investigation
| Tool | Use when | Key params |
|---|---|---|
| `get_service_summary` | **Primary tool for single-service health by name.** Full picture: symptoms, root causes, SLOs, metrics, deps, slow queries, events, error logs. Resolves names automatically. | `service` (substring match), `lookback_hours` |
| `get_environment_health` | Global or scoped health overview. Also use for system-wide SLO status (returns at-risk SLOs). | `namespaces`, `clusters`, `services`, `products`, `active_only`, `lookback_hours` |
| `get_incident_impact` | Deep incident investigation — responsible service, business context, blast radius. **Not for health checks.** | `root_cause_id`, `root_cause_name`, `entity_id`, `start_time/end_time` |
| `get_entity_health` | Health for any entity by ID (pods, DBs, queues, services). Requires entity_id from `name_lookup`. | `entity_id`, `lookback_hours` |
| `team_health` | All services owned by a team. Follow up with `get_incident_impact` for degraded services. | `team` (partial match) |

### Diagnosis
| Tool | Use when | Key params |
|---|---|---|
| `get_root_causes` | All active root causes (structured JSON with impact graphs). Call `name_lookup` first if a name is mentioned. **Note:** >10 results omit symptoms, causal_chain, and impact_service_graph — use `root_cause_id` or narrower filters for full detail. | `active_only`, `related_entity_ids`, `cluster_names`, `namespace_names`, `product_names`, `customer_names`, `symptom_ids`, `root_cause_name`, `root_cause_id` |
| `get_symptoms` | **Best first step in any incident** — call with no `entity_ids` to see all active symptoms across every entity. | `entity_ids` (optional), `active_only`, `lookback_hours`, `symptom_name`, `cluster_names`, `namespace_names` |
| `get_alerts` | Alert history, mapped/unmapped status. Supports name search via `alert_name_expr`. | `alert_name_expr`, `entity_ids`, `mapping_state_filters`, `alert_state_filters`, `start_time/end_time` |
| `investigate_alert` | One-step alert investigation. Pass a raw alert object from `get_alerts`, get `get_entity_health` back. | `alert` (full alert object), `lookback_hours` |
| `get_logs` | Live entity logs OR stored evidence logs. | `entity_id` XOR `root_cause_id`, `severity_filter`, `message_contains` |
| `get_events` | Lifecycle events (deploys, restarts, scaling). | `entity_id`, `severity_filter`, `message_contains` |
| `get_slow_queries` | DB slow query analysis. | `entity_ids` |

### Observability data
| Tool | Use when | Key params |
|---|---|---|
| `get_metrics` | Numeric snapshots, time-series, or aggregated fleet-level values. Supports `time_aggregate` to reduce a window to one scalar, and `entity_aggregate` to collapse across all entities. | `entity_ids`, `metrics`, `window_minutes`, `time_aggregate`, `entity_aggregate` |
| `get_slo` | SLO state, error budget, burn rate for specific services (requires entity IDs). For system-wide SLO overview, use `get_environment_health`. | `entity_ids`, `only_at_risk`, `only_violated` |
| `get_config` | Raw config files for an entity. | `entity_id`, `name_contains` |
| `get_topology` | Dependency/dependent/dataflow graph. | `entity_id`, `mode`, `levels` |

### Post-deploy & reliability
| Tool | Use when | Key params |
|---|---|---|
| `reliability_delta` | Single-service pre/post deploy comparison. | `service`, `lookback_hours`, `window_minutes` |
| `fleet_reliability_delta` | Batch regression check across multiple services. | `team`, `namespace`, `services`, `lookback_hours`, `window_minutes` |

### Reporting & actions
| Tool | Use when | Key params |
|---|---|---|
| `generate_ticket` | Create Jira/GitHub/Linear ticket draft. | `task` |
| `postmortem` | Generate postmortem for a resolved incident. | `root_cause_id` (preferred), or `root_cause_name` + `entity_name`, or `service` + `incident_start` |

---

## Name resolution pattern

**When a user mentions a name, call `name_lookup` first:**

```
name_lookup(name_mention="checkout")
  → Entity → pass id to get_metrics, get_slo, get_topology, get_alerts, get_events, get_config
  → Entity → pass id to get_root_causes(related_entity_ids=[id])
  → Entity → pass id to get_incident_impact(entity_id=id)
  → Cluster → pass name to get_root_causes(cluster_names=[name])
  → Namespace → pass name to get_root_causes(namespace_names=[name])
```

---

## get_metrics aggregation

`get_metrics` supports two aggregation levels for fleet-level queries:

**`time_aggregate`** — reduce a windowed time-series to one scalar per entity:
- `mean`, `sum`, `min`, `max`, `p95`, `count`, `delta`, `pct_change`, `latest`, `first`

**`entity_aggregate`** — collapse all entities to one scalar per metric:
- `mean`, `sum`, `min`, `max`, `p95`

Examples:
- "Average error rate across all services over 1h" → `time_aggregate="mean"`, `entity_aggregate="mean"`, `window_minutes=60`
- "Which service has highest p95 latency?" → `entity_aggregate="max"`
- "Total request rate across all pods?" → `entity_aggregate="sum"`

Entity types with metrics: Service, Database, Container, Pod, AIModel, MCPTool, ServiceAccess, AIModelAccess.

---

## Primary decision tree

```
"Is X healthy?" / simple health check
├─ Service name known → get_service_summary(service="X")       ← 1 call, full picture
│    OR get_environment_health(services=["X"])                   ← 1 call, quick status
│
├─ No service name / system sweep → get_environment_health()    ← 1 call
│
├─ System-wide SLO check → get_environment_health()             ← returns at-risk SLOs
│
└─ Incident investigation (known degraded)?
     ├─ Root cause ID known → get_incident_impact(root_cause_id=)
     ├─ Entity + RC name → get_incident_impact(entity_id=, root_cause_name=)
     └─ Want all signals → get_symptoms()
```

---

## Evidence: description vs get_logs

Only call `get_logs` when `description` is generic AND `has_stored_logs=true`.

---

## Owner resolution

- `causely.ai/team` in entity.labels → that is the owner.
- Or use `get_incident_impact` which returns `responsible_context` with team, product, customer, project.
- Label absent → `team_health(team="<partial-name>")`.

---

## Output template

### 🔴 / 🟡 / 🟢 [Service] — [Status]

**Root cause:** [name + entity + portal link]
**Responsible:** [from get_incident_impact responsible_context or causely.ai/team label]
**Evidence:** [from `description` field]
**Blast radius:** [from `impacted_services`]
**Customer impact:** [from `impacted_customers` or `impacted_context`]
**Recommended actions:** [from `remediation` field]
**Links:** [portal links]
