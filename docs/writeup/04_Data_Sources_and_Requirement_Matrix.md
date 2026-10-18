> Latest access policy: all signed-in accounts can use operational functions. Only Managers can open the dashboard and manage roles. See [current access and dashboard](07_Current_Access_and_Dashboard.md).

> UI language update (2026-10-18): R3–R5 now display in Thai to match R1–R2. See [Thai terminology and current screen labels](05_Thai_UI_Terminology.md). English screen labels below refer to the earlier wording.

# Data sources and current requirements

Updated 18 October 2026. R5 now follows the revised scope in `00_Current_Scope_and_Acceptance.md`.

## Where did the purchase-price trend data come from?

**Actual received supplier purchases entered by an operator in Purchase receipts.** There is no market-price API, web scraping, supplier catalog import or invented historical series.

```text
Supplier invoice/receipt
  -> operator enters material, received quantity, actual unit price, supplier, reference and date
  -> StockRepository.recordPurchaseReceipt()
  -> SQLite purchase_receipts: one immutable row per recorded lot
  -> dashboardStats(days) selects dated bottle receipts
  -> one price point per lot, with full receipt details visible
```

| Field | Source/meaning |
|---|---|
| item_code | Selected raw SKU; chart series are PET_350, PET_600, PET_1500 |
| quantity | Actually received quantity in that SKU's inventory unit |
| unit_price | Actual THB price per inventory unit from the supplier document |
| supplier | Operator-entered supplier identity |
| reference | Invoice/receipt reference for tracing the point |
| purchased_at | Operator-entered purchase-document calendar date; future dates rejected |
| created_at | When the app recorded/received the purchase |

Saving is atomic: insert receipt, add stock, update the item's current unit cost, and record stock history. Do not receive the same quantity again using ordinary Stock In.

The graph reads receipt `unit_price` directly, filters `purchased_at` to the selected window through today, and sorts by purchase date then receipt ID. **There is no averaging and no replacement by today's cost.** Each point is one recorded lot; colors separate bottle sizes. Horizontal spacing is chronological lot sequence, not elapsed calendar time. The supplier/date/quantity/reference are displayed below.

Fresh installations have no receipts and show an empty-state message. Old stock movements and purchase-order drafts are not backfilled as actual purchase prices. An old current item cost cannot establish a historical invoice price. Test prices such as 1.25/1.50 exist in disposable test fixtures and are not automatically inserted into the app.

The app preserves entered facts; it does not independently verify invoices. Use the SKU's unit: convert a carton invoice to price per bottle first if the inventory unit is bottle, retaining the invoice reference.

## Other dashboard calculations

| Measure | Stored source/calculation |
|---|---|
| Orders today | Count b2b_orders by local created_at date |
| Production today | Sum production_output history today |
| Due/overdue shipping | Unfulfilled confirmed/awaiting_production orders due today or earlier; legacy undated active orders are included |
| Fulfilled sales | Order-line quantity * saved selling price, filtered by fulfilled_at |
| Selling price | Entered in the B2B form; distinct from material purchase cost |
| Ready-to-ship stock | On-hand minus reserved, per finished SKU and its displayed unit |
| Raw-stock value | Current quantity * current unit cost; not FIFO/historical valuation |
| Critical materials | Existing Provider stock-risk policy/consumption calculation |
| Material usage | Negative production_consume history, grouped by material |
| Best sellers | Fulfilled quantities and sales grouped by product |

Today is one local calendar date; 7/30 days are rolling inclusive windows. Draft, cancelled and merely confirmed orders do not count as fulfilled sales. Sales here are not a payment/tax ledger.

## R3 planning inputs

Recipes are entered from the actual bill of materials per ONE finished SKU unit. Supplier lead days come from Alerts stock policy; production lead days come from recipe setup. Both finished/raw availability subtract reservations, and raw demand is aggregated across all products.

Earliest estimated delivery = today + longest supplier lead among currently short materials + longest production lead among products needing production. The model assumes parallel supplier ordering. It does not schedule machine capacity, transport, supplier holidays or working-day calendars. Missing recipes/materials or an early promised date block confirmation; warned drafts can be retained.

## Requirement matrix

| ID | Current result |
|---|---|
| FR3.1 | Customer creation and search/selection |
| FR3.2 | Quantities, selling prices and delivery date |
| FR3.3 | Finished-stock check plus recipe/material feasibility |
| FR3.4 | Deficits, supplier lead feedback and infeasible-confirmation block |
| FR3.5 | Finished/raw allocation, production completion, fulfillment/cancellation |
| FR4.1 | Daily orders, production, due shipping and fulfilled sales |
| FR4.2 | Ready-to-ship product-size quantities/chart |
| FR4.3 | Individual critical/reorder materials on Dashboard |
| FR4.4 | Actual recorded purchase-lot price history; no fabricated data |
| FR4.5 | Today, rolling 7 days, rolling 30 days |
| Revised R5 | Local registration/login/logout and Manager role designation; no realtime claim |

Old two-device R5 descriptions and historic Pass labels are not evidence for this revised implementation. Tests verify behavior with synthetic isolated data; valid operating data still requires real recipes, prices and lead times.
