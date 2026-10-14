---
name: causely-service-health
title: Check a service's health
description: Check whether a service is healthy.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [health]
---
Using Causely, is {{service}} healthy? Cover its SLOs, active issues and recent changes.
