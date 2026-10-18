> Latest access policy: all signed-in accounts can use operational functions. Only Managers can open the dashboard and manage roles. See [current access and dashboard](07_Current_Access_and_Dashboard.md).

> UI language update (2026-10-18): R3–R5 now display in Thai to match R1–R2. See [Thai terminology and current screen labels](05_Thai_UI_Terminology.md). English screen labels below refer to the earlier wording.

# Water World: current scope and acceptance

Updated 18 October 2026. This supersedes the earlier writeup's cloud-sync scope.

## Revised R5

R5 covers **registration, login, logout, Manager role designation and role-dependent access**. Cross-device synchronization is outside this revised scope. SQLite persists data within one installation. Legacy sync_queue data is not presented as completed synchronization.

A fresh database creates the demonstration account `admin` / `123456`, Manager. Migration version 8 preserves saved account IDs and hashes. Registration creates an active User who can sign in immediately, without approval. Back to login closes registration. A Manager assigns operational/custom roles in Team accounts; admin retains Manager permissions.

| Role | Access |
|---|---|
| Manager | Dashboard, Inventory, Alerts, B2B, History, recipes, purchase receipts, Team accounts |
| Production | Inventory, production-order queue, History, recipe setup |
| Purchasing | Alerts, B2B, History, purchase receipts |
| User/custom label | History; operational editing requires a recognized role |

## Current acceptance

| Requirement | Implementation | Evidence |
|---|---|---|
| R3 customers | Add contact/address; search business/contact/phone | Search test and Android form check |
| R3 planning | Delivery date, selling price, finished availability and recipe/material deficits | Validation, shared-material and lead-time tests |
| R3 allocation | Finished/raw reservations, production, fulfillment and cancellation | Transaction/lifecycle tests |
| R4 daily KPIs | Today's orders, production, due shipping and fulfilled sales | Sales/production assertions |
| R4 charts | Ready-to-ship SKU sizes, critical materials, sales, production/dispatch, consumption | Data tests and dashboard rendering |
| R4 prices | Actual recorded bottle purchase prices, dated and traceable to receipts | Immutable-price/date-filter tests |
| R4 freshness | Today/rolling 7/30 days; reload on Provider revision | Dashboard refresh regression |
| Revised R5 | Immediate registration/login, Manager designation and protected permissions | Auth/navigation tests |
| Database | Foreign keys, rejected unknown customers, preserved old accounts/reservations | Integrity/version-7 migration tests |

No factory recipes or historical prices are invented. Empty receipt history stays empty. Lead times are calendar-day planning estimates, not capacity schedules. Fulfilled sales are not cash collected. See the test guide for observed results and the data-sources document for the exact price lineage.
