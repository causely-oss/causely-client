---
name: causely-alert-triage
description: >
  Use this skill when the user is starting from an alert — they received a PagerDuty page, Datadog alert, Prometheus/Alertmanager notification, Slack alert, or OpsGenie notification and want to understand what it means. Trigger for questions like "I got paged for KubeContainerWaiting", "what does this alert mean?", "PagerDuty woke me up for high error rate on checkout", "Datadog says memory is high on X", "what alerts are firing?", "what alerts are firing on X?", "how many unmapped alerts do we have?", "is this alert noise or real?", "which alerts map to Causely symptoms?", or "audit alert noise". Also trigger when the user pastes an alert name, alert payload, or references an external alerting system.
---

# Causely Alert Triage Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs before calling tools that require entity IDs.

---

## Core tools for alert-driven triage

| Tool | Use when | What it returns |
|---|---|---|
| `get_alerts(alert_name_expr=)` | **Search alerts by name — no entity IDs needed.** Substring search across alert name, entity name, and cluster. | Alert name, symptom mapping, severity, count, timestamps |
| `investigate_alert(alert=)` | **One-step alert investigation.** Pass a raw alert object from `get_alerts`, get `get_entity_health` result back alongside the alert. | Entity health summary + original alert context |
| `get_alerts(entity_ids=)` | Scope alerts to a specific entity | All alerts firing on that entity |
| `get_root_causes(symptom_ids=)` | Find diagnosed cause behind a mapped alert | Root causes with evidence, blast radius, remediation |
| `get_service_summary(service=)` | Full health check when service name is known | All-in-one: symptoms + RCs + SLOs + metrics + deps + events + logs |
| `get_symptoms()` | All active symptoms, no IDs needed | Full signal picture including crash/OOM/pod failures |

---

## Core rule: get_alerts + investigate_alert

**`get_alerts` supports `alert_name_expr`** — case-insensitive substring search across alert names, entity names, and clusters. Entity IDs are optional.

**`investigate_alert` is the one-step follow-up.** Pass a raw alert object from `get_alerts` and get entity health back — no need to separately resolve entity IDs and call `get_entity_health`.

**`alert_state_filters`** (e.g. `["firing","resolved"]`) overrides `active_only` when set.

**Mapping states:** `"mapped_entity_symptom"` (Causely has mapped to a symptom) and `"unmapped"` (not incorporated).

**For unmapped alerts:** do not try to infer an entity or call other tools — surface the unmapped state directly to the user.

---

## Decision tree

**Alert received — search by alert name (recommended):**
```
get_alerts(alert_name_expr="<alert-name>", active_only=true)   ← 1 call
  → if mapped (mapping_state="mapped_entity_symptom"):
       → investigate_alert(alert=<alert_object>)                ← 1 call, entity health + alert
       → or get_root_causes(symptom_ids=[...]) for diagnosis
  → if unmapped: surface unmapped state to user
```

**Alert received — service name known:**
```
get_service_summary(service="<service>")                       ← 1 call
  → full picture — likely shows what triggered the alert
```

**Alert noise audit:**
```
get_alerts(active_only=true, mapping_state_filters=["unmapped"])  ← 1 call
  → high-count unmapped alerts = noise candidates
```

**Time-scoped alert review:**
```
get_alerts(start_time="...", end_time="...", alert_state_filters=["firing","resolved"])  ← 1 call
```

**Multiple alerts firing at once:**
```
get_symptoms()                                              ← 1 call, all signals
  → or get_root_causes(active_only=true) to check shared origin
```

---

## Output format

### 🔔 Alert triage: [alert name]

**Alert:** [alert_name] · **Service:** [entity name] · **Status:** [firing/resolved] · **Severity:** [from alert]
**Causely mapping:** ✅ Mapped to "[symptom_name]" / ❌ Unmapped
**Root cause:** [from investigate_alert or get_root_causes — name + portal link]
**Evidence:** [from description field]
**Blast radius:** [from impacted_services]
**Customer impact:** [from impacted_customers]
**Recommended actions:** [from remediation field]
**Links:** [portal links]
