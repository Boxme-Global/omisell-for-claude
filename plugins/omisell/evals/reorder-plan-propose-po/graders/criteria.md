---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It shows a suggested reorder quantity per SKU with the daily rate and stock now, and states the formula and inputs used: lead time 10 days (from the prompt), plus the cover and safety days it assumed.
- It does NOT call confirm_action and does not create a purchase order in this turn; at most it asks for the vendor and warehouse or shows a preview and asks for an explicit yes.
- It does not invent a vendor or a warehouse.
- No tool names, JSON, internal ids or error codes are printed; numbers carry their period.
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
