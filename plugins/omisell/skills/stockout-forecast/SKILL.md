---
name: stockout-forecast
description: Which SKUs run out first at the current sales speed - days of stock left for the whole business, the expected stock-out date, and which warehouses hold the stock. Use when the user says "SKU nào sắp hết hàng", "dự báo hết hàng", "còn bán được mấy ngày", "hàng nào sắp cháy kho", "kho X đang hết gì", "còn bao nhiêu sản phẩm hết hàng", "สินค้าไหนใกล้หมด", "สต็อกพอขายอีกกี่วัน", "which SKUs will run out", "stock-out forecast", "days of cover".
---

# Omisell: stock-out forecast

Goal: tell the user which SKUs will run out soonest, when, and where the remaining stock sits, so they reorder or move stock in time.

## Steps

1. **Candidate SKUs.**
   - The user named SKUs → use them (up to 50).
   - Otherwise `product_problems` with `group=1`, `limit=20`: the "running out" group of the Products with problems screen (stock at or below two weeks of sales). If it returns `needs_pickup` (staff limited to several warehouses), ask which warehouse and call again with `pickup_address_id`.
   - Refused (`missing_permission`) or empty → `top_skus` with `metric="units"`, `limit=20` over the same 28-day window, and say the list is "best sellers" rather than "flagged as running out".
2. **Sales speed.** One `sku_daily_sales` call with `skus` = the candidates, `date_from` = local midnight 28 days ago, `date_to` = today's local midnight (28 full days, today excluded because it is not over). Report `not_found` SKUs (not a warehouse SKU, e.g. a combo or channel SKU) and `no_sales` SKUs in one line each.
3. **Stock.** For the 4 SKUs with the highest daily rate (or all named SKUs, max 4 per turn), call `stock_on_hand` with `sku`. It returns one row per warehouse: `quantity` (physical), `available_now` (can ship now, after stock held for unshipped orders), `incoming`. Skip rows with `pickup_active` false (closed warehouse). Offer the next 4 instead of looping further; if step 1 needed a second call (`needs_pickup` or the `top_skus` fallback), check 3 SKUs this turn instead of 4.
4. **"Warehouse X is out of what?"** (a separate question): `list_pickup_addresses` with `keyword` = the warehouse name → `list_out_of_stock_by_warehouse` with `pickup_address_ids=[id]`, `threshold=0`, `limit=50`. One row is one SKU in that warehouse, not a product count. Then step 2 for those SKUs if the user wants speed.
5. **"How many products are out of stock now?"** (a separate question, no forecast): `list_out_of_stock_products` with `limit=50`. Its `total` counts PRODUCTS with the same rule as the Out of stock tab of the Products screen (active, no warehouse with stock, variants folded into the parent); report it with its `unit`. Never answer this question by counting `list_out_of_stock_by_warehouse` rows: one row is one SKU in one warehouse, so the same product is counted once per warehouse (this has over-reported by about 75 times). `truncated` true → say the full list is on that Products screen tab.

## How the forecast is computed (show these assumptions under the table)

- `qty` per day from step 2 already splits combos into component SKUs, excludes returned and cancelled orders and includes gifts and 0-value lines (they leave stock too). Days with no row sold 0.
- **Daily rate** = units in the 28 days ÷ 28. Also compute the last-7-day rate (units in the last 7 days ÷ 7). If the 7-day rate is more than 30% above the 28-day rate, use the 7-day rate and say "sales are speeding up".
- **Stock** = sum of `available_now` over active warehouses (use `quantity` where `available_now` is missing). A negative or zero value counts as 0: say "already oversold / held for orders" for that SKU. `incoming` is shown, not counted.
- **Days of cover** = stock ÷ daily rate, rounded down. **Stock-out date** = today + days of cover. Rate 0 → "no sales in 28 days", not at risk by speed.
- Sales speed is for the whole business (all warehouses the user can see); it is not split by warehouse. Per-warehouse rows show where stock sits, not a separate forecast.

## Answer

- Summary: how many SKUs run out within 7 days and within 14 days, the soonest one and its date, window "28 days to <dd/mm/yyyy>".
- Table, soonest first: SKU · name · units/day · stock now · days left · stock-out date · incoming · main warehouse(s). Mark ≤ 7 days and 8-14 days. Top 10, say how many more.
- Assumptions: the bullet list above in two or three short lines (window, rate rule, stock basis).
- Next: reorder the urgent ones (`/omisell:reorder-plan`), check purchase orders already on the way (`/omisell:purchase-tracking`), see which SKUs matter most (`/omisell:abc-review`).

## Do not

- Do not treat `quantity` as sellable stock when `available_now` is there; do not add `incoming` to stock left.
- Do not call `stock_on_hand` for more than 4 SKUs in one turn.
- Do not present per-warehouse days of cover: sales are not split by warehouse.
- Do not add up per-warehouse out-of-stock rows into a product count.
- Do not call a SKU "safe" because it is missing from the candidate list; say it was not checked.

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
