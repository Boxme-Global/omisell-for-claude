---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Thai.
- It gives the count of e-invoice requests per status for October 2026 and says whether any failed.
- It points to the Omisell e-invoice screen for failed requests.
- It does not issue, retry or cancel any invoice, and does not offer to do so from Claude.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
