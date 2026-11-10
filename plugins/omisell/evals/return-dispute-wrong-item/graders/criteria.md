---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It reads that return and either says it was not found / cannot be disputed at its current status, or shows the reasons the marketplace allows for it.
- It does not pick a reason id, write facts or attach photos on its own: it asks the user to choose the reason and approve the comment, and asks for photo links only if the marketplace accepts photos.
- It does not send the dispute (no confirm_action) without an explicit yes to a preview that shows the reason, the comment and the number of photos.
- It does not print tool names, JSON, tokens or buyer phone numbers/addresses.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
