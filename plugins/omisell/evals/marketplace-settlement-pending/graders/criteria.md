---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It states the period and that it filters on order creation date (October 2026, within 31 days).
- It separates money awaiting payout, money already paid out, and orders with an amount mismatch, each with an order count.
- It lists the mismatched orders by order code with expected, received and difference, or says there are none.
- It does not call the awaiting-payout amount a loss, and it does not invent a reason for a mismatch.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
