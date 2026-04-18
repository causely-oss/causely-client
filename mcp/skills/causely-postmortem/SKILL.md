---
name: causely-postmortem
description: >
  Use this skill when the user wants to generate a postmortem, incident retrospective, incident report, or blameless review for a resolved or active incident. Trigger for questions like "write a postmortem for the checkout incident", "generate an incident report", "create a retrospective for last night's outage", "what happened with X? write it up", "incident summary for the team", "create a ticket for the remediation", or "draft a Jira ticket for this fix". Also trigger when someone asks to document an incident for future reference, create action items from an incident, or generate a structured engineering ticket. This skill covers both the postmortem tool and the generate_ticket tool.
---

# Causely Postmortem & Ticket Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

---

## Core tools for postmortems and tickets

| Tool | Use when | What it returns |
|---|---|---|
| `postmortem(root_cause_id=)` | Generate full postmortem from Causely data | Markdown + structured fields: title, summary, timeline, root cause, blast radius, contributing factors, action items |
| `generate_ticket(task=)` | Create an engineering ticket draft | Structured JSON: title, description, context, requirements, acceptance criteria, notes |
| `get_root_causes(active_only=false, lookback_hours=N)` | Find the root cause ID for postmortem | Historical root causes with IDs |
| `triage(entity_name=, start_time=, end_time=)` | Scoped incident summary for a time window | Markdown narrative with root causes, symptoms, impact |
| `get_events(entity_id=)` | Build incident timeline | Lifecycle events (deploys, restarts, config changes) |
| `get_symptoms(active_only=false, lookback_hours=N)` | Reconstruct signal timeline | Historical symptom start/end for timeline building |

---

## Decision tree

**Generate postmortem — root cause ID known:**
```
postmortem(root_cause_id="<id>")                           ← 1 call
  → complete postmortem: title, summary, timeline, root cause,
    blast radius, contributing factors, action items
  → done
```

**Generate postmortem — root cause ID unknown:**
```
get_root_causes(active_only=false, lookback_hours=48, root_cause_name="<name>")  ← 1 call
  → find the matching root cause, get its ID
  → or: triage(entity_name="<service>", start_time=, end_time=) to find RCs in window

postmortem(root_cause_id=<id>)                             ← 2nd call
  → complete postmortem
```

**Generate postmortem — by service + time window (legacy path):**
```
postmortem(service="<service>", incident_start="2025-03-14T00:00:00Z")  ← 1 call
  → postmortem scoped to that service and time
```

**Generate postmortem — by root cause name:**
```
postmortem(root_cause_name="<name>", entity_name="<service>")  ← 1 call
  → if ambiguous: returns ambiguity_candidates → re-submit with root_cause_id
```

**Enrich postmortem with additional context:**
```
get_entities(query="<service>") → get_events(entity_id=<id>)  ← timeline enrichment
get_symptoms(active_only=false, lookback_hours=48, entity_ids=[id])  ← signal timeline
  → add deploy events, symptom transitions to the postmortem narrative
```

**Generate remediation ticket from postmortem:**
```
postmortem(root_cause_id=<id>)                             ← 1 call
  → extract action items from postmortem
generate_ticket(task="<action item description>")           ← 1 call per ticket
  → structured ticket: title, description, acceptance criteria
```

**Generate ticket without postmortem (standalone):**
```
generate_ticket(task="<description of the remediation work>")  ← 1 call
  → Jira/GitHub/Linear-ready ticket draft
```

---

## Postmortem input priority

Use the first applicable lookup path:
1. **`root_cause_id`** — preferred; directly identifies the root cause
2. **`root_cause_name` + `entity_name`** — resolves by name; returns candidates if multiple match
3. **`service` + `incident_start`** — legacy path; requires service name and RFC3339 start time

`incident_id` alone is not resolvable — always pair it with one of the paths above.

---

## Output format

### 📋 Incident postmortem

[Postmortem markdown from the `postmortem` tool — includes title, summary, timeline, root cause analysis, blast radius, contributing factors, and action items]

---

### 🎫 Remediation tickets

For each action item from the postmortem:

**Title:** [from generate_ticket]
**Priority:** [inferred from severity]
**Description:** [from generate_ticket — context + requirements]
**Acceptance criteria:** [from generate_ticket]

---

## Important behaviours

- **Prefer `root_cause_id`** over other lookup paths — it's the most reliable and unambiguous.
- **Handle ambiguity gracefully**: if `postmortem(root_cause_name=)` returns `ambiguity_candidates`, present the candidates to the user and ask them to pick one, then re-call with the selected `root_cause_id`.
- **Don't re-investigate**: the postmortem tool synthesises from Causely's data layer. Do not separately call triage + get_root_causes + get_logs to rebuild what postmortem already returns.
- **Tickets are forward-looking**: use `generate_ticket` for remediation work, not for documenting what happened (that's the postmortem).
- **Surface portal links** so engineers can drill into the Causely data behind the postmortem.
