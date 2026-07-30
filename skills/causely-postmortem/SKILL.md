---
name: causely-postmortem
description: >
  Use this skill when the user wants to generate a postmortem, incident retrospective, incident report, or blameless review for a resolved or active incident. Trigger for questions like "write a postmortem for the checkout incident", "generate an incident report", "create a retrospective for last night's outage", "what happened with X? write it up", "incident summary for the team", "create a ticket for the remediation", or "draft a Jira ticket for this fix". Also trigger for documenting incidents or creating action items.
---

# Causely Postmortem & Ticket Skill

Read `references/complete-investigation.md` for the full 33-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names. Use `name_mention_type="Diagnosis"` to find diagnoses by name.

---

## Core tools

| Tool | Use when |
|---|---|
| `postmortem(diagnosis_id=)` | Generate full postmortem |
| `generate_ticket(task=)` | Engineering ticket draft |
| `get_diagnoses(active_only=false, lookback_hours=N)` | Find diagnosis ID |
| `get_diagnosis_details(diagnosis_id=)` | Full evidence to enrich postmortem |
| `get_incident_impact(diagnosis_id=)` | Business context enrichment |
| `name_lookup(name_mention_type="Diagnosis")` | Resolve diagnosis names |

---

## Decision tree

- **Diagnosis ID known** → `postmortem(diagnosis_id=)`
- **Diagnosis name known** → `name_lookup(name_mention_type="Diagnosis")` → `postmortem(diagnosis_id=)`
- **Need evidence detail** → `get_diagnosis_details(diagnosis_id=)` for causal_chain + impact_service_graph
- **Business context** → `get_incident_impact(diagnosis_id=)`
- **Standalone ticket** → `generate_ticket(task=)`

---

## Important behaviours

- **Prefer `diagnosis_id`** — most reliable.
- **Handle ambiguity:** if `postmortem(diagnosis_name=)` returns `ambiguity_candidates`, present and ask user to pick.
- **`get_diagnosis_details` for causal_chain** — explains WHY Causely diagnosed this diagnosis.
- **Don't re-investigate:** `postmortem` synthesises from Causely data.

---

## Output format

### 📋 Incident postmortem

[Postmortem markdown from the `postmortem` tool — includes title, summary, timeline, diagnosis analysis, blast radius, contributing factors, and action items]

**Causal explanation:** [from get_diagnosis_details causal_chain — WHY Causely identified this diagnosis]

**Business context:** [from get_incident_impact — responsible team, impacted products, customers]

---

### 🎫 Remediation tickets

For each action item from the postmortem:

**Title:** [from generate_ticket]
**Priority:** [inferred from severity]
**Description:** [from generate_ticket — context + requirements]
**Acceptance criteria:** [from generate_ticket]
