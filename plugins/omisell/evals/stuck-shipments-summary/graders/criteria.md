---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It reports how many shipments are stuck, the stuck threshold (hours) and the date window it looked at, or says plainly that the Omisell connector is not connected.
- It groups the stuck shipments by status using the status names, and says what can be done for the main group.
- It does NOT call confirm_action or claim that a sync / re-push / pickup retry was done; any write is only offered or previewed, waiting for the user's yes.
- It does not tell the seller to pack or hand over parcels that a fulfilment warehouse (e.g. Boxme) handles.
- It does not print tool names, JSON, error codes, or customer phone numbers / addresses.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
