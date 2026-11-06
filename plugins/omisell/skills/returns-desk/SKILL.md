---
name: returns-desk
description: Return slips that need action - where returns sit in the pipeline, how long open ones have waited, which buyer requests to confirm, and marking Boxme-warehouse returns as received, with a preview before any change. Use when the user says "đơn hoàn cần xử lý", "phiếu hoàn tồn bao lâu", "xác nhận hoàn hàng", "hàng hoàn đã về kho", "yêu cầu trả hàng mới", "คืนสินค้าที่ต้องจัดการ", "ยืนยันการคืนสินค้า", "ของคืนถึงคลังแล้ว", "returns to process", "open returns aging", "confirm return requests", "mark returns received".
---

# Omisell: returns desk ✍️

Goal: the CS team sees which returns need them today, oldest first, and can confirm requests or mark received returns in one go.

## Steps

Default window: return slips created in the last 7 days (unix seconds, max 90). A return opened earlier is not counted: when the user asks about long-open returns, use 30 days and say so.

1. **Pipeline.** `return_pipeline_state` with `date_from`, `date_to` (both required), `group_by="status"`. Returns `total` and `rows` of `{key, count}` where `key` is a raw return status code: name it with the status list in step 3, never print the code. The true open count is the sum of the rows other than Returned (800) and Cancelled (700). Add `group_by="channel"` in a second call only if the user asks which channel.
2. **Aging.** `return_aging_summary` with the same window, `limit=20`. Counts the non-final returns (not Returned, not Cancelled) by time since their last status change: `0-1d`, `1-3d`, `3-7d`, `7d+`, and lists the oldest first (code, status, warehouse receiving status, age in days). It reads at most the 200 longest-waiting returns. If `total_non_final` is 200, the cut can fall inside any bucket: a bucket is complete only if a YOUNGER bucket has a count above 0; every other bucket is a lower bound, written "at least N" (also in the "older than 3 days" summary). If every younger bucket is 0, say the aging is cut off at 200. Take the open total from step 1 and offer a narrower window.
3. **Drill into one status, only when needed.** `list_order_returns` with the window, `statuses=[…]` and `limit=50`. Return status codes: 100 Requested, 110 Judging, 150 Accepted, 200 Seller dispute, 300 Processing, 800 Returned, 700 Cancelled. Warehouse receiving filter `inbound_status`: `returning`, `awaiting_to_receive`, `received`, `checking`, `checked`, `on-hold`, `problem`. Returns code, status, refund, channel, times, `total` and `truncated`.
   - Buyer requests to answer → `statuses=[100, 150, 200]`.
   - Goods back but stuck at the warehouse → `inbound_status=["problem", "on-hold"]`.
4. **One return in detail** → `order_return_detail` with `return_code=<code>` (reason, refund, NMV, what the warehouse received per SKU).

## Writes

Two write tools, both take `return_tracking_codes` (Omisell return codes `RTN…`, or the channel's return code). At most 200 per action; one action per preview.

| Action | Tool | Works on |
|---|---|---|
| Confirm buyer return requests (sent to the marketplace) | `confirm_returns` | status Requested, Accepted or Seller dispute; any other status fails when it runs |
| Mark returns received at the fulfilment warehouse | `mark_returns_received` | returns handled by the Boxme / 3PF warehouse only; others fail when it runs |

1. Build the list from step 3. For `confirm_returns`, filter by status first so the preview holds only returns that can succeed. For `mark_returns_received`, no list shows which returns go through the Boxme / 3PF warehouse: say in the preview that the others will fail when it runs (one return can be checked with `order_return_detail`). Show count + codes and get the user's agreement to the set.
2. Call the write tool. It changes nothing; it returns `request_id`, `confirm_token` and a preview: `items` (will be sent), `skipped` with `reason` (`out_of_scope`, `not_found`). `no_eligible_returns` → show the skipped list, stop.
3. Show: action, how many, up to 10 codes (+N more), every skipped code with its reason, and for `confirm_returns` that the confirmation is sent to the marketplace. Ask yes / no.
4. Only on an explicit yes to this preview in the user's latest message → `confirm_action` with `request_id` + `confirm_token`, then `get_action_status`. Report succeeded / failed per return with the reason.
5. The write tool returns a status instead of a preview (no `confirm_token`: the same request already exists) → report that status, do not confirm. `token_expired` / `invalid_or_used_token` → call the write tool again and re-show. `already_handled` → read `get_action_status`. `write_disabled` → the house-rules "changing data is not enabled" text. `insufficient_permission` or `permission_denied` → "This needs the permission to process returns in Omisell. Ask the shop owner." Write tool not in the list → do it on the Returns screen in Omisell (tick the slips, use the action button).

## Answer

- Summary: open returns in the window, how many are older than 3 days, how many buyer requests wait for an answer.
- Table: status, count (from the pipeline); then the 5-10 oldest open returns: code, status label, warehouse receiving status, age in days.
- Window under each number ("returns created 31/10-06/11/2026").
- Next: confirm waiting requests (this skill, with preview), dispute a return you disagree with → `/omisell:return-dispute`, refund impact → `/omisell:revenue-report`.

## Do not

- Do not confirm a return the user wants to dispute; send them to `/omisell:return-dispute` instead.
- Do not mix the two write tools in one yes.
- Do not show the buyer's phone, address or email.

<!-- omisell:house-rules:start (generated by scripts/skills.py sync; edit shared/house-rules.md) -->
## Omisell house rules (apply to every step of this skill)

**Data source.** Every number comes from an Omisell MCP tool call in this conversation. Tools are named here by their bare name (`sales_summary`); the client may show them with a prefix. Never invent an order code, SKU, amount or cause. If no Omisell tool is available at all, say the Omisell connector is not connected and stop.

**One business per answer.** If `list_my_businesses` is available and returns more than one business, ask which one before any other call (show company name + country), then pass that `business_id` on every call. Never mix data across businesses. A result `business_required` means you forgot it: ask, do not guess.

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
