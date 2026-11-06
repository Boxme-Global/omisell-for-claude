---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It lists SKUs with the lowest gross profit first, with net sales, cost, gross profit and margin, and the period (order creation date, at most 31 days).
- SKUs with no cost recorded are called out as cost not recorded, not as loss-making.
- It does not subtract fees, shipping or ads to make a net profit figure.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
