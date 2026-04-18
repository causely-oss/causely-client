# Causely Skills for Claude

7 skills covering all 25 Causely MCP tools. Drop each folder into your skills directory.

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

Each skill includes `references/complete-investigation.md` — the master reference doc with the full tool inventory, decision trees, evidence strategy, owner resolution, and fallback guidance.
