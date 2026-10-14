---
name: causely-alert-triage-example
title: Diagnose a firing alert
description: Find the diagnosis behind an alert that is firing on a service.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [skill-example]
---
Using Causely, an alert is firing for {{service}}. Which diagnosis is causing it?
