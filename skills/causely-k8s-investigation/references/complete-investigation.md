# Complete Investigation Reference

## Efficiency-first principle

**`get_service_summary` or `get_environment_health` for health checks.** `get_service_summary(service=)` resolves names automatically and returns symptoms, diagnoses, SLOs, metrics, deps, events, and logs in one call. `get_environment_health` gives overall status and diagnoses but does NOT include SLO state.

**`get_diagnoses` returns lightweight summaries.** It does NOT include symptoms, causal_chain, impact_service_graph, exceptions, or events. Follow up with `get_diagnosis_details(diagnosis_id=)` for full evidence on a specific diagnosis.

**`get_slo` for all SLO questions.** Supports fleet-wide queries without entity_ids using `cluster_names` and `namespace_names` filters.

**`description` is Causely's pre-synthesised evidence.** Do not call `get_logs` to regenerate it.

---

## Complete tool inventory (33 tools)

### Discovery & name resolution
| Tool | Use when | Key params |
|---|---|---|
| `name_lookup` | **Call first when a user mentions a name.** | `name_mention`, `name_mention_type`, `entity_types` |
| `get_entities` | List entities by type/cluster/namespace, or look up by exact ID. | `entity_id`, `entity_types`, `cluster_names`, `namespace_names`, `limit` |
| `count_entities` | **"How many entities per cluster/namespace/type?"** Single SQL GROUP BY — do NOT use get_entities + count client-side (caps at 200). | `group_by` (cluster/namespace/customer/product/type), `entity_types`, scope filters |
| `get_label_values` | Enumerate teams, products, clusters, namespaces. | `label_key`, `query` |
| `get_integration_status` | Check scraper/integration coverage. | `cluster_names` |
| `rank_entities` | **Bulk ranking by dependency/dependent count.** Do NOT loop `get_topology`. | `entity_type`, `mode`, `limit`, scope filters |

### Issues (incident-level grouping)
| Tool | Use when | Key params |
|---|---|---|
| `get_issues` | **Incident-level view.** Groups related diagnoses per entity into a single issue with a primary_diagnosis. Lightweight summary. | `active_only`, `entity_ids`, `cluster_names`, `namespace_names`, `entity_types`, `severities`, `peak_severities`, `issue_names` |
| `get_issue_details` | **Full detail for one issue.** Uncapped diagnosis_count, breakdown by type/name, primary_diagnosis_detail (full evidence), all associated diagnoses. | `issue_id` |

### Health & investigation
| Tool | Use when | Key params |
|---|---|---|
| `get_service_summary` | **Primary single-service health by name.** Resolves names automatically. | `service`, `lookback_hours` |
| `get_environment_health` | Global or scoped health overview. **Does NOT report SLO state.** | `namespaces`, `clusters`, `services`, `products`, `active_only`, `lookback_hours` |
| `get_incident_impact` | Incident investigation — responsibility + business context. **Not for health checks.** | `diagnosis_id`, `diagnosis_name`, `entity_id` |
| `get_entity_health` | Health for any entity by ID. | `entity_id`, `lookback_hours` |
| `team_health` | All services owned by a team. | `team` |

### Diagnosis
| Tool | Use when | Key params |
|---|---|---|
| `get_diagnoses` | All active diagnoses — **lightweight summary only.** Does NOT include causal_chain, symptoms, or impact_service_graph. | `active_only`, `related_entity_ids`, `cluster_names`, `namespace_names`, `symptom_ids`, `diagnosis_id` |
| `get_diagnosis_details` | **Full evidence for a single diagnosis.** Returns symptoms, causal_chain, impact_service_graph, exceptions, events. Follow-up to `get_diagnoses`. | `diagnosis_id` |
| `get_symptoms` | **Best first step in any incident** — no entity_ids needed. | `entity_ids`, `active_only`, `lookback_hours`, `symptom_name` |
| `get_alerts` | Alert history, mapped/unmapped. `alert_name_expr` for name search. | `alert_name_expr`, `mapping_state_filters`, `alert_state_filters` |
| `investigate_alert` | One-step alert → entity health. | `alert`, `lookback_hours` |
| `get_logs` | Live entity logs OR stored evidence logs. | `entity_id` XOR `diagnosis_id` |
| `get_events` | Lifecycle events (restarts, scaling, crash/OOM). **NOT for deployments/config changes** — use `get_symptoms(symptom_name="VersionChanged", entity_types=["ComputeSpec"])` instead. | `entity_id` |
| `get_slow_queries` | DB slow query analysis. | `entity_ids` |

