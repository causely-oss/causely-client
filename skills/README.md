# Causely Skills for Claude

8 skills covering all 50 Causely MCP tools.

## Architecture

**causely-mcp** is the routing guide — it dispatches to specialized skills based on user intent. Each specialized skill has its own tool routing, decision trees, playbooks, and output formats.

```
causely-mcp (router)
├── causely-health-reporting     → health checks, SLOs, standups, rankings
├── causely-alert-triage         → alert investigation (2 calls done)
├── causely-change-impact        → deploy validation, snapshots, reliability delta
├── causely-correlated-incidents → multi-service outage correlation
├── causely-k8s-investigation    → pod/container/node issues
├── causely-postmortem           → postmortems, ticket drafts
├── causely-admin                → thresholds, tiers, issue snoozing
└── (causality exploration)      → handled directly by causely-mcp
```

## Skills

| Skill | Key tools |
|---|---|
| **causely-mcp** | Routing guide + causality model exploration |
| **causely-change-impact** | reliability_delta, fleet_reliability_delta, create_snapshot, get_snapshots, compare_snapshots, delete_snapshot |
| **causely-admin** | threshold tools, service tier tools, issue ignore tools |
| **causely-health-reporting** | get_service_summary, get_business_transaction_summary, get_environment_health, get_slo, get_issues, team_health |
| **causely-correlated-incidents** | get_issues, get_issue_details, get_diagnoses, get_diagnosis_details, get_incident_impact, get_topology, rank_entities |
| **causely-k8s-investigation** | get_service_summary, get_symptoms, get_entity_health, get_events, get_config, get_potential_diagnoses |
| **causely-postmortem** | postmortem, generate_ticket, get_issue_details, get_diagnosis_details, get_incident_impact |
| **causely-alert-triage** | get_alerts, investigate_alert (full issue details — 2 calls done!) |

## Tools (50)

clear_service_tier, compare_snapshots, count_entities,
create_snapshot, create_threshold_configuration,
delete_snapshot, delete_threshold_configuration,
fleet_reliability_delta, generate_ticket,
get_alerts, get_business_transaction_summary, get_config, get_diagnoses,
get_diagnosis_details, get_diagnosis_observable_signals, get_entities,
get_entity_health, get_environment_health, get_events, get_incident_impact,
get_integration_status, get_issue_details, get_issue_ignore_status, get_issues,
get_label_values, get_logs, get_metrics, get_potential_diagnoses,
get_potential_observable_signals, get_service_summary, get_service_tier,
get_signal_potential_diagnoses, get_slo, get_slow_queries, get_snapshots,
get_supported_threshold_metrics, get_symptoms, get_threshold_configurations,
get_topology, ignore_issue, investigate_alert, name_lookup, postmortem,
rank_entities, reliability_delta, set_service_tier, submit_feedback,
team_health, unignore_issue, update_threshold_configuration
