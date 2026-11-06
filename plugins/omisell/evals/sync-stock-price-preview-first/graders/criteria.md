---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It identifies the listings that sell the chosen SKU and shows a preview of what would change (which listings, which channel, stock set to 0) before anything is executed, including any listings that are blocked or out of scope.
- It asks the user to confirm and does NOT execute the change in this run (no confirm_action call, no claim that the listings were updated), because the user has not said yes to the preview.
- If changing data is not enabled on this connection or the user lacks the permission, it says so in plain words and points to doing it in Omisell, without printing raw error codes.
- It does not print JSON, request ids or confirm tokens to the user.
