---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in English.
- It names which flash sale it measured (name, store, dates) or asks the user to pick one when several fit.
- When it reports revenue it says the flash sale revenue is an estimate (units times the current flash price).
- If it compares with before the campaign, it states both periods and gives units per day before and during; it does not judge success from estimated revenue alone.
- Every number carries its period; no campaign ids, tool names or JSON.
- If the flash sale is no longer in Omisell or the connector is not connected, it says so instead of inventing figures.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
