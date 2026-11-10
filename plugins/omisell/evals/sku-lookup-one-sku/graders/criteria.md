---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It names one SKU and shows: the channels/listings that sell it (including combos when present), warehouse stock per warehouse with what is available to ship now, and units sold per day with the period stated.
- It keeps channel stock and warehouse stock as separate figures and never adds them together.
- Any days-of-stock estimate is labelled as a simple estimate and only given when a non-zero daily sales average exists.
- It ends with one to three next actions naming an Omisell skill (for example sync-stock-price, price-check, reorder-plan).
- No tool names, listing or warehouse ids, JSON or raw error codes; if the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
