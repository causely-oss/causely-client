---
name: causely-alert-triage
description: >
  Use this skill when the user is starting from an alert — they received a PagerDuty page, Datadog alert, Prometheus/Alertmanager notification, Slack alert, or OpsGenie notification and want to understand what it means. Trigger for questions like "I got paged for KubeContainerWaiting", "what does this alert mean?", "PagerDuty woke me up for high error rate on checkout", "what alerts are firing?", "how many unmapped alerts do we have?", "is this alert noise or real?", or "audit alert noise". Also trigger when the user pastes an alert name or payload.
---

# Causely Alert Triage Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for alert-driven triage

| Tool | Use when | What it returns |
|---|---|---|
| `get_alerts(alert_name_expr=)` | **Search alerts by name — no entity IDs needed.** | Alert name, symptom mapping, severity, count, timestamps |
| `investigate_alert(alert=)` | **One-step alert investigation.** Pass raw alert from `get_alerts`, get entity health back. | Entity health + original alert context |
| `get_root_causes(symptom_ids=)` | Find diagnosed cause behind a mapped alert | Root causes with evidence, blast radius, remediation |
| `get_incident_impact(root_cause_id=)` | Responsibility + business context for a root cause | Responsible entity + team/product/customer |
| `get_service_summary(service=)` | Full health check when service name is known | All-in-one |
| `get_symptoms()` | All active symptoms, no IDs needed | Full signal picture |

---

## Decision tree

**Alert received — search by alert name (recommended):**
```
get_alerts(alert_name_expr="<alert-name>", active_only=true)   ← 1 call
  → if mapped (mapping_state="mapped_entity_symptom"):
       → investigate_alert(alert=<alert_object>)                ← 1 call, entity health + alert
       → or get_root_causes(symptom_ids=[...]) for diagnosis
       → get_incident_impact(root_cause_id=) for responsibility
  → if unmapped: surface unmapped state to user
```

**Alert received — service name known:**
```
get_service_summary(service="<service>")                       ← 1 call
```

**Alert noise audit:**
```
get_alerts(active_only=true, mapping_state_filters=["unmapped"])  ← 1 call
```

**Multiple alerts firing at once:**
```
get_symptoms()                                              ← 1 call, all signals
  → or get_root_causes(active_only=true) to check shared origin
```

---

## Mapping states

- `"mapped_entity_symptom"` — Causely has mapped to a named symptom
- `"unmapped"` — not incorporated; for unmapped alerts, do not infer entities or call other tools

**`alert_state_filters`** (e.g. `["firing","resolved"]`) overrides `active_only`.

---

## Output format

### 🔔 Alert triage: [alert name]

**Alert:** [alert_name] · **Service:** [entity name] · **Status:** [firing/resolved]
**Causely mapping:** ✅ Mapped to "[symptom_name]" / ❌ Unmapped
**Root cause:** [from investigate_alert or get_root_causes]
**Responsible:** [from get_incident_impact responsible_context]
**Blast radius:** [from impacted_services]
**Recommended actions:** [from remediation]
**Links:** [portal links]
