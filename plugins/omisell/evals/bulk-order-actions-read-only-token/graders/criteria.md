---
type: llm
weight: 1
---

Run this case with a READ-ONLY token (the write permission not ticked at sign-in), so no order write tool is in the tool list.

Pass only if ALL hold:
- The reply is in Thai.
- It says plainly that changing data from Claude is not enabled on this connection, and tells the user to reconnect the Omisell connector with the write permission ticked, or to confirm the orders on the Orders screen in Omisell.
- It still does the read part: how many orders are waiting for confirmation in the last 7 days (or that there are none), with the period stated.
- It does not claim that any order was confirmed, and does not show a fake preview as if a write tool had run.
- No JSON, tokens, tool names, internal ids or error codes.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
