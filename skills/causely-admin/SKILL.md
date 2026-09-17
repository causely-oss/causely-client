---
name: causely-admin
description: >
  Use this skill when the user wants to configure, tune, or administer Causely settings. Trigger for questions like "set the error rate threshold for checkout to 1%", "make checkout a critical service", "enable SLO on this endpoint", "hide this service", "snooze this issue for 24 hours", "ignore this issue until next week", "what threshold overrides exist?", "what tier is checkout?", "stop ignoring this issue", "set a minimum latency threshold", "configure thresholds for all services in prod cluster", or "what metrics can I set thresholds on?". Also trigger for "reduce alert noise", "too many false positives", or "this service shouldn't trigger alerts". Requires Developer or Admin role for write operations.
---

# Causely Administration Skill

Read `references/complete-investigation.md` for the full tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to entity IDs before calling admin tools.

---

## Admin tools (11)

### Threshold configuration
| Tool | Use when | Key params |
|---|---|---|
| `get_supported_threshold_metrics` | **Call first** before creating thresholds — lists valid metric keys for an entity type. | `entity_type` (optional) |
| `get_threshold_configurations` | List existing threshold overrides. Filter by `id`, `scope`, or `target_entity_id`. | `id`, `scope`, `target_entity_id` |
| `create_threshold_configuration` | Create a manual threshold override. Affects both signal detection AND SLO evaluation. | `scope` (INDIVIDUAL/LABEL/GLOBAL), `target_entity_id`, `label_selector`, `thresholds`, `min_thresholds`, `min_latency_threshold_ms` |
| `update_threshold_configuration` | Update existing override values. Cannot change scope or target — delete and recreate instead. | `id`, `thresholds`, `min_thresholds`, `min_latency_threshold_ms` |
| `delete_threshold_configuration` | Delete override — reverts to default or learned thresholds. | `id` |

### Service tiers
| Tool | Use when | Key params |
|---|---|---|
| `get_service_tier` | Check an entity's current priority tier. | `entity_id` |
| `set_service_tier` | Set priority tier — affects SLO tracking and diagnosis visibility. | `entity_id`, `tier` (sloEnabled/sloDisabled/hidden/unassigned) |
| `clear_service_tier` | Remove tier config entirely — reverts to no explicit tier. For non-Service entities with sloEnabled, this also removes the SLO. | `entity_id` |

### Issue management
| Tool | Use when | Key params |
|---|---|---|
| `get_issue_ignore_status` | Check if an issue is currently snoozed. | `issue_id` |
| `ignore_issue` | Snooze an issue until a time — severity suppressed, issue not deleted. | `issue_id`, `until` (RFC3339) |
| `unignore_issue` | Restore normal severity immediately. | `issue_id` |

---

## Key concepts

### Threshold sources
A threshold has one active source at a time:
- **Default** — system-provided, broadly applicable
- **Learned** — auto-adapted from historical behavior (only some metrics)
- **Manual** — user override, pauses learning until removed

Setting a manual threshold via `create_threshold_configuration` pauses learning. Deleting it reverts to default/learned.

### Minimum learned thresholds
For metrics that support learning, you can set a minimum (floor) without disabling learning entirely. Use `min_thresholds` or `min_latency_threshold_ms` instead of `thresholds`. Pass `min_latency_threshold_ms=0` to explicitly disable the learned minimum.

### Threshold scopes
- **INDIVIDUAL** — one entity, set `target_entity_id`
- **LABEL** — all entities matching `label_selector` (e.g. `{"causely.ai/cluster": "prod"}`)
- **GLOBAL** — every entity of the relevant type, leave target and selector unset

### Service tiers
| Tier | SLO | Diagnosis visibility | Use case |
|---|---|---|---|
| `sloEnabled` | Active (creates SLO for non-Service entities) | Active view, Urgent if SLO violated | Core APIs, payments, auth |
| `sloDisabled` | Off | Active view, never Urgent | Internal dashboards, staging |
| `hidden` | Off | Hidden tab only | Background jobs, test services |
| `unassigned` | Default behavior | Default behavior | Clear any previous decision |

### Issue snoozing
Ignoring an issue suppresses its severity until the expiry time. The issue is NOT deleted — it remains trackable. Calling `ignore_issue` again replaces the previous expiry.

---

## Decision tree

**"Set error rate threshold for checkout to 1%":**
```
name_lookup("checkout") → entity_id
get_supported_threshold_metrics(entity_type="Service") → find "RequestErrorRate" key
create_threshold_configuration(scope="INDIVIDUAL", target_entity_id=id, thresholds={"RequestErrorRate": 0.01})
```

**"Set a minimum latency threshold to prevent over-learning":**
```
name_lookup("checkout") → entity_id
create_threshold_configuration(scope="INDIVIDUAL", target_entity_id=id, min_latency_threshold_ms=200)
```

**"Set thresholds for all services in the prod cluster":**
```
create_threshold_configuration(scope="LABEL", label_selector={"causely.ai/cluster": "prod"}, thresholds={"RequestErrorRate": 0.02})
```

**"Make checkout a critical service with SLO":**
```
name_lookup("checkout") → entity_id
set_service_tier(entity_id=id, tier="sloEnabled")
```

**"Enable SLO on this HTTP endpoint":**
```
name_lookup("/api/checkout") → entity_id (HTTPPath type)
set_service_tier(entity_id=id, tier="sloEnabled")
```

**"Hide this noisy service":**
```
name_lookup("test-service") → entity_id
set_service_tier(entity_id=id, tier="hidden")
```

**"Snooze this issue for 24 hours":**
```
ignore_issue(issue_id=<id>, until="<now + 24h in RFC3339>")
```

**"Stop ignoring this issue":**
```
unignore_issue(issue_id=<id>)
```

**"What threshold overrides exist?":**
```
get_threshold_configurations()
```

**"What tier is checkout?":**
```
name_lookup("checkout") → entity_id
get_service_tier(entity_id=id)
```

---

## Important behaviours

- **All write operations require Developer or Admin role.** Read operations (get_service_tier, get_threshold_configurations, get_issue_ignore_status, get_supported_threshold_metrics) are available to all roles.
- **Always call `get_supported_threshold_metrics` before creating thresholds.** Metric keys vary by entity type — using an invalid key silently fails.
- **Threshold changes affect both signal detection AND SLO evaluation.** Warn the user when creating thresholds that this has dual impact.
- **Prefer minimum learned thresholds over full manual overrides** when the user wants to prevent over-learning but keep adaptive behavior.
- **`update_threshold_configuration` cannot change scope or target.** Delete and recreate instead.
- **`clear_service_tier` removes SLOs on non-Service entities.** If the user wants to keep the tier record but disable SLO, use `set_service_tier(tier="sloDisabled")` instead.
- **Issue snoozing is time-bounded.** Always calculate an RFC3339 timestamp for the `until` parameter.

---

## Closeout

- **Closeout feedback is mandatory after multi-tool investigations.** First: `tool_search("Causely Staging submit_feedback")` to load the tool. Then end with "Was this investigation helpful? 👍 / 👎" — when the user responds, immediately call `submit_feedback`. Rating from yes/no ONLY. Skip on single-tool fast paths.
