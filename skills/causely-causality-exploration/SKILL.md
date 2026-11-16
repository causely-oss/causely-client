---
name: causely-causality-exploration
description: >
  Use this skill when the user asks what COULD be wrong or what COULD cause something, rather than what is wrong right now, or asks how Causely reasons. Trigger for: "what diagnoses could checkout have?", "what could explain HighErrorRate on payment?", "what signals would MemoryPressure cause?", "show me all signals on this entity, active and potential", "what is the causality model for this service?", "how does Causely work?", "how did Causely arrive at this diagnosis?", "why did Causely diagnose this?", or "what is Causely's causal reasoning?". Covers the theoretical causality model (hypotheses and signal relationships), not just observed state.
---

# Causely Causality Exploration Skill

These tools explore Causely's **theoretical** causality model: hypotheses and signal relationships, not only what is observed right now. For what is actually wrong, use **causely-service-analysis**.

Use `name_lookup(name_mention=)` to resolve names to entity IDs.

---

## Core tools

| Tool | Use when |
|---|---|
| `get_potential_diagnoses(entity_id=)` | All diagnosis hypotheses for one entity, active and causality-only |
| `get_diagnosis_observable_signals(entity_id=, diagnosis_name=)` | Which signals a given diagnosis could cause |
| `get_potential_observable_signals(entity_id=)` | All signals on one entity: active, inactive, potential |
| `get_signal_potential_diagnoses(entity_id=, signal_name=)` | Which diagnoses could explain a given signal |
| `get_symptoms(entity_ids=[id])` | The observed signals, to compare against the model |
| `get_issue_details(issue_id=)` | `entity_causal_chain` shows why Causely reached a specific diagnosis |

---

## Decision tree

**Forward: entity → diagnoses → signals**
```
name_lookup → get_potential_diagnoses(entity_id=)
  → get_diagnosis_observable_signals(entity_id=, diagnosis_name=)
  → compare to get_symptoms(entity_ids=[id]) to see which are actually active
```

**Reverse: signal → diagnoses**
```
name_lookup → get_potential_observable_signals(entity_id=)
  → get_signal_potential_diagnoses(entity_id=, signal_name=)
```

**"How did Causely arrive at this diagnosis?"**
```
get_issue_details(issue_id=)   ← entity_causal_chain in primary_diagnosis_detail
```
Start at `root_entity_id` and follow edges outward. Each node lists the signals the diagnosis causes there, with the probability. Probabilities degrade with distance from the root, which confirms the origin. The probabilities come from Causely's pre-built causal model, not from an LLM.

---

## Important behaviours

- **`get_potential_diagnoses` is not `get_diagnoses`.** The former returns model hypotheses for one entity, including causality-only ones. The latter returns observed active diagnoses.
- **`get_potential_observable_signals` is not `get_symptoms`.** The former includes inactive and potential signals on one entity. The latter returns observed symptoms across the environment.
- **`signal_type` selects the kind of signal** for `get_signal_potential_diagnoses`: Symptom (default), Event, or SLO. `get_potential_observable_signals` takes `signal_types` (symptom, event, slo, dynamic_symptom) to filter.
- **`get_diagnosis_observable_signals` returns at most 100 entities.** Use `max_hops` to narrow, `limit` and `after` to page, and `start_entity_id` only to expand a graph you already have. This is the theoretical model; `get_issue_details` shows the same shape built from the observed incident.
- **Signal names are internal.** Take `signal_name` from `name_lookup` or `get_potential_observable_signals`, not from display text.

---

## Output formats

### 🧬 Diagnosis hypotheses: [entity]

| Diagnosis | State | Observable signals |
|---|---|---|
| [name] | active / causality-only | [signals it could cause] |

**Currently active:** [which hypotheses match observed symptoms]

### 🧬 Signal explanations: [signal] on [entity]

| Candidate diagnosis | State | Why it fits |
|---|---|---|

---

## Closeout

- Load `submit_feedback` via `tool_search` at the start of an investigation. The tool description has the rest.
