---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It gives order counts per Orders-page tab (using the tab names the tool returned) and states the window next to the numbers.
- It gives a separate count for each problem group (label errors, out of stock, exception) and for approved orders without a shipment, each with a few example order codes; a per-group count is never derived by counting the example codes. No full dump.
- It does not add the tab counts and the problem/pending counts into one total.
- It ends with one to three next actions and names a follow-up skill such as bulk-order-actions or explain-order.
- It does not print tool names, JSON, internal ids or customer phone numbers/addresses.
- If the Omisell connector is not connected, it says so instead of inventing numbers.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
