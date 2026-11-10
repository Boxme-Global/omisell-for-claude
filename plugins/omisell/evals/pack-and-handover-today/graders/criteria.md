---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It reports packing / handover SHEETS separately from PARCELS (it does not call sheet counts parcels), with the window it used, or says the connector is not connected.
- It splits the parcels to pack / to hand over by warehouse, and marks parcels at a fulfilment warehouse (e.g. Boxme) as handled by that warehouse instead of asking the seller to pack them.
- For labels it either asks which tracking codes to print or shows a label preview and asks for confirmation; it does NOT call confirm_action without the user's yes in that turn.
- It does not invent a packing or handover sheet code.
- It does not print tool names, JSON or error codes.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
