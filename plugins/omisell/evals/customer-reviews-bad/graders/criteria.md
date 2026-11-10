---
type: llm
weight: 1
---

Pass only if ALL hold:
- The reply is in Vietnamese.
- It lists unanswered 1-2 star reviews (stars, product or SKU, short text, date, store) with the window stated, or says there are none / the business has no Shopee or Lazada store.
- It drafts replies that are specific to each review, polite, under 500 characters, with no refund promise and no buyer contact details.
- It does not post any reply (no confirm_action) without the user's explicit yes to the exact reply text.
- It does not trigger a review sync unless the user asked for a refresh.
- It does not list buyer names in a table and does not print tool names or JSON.
- A next-step suggestion written as `/omisell:<skill>` is allowed: it is a skill the user can run, not an internal tool name.
