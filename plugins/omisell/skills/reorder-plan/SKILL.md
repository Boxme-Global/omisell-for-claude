---
name: reorder-plan
description: Suggests how many units of each SKU to buy from the sales speed, stock left and supplier lead time, then (after the user agrees) creates one purchase order from a vendor into a warehouse. Use when the user says "cần nhập bao nhiêu", "đề xuất nhập hàng", "lên kế hoạch nhập", "tạo phiếu nhập", "tạo đơn mua hàng", "ควรสั่งซื้อเท่าไหร่", "สร้างใบสั่งซื้อ", "reorder plan", "how much should I reorder", "create a purchase order".
---

# Omisell: reorder plan

Goal: a reorder quantity per SKU that the user can defend, and, only on their yes, one purchase order in Omisell.

## Inputs (ask once, in one message, only what is missing)

- SKUs: named by the user, or none (then step 1 picks them).
- Supplier **lead time** in days (order to goods on the shelf). Unknown → assume 7 and say so.
- **Cover** days to buy for after the goods arrive. Default 30.
- **Safety** days for late deliveries and spikes. Default 7.

## Steps (plan: at most 6 calls)

1. **SKUs.** Named → use them (max 50, one purchase order holds 50 lines). Otherwise `product_problems` with `group=1`, `limit=30` (running out at the two-week sales rate; `needs_pickup` → ask which warehouse and pass `pickup_address_id`). Refused → `top_skus` with `metric="units"`, `limit=30`, last 28 days.
2. **Sales speed.** One `sku_daily_sales` call: `skus`, `date_from` = local midnight 28 days ago, `date_to` = today's local midnight. `not_found` SKUs (combo / channel SKU) cannot be bought by that code: list them and ask for the warehouse SKU.
3. **Stock.** `stock_on_hand` with `sku`, one call each, for the 4 SKUs with the highest daily rate (or the 4 the user named first). Skip warehouse rows with `pickup_active` false. Offer the next 4 in the next turn rather than looping: the plan can grow over several turns and go into one purchase order at the end (max 50 lines). If step 1 needed a second call (`needs_pickup` or the `top_skus` fallback), check 3 SKUs this turn instead of 4.

## Formula (show it under the table, with the numbers used)

- **Daily rate** = units sold in the 28 days ÷ 28 (combos already split into component SKUs, returns and cancels excluded, gifts included). If the last 7 days ÷ 7 is more than 30% higher, use that and say "sales are speeding up".
- **Stock** = `available_now` (sellable now: stock held for unshipped orders already subtracted; use `quantity` only where it is missing) summed over active warehouses; negatives count as 0. Not counted: `incoming`, and purchase orders not yet received (checked in step 4).
- **Need** = daily rate × (lead time + safety + cover) − stock, rounded up. Need ≤ 0 → "no reorder needed".
- **Urgent** when stock ÷ daily rate < lead time + safety: it runs out before a new delivery lands.
- Daily rate 0 → do not suggest a quantity; say "no sales in 28 days".
- Sales speed covers the whole business, and so does stock; the purchase order then lands in one warehouse.

## Answer (plan)

- Summary: N SKUs to reorder, M urgent, total units; window "28 days to <dd/mm/yyyy>"; lead time / safety / cover used.
- Table, urgent first: SKU · units/day · stock now · days left · suggested qty · urgent?
- Then ask: "Create a purchase order for these? Tell me the vendor and the receiving warehouse, and any quantity you want to change."

## Writes

4. **Before proposing**, one `list_purchase_orders` call with `state="open"`: with `keyword` = the SKU when the plan has exactly one SKU, otherwise `limit=50` and no keyword. Show open orders not yet fully received (code, vendor, ordered / received, expected date). With one SKU they may already cover the need: ask whether to reduce it. With several SKUs present them only as context ("open purchase orders, possibly for other SKUs"): their quantities are per purchase order, not per SKU, so never cut a specific line because of them.
5. **Propose.** `create_purchase_order` with `vendor_id`, `pickup_address_id`, `skus` and `quantities` (same order, whole numbers). It needs the vendor's numeric id; no tool on this connection looks vendors up by name. If the user does not have the id, give them the final table to enter on the Omisell Purchase orders screen and stop there. Take `pickup_address_id` from `list_pickup_addresses`; never guess either id.
6. **Show the preview** it returns: vendor, warehouse, lines (SKU × qty), total amount (the preview carries no currency field: show it in the business country's currency), SKUs at cost 0 (prices come from the products' purchase price), and every `skipped` line with its reason in plain words (unknown SKU, SKU with variants: order the variant SKUs, duplicate, bad quantity). An error instead of a preview: explain it (vendor inactive, vendor type not allowed, warehouse inactive or managed by a fulfilment partner) and ask for another choice.
7. **Confirm** only when the user's latest message says yes to this preview: `confirm_action` with `request_id` and `confirm_token`. Changed quantities → call `create_purchase_order` again for a new preview. The token expires after 10 minutes.
8. **Report** with `get_action_status` (`request_id`): succeeded or failed, and say the purchase order does not receive goods or change stock; receiving happens in Omisell. Suggest `/omisell:purchase-tracking` to follow it.

## Do not

- Do not propose a purchase order in the same turn as the first plan; the user reviews the numbers first.
- Do not invent a vendor, a warehouse or a lead time; do not round quantities to pack sizes nobody gave you.
- Do not put more than 50 SKUs or more than one vendor in one purchase order.

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
