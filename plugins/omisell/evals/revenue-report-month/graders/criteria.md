---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in English.
- It gives NMV with order count and refunded NMV with return count for last month, stating the date basis (completion date by default).
- It does not present sales NMV minus return NMV as an official net revenue figure.
- If it mentions gross or net revenue, it says the revenue screens report NMV and points to gross margin for net sales.
- It does not print tool names, JSON, error codes, permission rule codes or internal ids (store, carrier, warehouse ids).
- If the Omisell connector is not connected, it says so instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
