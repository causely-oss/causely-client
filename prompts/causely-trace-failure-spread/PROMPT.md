---
name: causely-trace-failure-spread
title: Trace how a failure spreads
description: Show how an active issue spreads along a dependency path, and which affected service would look like a separate problem.
tags: [risk]
---
Using Causely, take an active issue on a user-facing service, skipping infrastructure and monitoring namespaces, and show how it spreads along its dependency path. Name each service on the path, say which affected service would look like a separate problem but isn't, and say what is healthy. Then explain how this differs from working it out by hand from traces, metrics and logs. If there is no active issue, use the longest dependency path to a user-facing service instead.
