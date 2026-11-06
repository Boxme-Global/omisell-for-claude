---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It states the 30-day period with dates.
- It compares the channels on sales and at least two of: cancel rate, returns, marketplace fees, delivery speed.
- It does not rank on sales alone when fees, cancels or returns change the picture.
- If sales by store is refused, it says that view needs the shop owner in plain words and still compares what it can.
- No tool names, JSON, internal ids or platform codes such as shopee_v2 appear.
- If the Omisell connector is not connected, it says so instead of inventing numbers.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
