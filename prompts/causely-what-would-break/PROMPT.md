---
name: causely-what-would-break
title: See what would break
description: Find what would break if a service failed, what could cause that, and which signals are missing to catch it.
arguments:
  - name: service
    description: The service to ask about, such as "checkout".
    required: true
tags: [risk]
---
Using Causely, what would break if {{service}} failed? What could cause that, and which signals are missing to catch it?
