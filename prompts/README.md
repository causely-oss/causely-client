# Causely prompts

Ready-to-use prompts for talking to Causely through an MCP-capable agent (Cursor, Claude, VS Code, and others). Each prompt is a plain markdown file, so any tool can read it. The layout mirrors [`skills/`](../skills).

```
prompts/
  causely-<name>/
    PROMPT.md
  schema/prompt.frontmatter.schema.json
```

## Format

`PROMPT.md` is YAML frontmatter followed by the prompt text. The frontmatter follows the [MCP prompt definition](https://modelcontextprotocol.io/specification/server/prompts) (`name`, `title`, `description`, `arguments`).

```md
---
name: causely-discover-environment-with-entities
title: See what Causely found
description: Same as discovering the environment, citing how many entities Causely has already discovered.
arguments:
  - name: entities
    description: What Causely has already discovered, such as "12 entities".
    required: false
tags: [discovery]
---
What has Causely found in my environment so far? It has already discovered {{entities}}. ...
```

| Field | Required | Notes |
|-------|----------|-------|
| `name` | yes | Same as the directory name. Lowercase kebab-case, starts with `causely-`. |
| `title` | yes | Short human label. |
| `description` | yes | One sentence on what the prompt is for. |
| `arguments` | no | Values the text interpolates. Each has `name`, `description`, `required`. |
| `tags` | no | Free-form labels for grouping. |

The body is the exact text sent to an agent. Insert an argument with `{{name}}`; every placeholder must be declared in `arguments`.

### Frontmatter syntax

Frontmatter is a small subset of YAML so that any consumer can read it without a full parser: `key: value` lines with plain, `'single'` or `"double"` quoted values, inline lists (`tags: [a, b]`), `true` / `false`, and one block list of maps for `arguments`. Anchors, multi-line values, nested lists, tabs and inline comments are not supported.

## Writing a prompt

- Name Causely, so the agent uses the Causely tools.
- Write impersonal requests. Don't use first person (my, our, me), and don't name roles or people. Name the thing asked about, or take it as an argument.
- Make the title say what the prompt finds or does, in a few plain words, and keep titles unique.
- Write complete, grammatical sentences.
- Work without extra context. Don't ask for something the person may not have to hand, such as an alert to paste.
- Say what to ask. Add how to answer only where the answer is poor without it, such as a length limit, what to cover, or "state only what Causely reports". People copy these prompts into their own agent, so the prompt has to work without any other instructions.
- Names are stable once published. Fix wording in place; to retire a prompt, leave it and add a new one rather than renaming.

## Fetching

Prompts are served unchanged from GitHub, one file per prompt:

```
https://raw.githubusercontent.com/causely-oss/causely-client/main/prompts/<name>/PROMPT.md
```

Prompts say nothing about where or for whom they are shown. Choosing which prompt to show is up to the consumer.

## Prompts

| Name | Purpose |
|------|---------|
| `causely-discover-environment` | Walk through what Causely has found so far |
| `causely-discover-environment-with-entities` | The same, citing how many entities were discovered |
| `causely-discover-team-environment` | Walk through the connected clusters and how their services relate |
| `causely-discover-cluster` | Walk through the services in a cluster |
| `causely-explain-environment` | Explain what Causely knows in plain language |
| `causely-whats-broken` | Active issues with diagnoses, most urgent first |
| `causely-what-changed` | Recent deploys and config changes, and their effect |
| `causely-trace-failure-spread` | How a failure in one service would spread, and which affected service would look like a separate problem |
| `causely-what-would-break` | What would break if a service failed, what could cause it, and which signals are missing |
| `causely-explain-diagnosis` | What is causing the problem on a service, what it affects, and which signals show it |
| `causely-check-area-covered` | How much of the environment Causely sees, and what it can't |
| `causely-check-cluster-covered` | The services in a cluster, what depends on them, and what Causely can't see |
| `causely-whats-at-risk` | What is most at risk and what could cause it, in plain language |
| `causely-verify-active-issues` | Quick check that an agent can reach Causely |
| `causely-incident-impact` | Impact of an incident |
| `causely-service-health` | Health of a service |
| `causely-post-deploy` | Did a recent deploy break anything |
| `causely-<skill>-example` | Example prompt for each skill in [`skills/`](../skills) |
