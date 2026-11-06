---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in English.
- It reports flash-sale price warnings (count, and for the top items: SKU, normal price, flash price, discount) or clearly says there are none.
- For the product's price movement it states the period (about 30 days, with dates) and compares price with orders per day; it does not claim the price "did not change" for a listing that has no listed-price history, and it treats change dates as approximate.
- It does not attribute a sales change to the price without saying it is a signal, not proof.
- Money is shown in the store's currency; no tool names, JSON or internal ids.
- If the Omisell connector is not connected, it says so instead of inventing prices.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
