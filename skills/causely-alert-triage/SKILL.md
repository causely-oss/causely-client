---
name: causely-alert-triage
description: >
  Use this skill when the user is starting from an alert — they received a PagerDuty page, Datadog alert, Prometheus/Alertmanager notification, Slack alert, or OpsGenie notification and want to understand what it means. Trigger for questions like "I got paged for KubeContainerWaiting", "what does this alert mean?", "PagerDuty woke me up for high error rate on checkout", "what alerts are firing?", "how many unmapped alerts do we have?", "is this alert noise or real?", or "audit alert noise". Also trigger when the user pastes an alert name or payload.
---

# Causely Alert Triage Skill

Read `references/complete-investigation.md` for the full 28-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs.

---

## Core tools

| Tool | Use when | What it returns |
|---|---|---|
| `get_alerts(alert_name_expr=)` | **Search alerts by name — no entity IDs needed.** | Alert name, symptom mapping, severity, count, timestamps |
| `investigate_alert(alert=)` | **One-step alert → entity health.** | Entity health + alert context |
| `get_root_causes(symptom_ids=)` | Find diagnosed cause behind a mapped alert | Root causes with evidence, remediation |
| `get_incident_impact(root_cause_id=)` | Responsibility + business context | Responsible entity + team/product/customer |
| `get_service_summary(service=)` | Full health check when service name is known | All-in-one |
| `get_symptoms()` | All active symptoms, no IDs needed | Full signal picture |

---

## Decision tree

**Alert received — search by name:**
```
get_alerts(alert_name_expr="<alert-name>", active_only=true)
  → mapped (mapped_entity_symptom): investigate_alert(alert=) or get_root_causes(symptom_ids=)
  → mapped_entity_only: entity found but no schema symptom
  → unmapped_insufficient_labels: alert lacks entity-identifying labels
  → unmapped_entity_not_found: entity no longer exists (pod deleted?)
  → unmapped: legacy state
```

**Alert received — service name known:** `get_service_summary(service=)`

**Alert noise audit:** `get_alerts(mapping_state_filters=["unmapped_insufficient_labels","unmapped_entity_not_found","unmapped"])`

**Multiple alerts:** `get_symptoms()` or `get_root_causes(active_only=true)` to check shared origin

---

## Alert mapping states

| Value | Meaning | Action |
|---|---|---|
| `mapped_entity_symptom` | Mapped to a schema symptom on an entity | Follow `symptom_name` → `get_root_causes(symptom_ids=)` |
| `mapped_entity_only` | Entity found but no schema symptom matched | Check `get_entity_health(entity_id=)` |
| `unmapped_insufficient_labels` | Alert lacks entity-identifying labels | Surface to user — Causely can't determine target |
| `unmapped_entity_not_found` | Entity-identifying labels present but entity gone | Likely pod crashed/deleted |
| `unmapped` | Legacy state | Treat as unmapped |

For unmapped alerts: do not infer entities or call other tools — surface the unmapped state directly.

---

## Output format

### 🔔 Alert triage: [alert name]

**Alert:** [alert_name] · **Service:** [entity name] · **Status:** [firing/resolved]
**Mapping:** ✅ `mapped_entity_symptom` / ⚠️ `mapped_entity_only` / ❌ unmapped ([reason])
**Root cause:** [from investigate_alert or get_root_causes]
**Responsible:** [from get_incident_impact]
**Links:** [portal links]
