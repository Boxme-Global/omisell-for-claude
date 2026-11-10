---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in English.
- It states the exact week covered (Monday to Sunday dates) and compares it with the week before.
- It has a per-channel view with sales, and fees and gross margin when the data allows; if margin per channel is refused, it says that needs the shop owner in plain words and gives what it can.
- It lists best-selling SKUs and the SKUs that sold least.
- It keeps recognised (completed-order) revenue separate from sales instead of adding them together.
- No tool names, JSON, internal ids or raw permission codes appear.
- If the Omisell connector is not connected, it says so instead of inventing numbers.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
