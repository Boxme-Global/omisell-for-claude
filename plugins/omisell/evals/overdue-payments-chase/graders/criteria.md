---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It uses 15 days and explains it means orders created at least 15 days ago with an overdue, debt or partly paid payment.
- It lists open orders by order code, channel and created date, and says how many more exist.
- It separates (or mentions) closed orders that still carry an overdue payment record from open ones.
- It does not show an amount owed (the tool returns none) and does not change any payment status.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
