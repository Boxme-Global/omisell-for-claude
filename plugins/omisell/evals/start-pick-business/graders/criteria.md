---
type: llm
weight: 1
---

Run this case with a token that covers SEVERAL businesses (the other cases use a single-business token).

Pass only if ALL hold:
- Before showing any sales figure, it asks which business to use and lists the businesses by company name (and country), because the connection covers more than one.
- It does not mix figures from several businesses, and it does not pick one silently.
- It does not print internal ids, tool names or JSON.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
