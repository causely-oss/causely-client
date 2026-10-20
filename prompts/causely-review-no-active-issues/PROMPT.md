---
name: causely-review-no-active-issues
title: See how a problem would spread
description: Show how a problem in one service would spread to others, from a recent issue or a prediction for the most depended-on service.
tags: [risk]
---
Using Causely, show me how a problem in one service would spread to others
 in my environment.
Start with an Issue from the last week where the problem reached at least
 two services away from where it started. If there isn't one, pick the
 service the most others depend on, and show what Causely expects would
 happen if it failed. Make it clear that this part is a prediction, not
 something that happened. Skip infrastructure, tooling, and external services.
 Don't tell me how you picked it.
Explain it the way you'd explain it to a teammate on call, in under 200 words:
• What would break, and who would notice first.
• How the problem would travel, service by service, and which service would
 look like its own separate problem.
• What I'd most likely get wrong tracing it by hand, and how far from the
 real cause that would leave me.
• Whether everything on this path is healthy right now.
• In one sentence, how Causely knows this.
Make Causely the subject of each finding. Use plain words, not Causely's
 internal terms or scores. Only say what Causely actually reported. End by
 offering to show how a different kind of failure would spread from the same
 service.