### Causality model / hypothesis exploration
| Tool | Use when | Key params |
|---|---|---|
| `get_potential_diagnoses` | Causality-model-inferred diagnosis hypotheses (active + causality-only). | `entity_id` |
| `get_potential_observable_signals` | All signals on an entity (active + inactive + causality potential). | `entity_id`, `signal_types` |
| `get_signal_potential_diagnoses` | Reverse lookup: which diagnoses explain a signal. | `entity_id`, `signal_name`, `signal_type` |
| `get_diagnosis_observable_signals` | Causality chain: what signals a diagnosis could cause. | `entity_id`, `diagnosis_name` |

### Observability data
| Tool | Use when | Key params |
|---|---|---|
| `get_metrics` | Snapshots, time-series, or aggregated fleet values. | `entity_ids`, `metrics`, `window_minutes`, `time_aggregate`, `entity_aggregate` |
| `get_slo` | **SLO state, error budget, burn rate.** Fleet-wide without entity_ids using `cluster_names`/`namespace_names`. | `entity_ids`, `cluster_names`, `namespace_names`, `only_at_risk`, `only_violated` |
| `get_config` | Raw config files. | `entity_id`, `name_contains` |
| `get_topology` | Dependency/dependent/dataflow graph. **Do NOT loop — use `rank_entities`.** | `entity_id`, `mode`, `levels` |

### Post-deploy & reliability
| Tool | Use when | Key params |
|---|---|---|
| `reliability_delta` | Single-service pre/post deploy comparison. | `service` |
| `fleet_reliability_delta` | Batch regression check. | `team`, `namespace`, `services` |

### Reporting & actions
| Tool | Use when | Key params |
|---|---|---|
| `generate_ticket` | Jira/GitHub/Linear ticket draft. | `task` |
| `postmortem` | Postmortem for a resolved incident. | `diagnosis_id`, `diagnosis_name` + `entity_name`, `service` + `incident_start` |

---

## Name resolution

```
name_lookup(name_mention="checkout")
  → Entity → pass id to get_issues(entity_ids=[id]), get_diagnoses(related_entity_ids=[id])
  → Entity → pass id to get_metrics, get_slo, get_topology, get_alerts, get_events, get_config
  → Entity → pass id to get_incident_impact(entity_id=id)
```

---

## Issues, Diagnoses, and Signals

An **Issue** is the persistent thread that ties every diagnosis of the same underlying problem together — one thing to acknowledge, one thing to share with the team, one thing to resolve.

An Issue causes anomalies, which trigger **Signals**: alerts, log messages, events. At any point during the life of the Issue the system may infer a **Diagnosis** — the best explanation of the observations at that moment. As anomalies appear and clear, as affected services shift, as alerts fire and stop, the Signals change, and the Diagnosis updates to match.

The Issue holds all of it together across all those changes. If two Diagnoses share even one Signal — present now or at any point in the past — they are treated as expressions of the same Issue. The Diagnosis can keep changing shape, but as long as Diagnoses keep sharing a Signal, it's still one Issue.

**The Diagnosis evolves. The Issue doesn't.**

| Concept | Causely term | Tool | Stability |
|---|---|---|---|
| Persistent incident identity | Issue | `get_issues` → `get_issue_details` | Stable — doesn't change |
| Current best explanation | Diagnosis (diagnosis) | `get_diagnoses` → `get_diagnosis_details` | Evolves as signals change |
| Observable anomaly | Signal (symptom/alert/event) | `get_symptoms`, `get_alerts`, `get_events` | Comes and goes |

### When to use which

| Question | Tool | Why |
|---|---|---|
| "What incidents are active?" | `get_issues()` | Stable incident grouping across evolving diagnoses |
| "What's the current diagnosis?" | `get_diagnoses()` | Current best explanation (may change) |
| "Full detail for this incident" | `get_issue_details(issue_id=)` | Uncapped RC count + primary_diagnosis_detail |
| "Full evidence for this diagnosis" | `get_diagnosis_details(diagnosis_id=)` | causal_chain + impact_service_graph |
| "What signals are firing?" | `get_symptoms()` | Current observable anomalies |

