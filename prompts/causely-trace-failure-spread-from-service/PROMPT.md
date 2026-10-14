---
name: causely-trace-failure-spread-from-service
title: Trace how a failure in a service would spread
description: Show how a failure in a service would spread when nothing is failing, which services it depends on, and which signals are missing to catch it early.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [risk]
---
Using Causely, suppose {{service}} started failing, and set aside any issues that are active now. In under 200 words and short paragraphs, show from the dependency graph how that would spread: name only the services, in order from {{service}} to the user-facing service, and say which affected service would look like a separate problem but isn't. Say which services {{service}} depends on and whether Causely reports them as healthy, and which signals are missing to catch a failure early. Then say how this differs from tracing it by hand through traces, metrics and logs. State only what Causely reports. End by offering to find what could cause such a failure.
