# Causely Skills for Claude

9 skills covering all 52 Causely MCP tools. Each skill is self-contained; `causely-mcp` is a short table of contents.

**Issues-first investigation:** `get_issues` → `get_issue_details` is the primary flow.

| Skill | Key tools |
|---|---|
| **causely-mcp** | Table of contents and chaining guide |
| **causely-service-analysis** | get_service_summary, get_issues, get_issue_details, get_environment_health, get_slo, get_business_transaction_summary, team_health, get_incident_impact, rank_entities, count_entities, get_label_values, get_slow_queries |
| **causely-alert-triage** | get_alerts, investigate_alert, get_integration_status (alert-rule counts) |
| **causely-change-impact** | reliability_delta, fleet_reliability_delta, create_snapshot, get_snapshots, compare_snapshots, delete_snapshot |
| **causely-correlated-incidents** | get_issues, get_issue_details, get_incident_impact, get_topology, rank_entities |
| **causely-k8s-investigation** | get_service_summary, get_symptoms, get_entity_health, get_events, get_config, get_metrics, get_logs |
| **causely-causality-exploration** | get_potential_diagnoses, get_diagnosis_observable_signals, get_potential_observable_signals, get_signal_potential_diagnoses |
| **causely-postmortem** | postmortem, generate_ticket |
| **causely-admin** | threshold tools, service tier tools, issue ignore tools; read-only platform status: get_integration_status, get_agent_versions, get_notification_configurations |
