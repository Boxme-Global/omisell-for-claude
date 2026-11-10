---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It reports COD awaiting reconciliation, COD reconciled and abnormal parcels, with the period and that it counts parcels by delivery date.
- Abnormal parcels are listed by tracking code with COD, received and difference, or it says there are none.
- It does not describe reconciliation statement amounts as shipping fees.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
