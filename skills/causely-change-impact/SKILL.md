---
name: causely-change-impact
description: >
  Use this skill when the user asks about the impact of a deployment, configuration change, rollout, or infrastructure update — or wants to create, compare, or manage environment snapshots. Trigger for: "did our deployment break anything?", "validate the rollout", "post-deploy health check", "check for regressions", "fleet-wide deploy validation", "compare before and after", "take a snapshot", "create a baseline snapshot", "compare staging vs production", "list my snapshots", "is my deploy safe?", "CI/CD deployment gate", "shift left validation", "load test regression", "environment drift detection", or "reliability delta". Covers both quick metric deltas (reliability_delta) and full snapshot-based comparisons.
---

# Causely Change Impact & Reliability Delta Skill


Use `name_lookup(name_mention=)` to resolve names.

---

## Tools (10)

### Quick metric comparison (immediate, read-only)
| Tool | Use when |
|---|---|
| `reliability_delta(service=, cluster_name=, namespace_name=)` | Single-service before/after metric comparison (auto-detects last deploy). Use `cluster_name`/`namespace_name` to disambiguate, or `entity_id` to skip name resolution. |
| `fleet_reliability_delta(team= or namespace= or cluster= or services=[])` | Batch regression check. Scope by team, namespace, cluster, or explicit services list. Use `service_type` to narrow. |
| `get_service_summary(service=)` | Post-deploy health check |
| `get_issue_details(issue_id=)` | Full evidence when regression detected (entity_causal_chain + impact_service_graph in one call) |
| `get_incident_impact(diagnosis_id=)` | Responsibility + business context |
| `get_symptoms(symptom_name="VersionChanged", entity_types=["ComputeSpec"])` | Detect deployment events |

### Snapshot-based comparison (async, persistent, Developer/Admin)
| Tool | Use when |
|---|---|
| `create_snapshot` | Capture environment state (topology, diagnoses, metrics) over up to 2 hours. Async — returns PENDING. | 
| `get_snapshots` | List/search/poll snapshots. Poll for COMPLETE before comparing. |
| `compare_snapshots` | Compare baseline vs after. Returns ACCEPTED/REJECTED. Only COMPLETE snapshots. |
| `delete_snapshot` | Permanently delete a snapshot. |

---

## When to use which

| Scenario | Tool | Why |
|---|---|---|
| Quick "did my deploy break checkout?" | `reliability_delta(service="checkout")` | Immediate, auto-detects deploy, metric-level |
| Quick fleet-wide post-deploy | `fleet_reliability_delta(team=)` | Immediate, batch, metric-level |
| Full deploy validation (CI/CD gate) | Snapshots: create before + after → compare | Persistent, auditable, ACCEPTED/REJECTED, root-cause-aware |
| Shift-left staging validation | Snapshots: compare staging RC vs known-good baseline | Full environment comparison |
| Load test regression analysis | Snapshots: compare stable-under-load vs candidate-under-load | Surfaces capacity issues and bottlenecks |
| Environment drift detection | Snapshots: compare prod vs staging, or periodic snapshots | Configuration and behavior differences |
| Reliability trend tracking | Snapshots: periodic baselines → compare week over week | Track reliability over time |

---

## Decision trees

**Single-service quick check:**
```
reliability_delta(service=, cluster_name=, namespace_name=) → if REGRESSION: get_issue_details(issue_id=) → get_incident_impact
```

**Fleet-wide quick check:**
```
fleet_reliability_delta(team= or namespace= or cluster= or services=[]) → detail per REGRESSION service
```

**Full snapshot-based deploy validation:**
```
create_snapshot(name="baseline-v1.2.3", description="before deploy", tags={"release": "v1.2.3", "phase": "baseline"})
  → poll get_snapshots(id=) until COMPLETE
  → [deploy happens + stabilization]
create_snapshot(name="after-v1.2.3", description="after deploy", tags={"release": "v1.2.3", "phase": "after"})
  → poll get_snapshots(id=) until COMPLETE
compare_snapshots(snapshot_ids=[baseline_id, after_id])
  → 🟢 ACCEPTED (no new urgent diagnoses) or 🔴 REJECTED (regression detected)
```

**Load test regression:**
```
create_snapshot(name="baseline-load", description="stable version under load")
  → [run load test on new version]
create_snapshot(name="candidate-load", description="new version under load")
  → compare_snapshots → ACCEPTED/REJECTED
```

