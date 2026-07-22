---
name: causely-postmortem
description: >
  Use this skill when the user wants to generate a postmortem, incident retrospective, incident report, or blameless review for a resolved or active incident. Trigger for questions like "write a postmortem for the checkout incident", "generate an incident report", "create a retrospective for last night's outage", "what happened with X? write it up", "incident summary for the team", "create a ticket for the remediation", or "draft a Jira ticket for this fix". Also trigger for documenting incidents or creating action items.
---

# Causely Postmortem & Ticket Skill

Read `references/complete-investigation.md` for the full 30-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names. Use `name_mention_type="RootCause"` to find root causes by name.

---

## Core tools

| Tool | Use when |
|---|---|
| `postmortem(root_cause_id=)` | Generate full postmortem |
| `generate_ticket(task=)` | Engineering ticket draft |
| `get_root_causes(active_only=false, lookback_hours=N)` | Find root cause ID |
| `get_root_cause_details(root_cause_id=)` | Full evidence to enrich postmortem |
| `get_incident_impact(root_cause_id=)` | Business context enrichment |
| `name_lookup(name_mention_type="RootCause")` | Resolve root cause names |

---

## Decision tree

- **Root cause ID known** → `postmortem(root_cause_id=)`
- **Root cause name known** → `name_lookup(name_mention_type="RootCause")` → `postmortem(root_cause_id=)`
- **Need evidence detail** → `get_root_cause_details(root_cause_id=)` for causal_chain + impact_service_graph
- **Business context** → `get_incident_impact(root_cause_id=)`
- **Standalone ticket** → `generate_ticket(task=)`

---

## Important behaviours

- **Prefer `root_cause_id`** — most reliable.
- **Handle ambiguity:** if `postmortem(root_cause_name=)` returns `ambiguity_candidates`, present and ask user to pick.
- **`get_root_cause_details` for causal_chain** — explains WHY Causely diagnosed this root cause.
- **Don't re-investigate:** `postmortem` synthesises from Causely data.

---

## Output format

### 📋 Incident postmortem

[Postmortem markdown from the `postmortem` tool — includes title, summary, timeline, root cause analysis, blast radius, contributing factors, and action items]

**Causal explanation:** [from get_root_cause_details causal_chain — WHY Causely identified this root cause]

**Business context:** [from get_incident_impact — responsible team, impacted products, customers]

---

### 🎫 Remediation tickets

For each action item from the postmortem:

**Title:** [from generate_ticket]
**Priority:** [inferred from severity]
**Description:** [from generate_ticket — context + requirements]
**Acceptance criteria:** [from generate_ticket]
