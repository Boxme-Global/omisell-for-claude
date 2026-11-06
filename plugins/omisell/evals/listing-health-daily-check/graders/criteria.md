---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It reports listings with zero stock ON THE CHANNEL separately from listings not linked to a warehouse SKU, each with a count, and it does not present warehouse stock or "running out soon" as "out of stock on the channel".
- It says how many listings were checked (or that only the newest ones were checked) instead of implying the whole catalogue was scanned when it was not.
- It gives the date the check was made, and ends with one to three next actions that name an Omisell skill (for example sync-stock-price or sku-lookup).
- It does not print tool names, numeric listing ids, JSON or raw error codes (SKUs and product names are fine); a refused part is explained in plain words and the rest is still answered.
- If the Omisell connector is not connected, it says so instead of inventing listings.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
