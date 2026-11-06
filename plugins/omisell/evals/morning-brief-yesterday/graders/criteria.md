---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It gives yesterday's sales with the date, and compares it with the same weekday of the previous week (or says that data is missing).
- It covers orders with problems, orders waiting because of out-of-stock, and returns, each with its period.
- It ends with one to three next steps that name Omisell skills.
- It shows no customer phone number, address or email, no tool names, no JSON and no raw error.
- If the Omisell connector is not connected, it says so instead of inventing numbers.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
