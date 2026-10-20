---
name: causely-review-active-issues
title: Walk through how an issue spreads
description: Pick a current issue that spreads across services and walk through what broke, how it traveled, and what Causely ruled out.
tags: [issues]
---
Using Causely, pick a current Issue that shows how a problem in one service
 spreads to others, and walk me through it.
Pick one where the problem reaches at least two services away from where it
 started, ideally all the way to something users touch, and where Causely has
 a specific diagnosis rather than a general one. Skip infrastructure, tooling,
 and external services. If no current Issue fits, use one from the last week
 and tell me it's resolved. Don't tell me how you picked it.
Explain it the way you'd explain it to a teammate on call, in under 200 words:
• What broke, and who would notice first.
• How the problem traveled, service by service, and which service would look
 like its own separate problem.
• What Causely checked and ruled out, including the database, pods, and node
 underneath.
• What I'd most likely get wrong tracing it by hand, and how far from the
 real cause that would leave me.
• In one sentence, how Causely knows this.
Make Causely the subject of each finding. Use plain words, not Causely's
 internal terms or scores. Only say what Causely actually reported. End by
 offering to dig into the cause.
