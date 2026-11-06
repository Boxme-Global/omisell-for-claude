---
name: customer-reviews
description: Product reviews on Shopee and Lazada - unanswered reviews, low ratings, what buyers complain about, and a drafted reply posted only after the user approves it. Use when the user says "đánh giá chưa trả lời", "đánh giá xấu", "review 1 sao", "trả lời đánh giá", "khách chê gì", "รีวิวที่ยังไม่ได้ตอบ", "รีวิวแย่", "ตอบรีวิว", "unanswered reviews", "bad reviews", "reply to reviews", "what are customers complaining about".
---

# Omisell: customer reviews ✍️

Goal: CS sees which reviews still need a reply, worst first, and posts good replies without leaving Claude.

Reviews exist only for Shopee and Lazada stores. TikTok, website and other channels have none in Omisell: say so if the user asks about them.

## Steps

1. **Unanswered, bad first.** `list_reviews` with `replied=false`, `limit=50`. Default window: reviews rated in the last 30 days (`rated_from` / `rated_to` in unix seconds, max 90 days); say the window. Returns `reviews` (newest first: `review_id`, `store_id`, `store_name`, `platform`, `rating`, `content`, `images`, `rated_at`, `product` name + SKU, `order` code, `reply`, `last_reply_failed`), `count`, `truncated`, and a `note` when the business has no Shopee / Lazada store.
   - "bad reviews" → add `ratings=[1, 2]` (and 3 if the user says "under 4 stars").
   - only reviews with words → `has_content=true`.
   - one store → `store_ids=[…]` (store ids come back in the rows).
   - `truncated: true` → say there are more than shown and offer a narrower window or rating.
2. **Freshness.** The list is as fresh as Omisell's last pull. Call `request_review_sync` with `store_id` ONLY when the user asks to refresh or says a review they see on the marketplace is missing: it spends the shop's marketplace API quota. One store per call, once per 15 minutes; `queued: false` with `retry_after` is not an error, say when to try again. New reviews appear in `list_reviews` a few minutes after `queued: true`.
3. **What buyers complain about** (if asked): group the low-rating `content` into 3-5 themes (late delivery, wrong item, quality, packaging…) with a count and one short quote each. Base themes only on the review text returned.

## Writes

`reply_review` posts ONE reply to ONE review: `store_id`, `review_id` (both from `list_reviews`), `text` 1-500 characters.

1. Draft the reply in the language of the review, polite, specific to what the buyer wrote, under 500 characters. No promises of refunds or compensation the user did not approve, no buyer phone / address / email, no links. Show the draft and let the user edit it.
2. Call `reply_review` with the approved text. It changes nothing; it returns `request_id`, `confirm_token` and a preview with the exact text. Errors: `already_replied` (a reply exists, maybe posted on the seller centre: skip it), `review_not_found`, `invalid_text` (empty or over 500 characters: shorten).
3. Show the store, the stars, the review in one line and the exact reply. Ask yes / no. Only on an explicit yes to THIS reply in the user's latest message → `confirm_action`, then `get_action_status`.
4. Outcome: `succeeded` → posted, visible on the marketplace and the Omisell Reviews screen. `platform_rejected` → the marketplace refused; say so. `outcome_unknown` → do NOT reply again; call `request_review_sync` for that store, wait a few minutes, check with `list_reviews` (`review_ids=[…]`) whether the reply landed. `reply_in_progress` (another reply to this review is still running) or `lock_unavailable` → do not resend; wait a few minutes, then check with `list_reviews` (`review_ids=[…]`).
5. Several reviews → one draft, one preview, one yes each. Never post a batch behind one yes. `reply_review` returns a status instead of a preview (no `confirm_token`) → report it, do not confirm. `token_expired` / `invalid_or_used_token` → call `reply_review` again and re-show. `write_disabled` → the house-rules "changing data is not enabled" text. `insufficient_permission` or `permission_denied` → "Replying needs the customer review permission in Omisell. Ask the shop owner." `reply_review` missing from the tool list → reconnect the Omisell connector and tick the review reply permission, or reply on the Reviews screen in Omisell.

## Answer

- Summary: unanswered reviews in the window, how many are 1-2 stars, the store with the most.
- Table: stars, product / SKU, review text (shortened), date, store. Worst first, then oldest among the reviews fetched (the tool returns the newest ones; with `truncated: true` older unanswered reviews were not fetched, so say so or narrow by `ratings`), top 10 (+N more). `last_reply_failed: true` → mark "previous reply failed".
- Next: offer drafts for the top 3 low ratings; for a review about a late or wrong order → `/omisell:explain-order` with its order code; a pattern of quality complaints → tell the owner which SKU.

## Do not

