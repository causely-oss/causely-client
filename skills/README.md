# Causely Skills for Claude (Causely Staging API)

7 skills covering all 25 Causely Staging MCP tools.

## Skills

| Skill | Triggers on | Key tools used |
|---|---|---|
| **causely-mcp** | Any observability/reliability question (master router) | All 25 tools |
| **causely-change-impact** | Post-deploy validation, regression checks, rollouts | reliability_delta, fleet_reliability_delta, get_service_summary, get_incident_impact |
| **causely-health-reporting** | Morning standup, system overview, SLO reports | get_service_summary, get_environment_health, get_symptoms, team_health, get_slo |
| **causely-correlated-incidents** | Multi-service outages, blast radius, cascading failures | get_root_causes, get_incident_impact, get_topology, get_alerts |
| **causely-k8s-investigation** | Pod restarts, OOMKills, node pressure, resource issues | get_service_summary, get_symptoms, get_entity_health, get_events, get_config |
| **causely-postmortem** | Incident retrospectives, ticket generation | postmortem, generate_ticket, get_incident_impact, name_lookup |
| **causely-alert-triage** | Alert investigation from PagerDuty/Datadog/Alertmanager | get_alerts, investigate_alert, get_root_causes, get_incident_impact |

## Tool coverage (25 tools)

ask_causely, fleet_reliability_delta, generate_ticket, get_alerts, get_config,
get_entity_health, get_environment_health, get_events, get_incident_impact,
get_integration_status, get_label_values, get_logs, get_metrics,
get_root_causes, get_service_summary, get_slo, get_slow_queries,
get_symptoms, get_topology, investigate_alert, name_lookup, postmortem,
reliability_delta, team_health
