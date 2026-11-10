---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It reports open purchase orders grouped as late (past the expected date, goods not yet at the warehouse) and partly received (received less than ordered), with ordered vs received quantities, or says clearly that there are none.
- It does not use customer-return receiving figures as purchase-order receiving.
- It gives an "as of" time and does not state paid / unpaid amounts.
- No tool names, JSON, internal ids or error codes are printed.
- It suggests a next step (chase the vendor, complete the order in Omisell, /omisell:stockout-forecast or /omisell:reorder-plan).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
