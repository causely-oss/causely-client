# Complete Investigation Reference

## Efficiency-first principle

**`get_service_summary` or `get_environment_health` for health checks.** These are the fastest single-call tools for "is X healthy?" questions. `get_service_summary(service=)` resolves names automatically and returns symptoms, root causes, SLOs, metrics, deps, events, and logs in one call. `get_environment_health(services=["X"])` gives a scoped health status.

**`triage` is for deep investigation, not health checks.** Use triage when health is already known to be degraded and you need a structured narrative with portal links — or when you have a `root_cause_id` or `root_cause_name` to investigate.

**`description` is Causely's pre-synthesised evidence.** When `get_root_causes` or `triage` returns a `description` field with specific log patterns, error messages, or metrics, that is the evidence. Do not call `get_logs` to regenerate it.

---

## Complete tool inventory (25 tools)

### Discovery & name resolution
| Tool | Use when | Key params |
|---|---|---|
| `name_lookup` | **Call first when a user mentions a name.** Resolves entity/cluster/namespace/root-cause/symptom names to typed objects with IDs. | `name_mention` (required), `name_mention_type`, `cluster_names`, `namespace_names`, `entity_types` |
| `get_entities` | List entities by type/cluster/namespace, or look up by exact ID. | `entity_id`, `entity_types`, `cluster_names`, `namespace_names` |
| `get_label_values` | Enumerate teams, products, environments, clusters, namespaces. | `label_key` (e.g. `causely.ai/team`), `query` (substring filter) |
| `get_integration_status` | Check scraper/integration coverage per cluster. | `cluster_names` (optional) |

### Health & triage
| Tool | Use when | Key params |
|---|---|---|
| `get_service_summary` | **Primary tool for single-service health by name.** Full picture: symptoms, root causes, SLOs, metrics, deps, slow queries, events, error logs. Resolves names automatically. | `service` (substring match), `lookback_hours` |
| `get_environment_health` | Global or scoped health overview. Use `services=["X"]` for quick single-service check. | `namespaces`, `clusters`, `services`, `products`, `active_only`, `lookback_hours` |
| `triage` | Deep investigation into a specific entity or root cause. **Not for simple health checks.** Use when you need a structured narrative with portal links, or when you have a root_cause_id/root_cause_name. | `entity_name`, `root_cause_id`, `root_cause_name`, `start_time/end_time` |
| `get_entity_health` | Health for non-Service entities (pods, DBs, queues). Requires entity_id from `name_lookup`. | `entity_id`, `lookback_hours` |
| `team_health` | All services owned by a team. | `team` (partial match) |
| `ask_causely` | Free-form NL query, cross-entity synthesis. | `question` |

### Diagnosis
| Tool | Use when | Key params |
|---|---|---|
| `get_root_causes` | All active root causes (structured JSON with impact graphs). Call `name_lookup` first if a name is mentioned. | `active_only`, `related_entity_ids`, `cluster_names`, `namespace_names`, `product_names`, `customer_names`, `symptom_ids`, `root_cause_name` |
| `get_symptoms` | **Best first step in any incident** — call with no `entity_ids` to see all active symptoms across every entity in one call. | `entity_ids` (optional), `active_only`, `lookback_hours` |
| `get_alerts` | Alert history, mapped/unmapped status. Supports name search via `alert_name_expr`. Use `alert_state_filters` (e.g. `["firing","resolved"]`) to override `active_only`. | `alert_name_expr`, `entity_ids`, `mapping_state_filters`, `alert_state_filters`, `start_time/end_time` |
| `investigate_alert` | One-step alert investigation. Takes a raw alert object from `get_alerts` and returns `get_entity_health` alongside it. | `alert` (full alert object from get_alerts), `lookback_hours` |
| `get_logs` | Live entity logs OR stored evidence logs. | `entity_id` XOR `root_cause_id`, `severity_filter`, `message_contains` |
| `get_events` | Lifecycle events (deploys, restarts, scaling). | `entity_id`, `severity_filter`, `message_contains` |
| `get_slow_queries` | DB slow query analysis. | `entity_ids` |

### Observability data
| Tool | Use when | Key params |
|---|---|---|
| `get_metrics` | Numeric snapshots or time-series. | `entity_ids`, `metrics`, `window_minutes` (omit for snapshot) |
| `get_slo` | SLO state, error budget, burn rate. | `entity_ids`, `only_at_risk`, `only_violated` |
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

**When a user mentions a name, call `name_lookup` first.** It resolves names to typed objects with IDs:

```
name_lookup(name_mention="checkout")
  → Entity → pass id to get_metrics, get_slo, get_topology, get_alerts, get_events, get_config
  → Entity → pass id to get_root_causes(related_entity_ids=[id])
  → Cluster → pass name to get_root_causes(cluster_names=[name])
  → Namespace → pass name to get_root_causes(namespace_names=[name])
```

**`get_entities` lists and filters entities** by type, cluster, namespace, or exact ID:
```
get_entities(entity_types=["Service"], namespace_names=["otel-demo"])
```

---

## Primary decision tree

```
"Is X healthy?" / simple health check
├─ Service name known → get_service_summary(service="X")      ← 1 call, full picture
│    OR get_environment_health(services=["X"])                  ← 1 call, quick status
│
├─ No service name / system sweep → get_environment_health()   ← 1 call
│
└─ Need deep investigation (known degraded)?
     ├─ Entity name → triage(entity_name="X")                  ← narrative + portal links
     ├─ Root cause ID → triage(root_cause_id="abc")            ← root cause deep dive
     └─ Want all signals → get_symptoms()                      ← all active symptoms, no IDs needed
```

---

## Tool selection: triage vs get_service_summary vs get_environment_health

| Question | Tool | Why |
|---|---|---|
| "Is X healthy?" | `get_service_summary` or `get_environment_health(services=)` | Fast health check, resolves name automatically |
| "What's wrong with X?" (known degraded) | `triage(entity_name=)` | Deep narrative with portal links |
| "Is the system healthy?" | `get_environment_health()` | Global overview |
| "Full picture of X" | `get_service_summary(service=)` | All-in-one |

---

## Evidence: description vs get_logs

The `description` field on a root cause contains Causely's synthesised evidence. When it contains specific log patterns or error messages, **do not call `get_logs`**.

Only call `get_logs` when description is generic AND `has_stored_logs=true`. Use `limit=10` and `severity_filter=ERROR`.

---

## Owner resolution

- `causely.ai/team` in entity.labels → that is the owner.
- `causely.ai/owner-scraper` is NOT a team name.
- Label absent → `team_health(team="<partial-name>")`.
- No match → "Owner not registered — check service catalog (e.g. Backstage)"

---

## Output template

### 🔴 / 🟡 / 🟢 [Service] — [Status]

**Root cause:** [name + entity + portal link]
**Evidence:** [from `description` field]
**Blast radius:** [from `impacted_services`]
**Customer impact:** [from `impacted_customers`]
**Owner / team:** [from `causely.ai/team` label or `team_health`]
**Recommended actions:** [from `remediation` field]
**Links:** [portal links]
