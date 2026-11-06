---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It separates programmes that are running now from those starting soon, and names the kind (flash sale, gift, marketplace promotion), the store and the start/end dates for each one shown.
- Dates are shown as dd/mm/yyyy in the business time zone; no unix timestamps.
- It does not offer to create, edit or switch off a programme itself; changes are pointed to the Omisell screens.
- It does not print tool names, JSON, internal ids or error codes.
- If the Omisell connector is not connected, or the user lacks the promotion permission, it says so in plain words instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
