---
name: causely-trace-failure-spread
title: Trace how the most severe issue spreads
description: Find the most severe active issue on an application service and show how it spreads, and which affected service would look like a separate problem.
tags: [risk]
---
Using Causely, find the most severe active issue on an application service behind a user-facing one, meaning a service at the top of the call chain where users or clients enter. Ignore Causely's own components, ingress and mesh services, and infrastructure and monitoring namespaces. In under 200 words and short paragraphs, show how a failure at its source spreads: name only the services, in order from the source to the user-facing service. Say which affected service would look like a separate problem but isn't, and which services the source depends on are healthy, which rules them out as the cause. Then say how that differs from tracing it by hand through traces, metrics and logs. State only what Causely reports. If no issue qualifies, say so in one sentence. Otherwise, end by offering to investigate the source further.
