---
name: causely-health-reporting
description: >
  Use this skill when the user wants a scheduled, proactive, or summary view of system health — not an active incident. Trigger for requests like "give me the morning health report", "what's the state of the system?", "weekly reliability summary", "anything I should know before standup?", "system health overview", "how are our services doing overall?", "generate a status update", "SLO status report", "environment health check", "namespace health", "full service report", "is X healthy?", or "are any SLOs at risk?". Also trigger for digests, briefings, or dashboard-style summaries.
---

# Causely Health Reporting Skill

Read `references/complete-investigation.md` for the full 28-tool inventory and evidence strategy.

Use `name_lookup(name_mention=)` to resolve names to typed objects with IDs.

---

## Core tools

| Tool | Use when | What it returns |
|---|---|---|
| `get_service_summary(service=)` | **Primary single-service health.** Resolves name automatically. | Status + symptoms + RCs + SLOs + metrics + deps + events + errors |
| `get_environment_health()` | Global or scoped overview. **Returns at-risk SLOs.** | Overall status + root causes + at-risk SLOs |
| `get_root_causes(active_only=true)` | All active issues with evidence | Structured JSON per RC |
| `team_health(team=)` | Team-scoped standup | Degraded first, healthy grouped at end |
| `get_symptoms()` | All active symptoms — no IDs needed | Full signal picture |
| `rank_entities(entity_type=, mode=)` | "Which services have the most dependencies/dependents?" | Ranked list, single SQL query |
| `name_lookup` → `get_slo(entity_ids=)` | SLO for specific services | Per-SLO: budget %, burn rate |
| `get_entity_health(entity_id=)` | Non-service entity health | Symptoms, RCs, events, logs, metrics |

---

## Decision tree

- **"Is X healthy?"** → `get_service_summary(service=)`
- **Morning standup** → `get_environment_health()`
- **Namespace/cluster scoped** → `get_environment_health(namespaces=)` or `get_environment_health(clusters=)`
- **Team standup** → `team_health(team=)` → `get_incident_impact` for degraded services
- **SLO report** → `get_environment_health()`
- **"Which services are most critical?"** → `rank_entities(entity_type="Service", mode=dependents)`
- **Weekly trends** → `get_root_causes(active_only=false, lookback_hours=168)`

---

## Output formats

### Morning briefing

**🟢 / 🟡 / 🔴 System health: [status]** — *[N] active root causes*

| Service | Root cause | Severity | Since | Evidence | Owner |
|---|---|---|---|---|---|
| [from response] |

**SLOs at risk:** [from get_environment_health]

### On-call handoff

🔴 **Active now:** [severity · service · root cause]
🟡 **SLOs burning:** [burn rate > 1.0]
📋 **Watch list:** [recurring root causes in past 24h]
