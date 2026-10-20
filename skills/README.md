# Causely Skills for Claude (Causely Staging API)

8 skills covering all 46 Causely Staging MCP tools.

## Skills

| Skill | Key tools |
|---|---|
| **causely-mcp** | All 46 tools (master router) |
| **causely-admin** | threshold tools, service tier tools, issue ignore tools |
| **causely-change-impact** | reliability_delta, fleet_reliability_delta, get_service_summary, get_diagnosis_details |
| **causely-health-reporting** | get_service_summary, get_business_transaction_summary, get_environment_health, get_slo, get_issues, team_health |
| **causely-correlated-incidents** | get_issues, get_issue_details, get_diagnoses, get_diagnosis_details, get_incident_impact, get_topology, rank_entities |
| **causely-k8s-investigation** | get_service_summary, get_symptoms, get_entity_health, get_events, get_config, get_potential_diagnoses |
| **causely-postmortem** | postmortem, generate_ticket, get_issue_details, get_diagnosis_details, get_incident_impact |
| **causely-alert-triage** | get_alerts, investigate_alert (now returns full issue details — 2 calls done!) |

## Tools (46)

clear_service_tier, count_entities, create_threshold_configuration,
delete_threshold_configuration, fleet_reliability_delta, generate_ticket,
get_alerts, get_business_transaction_summary, get_config, get_diagnoses,
get_diagnosis_details, get_diagnosis_observable_signals, get_entities,
get_entity_health, get_environment_health, get_events, get_incident_impact,
get_integration_status, get_issue_details, get_issue_ignore_status, get_issues,
get_label_values, get_logs, get_metrics, get_potential_diagnoses,
get_potential_observable_signals, get_service_summary, get_service_tier,
get_signal_potential_diagnoses, get_slo, get_slow_queries,
get_supported_threshold_metrics, get_symptoms, get_threshold_configurations,
get_topology, ignore_issue, investigate_alert, name_lookup, postmortem,
rank_entities, reliability_delta, set_service_tier, submit_feedback,
team_health, unignore_issue, update_threshold_configuration
