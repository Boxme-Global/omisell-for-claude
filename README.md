# Omisell for Claude

Role-based workflow skills for Omisell sellers. Each skill knows which Omisell data to read, in which order, and how to present it for one job: the owner's morning brief, the start-of-shift order board, stuck parcels, listings out of sync, what to reorder, marketplace settlement, campaign results.

The skills run on the official Omisell connector (`https://mcp.omisell.com/mcp`). The plugin declares it, so installing the plugin is enough; you sign in with your own Omisell account and see exactly what your Omisell permissions allow.

Start with **`/omisell:start`**: it asks your role and suggests the skills that fit. Or ask in plain words with **`/omisell:ask`**.

> Tiếng Việt: xem [Cài đặt](#cài-đặt-tiếng-việt) bên dưới.

## Install

### Claude Code

```
/plugin marketplace add Boxme-Global/omisell-for-claude
/plugin install omisell@omisell
```

Then run `/mcp`, pick `omisell`, sign in with your Omisell account, and type `/omisell:start`.

### Claude desktop (Cowork) and claude.ai

1. Find **Omisell** in the Claude plugin directory and install it, or download `omisell-plugin.zip` from the [latest release](https://github.com/Boxme-Global/omisell-for-claude/releases) and use **Add → Upload plugin**.
2. Open a new conversation, sign in to Omisell when asked, and type `/omisell:start`.

### claude.ai with skills only

If you cannot install plugins:

1. Add the connector: **Settings → Connectors → Browse**, find **Omisell - Seller**, connect and sign in.
2. Download the skill files you need (`omisell-<skill>.zip`) from the [latest release](https://github.com/Boxme-Global/omisell-for-claude/releases).
3. **Customize → Skills → Upload**, one zip per skill. Skills need code execution turned on in Settings.

### Already using the Omisell connector?

Claude Code connects once when the plugin and the connector point at the same address, so the tools are not duplicated. If another Claude app shows the Omisell tools twice, turn one of them off.

## Skills

| Role | Skills |
|---|---|
| Everyone | `start`, `ask` |
| Shop owner / manager | `morning-brief`, `weekly-business-review`, `anomaly-check`, `channel-comparison`, `dead-stock-decision` |
| Order operations & customer service | `shift-start-orders`, `explain-order`, `bulk-order-actions`, `returns-desk`, `return-dispute`, `customer-reviews` |
| Warehouse & shipping | `stuck-shipments`, `track-shipment`, `courier-scorecard`, `pack-and-handover`, `warehouse-load` |
| E-commerce | `listing-health`, `sync-stock-price`, `price-check`, `shop-health`, `sku-lookup` |
| Purchasing & stock planning | `stockout-forecast`, `abc-review`, `reorder-plan`, `purchase-tracking` |
| Accounting / finance | `marketplace-settlement`, `carrier-reconciliation`, `fees-by-channel`, `revenue-report`, `overdue-payments`, `e-invoice-status`, `gross-margin` |
| Marketing | `campaign-overview`, `campaign-performance`, `flashsale-guard`, `customer-insights` |
| Dropship | `dropship-health` |

Skills answer in Vietnamese, Thai or English, following your language.

## What the skills will and will not do

- **Read** your shop's data through your own Omisell account. Staff see only what their Omisell role allows.
- **Change** data only after showing you a preview and getting your explicit yes in the conversation. Writing is a separate permission you tick when connecting; without it, the skills stay read-only and point you to the Omisell screen instead.
- Never show your customers' phone numbers, addresses or emails, except when you ask about one specific order.

## Privacy

Data flows only between Claude and Omisell's connector. See the [Omisell privacy policy](https://omisell.com/privacy.html) and [terms of service](https://omisell.com/terms-of-service.html). This repository holds instructions only: no credentials, business ids or customer data.

## Support

Questions or problems: contact Omisell support from the Omisell app.

---

## Cài đặt (tiếng Việt)

Plugin gồm các skill theo vai trò cho người bán dùng Omisell: báo cáo sáng của chủ shop, rà đơn đầu ca, vận đơn kẹt, listing lệch, hàng sắp hết, đối soát sàn, hiệu quả khuyến mãi. Dữ liệu đi qua connector chính thức của Omisell; bạn đăng nhập bằng tài khoản Omisell của mình và chỉ thấy đúng phần quyền Omisell cho phép.

**Claude Code**

```
/plugin marketplace add Boxme-Global/omisell-for-claude
/plugin install omisell@omisell
```

Sau đó gõ `/mcp`, chọn `omisell`, đăng nhập Omisell, rồi gõ `/omisell:start`.

**Claude desktop (Cowork) / claude.ai**: tìm **Omisell** trong danh mục plugin của Claude và cài, hoặc tải `omisell-plugin.zip` ở mục Releases rồi chọn **Add → Upload plugin**. Mở hội thoại mới và gõ `/omisell:start`.

**Chỉ dùng claude.ai, không cài được plugin**: thêm connector **Omisell - Seller** ở Settings → Connectors, tải file `omisell-<skill>.zip` ở mục Releases, rồi Customize → Skills → Upload từng file (cần bật code execution).

Mọi thao tác thay đổi dữ liệu đều hiện bản xem trước và chỉ chạy khi bạn đồng ý rõ ràng trong hội thoại.
