---
name: causely-postmortem
description: >
  Use this skill when the user wants to generate a postmortem, incident retrospective, incident report, or blameless review for a resolved or active incident. Trigger for questions like "write a postmortem for the checkout incident", "generate an incident report", "create a retrospective for last night's outage", "what happened with X? write it up", "incident summary for the team", "create a ticket for the remediation", or "draft a Jira ticket for this fix". Also trigger when someone asks to document an incident for future reference, create action items from an incident, or generate a structured engineering ticket.
---

# Causely Postmortem & Ticket Skill

Read `references/complete-investigation.md` for the full 25-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs. Use `name_mention_type="RootCause"` to find root causes by name.

---

## Core tools

| Tool | Use when | What it returns |
|---|---|---|
| `postmortem(root_cause_id=)` | Generate full postmortem from Causely data | Markdown + structured: title, summary, timeline, root cause, blast radius, action items |
| `generate_ticket(task=)` | Create an engineering ticket draft | Structured JSON: title, description, requirements, acceptance criteria |
| `get_root_causes(active_only=false, lookback_hours=N)` | Find root cause ID for postmortem | Historical root causes with IDs |
| `name_lookup(name_mention=, name_mention_type="RootCause")` | Resolve root cause names to IDs | Root cause objects with IDs |
| `get_service_summary(service=)` | Service context for postmortem enrichment | Full service picture |

---

## Decision tree

**Root cause ID known:**
```
postmortem(root_cause_id="<id>")                           ← 1 call → done
```

**Root cause ID unknown, name known:**
```
name_lookup(name_mention="<name>", name_mention_type="RootCause")  ← 1 call
postmortem(root_cause_id=<id>)                                      ← 2nd call
```

**Only service name known:**
```
postmortem(root_cause_name="<name>", entity_name="<service>")  ← 1 call
  → if ambiguous: returns candidates → re-call with root_cause_id
```

**Standalone ticket:**
```
generate_ticket(task="<description>")                      ← 1 call
```

---

## Postmortem input priority

1. **`root_cause_id`** — preferred, unambiguous
2. **`root_cause_name` + `entity_name`** — resolves by name; returns candidates if multiple match
3. **`service` + `incident_start`** — legacy path; requires RFC3339 start time

---

## Important behaviours

- **Prefer `root_cause_id`** — most reliable lookup path.
- **Handle ambiguity:** if `postmortem(root_cause_name=)` returns `ambiguity_candidates`, present candidates and ask user to pick, then re-call with `root_cause_id`.
- **Don't re-investigate:** `postmortem` synthesises from Causely data. Don't separately call triage + get_root_causes + get_logs to rebuild what it returns.
- **Tickets are forward-looking:** use `generate_ticket` for remediation work, not documenting what happened.
