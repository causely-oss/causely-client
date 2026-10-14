---
name: causely-post-deploy
title: Check whether a deploy broke anything
description: Check whether the latest deploy of a service broke anything.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [changes]
---
Using Causely, did the latest deploy of {{service}} break anything? Check the service and the services that depend on it.
