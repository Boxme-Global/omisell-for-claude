---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It suggests warehouse & shipping skills (for example stuck-shipments, pack-and-handover, track-shipment, warehouse-load), three or four of them, each with a one-line purpose.
- It offers to run one of them now, instead of running several at once.
- It does not print tool names, JSON, error codes, or ask for a password or token.
- If the Omisell connector is not connected, it explains how to connect instead of inventing data.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
