---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- If the profit tool was refused for a missing permission, the reply says in plain words that viewing profit needs the profit report (or cost management) permission and that the shop owner can grant it.
- It does not print the raw error, the error code or the permission rule code (such as report_profit_view).
- It does not make up profit numbers from other tools.
- If the user does have the permission, it answers with gross profit per SKU and the period instead.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