**Environment drift / reliability trend:**
```
compare_snapshots(snapshot_ids=[older_snapshot_id, newer_snapshot_id])
```

---

## Key concepts

### Snapshot lifecycle
1. `create_snapshot` → returns immediately with `status: PENDING`
2. Processing async (minutes to 45 min depending on environment size)
3. Poll `get_snapshots(id=)` until `status: COMPLETE` (or FAILED)
4. Only COMPLETE snapshots can be compared

### What a snapshot captures
- Topology: all entities and relationships
- Active diagnoses: grouped by name and type (urgent vs non-urgent)
- Resource metrics: CPU and memory utilization (avg and max)
- Service metrics: request rate, error rate, request duration, throughput

### Time window
- Max 2 continuous hours, custom start must be within last 6 hours
- Omit start/end for the last 2 hours (default)

### Reliability Delta (Causely branding)
Snapshot comparison is "Reliability Delta" in the Causely UI. Comparisons are **root-cause-aware** — they surface Causely diagnoses, not just metric thresholds.

### Interpreting results
- 🟢 **ACCEPTED** — no new urgent diagnoses, safe to proceed
- 🔴 **REJECTED** — new urgent diagnoses introduced, investigate before deploying

---

## Important behaviours

- **`get_events` does NOT cover deployments.** Use `get_symptoms(symptom_name="VersionChanged", entity_types=["ComputeSpec"])` for deploy detection.
- **`get_symptoms` `lookback_hours` is an interval-overlap filter.** For a stated window ("last hour"), set `active_only=false` and `lookback_hours`, then cross-check each symptom's `started_at` against the window yourself.
- **`reliability_delta` verdicts:** REGRESSION only when a new Critical or High diagnosis started after the release. Metric shifts alone give at most WARNING and never REGRESSION. A verdict marked "symptoms & diagnoses only" had no metrics to compare (metrics are kept for 24h by default).
- **`fleet_reliability_delta` checks at most 20 services per call**, most severe first, with a Truncated note for the rest. Narrow the scope if it truncates. When following up on one service, pass the fleet call's cluster and namespace as `cluster_name` / `namespace_name`.
- **Deploy before/after values** (image, resources) come from `get_service_summary` or `get_entity_health` (`service_details.configuration_changes`), not from `get_events`.
- **`get_symptoms` with `active_only=true` ignores `lookback_hours` entirely.** For a stated window set `active_only=false`.
- **Always poll for COMPLETE before comparing.** Comparing PENDING snapshots fails.
- **Baseline first.** `compare_snapshots(snapshot_ids=[baseline_id, after_id])`.
- **Tags for organization.** Use `release`, `phase`, `environment` for searchability.
- **Requires Developer/Admin** for `create_snapshot` and `delete_snapshot`.
- **Confirm before `delete_snapshot`.** Deletion is permanent and the captured data cannot be recovered. Name the snapshot (name, ID, time window) and wait for a yes. Do not delete snapshots as cleanup after your own test runs unless the user asked.
- **Processing time varies.** Small: minutes. Large: up to 45 minutes. Set expectations.

---

## Output formats

### 🚀 Quick deployment validation (reliability_delta)

**Service:** [name] · **Deploy time:** [from reliability_delta or get_symptoms VersionChanged] · **Report:** [now]
**Verdict:** ✅ PASS / ⚠️ WARNING / 🔴 REGRESSION / ⏳ WAIT
**Metric deltas:**
| Metric | Before (avg) | After (avg) | Delta | Status |
|---|---|---|---|---|
| [from reliability_delta response] |
**New diagnoses since deploy:** [name + started_at, or "None"]
**Evidence:** [from get_issue_details entity_causal_chain if called]
**Blast radius:** [from impact_service_graph]
**Recommended actions:** [from remediation; rollback if 🔴]
**Links:** [portal links]

### 📸 Snapshot comparison (compare_snapshots)

**Assessment:** 🟢 ACCEPTED / 🔴 REJECTED
**Baseline:** [name] ([start_time] → [end_time])
**After:** [name] ([start_time] → [end_time])
**Entities:** [stable] stable, [added] added, [removed] removed
**New diagnoses:** [count] — [grouped by name and entity type]
**Cleared diagnoses:** [count]
**Resource changes:** [CPU and memory deltas]
**Service changes:** [request rate, error rate, duration deltas]

---

## Closeout

- Load `submit_feedback` via `tool_search` at the start of an investigation. The tool description has the rest.
