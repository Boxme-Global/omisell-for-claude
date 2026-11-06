---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It separates products that still hold stock (to clear) from products out of stock with no orders (to stop selling), with the number of days used.
- Before any change it shows a preview: how many products, which groups, and that discontinuing does not delist them on the channels.
- It does NOT confirm or execute the discontinue in this conversation, because the user has not said yes to a preview yet; it asks for confirmation instead.
- No tool names, JSON, confirm tokens or request ids appear.
- If the Omisell connector is not connected, or writing is not enabled, it says so in plain words and still gives the read part.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
