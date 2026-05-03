# Complete Investigation Reference

## Efficiency-first principle

**`triage` is a complete answer in one call.** It returns root cause, symptoms, impacted services, impacted customers, remediation, and `has_stored_logs` — everything needed for a full six-dimension response. Do not follow it with separate `get_symptoms` or blast-radius calls; that data is already inside the triage response.

**`description` is Causely's pre-synthesised evidence.** When `get_root_causes` or `triage` returns a `description` field with specific log patterns, error messages, or metrics, that is the evidence. Do not call `get_logs` to regenerate it — Causely already did that work at detection time. Read `description` first.

---

## Complete tool inventory (25 tools)

### Discovery & inventory
| Tool | Use when | Key params |
|---|---|---|
| `get_entities` | Resolve names → entity IDs for any downstream tool | `query`, `entity_types`, `namespace_names`, `cluster_names` |
| `list_clusters` | Discover valid cluster names | `query` (optional filter) |
| `list_namespaces` | Discover valid namespace names | `query` (optional filter) |
| `get_label_values` | Enumerate teams, products, environments | `label_key` (e.g. `causely.ai/team`) |
| `get_integration_status` | Check scraper/integration coverage per cluster | `cluster_names` (optional filter) |

### Health & triage
| Tool | Use when | Key params |
|---|---|---|
| `triage` | Named entity health check — fastest, deterministic | `entity_name`, `root_cause_id`, `root_cause_name`, `start_time/end_time` |
| `get_environment_health` | Global or namespace-scoped health overview | `namespaces`, `services`, `lookback_hours` |
| `get_service_summary` | Comprehensive single-service health (all dimensions) | `service` (substring), `lookback_hours` |
| `get_entity_health` | Health for non-Service entities (pods, DBs, queues) | `entity_id`, `lookback_hours` |
| `team_health` | All services owned by a team | `team` (partial match) |
| `ask_causely` | Free-form NL query, cross-entity synthesis | `question` |

### Diagnosis
| Tool | Use when | Key params |
|---|---|---|
| `get_root_causes` | All active root causes (structured JSON with impact graphs) | `active_only`, `impacted_service_ids`, `symptom_ids`, `root_cause_name` |
| `get_symptoms` | Raw signals / historical timelines | `entity_ids`, `active_only`, `lookback_hours` |
| `get_alerts` | Raw alert history, mapped/unmapped status | `entity_ids`, `alert_name_filters`, `mapping_state_filters` |
| `get_logs` | Live entity logs OR stored evidence logs | `entity_id` XOR `root_cause_id`, `severity_filter` |
| `get_events` | Lifecycle events (deploys, restarts, scaling) | `entity_id`, `severity_filter`, `message_contains` |
| `get_slow_queries` | DB slow query analysis | `entity_ids` |

### Observability data
| Tool | Use when | Key params |
|---|---|---|
| `get_metrics` | Numeric snapshots or time-series | `entity_ids`, `metrics`, `window_minutes` |
| `get_slo` | SLO state, error budget, burn rate | `entity_ids`, `only_at_risk`, `only_violated` |
| `get_config` | Raw config files for an entity | `entity_id`, `name_contains` |
| `get_topology` | Dependency/dependent/dataflow graph | `entity_id`, `mode`, `levels` |

### Post-deploy & reliability
| Tool | Use when | Key params |
|---|---|---|
| `reliability_delta` | Single-service pre/post deploy comparison | `service`, `lookback_hours`, `window_minutes` |
| `fleet_reliability_delta` | Batch regression check across multiple services | `team`, `namespace`, `services`, `window_minutes` |

### Reporting & actions
| Tool | Use when | Key params |
|---|---|---|
| `generate_ticket` | Create Jira/GitHub/Linear ticket draft | `task` |
| `postmortem` | Generate postmortem for a resolved incident | `root_cause_id` (preferred), or `root_cause_name` + `entity_name`, or `service` + `incident_start` |

---

## Primary decision tree

```
Have a service name?
│
├─ triage(entity_name="<service>")          ← 1 call, full picture
│    ├─ Root cause, symptoms, blast radius, customer impact, remediation: all here
│    ├─ description populated with specifics? → use it as evidence, skip get_logs
│    ├─ description generic ("Inspect logs...") AND has_stored_logs=true?
│    │    └─ get_logs(root_cause_id=, limit=10, severity_filter=ERROR)   ← conditional 2nd call
│    └─ causely.ai/team label in entity.labels? → use it, skip team_health
│         └─ label absent? → team_health(team="<partial-name>")          ← conditional 2nd call
│
├─ Need metrics/SLOs/topology? (not in triage)
│    └─ get_entities(query="<service>") → get_metrics / get_slo / get_topology
│
└─ No name / system sweep?
     │
     ├─ get_environment_health()             ← 1 call, overall status
     └─ get_root_causes(active_only=true)    ← 1 call, all active issues with evidence
```

