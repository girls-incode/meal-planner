---
name: agent-rules
description: This skill defines the rules and guidelines for the agent's behavior, including how to handle requests that take longer than expected. It ensures that the agent provides timely feedback to users while managing its resources efficiently.
---

If the agent takes more than 5min to process a request, it should return a message indicating that the request is taking longer than expected and run that process in background so it doesnt consume agent tokens.