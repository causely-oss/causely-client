---
name: causely-trace-failure-spread
title: Trace how a failure spreads
description: Show how an active issue spreads along a dependency path, and which affected service would look like a separate problem.
tags: [risk]
---
Using Causely, find an active issue on a user-facing service, ignoring infrastructure and monitoring namespaces. In under 200 words and short paragraphs, show how a failure at its source spreads: name only the services, in order from the source to the user-facing service. Say which affected service would look like a separate problem but isn't, and which services the source depends on are healthy, which rules them out as the cause. Then say how that differs from tracing it by hand through traces, metrics and logs. State only what Causely reports. If there is no active issue, use the longest dependency path to a user-facing service. End by offering to investigate why the source is failing.
