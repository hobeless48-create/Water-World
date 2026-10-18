> Latest access policy: all signed-in accounts can use operational functions. Only Managers can open the dashboard and manage roles. See [current access and dashboard](07_Current_Access_and_Dashboard.md).

> UI language update (2026-10-18): R3–R5 now display in Thai to match R1–R2. See [Thai terminology and current screen labels](05_Thai_UI_Terminology.md). English screen labels below refer to the earlier wording.

# Water World R3-R5 code writeup

Updated 18 October 2026. Source is under Project/Work/Water-World-master/Water-World-master/lib. Function names are used instead of fragile handwritten line ranges.

## Architecture

Widgets own local forms/controllers. AuthProvider and InventoryProvider publish app state through Provider. StockRepository centralizes SQLite operations and accepts an injected AppDb in tests. Navigator push/pop handles pages/dialogs. Revised R5 does not require a cloud service.

| Source | Responsibility |
|---|---|
| data/stock_repository.dart | Existing stock operations and shared history helper |
| data/order_operations.dart | R3 feasibility, allocation and lifecycle |
| data/planning_data_operations.dart | Recipes and actual purchase receipts |
| data/analytics_operations.dart | R4 aggregate queries |
| order_models.dart | Typed ProductPlan, MaterialPlan and OrderPlan |

Dart part files belong to the same library. Extensions add callable methods to StockRepository while sharing its database/helpers. UI imports stock_repository.dart to use them. SQL uses bound arguments; multi-step writes use one transaction so failure rolls back the operation.

## AppDb migration

Version 8 enables foreign keys in onConfigure. Purchase receipts reference items; material allocations reference orders/products/materials. Missing customers are also rejected inside order creation.

New fields hold production lead days, delivery/confirmation/fulfillment dates and each line's reserved finished/production quantities. Old confirmed lines are migrated with reserved_finished = quantity. Old fulfilled_at is initialized from updated_at. Account IDs and password hashes are preserved. The upgrade test verifies a real version-7-shaped fixture, accounts, reservations and integrity.

## R3: precheckB2BOrder and _plan

1. Reject empty/duplicate lines, non-finite/non-positive quantities and invalid prices.
2. Finished availability = current_quantity - reserved_quantity.
3. Expand only the shortage through the configured recipe.
4. Aggregate raw demand across ALL products before checking availability, preventing caps/bottles being promised independently to two lines.
5. Subtract raw reservations and report shortages and supplier lead days.
6. Earliest estimate = local today + maximum supplier lead among short materials + maximum production lead among products needing production. No production means today. Missing recipes are explicitly reported.

This assumes parallel supplier ordering and calendar days. It does not schedule capacity, transport or working-day calendars.

## R3: transactional lifecycle

createB2BOrder saves the customer, date, notes, quantities and selling prices. The UI requires an availability check; an infeasible warned draft is allowed and reserves nothing.

confirmB2BOrder recalculates inside its transaction and rejects deficits, missing recipes or early dates. It reserves existing finished goods and raw materials for remaining production, snapshots allocations and sets awaiting_production or confirmed/ready-to-ship.

produceB2BOrder consumes saved raw allocations, decreases raw stock/reservations, inserts production history/batches, creates finished output and reserves it for the same order. It records operator-confirmed physical completion, not automatic manufacturing.

fulfillB2BOrder dispatches only confirmed output once and saves fulfilled_at. cancelB2BOrder releases outstanding finished/raw reservations without consuming physical inventory. Ordinary dispatch and production also refuse to consume reserved stock.

b2b_page.dart lists orders and guards action errors. b2b_order_dialog.dart owns search/date/quantity/selling-price inputs and the preview. planning_data_page.dart provides recipe/receipt forms with controller disposal. Production has a production queue; Purchasing/Manager have customer/order controls. Cancellation asks for confirmation.

## R4: queries and freshness

AnalyticsOperations.dashboardStats computes daily orders/production/due shipping/fulfilled sales, current inventory/open orders, available finished products, best sellers, production/dispatch, raw consumption and actual bottle receipt prices. Today and rolling 7/30 days use local calendar dates.

InventoryProvider increments revision after refresh. ExecutiveDashboardPage watches it in didChangeDependencies and replaces its cached SQL Future when needed. This fixes stale totals without querying on every build. Order, receipt and recipe changes refresh the shared Provider.

The price painter plots one actual received lot per point, with a color per bottle SKU. Horizontal spacing is chronological lot order. Supplier/reference/date/quantity appear below the graph. The exact lineage is in 04_Data_Sources_and_Requirement_Matrix.md.

## R5: revised local accounts

AuthProvider derives PBKDF2-SHA256 hashes with random salts. AppUser omits hashes. Registration creates active User accounts that can sign in immediately. Fresh demo databases seed admin / 123456, Manager; existing passwords are not reset every launch.

AuthGate shows sign-in without a session. RegisterPage returns success via Navigator.pop and includes Back to login. Manager-only methods reject unauthorized account/role changes. MainShell exposes permitted pages; a single-page User/custom role has no invalid NavigationBar. The legacy sync queue is outside revised R5, not a realtime implementation.

## Verification boundaries

Tests cover stock behavior, shared-material/date planning, reservations/production/fulfillment/cancellation, immutable receipt prices, foreign keys, dashboard refresh, migration and account permissions. See the test guide for current results.

The local implementation does not claim shared-server authorization, cash receipts, FIFO valuation, supplier-price import or capacity scheduling. Real recipes, invoices and lead times are user-supplied operating data.
