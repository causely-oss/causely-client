---
name: causely-health-reporting
description: >
  Use this skill when the user wants a scheduled, proactive, or summary view of system health — not an active incident. Trigger for requests like "give me the morning health report", "what's the state of the system?", "weekly reliability summary", "anything I should know before standup?", "system health overview", "how are our services doing overall?", "generate a status update", "SLO status report", "environment health check", "namespace health", "full service report", "is X healthy?", or "are any SLOs at risk?". Also trigger for digests, briefings, or dashboard-style summaries.
---

# Causely Health Reporting Skill

Read `references/complete-investigation.md` for the full 33-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs.

---

## Core tools

| Tool | Use when | What it returns |
|---|---|---|
| `get_service_summary(service=)` | **Primary single-service health.** | Status + symptoms + RCs + SLOs + metrics + deps + events + errors |
| `get_environment_health()` | Global or scoped overview. **Does NOT report SLOs.** | Overall status + diagnoses |
| `get_slo()` | **All SLO questions.** Fleet-wide with `cluster_names`/`namespace_names` or per-service with `entity_ids`. | Error budget, burn rate, at-risk, violated |
| `get_diagnoses(active_only=true)` | All active issues — lightweight summary | Structured JSON per RC; follow up with `get_diagnosis_details` for evidence |
| `team_health(team=)` | Team-scoped standup | Degraded first, healthy grouped at end |
| `get_symptoms()` | All active symptoms — no IDs needed | Full signal picture |
| `rank_entities(entity_type=, mode=)` | "Which services are most critical?" | Ranked list |

---

## Decision tree

- **"Is X healthy?"** → `get_service_summary(service=)`
- **Morning standup** → `get_environment_health()`
- **"Which SLOs are at risk?"** → `get_slo(only_at_risk=true)`
- **"SLOs violated in robot-shop?"** → `get_slo(namespace_names=["robot-shop"], only_violated=true)`
- **Namespace scoped** → `get_environment_health(namespaces=)`
- **Team standup** → `team_health(team=)` → `get_incident_impact` for degraded
- **"Which services are most critical?"** → `rank_entities(entity_type="Service", mode=dependents)`
- **Weekly trends** → `get_diagnoses(active_only=false, lookback_hours=168)`

---

## Output formats

### Morning briefing

**🟢 / 🟡 / 🔴 System health: [status]** — *[N] active diagnoses*

| Service | Diagnosis | Severity | Since | Evidence | Owner |
|---|---|---|---|---|---|

**SLOs at risk:** [from `get_slo(only_at_risk=true)`]

### On-call handoff

🔴 **Active now:** [severity · service · diagnosis]
🟡 **SLOs burning:** [from `get_slo(only_at_risk=true)` — burn rate > 1.0]
📋 **Watch list:** [recurring diagnoses in past 24h]