## Issue investigation workflow

```
get_issues(active_only=true)                    ← lightweight list: id, name, severity, entity, primary_diagnosis
  → pick the issue you need
get_issue_details(issue_id=)                    ← full detail: diagnosis_count, diagnosis_counts breakdown,
                                                   primary_diagnosis_detail (symptoms, causal_chain, impact_service_graph),
                                                   all associated diagnoses (lightweight)
```

---

## Diagnosis investigation workflow

```
get_diagnoses(active_only=true)           ← lightweight list: id, name, severity, description, remediation
  → pick the diagnosis you need
get_diagnosis_details(diagnosis_id=)      ← full evidence: symptoms, causal_chain, impact_service_graph, exceptions, events
  → causal_chain explains WHY Causely identified this as diagnosis
  → impact_service_graph shows blast radius
```

---

## Causality model exploration workflow

These 4 tools explore Causely's causality model — theoretical hypotheses and signal relationships, not just observed state.

**Forward path: entity → diagnoses → signals**
```
name_lookup(name_mention="<entity>") → entity_id
get_potential_diagnoses(entity_id=)
  → all diagnosis hypotheses for this entity (active + causality-only)
  → pick a diagnosis name
get_diagnosis_observable_signals(entity_id=, diagnosis_name=)
  → causality chain: what symptoms, events, and SLOs this diagnosis could cause
  → compare to get_symptoms() to see which are actually active
```

**Reverse path: signal → diagnoses**
```
get_potential_observable_signals(entity_id=)
  → all signals on this entity (active + inactive + causality potential)
  → pick a signal name
get_signal_potential_diagnoses(entity_id=, signal_name=)
  → which diagnosis hypotheses could explain this signal
```

**"How did Causely detect this?"**
```
get_diagnosis_details(diagnosis_id=)
  → causal_chain: walk edges from leaf symptoms toward root_node_id
  → edge probabilities show causal confidence (degrade downstream, confirming origin)
  → this is the OBSERVED causal graph, not the theoretical model
```

### Causality exploration output format

**Entity:** [name + type]

**Diagnosis hypotheses:**
| Diagnosis | State | Severity | Description |
|---|---|---|---|
| [from get_potential_diagnoses — active or causality-only] |

**Causality chain for [diagnosis]:**
| Signal | Type | Direction | Probability |
|---|---|---|---|
| [from get_diagnosis_observable_signals — chain edges from diagnosis to downstream signals] |

**Reverse lookup for [signal]:**
| Potential diagnosis | Confidence | Description |
|---|---|---|
| [from get_signal_potential_diagnoses — which diagnoses could explain this signal] |

**All observable signals:**
| Signal | Type | State | Description |
|---|---|---|---|
| [from get_potential_observable_signals — active, inactive, or causality potential] |

---

## SLO queries

`get_environment_health` does NOT report SLO state. Use `get_slo`:

| Question | Tool call |
|---|---|
| "Which SLOs are at risk?" | `get_slo(only_at_risk=true)` |
| "Which SLOs are violated?" | `get_slo(only_violated=true)` |
| "SLOs in the robot-shop namespace?" | `get_slo(namespace_names=["robot-shop"])` |
| "SLOs in chaos1 cluster?" | `get_slo(cluster_names=["chaos1"])` |
| "SLO for a specific service?" | `name_lookup` → `get_slo(entity_ids=[id])` |

---

## Owner resolution

- `causely.ai/team` in entity.labels → owner.
- `get_incident_impact` returns `responsible_context`.
- `team_health(team=)` as fallback.

---

## Output template

### 🔴 / 🟡 / 🟢 [Service] — [Status]

**Diagnosis:** [name + entity + portal link from get_diagnoses]
**Evidence:** [from `description` field; from get_diagnosis_details causal_chain for WHY; from get_logs if needed]
**Blast radius:** [from get_diagnosis_details impact_service_graph, or impacted_services on summary]
**Customer impact:** [from `impacted_customers` or get_incident_impact `impacted_context`]
**Responsible:** [from get_incident_impact `responsible_context` or `causely.ai/team` label]
**Recommended actions:** [from `remediation` field]
**Links:** [Causely portal links from response]
