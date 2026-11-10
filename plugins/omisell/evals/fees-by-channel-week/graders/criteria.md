---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It gives a fee total per channel and the largest fee types, with the period (last 7 days, order creation date).
- Fee types are shown as plain names (commission, transaction fee...), not raw column codes alone.
- It does not invent a fee percentage of revenue.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
