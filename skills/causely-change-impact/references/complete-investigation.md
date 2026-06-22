# Complete Investigation Reference

## Efficiency-first principle

**`get_service_summary` or `get_environment_health` for health checks.** `get_service_summary(service=)` resolves names automatically and returns symptoms, root causes, SLOs, metrics, deps, events, and logs in one call.

**`get_incident_impact` is for incident investigation, not health checks.** Use when health is already degraded and you need responsibility and business context.

**`description` is Causely's pre-synthesised evidence.** Do not call `get_logs` to regenerate it.

---

## Complete tool inventory (28 tools)

### Discovery & name resolution
| Tool | Use when | Key params |
|---|---|---|
| `name_lookup` | **Call first when a user mentions a name.** Resolves to typed objects with IDs. | `name_mention`, `name_mention_type`, `entity_types` |
| `get_label_values` | Enumerate teams, products, clusters, namespaces. | `label_key`, `query` |
| `get_integration_status` | Check scraper/integration coverage per cluster. | `cluster_names` |
| `rank_entities` | **Bulk ranking by dependency/dependent count.** Single SQL query — do NOT loop `get_topology`. | `entity_type`, `mode` (dependencies/dependents), `limit`, scope filters |

### Health & investigation
| Tool | Use when | Key params |
|---|---|---|
| `get_service_summary` | **Primary tool for single-service health by name.** | `service`, `lookback_hours` |
| `get_environment_health` | Global or scoped health overview. Also returns at-risk SLOs. | `namespaces`, `clusters`, `services`, `products`, `active_only`, `lookback_hours` |
| `get_incident_impact` | Deep incident investigation — responsibility + business context. **Not for health checks.** | `root_cause_id`, `root_cause_name`, `entity_id`, `start_time/end_time` |
| `get_entity_health` | Health for any entity by ID. | `entity_id`, `lookback_hours` |
| `team_health` | All services owned by a team. | `team` |

### Diagnosis
| Tool | Use when | Key params |
|---|---|---|
| `get_root_causes` | Active root causes with impact graphs. >10 results truncate detail. | `active_only`, `related_entity_ids`, `cluster_names`, `namespace_names`, `symptom_ids`, `root_cause_id` |
| `get_symptoms` | **Best first step in any incident** — no entity_ids needed for all active symptoms. | `entity_ids`, `active_only`, `lookback_hours`, `symptom_name` |
| `get_alerts` | Alert history, mapped/unmapped status. Supports `alert_name_expr` search. | `alert_name_expr`, `mapping_state_filters`, `alert_state_filters` |
| `investigate_alert` | One-step alert → entity health. | `alert`, `lookback_hours` |
| `get_logs` | Live entity logs OR stored evidence logs. | `entity_id` XOR `root_cause_id` |
| `get_events` | Lifecycle events (deploys, restarts, scaling). | `entity_id` |
| `get_slow_queries` | DB slow query analysis. | `entity_ids` |

### Causality model / hypothesis exploration
| Tool | Use when | Key params |
|---|---|---|
| `get_potential_diagnoses` | Causality-model-inferred diagnosis hypotheses for an entity (active + causality-only). | `entity_id` |
| `get_potential_observable_signals` | All observable signals on an entity (active + inactive + causality potential). | `entity_id`, `signal_types` |
| `get_signal_potential_diagnoses` | Reverse lookup: which diagnoses could explain a specific signal. | `entity_id`, `signal_name`, `signal_type` |
| `get_diagnosis_observable_signals` | Causality chain: what signals a diagnosis could cause. | `entity_id`, `diagnosis_name` |

### Observability data
| Tool | Use when | Key params |
|---|---|---|
| `get_metrics` | Numeric snapshots, time-series, or aggregated fleet-level values. | `entity_ids`, `metrics`, `window_minutes`, `time_aggregate`, `entity_aggregate` |
| `get_slo` | SLO state, error budget, burn rate. For system-wide, use `get_environment_health`. | `entity_ids`, `only_at_risk`, `only_violated` |
| `get_config` | Raw config files for an entity. | `entity_id`, `name_contains` |
| `get_topology` | Dependency/dependent/dataflow graph. **Do NOT loop — use `rank_entities` for rankings.** | `entity_id`, `mode`, `levels` |

### Post-deploy & reliability
| Tool | Use when | Key params |
|---|---|---|
| `reliability_delta` | Single-service pre/post deploy comparison. | `service`, `lookback_hours`, `window_minutes` |
| `fleet_reliability_delta` | Batch regression check across services. | `team`, `namespace`, `services` |

### Reporting & actions
| Tool | Use when | Key params |
|---|---|---|
| `generate_ticket` | Create Jira/GitHub/Linear ticket draft. | `task` |
| `postmortem` | Generate postmortem for a resolved incident. | `root_cause_id`, `root_cause_name` + `entity_name`, `service` + `incident_start` |

---

## Alert mapping states (get_alerts)

| Value | Meaning |
|---|---|
| `mapped_entity_symptom` | Alert mapped to a schema symptom on an entity |
| `mapped_entity_only` | Entity found but no schema symptom matched |
| `unmapped_insufficient_labels` | Alert lacks entity-identifying labels |
| `unmapped_entity_not_found` | Entity-identifying labels present but entity no longer exists |
| `unmapped` | Legacy state for rows written before the distinction was introduced |

---

## Name resolution pattern

```
name_lookup(name_mention="checkout")
  → Entity → pass id to get_metrics, get_slo, get_topology, get_alerts, get_events, get_config
  → Entity → pass id to get_root_causes(related_entity_ids=[id])
  → Entity → pass id to get_incident_impact(entity_id=id)
  → Entity → pass id to get_potential_diagnoses(entity_id=id)
```

---

## Causality model exploration workflow

For "how does Causely detect this?" or hypothesis exploration:
```
name_lookup(name_mention="<entity>") → entity_id
get_potential_diagnoses(entity_id=) → diagnosis hypotheses (active + causality-only)
get_diagnosis_observable_signals(entity_id=, diagnosis_name=) → causality chain
get_potential_observable_signals(entity_id=) → all signals (active + inactive + potential)
get_signal_potential_diagnoses(entity_id=, signal_name=) → which diagnoses explain a signal
```

---

## Primary decision tree

```
"Is X healthy?" → get_service_summary(service="X")
"Is the system healthy?" → get_environment_health()
"What's the impact? Who's responsible?" → get_incident_impact(root_cause_id=)
"Which services have the most dependencies?" → rank_entities(entity_type="Service", mode=dependencies)
"What could explain this symptom?" → get_signal_potential_diagnoses(entity_id=, signal_name=)
"What root causes could this entity have?" → get_potential_diagnoses(entity_id=)
```

---

## Evidence: description vs get_logs

Only call `get_logs` when `description` is generic AND `has_stored_logs=true`.

---

## Owner resolution

- `causely.ai/team` in entity.labels → that is the owner.
- `get_incident_impact` returns `responsible_context` with team, product, customer, project.
- `team_health(team="<partial>")` as fallback.
