---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in English.
- It gives the A / B / C split by sales for a stated window (at most 90 days) and separately a grading by stock value "as of now", without confusing the two.
- It names SKUs where stock value is high but sales are low (capital tied up), with stock value in the store's currency.
- It mentions sell-through (units sold vs starting stock) for at least the highlighted SKUs, or says plainly that part was unavailable.
- No tool names, JSON, internal ids or error codes are printed; numbers carry their period.
- It suggests next steps such as /omisell:stockout-forecast, /omisell:reorder-plan or /omisell:dead-stock-decision.
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
