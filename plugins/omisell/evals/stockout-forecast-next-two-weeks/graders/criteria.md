---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It lists SKUs with a daily sales rate, stock left, days left and an expected stock-out date, soonest first, and marks those running out within 14 days.
- It states the assumptions: the sales window (e.g. 28 days to a date), how the daily rate was computed, and that stock is sellable stock (held stock subtracted, incoming not counted).
- It does not claim a per-warehouse sales forecast; per-warehouse figures, if shown, are only where stock sits.
- Every number carries its period or "as of" date; no tool names, JSON, internal ids or error codes are printed.
- It suggests a next step such as /omisell:reorder-plan or /omisell:purchase-tracking.
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
