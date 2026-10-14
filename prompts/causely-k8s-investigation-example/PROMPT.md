---
name: causely-k8s-investigation-example
title: Find why pods are being OOMKilled
description: Find what is causing the pods of a service to be OOMKilled.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [skill-example]
---
Using Causely, why are the pods of {{service}} being OOMKilled? What is causing it?
