# Complete Investigation Reference

## Efficiency-first principle

**`get_service_summary` or `get_environment_health` for health checks.** `get_service_summary(service=)` resolves names automatically and returns symptoms, diagnoses, SLOs, metrics, deps, events, and logs in one call. `get_environment_health` gives overall status and diagnoses but does NOT include SLO state.

**`get_diagnoses` returns lightweight summaries.** It does NOT include symptoms, entity_causal_chain, impact_service_graph, exceptions, or events. Follow up with `get_diagnosis_details(diagnosis_id=)` for full evidence on a specific diagnosis.

**`get_slo` for all SLO questions.** Supports fleet-wide queries without entity_ids using `cluster_names` and `namespace_names` filters.

**`description` is Causely's pre-synthesised evidence.** Do not call `get_logs` to regenerate it.

---

## Complete tool inventory (50 tools)

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
| `get_service_summary` | **Primary single-service health by name.** Resolves names automatically. Use `cluster_name`/`namespace_name`/`service_type` to disambiguate. Pass `entity_id` to skip name resolution. | `service`, `cluster_name`, `namespace_name`, `entity_id`, `service_type`, `lookback_hours` |
| `get_business_transaction_summary` | **Primary tool for business transaction / user journey health by name.** Aggregates across all routes (Paths). | `business_transaction`, `lookback_hours` |
| `get_environment_health` | Global or scoped health overview. **Does NOT report SLO state.** | `namespaces`, `clusters`, `services`, `products`, `active_only`, `lookback_hours` |
| `get_incident_impact` | Incident investigation — responsibility + business context. **Not for health checks.** | `diagnosis_id`, `diagnosis_name`, `entity_id` |
| `get_entity_health` | Health for any entity by ID. | `entity_id`, `lookback_hours` |
| `team_health` | All services owned by a team. | `team` |

### Diagnosis
| Tool | Use when | Key params |
|---|---|---|
| `get_diagnoses` | All active diagnoses — **lightweight summary only.** Does NOT include entity_causal_chain, symptoms, or impact_service_graph. | `active_only`, `related_entity_ids`, `cluster_names`, `namespace_names`, `symptom_ids`, `diagnosis_id` |
| `get_diagnosis_details` | **Full evidence for a single diagnosis.** Returns symptoms, entity_causal_chain, impact_service_graph, exceptions, events. Follow-up to `get_diagnoses`. | `diagnosis_id` |
| `get_symptoms` | **Best first step in any incident** — no entity_ids needed. | `entity_ids`, `active_only`, `lookback_hours`, `symptom_name` |
| `get_alerts` | Alert history, mapped/unmapped. `alert_name_expr` for name search. | `alert_name_expr`, `mapping_state_filters`, `alert_state_filters` |
| `investigate_alert` | **One-step alert investigation.** Returns full issue details (entity_causal_chain + impact_service_graph) + entity health. Do NOT call get_issues/get_issue_details after. | `alert`, `lookback_hours` |
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
| `get_slo` | **SLO state, error budget, burn rate.** Fleet-wide without entity_ids using `cluster_names`/`namespace_names`. | `entity_ids`, `cluster_names`, `namespace_names`, `only_at_risk`, `only_violated`, `include_operations` |
| `get_config` | Raw config files. | `entity_id`, `name_contains` |
| `get_topology` | Dependency/dependent/dataflow graph. **Do NOT loop — use `rank_entities`.** | `entity_id`, `mode`, `levels` |

### Post-deploy & reliability
| Tool | Use when | Key params |
|---|---|---|
| `reliability_delta` | Single-service pre/post deploy comparison. Use `cluster_name`/`namespace_name` to disambiguate. | `service`, `cluster_name`, `namespace_name`, `entity_id`, `service_type`, `window_minutes` |
| `fleet_reliability_delta` | Batch regression check. Scope by `team`, `namespace`, `cluster`, or explicit `services` list. | `team`, `namespace`, `cluster`, `services`, `service_type`, `window_minutes` |

### Reporting & actions
| Tool | Use when | Key params |
|---|---|---|
| `generate_ticket` | Jira/GitHub/Linear ticket draft. | `task` |
| `postmortem` | Postmortem for a resolved incident. | `diagnosis_id`, `diagnosis_name` + `entity_name`, `service` + `incident_start` |
| `submit_feedback` | After investigation-terminal tools or when user volunteers feedback. Agent can self-rate (`source: "agent"`) or pass user feedback (`source: "user"`). | `rating`, `source`, `message`, `tools_used` |

### Administration & configuration
| Tool | Use when | Key params |
|---|---|---|
| `get_supported_threshold_metrics` | List valid metric keys before creating thresholds. | `entity_type` |
| `get_threshold_configurations` | List/get existing threshold overrides. | `id`, `scope`, `target_entity_id` |
| `create_threshold_configuration` | Create manual threshold override (affects signal detection AND SLO). | `scope` (INDIVIDUAL/LABEL/GLOBAL), `target_entity_id`, `label_selector`, `thresholds`, `min_thresholds` |
| `update_threshold_configuration` | Update existing override values (cannot change scope/target). | `id`, `thresholds`, `min_thresholds` |
| `delete_threshold_configuration` | Delete override — revert to default/learned. | `id` |
| `get_service_tier` | Check entity's priority tier. | `entity_id` |
| `set_service_tier` | Set priority tier (sloEnabled/sloDisabled/hidden/unassigned). Requires Developer/Admin. | `entity_id`, `tier` |
| `clear_service_tier` | Remove tier config entirely. For non-Service entities, also removes SLO. | `entity_id` |
| `get_issue_ignore_status` | Check if issue is snoozed. | `issue_id` |
| `ignore_issue` | Snooze issue until a time — severity suppressed. | `issue_id`, `until` (RFC3339) |
| `unignore_issue` | Restore normal severity immediately. | `issue_id` |

