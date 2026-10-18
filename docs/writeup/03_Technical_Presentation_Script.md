> Latest access policy: all signed-in accounts can use operational functions. Only Managers can open the dashboard and manage roles. See [current access and dashboard](07_Current_Access_and_Dashboard.md).

> UI language update (2026-10-18): R3–R5 now display in Thai to match R1–R2. See [Thai terminology and current screen labels](05_Thai_UI_Terminology.md). English screen labels below refer to the earlier wording.

# Technical presentation script: Water World R3-R5

Updated 18 October 2026. Keep each person's own contribution under the course's five-minute demo limit. Attribute team work accurately. Label illustrative/demo data explicitly.

## Opening

"My contribution extends the Flutter inventory app with B2B planning, a dashboard and local account management. We reuse SQLite and Provider. Current R5 covers registration, login and Manager role designation, without cross-device synchronization."

## R3

"The form searches customers, records a delivery date and accepts quantities and selling prices. It subtracts reservations from finished stock, expands shortages through the configured recipe, and combines raw demand across all lines. It reports a missing recipe instead of guessing one."

"The preview shows material deficits, supplier lead days and an earliest date estimate: the longest missing-material lead plus production lead. This is not a machine-capacity schedule. Warned drafts can be kept, but infeasible confirmation is blocked."

"Confirmation reserves goods/materials atomically. The operator records completed production; allocated materials are consumed and output is reserved for the same order. Fulfillment dispatches once. Cancellation releases outstanding reservations."

Demo: search customer, select date, show a deficit and feasible plan, reserve, complete production and fulfill/cancel. Point to history and quantities. Use prepared, explicitly labelled test records for a short demo.

## R4: explain where the data comes from

"The dashboard shows daily orders, production, due shipping and fulfilled sales, individual material alerts, available stock by product size and production/sales/consumption charts. Today/7/30 days filter the data. Provider changes invalidate the cached SQL results."

"Purchase-price history comes from purchase_receipts, not the internet and not today's item price. An operator records a received purchase's quantity, actual unit price, date, supplier and invoice reference. Each immutable bottle lot becomes a graph point. Saving receives stock once. Without receipts, history stays empty."

"Sales use saved selling prices and are recognized on fulfillment. They are not cash collected. Current raw-stock value uses current cost, not FIFO accounting."

Demo: show a receipt's price/date/reference matching a graph point, switch periods and show another lot. Change stock/order data and show automatic refresh. Describe synthetic prices as test data unless they are backed by actual invoices.

## R5

"Registration creates an active User who can sign in immediately. A Manager designates Production, Purchasing, Manager or another label. Pages/editing controls follow the role. Passwords are stored as salted PBKDF2 hashes."

Demo: register, use Back to login, sign in, then designate a role in Manager Team accounts and show the changed pages. Do not call the legacy queue realtime sync.

## Verification

"We test shared materials and dates, allocations, production/cancellation, immutable prices, dashboard refresh, migration and auth roles. The test guide records automated and Android results. Recipes, supplier prices and lead times are entered operating data, not fabricated presentation facts."

## Questions

| Question | Accurate answer |
|---|---|
| Where are the purchase prices from? | User-entered received supplier purchases with date/supplier/document reference; no external feed. |
| Why not items.unit_cost? | It changes; a receipt retains the price of a specific dated lot. |
| Why not purchase-order drafts? | They are planned/estimated orders, not actual goods received or paid prices. |
| Can two orders consume the same caps? | Availability subtracts reservations; combined demand is checked transactionally. |
| Does Complete production manufacture automatically? | No, it records an operator's completed production and stock effects. |
| Is delivery guaranteed? | No; configured lead-time estimates do not schedule capacity, transport or holidays. |
| Does R5 update another phone? | No; revised R5 is local registration/login/role designation. |