---

## Entity resolution pattern

Many tools require entity IDs. Use `get_entities` to resolve names first:

```
get_entities(query="checkout", entity_types=["Service"])
  → returns [{id: "abc-123", name: "otel-demo/checkoutservice", ...}]
  → pass id to get_metrics, get_slo, get_topology, get_alerts, etc.
```

**Entity name format:**
| Type | Format | Example |
|---|---|---|
| K8s service | `namespace/service-name` | `default/animal-service` |
| ECS task / VM | `cluster/task-name-hash` | `chaos/quarkus-workshop-hero-service-2b62b3ef` |
| Node | AWS/GCP hostname | `ip-192-168-12-32.us-east-2.compute.internal` |

---

## Evidence: description vs get_logs

The `description` field on a root cause contains Causely's synthesised evidence — extracted log patterns, error messages, counts, and context assembled at detection time. Examples:

- "Disk provider not supported... WARN mediation/scraper_manager.go:267 full resync failed {error: disk provider not supported, provider: kubernetes.io/aws-ebs} — Count: 22"
- "org.postgresql.util.PSQLException: The connection attempt failed — Count: 2"

When description contains this level of specificity, **do not call `get_logs`**. The evidence is already there.

Only call `get_logs` when description is generic (e.g. "Inspect the application logs for error messages or stack traces") AND `has_stored_logs=true`. Use `limit=10` and `severity_filter=ERROR`.

---

## The six dimensions — where each comes from

| Dimension | Source | Extra call needed? |
|---|---|---|
| Root cause | `triage.root_cause` or `get_root_causes[].name` | No |
| Evidence | `description` field on root cause | No — only call `get_logs` if description is generic AND `has_stored_logs=true` |
| Blast radius | `impacted_services` and `impact_service_graph` on root cause | No |
| Customer impact | `impacted_customers` on root cause | No |
| Owner / team | `entity.labels["causely.ai/team"]` | Only if label absent: `team_health(team=)` |
| Remediation | `remediation` field on root cause | No |

---

## Owner resolution

Check `entity.labels` in the triage or get_root_causes response first:
- `causely.ai/team` present → that is the owner. No extra call needed.
- `causely.ai/owner-scraper` is NOT a team name — it identifies the discovery mechanism. Never present this as the owner.
- `causely.ai/team` absent → `team_health(team="<partial-name>")`. Try the namespace name or service name prefix.
- `team_health` returns no match → "Owner not registered in Causely — check your service catalog (e.g. Backstage)"

---

## Tool reliability fallbacks

**`triage` returns "No Incident Data Found":** Service is likely healthy. Confirm with `get_root_causes(active_only=true)` to check system-wide, or accept the health verdict.

**`get_root_causes` returns empty list:** No active root causes. Check `get_symptoms(active_only=true)` for undiagnosed signals — but only if the user specifically needs to know about raw alerts.

**`get_logs` returns empty lines:** `has_stored_logs` may have been `false` or logs have expired. Note "No evidence logs available" — do not retry.

**`team_health` returns no match:** Try a shorter partial name. If still no match, report "Not registered — check service catalog".

**`get_entities` returns empty:** Try a broader query or check `list_namespaces` / `list_clusters` to discover valid scope values.

**All tools error:** Tell the engineer which calls you would have made. Direct them to https://portal.causely.app.

---

## Output template

### 🔴 / 🟡 / 🟢 [Service] — [Status]

**Root cause:** [name + entity + portal link from triage/get_root_causes]

**Evidence:**
- [from `description` field — quote specific log patterns or error messages]
- [if get_logs called: add 1–2 key ERROR lines as supplement]
- [if description generic and no logs: "No stored evidence (has_stored_logs=false)"]

**Blast radius:** [from `impacted_services`, or "None identified"]

**Customer impact:** [from `impacted_customers`, or "None identified"]

**Owner / team:** [from `causely.ai/team` label, or `team_health` result, or "Not registered — check service catalog"]

**Recommended actions:** [from `remediation` field]

**Links:** [Causely portal links from response]