- Do not list buyer names in tables; use the name only inside a reply draft when the user wants it.
- Do not call `request_review_sync` on every run.
- Do not post a reply the user has not read in full.

<!-- omisell:house-rules:start (generated by scripts/skills.py sync; edit shared/house-rules.md) -->
## Omisell house rules (apply to every step of this skill)

**Data source.** Every number comes from an Omisell MCP tool call in this conversation. Tools are named here by their bare name (`sales_summary`); the client may show them with a prefix. Never invent an order code, SKU, amount or cause. If no Omisell tool is available at all, say the Omisell connector is not connected and stop.

**One business per answer.** If `list_my_businesses` is available and returns more than one business, ask which one before any other call (show company name + country), then use that `business_id` on every call. Never mix data across businesses. A result `business_required` means you forgot it: ask, do not guess.

**Permissions.** Some calls are refused for this user. Translate, never print the raw error:
- `missing_permission` (read tools, with `required_rules`) or `insufficient_permission` (write proposals, with `required_rule`) → "This needs the <area> permission in Omisell. Ask the shop owner to grant it." Name the area in plain words, not the rule code.
- an owner-only tool refused, or `not_permitted_on_business` → "Only the shop owner can see this." Then use the fallback the skill names, if any.
- a write tool absent from the tool list → "Changing data from Claude is not enabled on this connection. Reconnect the Omisell connector and tick the write permission, or do it in Omisell: <screen>." Still finish the read part.
- a timeout → say that part took too long, offer a narrower period or fewer items, and keep the parts that worked.
Run what you can; one refused tool never ends the whole answer.

**Writes: preview, confirm, check.** Write tools only PROPOSE: they return a preview, a `request_id` and a one-time `confirm_token`. Show the preview (what changes, how many items, anything blocked). Call `confirm_action` only when the user clearly says yes to THAT preview in their latest message. Then call `get_action_status` and report succeeded / failed items. Never confirm on the user's behalf, never reuse an old token, never batch two previews into one yes. Prefer a `dry_run_*` tool first when one exists; when none does, the write tool's own proposal is the preview. If `confirm_action` answers `token_expired` or `invalid_or_used_token`, propose again and show the new preview; `already_handled` means read `get_action_status`; `batch_too_large` means split into batches of at most 200; `write_disabled` means writing is off for this business (say so, point to the Omisell screen); `permission_denied` is the permission refusal above, re-checked at confirm time (if the user is the owner, the connection lacks this write permission: reconnect and tick it); `not_found` means the request is gone: propose again; `audit_unavailable` means nothing was changed: say it did not start and offer to propose again later; `dispatch_failed` means it most likely did not start: ask the user to check the Omisell screen before proposing again, so the change is never applied twice. A status reply where you expected a preview means the same change was already proposed or done: report that status, do not confirm.

**Time and money.** Tools speak unix seconds. Show dates in the business country's time zone (VN, TH: UTC+7; PH: UTC+8) as dd/mm/yyyy. Money stays in the store's own currency with its symbol. Every number carries its period ("7 days to 05/11/2026"). When the user gives no period, use the skill's default (the last 7 days unless the skill says otherwise) and say so; do not ask first. Respect each tool's longest window (often 31 or 90 days): split or shorten, and say which.

**Language.** Reply in the user's language (Vietnamese, Thai or English), including table headers. When the user has written nothing to go by (only a slash command), use the business country's language: VN → Vietnamese, TH → Thai, otherwise English. The country comes from `list_my_businesses`; when that tool is absent, read it once per conversation from `store_detail` (any store id from `list_stores` with `limit` 1) or `pickup_address_detail` (any id from `list_pickup_addresses` with `limit` 1); list rows carry no country. With no source at all, use the user's interface language if known, else English. Take status names from the tools' `label`, never from a code. Labels and `note` texts come in the Omisell account's language, which can differ from the reply language: translate them into the reply language (e.g. "On processing" → "Đang diễn ra", "Upcoming" → "Sắp diễn ra"). When a tool returns a bare status code with no label, use the name the skill gives for it; if the skill gives none, describe the state in words instead of printing the number.

**Answer shape.**
1. One or two sentences that answer the question.
2. The numbers: a short table or list, top items only (say how many more).
3. What to do next: one to three concrete actions, plus the Omisell skill that does it (`/omisell:<skill>`).

**Privacy and internals.** Never show customer phone numbers, addresses or emails unless the user asked about one specific order. Never show table names, SQL, internal ids, tool names or JSON. (A `/omisell:<skill>` next-step suggestion is not a tool name; keep it.) Order codes, tracking codes and SKUs are fine.

**Budget.** At most about 6 tool calls per turn. Prefer one aggregate tool over a loop of per-item calls. If the question needs more, answer the core first and offer the rest.
<!-- omisell:house-rules:end -->
