---
name: causely-alert-triage
description: >
  Use this skill when the user is starting from an alert — they received a PagerDuty page, Datadog alert, Prometheus/Alertmanager notification, Slack alert, or OpsGenie notification and want to understand what it means. Trigger for questions like "I got paged for KubeContainerWaiting", "what does this alert mean?", "PagerDuty woke me up for high error rate on checkout", "Datadog says memory is high on X", "what alerts are firing on X?", "how many unmapped alerts do we have?", "is this alert noise or real?", "which alerts map to Causely symptoms?", or "audit alert noise". Also trigger when the user pastes an alert name, alert payload, or references an external alerting system. Use this skill over generic causely-mcp when the investigation starts from an alert rather than from a service name or health question.
---

# Causely Alert Triage Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

---

## Core tools for alert-driven triage

| Tool | Use when | What it returns |
|---|---|---|
| `get_entities(query=, entity_types=)` | Resolve the service/entity from the alert | Entity IDs for the affected service |
| `get_alerts(entity_ids=)` | See all alerts firing + mapping state | Alert name, symptom mapping, severity, count, timestamps |
| `get_root_causes(symptom_ids=)` | Find diagnosed cause behind a mapped alert | Root causes with evidence, blast radius, remediation |
| `triage(entity_name=)` | Quick full-picture health check | Root causes, symptoms, impact — all in one call |
| `get_symptoms(entity_ids=)` | Check which alerts promoted to symptoms | Named signals in the causal graph |
| `ask_causely(question=)` | Free-form query when alert name doesn't resolve | NL fallback for complex alert-to-cause questions |

---

## Core rule: alerts → entities → causes

External alerting systems (PagerDuty, Datadog, Alertmanager) fire raw alert names. Causely maps some alerts to named symptoms in its causal model. The workflow bridges from alert → entity → mapped symptom → root cause.

**`ask_causely` cannot resolve raw alert names.** Don't use it for "what is causing KubeContainerWaiting?" — use the structured workflow below.

---

## Decision tree

**Alert received — service name known:**
```
triage(entity_name="<service>")                            ← 1 call
  → if root causes found: that's likely what triggered the alert
  → description = evidence, remediation = what to do
  → done in most cases
```

If you need to see the specific alert and its mapping status:
```
get_entities(query="<service>", entity_types=["Service"])   ← 1 call
get_alerts(entity_ids=[id], active_only=true)               ← 1 call
  → find the alert by name
  → mapping_state = "mapped" → Causely has incorporated it
  → mapping_state = "unmapped" → Causely hasn't promoted it to a symptom
  → if mapped: symptom_name → get_root_causes(symptom_ids=[...]) for cause
```

**Alert received — service name unknown:**
```
ask_causely("What active root causes are there right now?")  ← 1 call
  → scan results for the alert pattern or affected service
  → then triage the identified service
```

**Alert name known, want to check if Causely knows about it:**
```
get_entities(query="<service>")                             ← 1 call
get_alerts(entity_ids=[id], alert_name_filters=["<alert-name>"])  ← 1 call
  → mapping_state tells you if Causely has incorporated this alert
  → if mapped: follow symptom_name → root cause chain
  → if unmapped: alert is noise or not yet incorporated
```

**Alert noise audit ("how noisy are our alerts?"):**
```
get_entities(query="<service>")                             ← 1 call
get_alerts(entity_ids=[id], mapping_state_filters=["unmapped"])  ← 1 call
  → high-count unmapped alerts = noise candidates for tuning
  → compare with get_alerts(mapping_state_filters=["mapped"]) for signal-to-noise
```

**Multiple alerts firing at once:**
```
get_root_causes(active_only=true)                           ← 1 call
  → check if multiple alerts map to the same root cause
  → impact_service_graph shows propagation → many alerts, one origin
```

---

## Mapping state guide

| mapping_state | Meaning | Action |
|---|---|---|
| `mapped` | Causely has promoted this alert to a named symptom | Follow `symptom_name` → `get_root_causes(symptom_ids=)` for diagnosis |
| `unmapped` | Causely hasn't incorporated this alert | May be noise, or a new signal type not yet configured |

---

## Output format

### 🔔 Alert triage: [alert name]

**Alert:** [alert_name from get_alerts or user's description]
**Service:** [entity name]
**Status:** [firing / resolved] · **Severity:** [from alert]
**Causely mapping:** ✅ Mapped to symptom "[symptom_name]" / ❌ Unmapped

**Root cause:** [from triage or get_root_causes — name + entity + portal link]

**Evidence:** [from description field]

**Blast radius:** [from impacted_services]

**Customer impact:** [from impacted_customers]

**Owner:** [from causely.ai/team label]

**Recommended actions:** [from remediation field]

**Links:** [portal links]

---

## Important behaviours

- **Start with `triage` when you have a service name.** It's faster and gives the full picture without needing to resolve alert → symptom → root cause manually.
- **Use `get_alerts` when the user specifically wants to see alert-level detail** — mapping status, alert counts, firing times.
- **Don't use `ask_causely` for alert name resolution** — it can't resolve raw Alertmanager or Datadog alert names to Causely entities.
- **Unmapped ≠ irrelevant**: an unmapped alert might be a real signal that Causely hasn't been configured to ingest yet. Don't dismiss it.
- **Multiple alerts, one cause**: when the user reports several alerts, check `get_root_causes` first — they often share a single origin visible in the impact graph.
