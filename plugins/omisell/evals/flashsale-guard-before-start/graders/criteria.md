---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It reports flash sale items whose price is at or below the warning threshold of the normal price (or says there are none), with SKU, normal price, flash price and discount.
- For stock it reads the flash sale's own items (registered, sold, remaining, quantity not held for lack of stock) without asking the user which SKUs to check, uses the quantity available to ship now (not incoming), checks only a few SKUs, and offers to check the rest only when some SKUs were left unchecked (checking every SKU of a small sale is fine).
- It does not ask the user for SKUs or for a flash sale id.
- It does not change a price or switch a flash sale off; it points to the Flash sale screen in Omisell.
- It presents a deep discount as a warning for the seller to confirm, not as a certain mistake.
- No tool names, JSON, internal ids or error codes.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
