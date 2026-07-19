---
name: causely-alert-triage
description: >
  Use this skill when the user is starting from an alert — they received a PagerDuty page, Datadog alert, Prometheus/Alertmanager notification, Slack alert, or OpsGenie notification and want to understand what it means. Trigger for questions like "I got paged for KubeContainerWaiting", "what does this alert mean?", "PagerDuty woke me up for high error rate on checkout", "what alerts are firing?", "how many unmapped alerts do we have?", "is this alert noise or real?", or "audit alert noise". Also trigger when the user pastes an alert name or payload.
---

# Causely Alert Triage Skill

Read `references/complete-investigation.md` for the full 30-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names.

---

## Core tools

| Tool | Use when |
|---|---|
| `get_alerts(alert_name_expr=)` | **Search by name — no entity IDs needed.** |
| `investigate_alert(alert=)` | **One-step alert → entity health.** |
| `get_root_causes(symptom_ids=)` | Find cause behind a mapped alert — lightweight summary |
| `get_root_cause_details(root_cause_id=)` | Full evidence: causal_chain + impact_service_graph |
| `get_incident_impact(root_cause_id=)` | Responsibility + business context |
| `get_service_summary(service=)` | Full health check when service name is known |

---

## Decision tree

**Alert received — search by name:**
```
get_alerts(alert_name_expr="<alert-name>", active_only=true)
  → mapped (mapped_entity_symptom):
       → investigate_alert(alert=) for entity health
       → or get_root_causes(symptom_ids=) → get_root_cause_details for evidence
  → mapped_entity_only: entity found, no schema symptom
  → unmapped_*: surface state to user, do not infer entities
```

**Alert received — service name known:** `get_service_summary(service=)`

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

**Alert:** [alert_name from get_alerts or user's description]
**Service:** [entity name]
**Status:** [firing / resolved] · **Severity:** [from alert]
**Causely mapping:** ✅ `mapped_entity_symptom` "[symptom_name]" / ⚠️ `mapped_entity_only` / ❌ unmapped ([reason])
**Root cause:** [from investigate_alert or get_root_causes — name + entity + portal link]
**Evidence:** [from description field; from get_root_cause_details causal_chain for WHY]
**Blast radius:** [from get_root_cause_details impact_service_graph or impacted_services]
**Customer impact:** [from impacted_customers or get_incident_impact impacted_context]
**Responsible:** [from get_incident_impact responsible_context or causely.ai/team label]
**Recommended actions:** [from remediation field]
**Links:** [portal links]
