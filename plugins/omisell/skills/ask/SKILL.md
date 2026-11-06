---
name: ask
description: Answer any free-form question about an Omisell shop (orders, shipments, stock, listings, returns, fees, revenue, promotions) by routing it to the right Omisell skill or tools. Use when the user asks about their Omisell data without naming a skill, e.g. "shop tôi hôm nay thế nào", "đơn này sao chưa giao", "còn bao nhiêu hàng", "ร้านวันนี้เป็นยังไง", "ยอดขายเมื่อวาน", "how is my shop doing", "why is this order late".
---

# Omisell: ask anything

Goal: one correct answer on real data, through the skill that already knows the workflow.

## Steps

1. **Business first.** Apply the business rule in the house rules below before any data call.
2. **Find the route.** Match the question to one row of the routing table. Match on intent, not keywords: "đơn kẹt" can mean stuck orders (order ops) or stuck parcels (shipping); an order code (`OD...`) points to `explain-order`, a tracking code to `track-shipment`.
3. **Ambiguous?** Pick the most likely route, answer, and say in one line which other reading you could also answer. Ask back only when the two readings need different data AND a wrong guess would waste a long call.
4. **Run it.**
   - The routed skill is installed → follow it (in Claude Code: `/omisell:<skill>`).
   - Not installed → answer directly with that row's tools, following the house rules. Use only tools that are in the tool list; if a needed one is missing, say that view is not available on this connection yet and answer what you can.
5. **Nothing matches** → use the most aggregate tool that fits (`aggregate_orders`, `aggregate_shipments`, `sales_summary`, `search_products`, `stock_on_hand`). If no Omisell tool covers it, say so plainly and point to the Omisell screen where it lives.
6. End with the next step and, when there is one, the skill that goes deeper.

## Routing table

| Question is about | Skill | Main tools |
|---|---|---|
| Overview, yesterday, this morning | `morning-brief` | `sales_summary`, `sales_by_channel`*, `find_problem_orders`, `oos_summary`, `return_analysis` |
| Weekly review, week by channel, gross profit | `weekly-business-review` | `sales_by_channel`*, `fee_aggregate_by_channel`, `top_skus`, `revenue_summary` |
| Anything unusual, sudden cancels or returns | `anomaly-check` | `cancel_analysis`, `return_analysis`, `find_stuck_shipments_summary`, `find_flashsale_price_warnings` |
| Compare channels | `channel-comparison` | `sales_by_channel`*, `fee_aggregate_by_channel`, `fulfillment_lead_time` |
| Slow / dead stock, discontinue | `dead-stock-decision` | `dead_stock_summary`, `discontinue_candidates` |
| Orders this shift, order tabs, orders waiting (overdue risk: per order only) | `shift-start-orders` | `count_orders_by_status_tab`, `find_problem_orders`, `find_pending_shipment_orders` |
| One order: why stuck, what is wrong | `explain-order` | `get_order_timeline`, `explain_order_problem`, `order_fee_breakdown` |
| Confirm / cancel / ship many orders | `bulk-order-actions` | `confirm_orders`, `cancel_orders`, `create_shipments_from_orders`, `change_order_pickup` |
| Returns to process, return age | `returns-desk` | `return_pipeline_state`, `return_aging_summary`, `list_order_returns` |
| Dispute a return with the marketplace | `return-dispute` | `order_return_detail`, `order_return_dispute_reasons`, `dispute_returns` |
| Product reviews, bad ratings, replies | `customer-reviews` | `list_reviews`, `reply_review` |
| Stuck parcels, not picked up | `stuck-shipments` | `find_stuck_shipments_summary`, `aggregate_shipments` |
| One parcel / tracking code | `track-shipment` | `get_shipment_journey_timeline`, `check_shipment_status_source`, `diagnose_shipment_issue` |
| Compare couriers | `courier-scorecard` | `courier_performance`, `fulfillment_lead_time` |
| Packing, handover, labels today | `pack-and-handover` | `packing_dispatch_status`, `get_labels`, `pack_shipments`, `dispatch_shipments` |
| Warehouse volume, returns coming back, open purchase orders | `warehouse-load` | `aggregate_shipments`, `dispatch_volume_by_warehouse`, `inbound_receiving_status` (returns only), `list_purchase_orders` |
| Listing problems, unmapped SKUs | `listing-health` | `product_problems`, `list_product_stores`, `sku_mapping` |
| Push stock / price to channels | `sync-stock-price` | `update_channel_stock`, `update_channel_price`, `mark_oos_on_channel`, `push_product_store_to_channel` |
| Price changes vs orders | `price-check` | `product_price_movement`, `find_flashsale_price_warnings`, `top_skus` |
| Shop score, penalties on the marketplace, is the shop connected / last sync | `shop-health` | `shop_health`, `store_detail` |
| One SKU: channels, stock, daily sales | `sku-lookup` | `search_products`, `product_detail`, `sku_mapping`, `stock_on_hand`, `sku_daily_sales` |
| How many products are out of stock now | `stockout-forecast` | `list_out_of_stock_products` (product count, never per-warehouse rows) |
| What runs out soon | `stockout-forecast` | `stock_on_hand`, `sku_daily_sales`, `list_out_of_stock_by_warehouse` |
| ABC, sell-through | `abc-review` | `inventory_abc_analysis`, `sell_through_rate` |
| How much to reorder, create a purchase order | `reorder-plan` | `sku_daily_sales`, `stock_on_hand`, `create_purchase_order` |
| Purchase orders waiting, late or partly received | `purchase-tracking` | `list_purchase_orders` |
| Marketplace settlement received vs pending | `marketplace-settlement` | `settlement_reconciliation`, `payment_status_breakdown` |
| COD vs carrier, cost reconciliation statements | `carrier-reconciliation` | `cod_reconciliation_status`, `cost_statement_summary` |
| Marketplace fees by channel | `fees-by-channel` | `fee_aggregate_by_channel`, `order_fee_breakdown` |
| Revenue (NMV), return revenue | `revenue-report` | `revenue_summary`, `return_revenue_summary` |
| Overdue unpaid orders | `overdue-payments` | `find_overdue_payment_orders`, `payment_status_breakdown` |
| E-invoices pending / failed | `e-invoice-status` | `einvoice_status` |
| Gross margin by SKU / channel | `gross-margin` | `gross_profit_by_sku` |
| Running / upcoming promotions | `campaign-overview` | `list_promotions` |
| Did the campaign work | `campaign-performance` | `promotion_performance`, `sku_daily_sales` |
| Flash sale price or stock risk | `flashsale-guard` | `find_flashsale_price_warnings`, `flashsale_items`, `stock_on_hand` |
| Returning vs one-time customers | `customer-insights` | `customer_segments` |
| Dropship orders fulfilled for resellers: SLA, 3PF errors, volume per reseller, unsettled amounts, orders by status | `dropship-health` | `dropship_sla_breach`, `dropship_3pf_push_failures`, `vendor_dropship_volume`, `aggregate_dropships` |

\* owner only. For staff, use `sales_summary` with `group_by` channel instead (sales per channel, no fees or margin) and say cost and margin per channel need the owner.

## Do not

- Do not chain several skills for one question; answer it, then offer the next.
- Do not answer from general knowledge about marketplaces when the question is about this shop's data.

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
