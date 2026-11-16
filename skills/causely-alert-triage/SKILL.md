---
name: causely-alert-triage
description: >
  Use this skill when the user is starting from an alert — they received a PagerDuty page, Datadog alert, Prometheus/Alertmanager notification, Slack alert, or OpsGenie notification and want to understand what it means. Trigger for questions like "I got paged for KubeContainerWaiting", "what does this alert mean?", "PagerDuty woke me up for high error rate on checkout", "what alerts are firing?", "how many unmapped alerts do we have?", "is this alert noise or real?", or "audit alert noise". Also trigger when the user pastes an alert name or payload.
---

# Causely Alert Triage Skill


Use `name_lookup(name_mention=)` to resolve names.

---

## Core tools

| Tool | Use when |
|---|---|
| `get_alerts(alert_name_expr=)` | **Search by name — no entity IDs needed.** Alerts carry `issues[]` with linked issues. |
| `investigate_alert(alert=)` | **One-step alert → full issue details + entity health.** Returns entity_causal_chain, impact_service_graph, diagnosis breakdown. Do NOT call get_issues/get_issue_details/get_diagnosis_details after. |
| `get_service_summary(service=)` | Full health check when service name is known (alternative entry point) |
| `get_integration_status(cluster_names=)` | Alert rule counts per Prometheus scraper (`alert_rules_configured`, `alerts_active`) |

---

## Decision tree

**Alert received — search by name (2 calls, done):**
```
get_alerts(alert_name_expr="<alert-name>", active_only=true)
  → alert now carries issues[] with linked issues
  → investigate_alert(alert=<alert_object>)
       → returns full issue details (entity_causal_chain + impact_service_graph) + entity health
       → DO NOT call get_issues/get_issue_details again for issues already returned
  → issues empty but alert.issues not: the linked issues are inactive (incident cleared);
    call get_issue_details(issue_id=) on each alert.issues[].id for the causal explanation
  → issues empty and alert.issues empty: no diagnosis explains this alert yet
  → issue_errors: linked issues whose detail failed to load; retry with get_issue_details
  → health_error set: the health snapshot failed to load; the issues are still valid
  → evidence logs are omitted; if has_stored_logs, fetch with get_logs(diagnosis_id=)
  → unmapped alerts: surface unmapped state, do not infer entities
```

**Alert received — service name known:** `get_service_summary(service=)`

**"No alerts are firing. Is that real?"** `get_alerts` only returns alerts that have fired. Check `get_integration_status` to tell a cluster with quiet rules (`alert_rules_configured` > 0, `alerts_active` 0) from one with no rules (0). A missing count means the rules sync has not completed, not zero.

**Alert noise audit:** `get_alerts(mapping_state_filters=["unmapped_insufficient_labels","unmapped_entity_not_found","unmapped"])`

---

## Alert mapping states

| Value | Meaning |
|---|---|
| `mapped_entity_symptom` | Mapped to a schema symptom |
| `mapped_entity_only` | Entity found, no schema symptom matched |
| `unmapped_insufficient_labels` | Alert lacks entity-identifying labels |
| `unmapped_entity_not_found` | Entity no longer exists (pod deleted?) |
| `unmapped` | Legacy state |

---

## Output format

### 🔔 Alert triage: [alert name]

**Alert:** [alert_name] · **Status:** [firing / resolved] · **Severity:** [from alert]
**Causely mapping:** ✅ `mapped_entity_symptom` "[symptom_name]" / ⚠️ `mapped_entity_only` / ❌ unmapped ([reason])
**Issue:** [from investigate_alert — issue name, severity, diagnosis_count, since started_at]
**Primary diagnosis:** [from primary_diagnosis_detail — name + entity]
**Evidence:** [from primary_diagnosis_detail description; from entity_causal_chain for WHY Causely diagnosed this]
**Blast radius:** [from impact_service_graph — affected services count + names]
**Responsible:** [from responsible_context or causely.ai/team label]
**Recommended actions:** [from remediation field]
**Links:** [portal links]

---

## Closeout

- Load `submit_feedback` via `tool_search` at the start of an investigation. The tool description has the rest.
