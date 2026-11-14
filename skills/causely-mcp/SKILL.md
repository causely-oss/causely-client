---
name: causely-mcp
description: >
  Table of contents for the Causely skills. Use this first when a request involves Causely or service reliability and it is unclear which Causely skill applies, or when a task spans several of them (for example alert to postmortem, or deploy to correlated outage). Each skill below owns its own tools, decision trees, and output formats.
---

# Causely Skills — Table of Contents

Read the skill that matches the request. Each is self-contained.

| Skill | Use for |
|---|---|
| **causely-service-analysis** | What's wrong with a service, is it healthy, active incidents, SLOs, standups, rankings, historical health |
| **causely-alert-triage** | A firing alert: find it and get the full causal explanation in two calls |
| **causely-change-impact** | Did a deploy or change break anything: metric deltas and snapshot comparisons |
| **causely-correlated-incidents** | Several services failing at once: shared cause and propagation |
| **causely-k8s-investigation** | Pods, containers, nodes: restarts, OOMKills, evictions, configs |
| **causely-causality-exploration** | What could be wrong, what could explain a signal, how Causely reasons |
| **causely-postmortem** | Postmortems and ticket drafts |
| **causely-admin** | Thresholds, service tiers, snoozing issues; read-only platform status (integrations, agent versions, notification routing) |

## Issues first

An **Issue** is the stable incident identity; a **Diagnosis** is the current best explanation and evolves as signals change. Start with `get_issues` → `get_issue_details`, which returns the causal chain, blast radius, and all diagnoses in one call. Use `get_diagnoses` only for filtering or drill-down.

## When a task spans skills

| Scenario | Start with | Then |
|---|---|---|
| Alert firing, then write it up | causely-alert-triage | causely-postmortem |
| Deploy broke something | causely-change-impact | causely-service-analysis for the full picture |
| Several services down after a deploy | causely-change-impact | causely-correlated-incidents |
| Pod crashing, are SLOs affected? | causely-k8s-investigation | causely-service-analysis (`get_slo`) |
| Too many false positives on a service | causely-service-analysis | causely-admin to tune the threshold |
