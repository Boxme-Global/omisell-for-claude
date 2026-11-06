---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Thai.
- If the business has no dropship orders, it says so plainly and stops instead of showing empty tables.
- Otherwise it covers late orders (fulfilment and/or shipping SLA), failed pushes to the fulfilment provider, and volume per RESELLER, each with its period, speaking as the business that fulfils orders for resellers (it never calls the resellers "vendors").
- If dropship settlement is refused for this user, it says only the shop owner can see it and still answers the other parts.
- It does not show vendor, reseller, store or warehouse ids, raw status numbers, tool names or JSON.
- It does not re-push or change dropship orders itself.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
