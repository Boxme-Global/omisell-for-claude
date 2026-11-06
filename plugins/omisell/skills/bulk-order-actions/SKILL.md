---
name: bulk-order-actions
description: Confirm, cancel, create shipments for, or move to another warehouse many orders at once, always with a preview of what will and will not change before anything runs. Use when the user says "xác nhận hết đơn chờ", "huỷ các đơn này", "tạo vận đơn hàng loạt", "đổi kho cho đơn", "duyệt đơn hàng loạt", "ยืนยันออเดอร์ทั้งหมด", "ยกเลิกออเดอร์หลายรายการ", "สร้างเลขพัสดุ", "เปลี่ยนคลังสินค้า", "confirm all pending orders", "cancel these orders", "create shipments in bulk", "change warehouse for orders".
---

# Omisell: bulk order actions ✍️

Goal: the user acts on a set of orders in one go and sees, before anything changes, exactly which orders will change and which are skipped and why.

## Steps

1. **Which action.** One of four, one per preview:

   | Action | Write tool | Arguments |
   |---|---|---|
   | Confirm orders waiting for confirmation | `confirm_orders` | `order_codes` |
   | Cancel orders (not shipments) | `cancel_orders` | `order_codes`, `reason` (required) |
   | Create shipments | `create_shipments_from_orders` | `order_codes`, optional `courier_id` + `courier_service_id` |
   | Move orders to another warehouse | `change_order_pickup` | `tracking_codes`, `pickup_address_id` |

   Codes may be Omisell order codes or the channel's order numbers. At most 200 orders per action; more → split and say so.
2. **Which orders.** Use the codes the user gave. If they describe a set instead ("all orders waiting for confirmation"), collect it first with one read:
   - waiting for confirmation → `find_pending_shipment_orders` with `statuses=[250]`, `limit=200`
   - approved, no shipment yet → `find_pending_shipment_orders` with `statuses=[300]`, `limit=200`
   - label errors → `find_problem_orders` with `problem_types=["label_fail"]`, `limit=200`
   Show the count and the window (default last 7 days) and ask the user to agree to that set before the write call. If `total` > the codes returned, say how many are left out.
3. **Missing inputs, ask, never invent:**
   - cancel → ask the reason in the user's words.
   - change warehouse → `list_pickup_addresses` with `is_active=true`, show the warehouse names, let the user pick; pass that warehouse's id.
   - create shipments with a courier the user named → only an id that appears in the preview's courier choices.
4. **Preview.** Call the write tool. It changes nothing; it returns a preview with `request_id` and `confirm_token`:
   - `items`: orders that will change,
   - `skipped`: each with `reason` = `wrong_status` (status does not allow this action), `out_of_scope` (another business or a warehouse this user cannot see), `not_found`,
   - `blockers` (create shipments only): orders with no courier yet, each with its courier choices.
   - `no_eligible_orders` → nothing can change; show the skipped list with reasons and stop.
5. **Show the preview** (see Writes) and wait for the user's answer.

## Writes

- The preview the user sees: action, number of orders that will change, up to 10 codes (+N more), and ALWAYS the skipped orders grouped by reason with their codes. For cancel: the reason text and that cancelling also cancels the order's shipments and refunds. For change warehouse: the target warehouse name. For blockers: each order and its courier choices (courier + service names).
- Ask one clear question ("Confirm these 18 orders? yes / no"). Call `confirm_action` with `request_id` and `confirm_token` only after an explicit yes to THIS preview in the user's latest message.
  - Create shipments with blockers: pass the user's choice as `slot_fill` = `{"<order code>": {"courier_id": …, "courier_service_id": …}}`, ids taken from that order's choices.
- Then `get_action_status` with `request_id`. `state` is `executing` (running in the background), `succeeded` or `failed`; `execution_result` holds per-order outcomes. Report: N succeeded, N failed with the reason per order. Still `executing` → say it is running and offer to check again; `stale: true` → say it went silent and suggest checking the orders in Omisell.
- `confirm_action` errors: `token_expired` / `invalid_or_used_token` → call the write tool again for a fresh preview, show it again; `already_handled` → read `get_action_status` instead; `batch_too_large` → split into batches of 200; `write_disabled` → the house-rules "changing data is not enabled" text; `not_found` → the request is gone, call the write tool again; `dispatch_failed` / `audit_unavailable` → nothing ran, say so and offer to retry later.
- The write tool returns a status instead of a preview (no `confirm_token`: the same request already exists) → report that status; do not confirm.
- `insufficient_permission` on the write tool, or `permission_denied` from `confirm_action` → "This needs the order edit permission (create shipment permission for shipments) in Omisell. Ask the shop owner."
- Write tool not in the tool list → house rules: point to Omisell Orders page, tick the orders, use the action button there.

## Answer

- Before confirm: the preview above, nothing else.
- After: summary (what was done, how many succeeded / failed), a failed-orders table (code, reason), next step (for example `/omisell:explain-order` for a failed one, `/omisell:shift-start-orders` to see the board again).

## Do not

- Never call `confirm_action` in the same turn as the preview, and never on "ok" said to something else.
- Never put two actions behind one yes (confirm + create shipments = two previews, two yeses).
- Do not use `cancel_orders` to cancel a shipment only; that cancels the whole order.
- Do not hide skipped orders to make the preview look clean.

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
