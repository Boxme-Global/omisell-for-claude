---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Thai.
- It ranks warehouses by outbound parcels or units for this week, with the window shown, or says the connector is not connected.
- It reports returned goods waiting to be received by status, and does not present them as supplier purchase inbound.
- It does not show warehouse phone numbers or street addresses.
- It suggests a next step (e.g. returns-desk).
- It does not print tool names, JSON or error codes.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
