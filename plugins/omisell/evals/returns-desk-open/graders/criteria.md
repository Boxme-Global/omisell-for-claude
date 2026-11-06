---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It gives counts of returns by status and the open returns by age (for example 0-1d, 1-3d, 3-7d, 7d+) with the window stated.
- It lists the oldest open returns with return code, status and age.
- It suggests next actions such as confirming waiting buyer requests (with a preview first) or disputing via return-dispute.
- It does not confirm or change any return.
- It does not print tool names, JSON, or buyer phone numbers/addresses.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
