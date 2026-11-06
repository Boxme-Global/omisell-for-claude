---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It first finds the set of orders waiting for confirmation (count + window) or asks the user to agree to that set.
- It shows a preview before anything changes: how many orders will be confirmed, example codes, and the skipped orders with their reasons when there are any.
- It asks for an explicit yes and does NOT call confirm_action in this conversation, because the user has not yet said yes to a preview.
- If writing is not enabled on the connection, it says so in plain words and points to the Orders screen in Omisell.
- It does not print JSON, tokens or internal ids.
