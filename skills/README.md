# Causely Skills for Claude

Seven skills cover all 25 Causely MCP tools. Install the **master router** by copying [`SKILL.md`](SKILL.md) and [`complete-investigation.md`](complete-investigation.md) from this `mcp/` directory into your agent’s skills layout (see your product’s skill docs for paths). Install each **leaf** skill by copying a folder from [`skills/`](skills/) (the folder includes `SKILL.md` and `references/complete-investigation.md`).

## Skills

| Skill | Triggers on | Key tools used |
|---|---|---|
| **causely-mcp** | Any observability/reliability question (master router) | All 25 tools |
| **causely-change-impact** | Post-deploy validation, regression checks, rollouts | reliability_delta, fleet_reliability_delta, triage, get_events, get_config, get_metrics |
| **causely-health-reporting** | Morning standup, system overview, SLO reports | get_environment_health, get_service_summary, get_slo, team_health, get_root_causes |
| **causely-correlated-incidents** | Multi-service outages, blast radius, cascading failures | get_root_causes, get_topology, get_alerts, triage |
| **causely-k8s-investigation** | Pod restarts, OOMKills, node pressure, resource issues | triage, get_entity_health, get_events, get_config, get_metrics, get_entities |
| **causely-postmortem** | Incident retrospectives, ticket generation | postmortem, generate_ticket, get_root_causes |
| **causely-alert-triage** | PagerDuty/Datadog/Alertmanager alert investigation | get_alerts, get_entities, triage, get_root_causes |

## Tool coverage

All 25 Causely MCP tools are covered across the skills:

- ask_causely, fleet_reliability_delta, generate_ticket, get_alerts, get_config
- get_entities, get_entity_health, get_environment_health, get_events
- get_integration_status, get_label_values, get_logs, get_metrics
- get_root_causes, get_service_summary, get_slo, get_slow_queries
- get_symptoms, get_topology, list_clusters, list_namespaces
- postmortem, reliability_delta, team_health, triage

## Shared reference

Each **leaf** skill under `skills/` includes `references/complete-investigation.md` (in this repository it is a symlink to [`complete-investigation.md`](complete-investigation.md) beside this README). The **causely-mcp** router skill reads `complete-investigation.md` from the same `mcp/` directory as `SKILL.md`. That file is the master reference: full tool inventory, decision trees, evidence strategy, owner resolution, and fallback guidance.