### Environment snapshots
| Tool | Use when | Key params |
|---|---|---|
| `create_snapshot` | Capture environment state (topology, diagnoses, metrics). Async — poll for COMPLETE. | `name`, `description`, `start_time`, `end_time`, `duration_minutes`, `tags` |
| `get_snapshots` | List/search/poll snapshots. | `id`, `name_search`, `description_search`, `tags`, `start_time`, `end_time` |
| `compare_snapshots` | Compare baseline vs after. Returns ACCEPTED/REJECTED. Only COMPLETE snapshots. | `snapshot_ids` (baseline first), `max_items` |
| `delete_snapshot` | Permanently delete a snapshot. Requires Developer/Admin. | `id` |

---

## Name resolution

```
name_lookup(name_mention="checkout")
  → Entity → pass id to get_issues(related_entity_ids=[id]), get_diagnoses(related_entity_ids=[id])
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
| "Full evidence for this diagnosis" | `get_diagnosis_details(diagnosis_id=)` | entity_causal_chain + impact_service_graph |
| "What signals are firing?" | `get_symptoms()` | Current observable anomalies |

## Issue investigation workflow

```
get_issues(active_only=true)                    ← lightweight list: id, name, severity, entity, primary_diagnosis
  → pick the issue you need
get_issue_details(issue_id=)                    ← full detail: diagnosis_count, diagnosis_counts breakdown,
                                                   primary_diagnosis_detail (symptoms, entity_causal_chain, impact_service_graph),
                                                   all associated diagnoses (lightweight)
```

---

## Diagnosis investigation workflow

```
get_diagnoses(active_only=true)           ← lightweight list: id, name, severity, description, remediation
  → pick the diagnosis you need
get_diagnosis_details(diagnosis_id=)      ← full evidence: symptoms, entity_causal_chain, impact_service_graph, exceptions, events
  → entity_causal_chain explains WHY Causely identified this as diagnosis
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
  → entity_causal_chain: walk edges from leaf symptoms toward root_entity_id
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
**Evidence:** [from `description` field; from get_diagnosis_details entity_causal_chain for WHY; from get_logs if needed]
**Blast radius:** [from get_diagnosis_details impact_service_graph, or impacted_services on summary]
**Customer impact:** [from `impacted_customers` or get_incident_impact `impacted_context`]
**Responsible:** [from get_incident_impact `responsible_context` or `causely.ai/team` label]
**Recommended actions:** [from `remediation` field]
**Links:** [Causely portal links from response]

---

## Closeout feedback

**Tool loading:** At the start of any multi-tool Causely investigation, call `tool_search("Causely submit_feedback")` to ensure `submit_feedback` is loaded. Do this alongside your first investigation tool call — do not wait until the end.

`submit_feedback` has two modes — **agent self-rating** and **user feedback**:

### Mode 1: Agent self-rating (headless or interactive)

After calling an investigation-terminal tool (`get_issue_details`, `get_diagnosis_details`, `investigate_alert`, `get_incident_impact`), you can call `submit_feedback` yourself without asking the user:
- `source: "agent"`
- `rating: "positive"` if the Causely result was useful/correct, `"negative"` if wrong/missing/unhelpful
- `message`: what the result showed (e.g. "identified exec format error as root cause of mysql crash loop")
- `tools_used`: Causely tools called this turn (exclude `submit_feedback`)

No user needs to be present. Use this in headless/CI runs and when the investigation is straightforward.

### Mode 2: User feedback (interactive)

After a multi-tool investigation with a user present:
1. **Ask for feedback.** If your client has an interactive input tool (e.g. `ask_user_input`), use it for clickable buttons:
   ```
   ask_user_input(questions=[{"question": "Was this investigation helpful?", "options": ["Yes", "No"], "type": "single_select"}])
   ```
   If no interactive input tool is available, ask in plain text: "Was this investigation helpful? (yes/no)"
2. When the user responds, **immediately call** `submit_feedback`:
   - `source: "user"`
   - `rating`: from the yes/no ONLY — do NOT re-interpret based on message words
   - `message`: user's words verbatim
3. **"Yes, X was a problem" = positive.** The user is saying Causely correctly identified the problem. Words like "problem", "issue", "error" describe what Causely found, not dissatisfaction.
4. Also call when the user volunteers feedback unprompted ("that was helpful", "this is wrong") — map to positive/negative, `source: "user"`.

### Common rules (both modes)

- **Do not** call on single-tool fast paths (`get_service_summary`, `get_slo`, `name_lookup`, etc.).
- `tools_used`: list every Causely tool called this turn (exclude `submit_feedback`).
- Do not treat feedback as a separate user request requiring confirmation.
