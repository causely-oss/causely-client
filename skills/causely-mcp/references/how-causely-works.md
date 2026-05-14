# How Causely Identifies Root Causes

Causely uses an **ontology-first causal reasoning engine** — not bottom-up log correlation or ML anomaly detection. Here is the six-step detection pipeline:

---

## Step 1 — Semantic distillation (mediation layer)

A mediation layer runs **locally in the cluster** and distills raw telemetry (logs, metrics, traces) from every instrumented service into structured **entities**, **relations**, and **symptoms**. Logs are not pattern-matched — they are interpreted as semantic symptom states on known entities (e.g. "High Request Error Rate" on `otel-demo/payment`). Only this distilled semantic data is sent to the causal reasoning engine. Raw telemetry stays in the cluster.

---

## Step 2 — Pre-built causal model (no training required)

Causely ships with a built-in **causal knowledge library** encoding how specific root cause types degrade service performance. For example, it knows that a "Service Malfunction" on a payment-type service produces high error rates on the service, its RPC methods, and upstream callers. This model is active from deployment — it does not need to learn from historical incidents.

---

## Step 3 — Live topology graph

Causely continuously discovers and maintains a **topology graph** from OpenTelemetry traces and cluster metadata. Before any symptoms fire, it already knows the full dependency chain:

```
payment → checkout → frontend → frontend-proxy + load-generator
```

This graph is the foundation for blast radius analysis and cross-service impact modeling.

---

## Step 4 — Causality mapping via Bayesian network

Combining the pre-built causal model with the live topology, Causely generates a **Bayesian network** — a probabilistic model of how root causes propagate through this specific environment. This is represented as two structures:

- **Causality Graph (DAG):** Nodes are root causes and symptoms; edges carry probabilities representing how likely a cause produces each symptom.
- **Codebook:** Each root cause has a unique signature — a vector of probabilities across all possible symptoms in the system.

---

## Step 5 — Probabilistic inference identifies the root cause

When symptoms appear, Causely matches the observed symptom pattern against the codebook signatures to infer the most likely root cause. Probabilities decay at each propagation hop, expressing decreasing confidence that a downstream symptom is caused by this specific root cause versus another factor. Example from a real incident:

| Propagation hop | Probability |
|---|---|
| Root cause → payment service failure | 1.0 |
| Payment → RPC method `Charge` failure | 0.9 |
| RPC failure → `PlaceOrder` failure | 0.675 |
| PlaceOrder → checkout service failure | 0.375 |
| Checkout → frontend failure | 0.141 |
| Frontend → individual HTTP paths | ~0.127 each |

---

## Step 6 — SLO impact tracked automatically

Causely maps each active root cause to any SLOs that are burning as a consequence. SLO violations are attributed to the root cause, not just reported as independent alerts.

---

## Why this matters operationally

- **No training data needed.** The causal model works on day one, even in environments with no prior incidents.
- **Single root cause, not an alert flood.** Causely surfaces the one cause behind dozens of downstream symptoms — not each symptom separately.
- **Blast radius is built in.** The topology graph means you always know which services, customers, and SLOs are affected.
- **Evidence is pre-synthesised.** The `description` field on a root cause already contains the distilled log patterns and error messages — you do not need to search logs manually.
