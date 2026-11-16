---
name: causely-admin
description: >
  Use this skill when the user wants to configure, tune, or administer Causely settings. Trigger for questions like "set the error rate threshold for checkout to 1%", "make checkout a critical service", "enable SLO on this endpoint", "hide this service", "snooze this issue for 24 hours", "ignore this issue until next week", "what threshold overrides exist?", "what tier is checkout?", "stop ignoring this issue", "set a minimum latency threshold", "configure thresholds for all services in prod cluster", or "what metrics can I set thresholds on?". Also trigger for "reduce alert noise", "too many false positives", or "this service shouldn't trigger alerts". Also trigger for read-only platform status: "is monitoring configured for prod?", "which clusters have outdated Causely agents?", "did the agent update reach every cluster?", "which scrapers failed?", "where are notifications sent?", "is every cluster covered by a notification config?". Requires Developer or Admin role for write operations.
---

# Causely Administration Skill


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

## Platform status (read-only)

| Tool | Use when |
|---|---|
| `get_integration_status(cluster_names=)` | Monitoring coverage per cluster: configured scrapers, scrapers that failed to initialise, and integrations Causely detected but that are not configured. Prometheus scrapers also report `alert_rules_configured` and `alerts_active` (counts only) |
| `get_notification_configurations(cluster_name=, destination_type=, name_contains=, id=)` | Where notifications are sent (Slack, Teams, OpsGenie, ...), which clusters process them, and the filters that decide what is sent. Omit all inputs to list every configuration |
| `get_agent_versions(cluster_names=, outdated_only=)` | Causely agent versions per cluster: mediator, Beyla, operator presence, and every per-host agent seen in the last 10 minutes |

**"Is monitoring configured for prod?"**
```
get_integration_status(cluster_names=["prod"])
```
Failed internal scrapers are still listed; successful internal ones (names starting Kubernetes or Causely) are filtered out. A missing alert-rule count means the rules sync has not finished, not zero.

**"Which clusters are behind on agent updates?" / CVE rollout:**
```
get_agent_versions(outdated_only=true)
```
`mediator.update_status` is one of NO_OPERATOR, UP_TO_DATE, UPDATING, UPDATE_AVAILABLE. Versions that are missing or not semantic versions are not counted, so when `outdated` is false, check the `current` values before saying a cluster is up to date. Operator and ML versions are not recorded.

**"Where do notifications for prod go?" / "Is every cluster covered?":**
```
get_notification_configurations(cluster_name="prod")        ← also returns global configurations
get_notification_configurations(destination_type="Slack")   ← or Teams, OpsGenie
get_notification_configurations()                           ← full list, to audit coverage
```
To audit coverage, compare each configuration's `clusters` (and `global`) against the cluster list from `count_entities(group_by="cluster")`. To explain why a notification was or was not sent, read the `filters`: they can scope by cluster, namespace, entity type, or diagnosis, and an empty list means everything the clusters process is sent. Destination secrets and the channel are not returned; the configuration name is usually the best hint of the target channel.

---

## Confirmation before writing

Confirm when the agent chose or inferred any part of the action (metric, value, scope, target, duration), or when the action is hard to undo. When the user named the entity, value, and scope themselves and the action is easy to reverse, their request is the authorization: act, then report what changed.

| Action | Confirm? |
|---|---|
| `create_threshold_configuration` with `LABEL` or `GLOBAL` scope | **Always** (fleet-wide effect) |
| `create`/`update` threshold, `INDIVIDUAL` scope | Only if the agent chose the metric or value. On update, show before → after |
| `delete_threshold_configuration` | **Yes** (the override is lost; learned thresholds take over) |
| `set_service_tier` to `hidden` | **Yes** (can hide a real incident from the active view) |
| `set_service_tier` to `sloEnabled` / `sloDisabled` | Only if the agent inferred the tier |
| `clear_service_tier` on a non-Service entity | **Yes** (also removes its SLO) |
| `ignore_issue` | Only if the agent chose the duration or the issue |
| `unignore_issue` | No (restores the safe default) |

A confirmation states: the action, the target (name and ID), the scope, current value → new value, and the impact (for thresholds, that detection and SLO evaluation both change). If your client has an interactive input tool (e.g. `ask_user_input`), offer Apply / Cancel buttons; otherwise ask in plain text.

**No admin writes as a side effect of an investigation.** While investigating, do not snooze an issue, tune a threshold, or change a tier unprompted. Suggest it and wait for the user.

**Headless runs.** With no user present to confirm, perform a write only if the task explicitly spelled it out, and report exactly what was changed.

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

**"Set thresholds for all services in the prod cluster" (confirm first, fleet-wide):**
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

**"Hide this noisy service" (confirm first):**
```
name_lookup("test-service") → entity_id
set_service_tier(entity_id=id, tier="hidden")
```

**"Too many false positives on X" / "stop alerting on X" (agent chooses the value, so propose first):**
```
name_lookup("X") → entity_id
get_service_summary(service="X")                          ← see which signal is noisy and its current level
get_threshold_configurations(target_entity_id=id)         ← existing override? update it, don't duplicate
get_supported_threshold_metrics(entity_type=...)          ← valid metric key
→ propose: metric, proposed value, scope, impact  →  wait for confirmation
create_threshold_configuration(...) or update_threshold_configuration(id=, ...)
```
Prefer `min_thresholds` / `min_latency_threshold_ms` over a hard override when the goal is to stop over-learning.

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
- **Threshold changes affect both signal detection AND SLO evaluation.** State this dual impact in the confirmation.
- **Prefer minimum learned thresholds over full manual overrides** when the user wants to prevent over-learning but keep adaptive behavior.
- **`update_threshold_configuration` cannot change scope or target.** Delete and recreate instead.
- **`clear_service_tier` removes SLOs on non-Service entities.** If the user wants to keep the tier record but disable SLO, use `set_service_tier(tier="sloDisabled")` instead.
- **Use the issue's top-level `id` as `issue_id`.** `get_issues` returns it as `issues[].id`, and it is the only value that works with `ignore_issue`, `unignore_issue`, `get_issue_ignore_status` and `get_issue_details`. `primary_diagnosis.id` is a diagnosis ID; passing it snoozes nothing or the wrong thing.
- **`update_threshold_configuration` leaves omitted fields unchanged.** Pass `{}` to clear `thresholds` or `min_thresholds`. `min_latency_threshold_ms` is shorthand for `min_thresholds.RequestDuration`; if you pass both, `min_thresholds` wins for that key. Replacing `min_thresholds` wholesale drops an existing `RequestDuration` minimum unless you include it.
- **Issue snoozing is time-bounded.** Always calculate an RFC3339 timestamp for the `until` parameter.

---

## Closeout

- Load `submit_feedback` via `tool_search` at the start of an investigation. The tool description has the rest.
