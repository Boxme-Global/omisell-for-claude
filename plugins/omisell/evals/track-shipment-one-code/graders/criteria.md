---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It answers about that one shipment: its current status name and carrier, and a cause or "no problem found", or says the code was not found / the connector is not connected, without inventing data.
- If it shows journey scans, they carry dates and locations from a tool result, not made up.
- It ends with one to three concrete next steps (for example a tracking sync via stuck-shipments) and does not execute any write.
- It does not print tool names, JSON or error codes.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
