---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Thai.
- It reports Shopee penalty points (total and sources) and ongoing punishments, or clearly says there are none or that the shop's data could not be read.
- It lists metrics that are off target or worse than the previous period, using the metric names and numbers the tool returned, without inventing a target.
- If several shops exist and none was named, it asks which shop (or reads at most a few) instead of guessing; channels without health data are named as unsupported.
- It ends with one to three concrete next actions; no tool names, JSON or raw error codes.
- If the Omisell connector is not connected, it says so instead of inventing numbers.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
