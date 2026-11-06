---
name: stuck-shipments
description: Find shipments stuck at one status (not picked up, not moving, not received by the fulfilment warehouse), explain where they stalled, and fix them with a tracking sync, a re-push to the fulfilment warehouse or a pickup retry after the user confirms. Use when the user says "vận đơn kẹt", "đơn chưa lấy hàng", "hãng chưa tới lấy", "đơn nằm im mấy ngày", "đẩy lại kho", "gọi lấy lại hàng", "พัสดุค้าง", "ขนส่งยังไม่มารับ", "stuck shipments", "not picked up", "parcels not moving".
---

# Omisell: stuck shipments

Goal: the user knows how many parcels are stuck, at which step and with which carrier, and unblocks the ones that can be unblocked from Claude.

## Steps

1. **Summary.** `find_stuck_shipments_summary` with `period: "last_30_days"` (or the user's window; max 90 days). The window filters on the shipment's creation date; the default of 7 days misses older parcels, so say which window you used. Returns `total`, `by_status` (`status`, `label`, `count`), `samples` (up to 10 tracking codes, newest change first) and `stuck_hours_threshold`.
   - Report the threshold the result gives back. Do not promise another one: on the current server a different `stuck_hours` is not applied.
   - `total` 0 → say nothing is stuck for that window and stop.
2. **Who carries them.** If the user asks "which carrier" or one status dominates, call `aggregate_shipments` with the same window, `statuses` = the stuck status codes from step 1, `group_by: ["courier", "pickup"]`. `by_courier` is the real carrier, `by_pickup` keys are warehouse ids. This counts every parcel currently at those statuses, not only the stuck ones; say so. Only when you show the warehouse split, map ids to names with `list_pickup_addresses` with `limit` 200 and no `is_active` filter (a parcel can sit in a warehouse deactivated since). An id with no match, or a `truncated` list, shows as "another warehouse", never as a bare id.
3. **One parcel looks odd** → `diagnose_shipment_issue` with its `tracking_code` (at most 3 per turn). Use its cause and next actions; for anything deeper hand over to `/omisell:track-shipment`.

## Reading the statuses

Group the `by_status` rows into what the user can do (codes are what the tools return; show the `label`):

| Group | Codes | What helps |
|---|---|---|
| Pickup failed / refused | 201, 250, 260, 265 | pickup retry (marketplace-booked parcels) |
| Waiting for label / courier | 100, 101, 102, 120 | check the channel; diagnose one sample |
| Waiting to be packed / processed | 200, 205, 211, 213, 215, 216 | own warehouse: pack it (`/omisell:pack-and-handover`); fulfilment warehouse: re-push if it never received it |
| Out of stock | 150 | restock; nothing to retry |
| Moving but no new scan | 300, 305, 310, 315, 320, 350 | tracking sync, then the carrier |
| Exception / cancel requested | 777, 400 | handle in Omisell, diagnose one sample |
| Driver being assigned | 225 | wait or follow up with the carrier; diagnose one sample |
| Lost by the carrier | 317 | follow the compensation claim with the carrier |
| Returning to the seller | 500, 501, 510, 520 | nothing to retry here; returns → `/omisell:returns-desk` |

Any other code: describe it by its `label` only, with no suggested action.

Who packs depends on the warehouse. Read `fulfillment_provider` as: `merchant` or empty = the seller's own warehouse (the seller packs); `self` = fulfilled by the marketplace or a partner (FBS, FBL...: the marketplace packs); `vendor` = a dropship vendor; `boxme` or any other provider code = a fulfilment warehouse (3PF) that packs and hands over itself. Show "own warehouse" / "marketplace" / "vendor" / the provider name, never the raw code. For marketplace or 3PF warehouses never tell the seller to pack or hand over; for a 3PF the fix is a re-push or a ticket with that warehouse.

## Answer

- Summary: how many parcels are stuck, the threshold, the window, and the biggest group.
- Table: status label · count · what helps, biggest first; then the carrier split if fetched (top 5).
- Next: the one or two actions that fit the biggest groups, with the sample codes they would apply to. Suggest `/omisell:track-shipment` for one parcel, `/omisell:courier-scorecard` when one carrier dominates.

## Writes

Which codes: only codes from this conversation (step 1 `samples`, a diagnose result, or codes the user pasted). There is no tool here that lists every code at a status; for more than the samples, ask the user to paste the codes from the Omisell Shipments screen (max 200 per action).

| Action | Preview first | Then propose | Rule |
|---|---|---|---|
| Sync tracking from the carrier | `dry_run_sync_shipments_tracking(tracking_codes)` | `sync_shipments_tracking(tracking_codes)` | safe on any in-scope code |
| Re-push to the fulfilment warehouse | `dry_run_push_shipments_to_3pl(tracking_codes)` | `push_shipments_to_3pl(tracking_codes)` | only codes in `eligible`; the warehouse has not received them |
| Ask the channel to pick up again | `dry_run_retry_ship_pickup(tracking_codes)` | `retry_ship_pickup(tracking_codes)` | only codes whose status is a pickup failure (201, 250, 260, 265); `samples` carry no status, so confirm each by a diagnose call or the user's own list first |

Flow for each action, one action at a time:
1. Call the `dry_run_*` tool. Show `eligible`, and also `ineligible` / `out_of_scope` / `not_found` with a count and the codes, so the user sees what will be left out.
2. Call the verb with the eligible codes only. Show its preview (summary, items, `skipped`). Ask for a yes.
3. Only on a clear yes to that preview in the user's latest message: `confirm_action(request_id, confirm_token)`.
4. `get_action_status(request_id)` and report succeeded / failed per code. If still running, say so and offer to check again.

Write tool missing from the tool list → say changing data is not enabled on this connection, and point to Omisell → Shipments (select the parcels → Sync tracking / Push to warehouse / Retry pickup).

## Do not

- Do not call a write verb before its dry run, or propose two actions under one yes.
- Do not retry pickup on parcels that are already moving, delivered or at a fulfilment warehouse.
- Do not loop `diagnose_shipment_issue` over every sample.
- Do not invent tracking codes from a carrier name or a status.

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
