---
name: causely-change-impact-example
title: Review a service's recent changes
description: Find how recent deploys and config changes affected a service and the services around it.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [skill-example]
---
Using Causely, how have recent changes to {{service}}, such as deploys and config changes, affected it and the services that depend on it?
