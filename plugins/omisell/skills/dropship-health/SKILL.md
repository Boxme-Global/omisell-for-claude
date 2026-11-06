---
name: dropship-health
description: Health check for a shop that fulfils dropship orders for resellers - orders past their fulfilment or shipping SLA, orders that failed to reach the fulfilment provider (3PF), volume per reseller, and (owner only) shipped orders the resellers have not settled yet. Use when the user says "dropship có vấn đề gì", "đơn dropship trễ SLA", "đẩy 3PF lỗi", "sản lượng dropship theo reseller", "reseller còn nợ tiền dropship", "ดรอปชิปมีปัญหาไหม", "ออเดอร์ดรอปชิปล่าช้า", "dropship health", "dropship SLA breaches", "dropship volume by reseller".
---

# Omisell: dropship health

Goal: show a shop that fulfils dropship orders for resellers which of those orders are late or stuck, which resellers send the most, and how much they still have to settle, so the shop clears its own backlog first.

The Omisell dropship tools report the dropship orders this business FULFILS AS THE VENDOR: each order comes from a reseller, and `vendor_id` on a row is only the reseller's own record of this business. Speak from that side ("orders you fulfil for resellers"), never "your vendors".

## Steps

Each tool filters on a different date, so each gets its own window (unix seconds, max 90 days). Volume uses the user's period, default the last 7 days.

1. **Gate.** `vendor_dropship_volume` with `date_from`, `date_to` (the period) and `group_by: ["reseller"]`. If `total_orders` is 0, try once more with the last 30 days. Still 0 → say this business fulfils no dropship orders in that period (dropship is a Philippines-only product today) and stop; do not call the other tools.
2. `dropship_sla_breach` with `breach_type: "fulfill"` and a CREATED window of the last 30 days (`date_from` = now − 30 d, `date_to` = now), whatever the user's period: it only sees orders created in its window, and the oldest late orders are the ones to clear.
3. `dropship_sla_breach` with `breach_type: "shipped"`, same 30-day created window.
4. `dropship_3pf_push_failures` with the defaults (`min_retry` 2). It always looks at orders created in the last 7 days.
5. `dropship_settlement_aging` with a SHIPPED window of the last 90 days (`date_from` = now − 90 d, `date_to` = now), so every age band can fill. These are shipped orders the resellers have not settled with this business yet. It is owner-only: if refused, say "Only the shop owner can see dropship settlement" and finish with steps 1-4.
   - If the result carries `warning` / `settlement_records_found: 0`, there are no settlement records at all in Omisell: report that, NOT the buckets as money owed.

6. **Orders by status (only when the user asks for it, in place of steps 2-4 to stay within budget).** `aggregate_dropships` with `date_from`, `date_to` (order created, max 90 days) and `group_by: ["status"]`. Returns `total` and `by_status` rows of `key` (status code) and `count`. Name the codes: 100 New, 110 Awaiting label, 120 Label generated, 150 Out of stock, 200 Picking, 215 Processing at warehouse, 220 Ready to ship, 260 Courier refused pickup, 300 Shipped, 400 Cancellation requested, 600 Returned, 700 Cancelled by seller, 701 Cancelled by operator, 702 Cancelled by partner, 703 Cancelled by system, 704 Cancelled by warehouse, 708 Cancelled (items lost at 3PF). Any other code: say "other status" without the number.

## Answer

- Summary: dropship orders fulfilled for resellers in the period, how many created in the last 30 days are now past SLA (fulfil / ship), how many failed to reach 3PF in the last 7 days, and (owner) shipped orders resellers have not settled for 30+ days.
- Resellers: the volume rows carry ids only, so rank resellers by order count ("reseller 1, 2, 3 by volume"); when a late or failed sample carries `reseller_name`, use that name instead. Table: Reseller · Orders · Total fee · Total COD.
- Late orders: tracking code · Reseller (`reseller_name`) · Store (`store_name`, this business's own store) · Late to (fulfil / ship) · Due (date/time in the business time zone) · Handling (`fulfill_type` 1 = fulfil now, 2 = normal) · Status (`label`), overdue longest first, top 10, plus `total`. Say the list covers orders created in the last 30 days.
- 3PF failures: tracking code · Reseller · Retries (`number_3pf`) · Created, most retries first, plus `total`.
- Settlement (owner): Age band (0-7 / 8-15 / 16-30 / 30+ days) · Orders · Amount not yet settled. Say it covers orders shipped in the last 90 days; older ones are not counted.
- When a name field is missing, say "a reseller" / "your store" rather than an id.
- Next: clear the late orders first (oldest due first); re-push failed orders from the Dropship screen in Omisell; follow up the reseller with the oldest unsettled orders; parcels stuck after handover → `/omisell:stuck-shipments`.

## Do not

- Do not call the resellers "vendors", and do not present this business as the reseller.
- Do not re-push to 3PF or change dropship orders from this skill; it only reads.
- Do not show vendor, reseller, store or warehouse ids, or raw status numbers.
- Do not present unsettled buckets as money owed when the tool warns there are no settlement records.

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
