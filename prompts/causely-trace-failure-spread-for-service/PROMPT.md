---
name: causely-trace-failure-spread-for-service
title: Trace how an active issue on a service spreads
description: Show how the active issue affecting a service spreads from its source, and which affected service would look like a separate problem.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [risk]
---
Using Causely, take the active issue affecting {{service}} and show how it spreads from its source along the dependency path. In under 200 words and short paragraphs, name only the services, in order from the source to the user-facing service. Say which affected service would look like a separate problem but isn't, and which services the source depends on are healthy, which rules them out as the cause. Then say how that differs from tracing it by hand through traces, metrics and logs. State only what Causely reports. If {{service}} has no active issue, say so in one sentence. Otherwise, end by offering to investigate the source further.
