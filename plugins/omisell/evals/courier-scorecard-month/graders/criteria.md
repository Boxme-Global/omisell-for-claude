---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in English.
- It states the period it used (last month, with dates) next to the numbers.
- It compares carriers on delivery success rate and on delivery time, and gives a return / failed-delivery rate, or says plainly that the connector is not connected.
- It names carriers as the tools return them and flags carriers with too few parcels to rank.
- It suggests a next step (e.g. shipping rules, stuck-shipments).
- It does not print tool names, JSON, revenue figures or error codes.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
