---
name: causely-check-cluster-covered
title: Check how well a cluster is covered
description: Show the services in a cluster, what depends on them, and what Causely can't see.
arguments:
  - name: cluster
    description: The cluster to ask about, such as "production-1".
    required: true
tags: [coverage]
---
Using Causely, is {{cluster}} fully covered? List its services, what depends on them, and what Causely can't see.
