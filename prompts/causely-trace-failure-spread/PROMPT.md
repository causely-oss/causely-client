---
name: causely-trace-failure-spread
title: Trace how a failure spreads
description: Show how a failure in one service would spread, and which affected service would look like a separate problem.
tags: [risk]
---
Using Causely, pick one service in the environment and show how a failure there would spread to the services that depend on it. Name each service along the path, and point out any that would look like a separate problem but isn't. Then explain how this differs from working it out by hand from traces, metrics and logs.
