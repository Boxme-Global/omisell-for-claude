---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It looks up that single order code and either explains its current status with a reason taken from the tools, or says the code was not found in this business and asks to check it.
- If found, it shows a short timeline (a few events with dates in the business time zone) rather than the whole activity log.
- It names one concrete next action matched to the cause (for example create the shipment, or check the parcel with track-shipment).
- It does not invent a cause, a deadline or an order code that the tools did not return.
- It does not print tool names, JSON or internal ids.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
