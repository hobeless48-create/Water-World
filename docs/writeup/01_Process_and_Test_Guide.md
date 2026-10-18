> Latest access policy: all signed-in accounts can use operational functions. Only Managers can open the dashboard and manage roles. See [current access and dashboard](07_Current_Access_and_Dashboard.md).

> UI language update (2026-10-18): R3–R5 now display in Thai to match R1–R2. See [Thai terminology and current screen labels](05_Thai_UI_Terminology.md). English screen labels below refer to the earlier wording.

# Water World R3-R5 process and test guide

Updated 18 October 2026. R5 follows 00_Current_Scope_and_Acceptance.md: local registration, login and Manager role designation.

## Run

From Project/Work/Water-World-master/Water-World-master:

```powershell
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Use the detected device ID. The APK is build/app/outputs/flutter-apk/app-debug.apk. Version-8 migration preserves accounts, inventory and old confirmed reservations. Do not clear data to upgrade. Fresh-install demo login: admin / 123456, Manager. This emulator's saved admin password was explicitly updated; other saved databases retain their credentials.

Registration creates an active User who can sign in immediately. Back to login closes registration without creating an account.

## Prepare operating data

1. As Manager, open Production recipes from the top menu. Enter raw quantities per ONE finished SKU unit. If that unit is pack, enter the bill of materials per pack.
2. Set production lead time in calendar days; zero means same-day planning. Configure supplier lead days in the existing Alerts stock-policy editor.
3. Open Purchase receipts. Enter actual received quantity, actual unit price, supplier, document reference and purchase date.
4. Saving receives stock once. Do not also use ordinary Stock In for the same goods. Stock In without a supplier price does not create purchase-price history.

Seeded SKUs are a catalog, not invented factory recipes or prices. Missing recipes and empty history are reported.

## R3 acceptance

1. Add a customer with contact, phone and address. Search by business/contact/phone in New order.
2. Choose a promised delivery date, quantities and selling prices per SKU unit.
3. Press Check availability. Inspect finished allocation, production shortage, combined raw demand, unreserved balances, deficits and supplier lead days.
4. A missing recipe, material deficit or early date warns the user. Drafts may be saved; infeasible confirmation is blocked.
5. Confirm sufficient finished stock: it becomes reserved and ready to ship (confirmed).
6. Confirm a feasible production order: existing goods and raw materials are reserved; status is awaiting_production.
7. As Production/Manager, open Production orders/B2B and select Complete reserved production after physical completion. The transaction consumes materials, records output and reserves that output for the same order.
8. As Purchasing/Manager, fulfill the ready order. Stock/reservations decrease once; b2b_dispatch and fulfilled_at are recorded. Its saved selling prices now contribute to fulfilled sales.
9. Test cancellation before/after production: outstanding reservations release without consuming physical inventory. Produced goods remain in stock after cancellation.
10. Test competing allocations, repeated actions, early dates, invalid quantities and missing customers. Rejections must leave no partial reservations.

Synthetic regression example (disposable database only): recipe is one PET_350 plus one CAP_SCREW per FG_350, production lead one day. Start with two finished units, five bottles and five caps. Order seven units at 12 THB for a future date. Reserve two goods plus five of each material; produce and fulfill. Fulfilled sales are 84 THB and reservations are zero. These numbers are test data, not factory facts.

With only one bottle and supplier lead five days, the order is short four bottles. Earliest estimate is today + five supplier days + one production day. Confirmation remains blocked until materials and the promised date are feasible.

## R4 acceptance

1. As Manager, inspect today's orders, production, due/overdue shipping and fulfilled sales.
2. Check ready-to-ship 350/600/1500 ml product quantities against on-hand minus reserved, using each SKU's unit.
3. Inspect individual critical materials and safety/reorder thresholds.
4. Switch Today / 7 days / 30 days. Draft/cancelled orders must not count as fulfilled sales.
5. Record an actual receipt and return to Dashboard: stock totals and purchase prices refresh without restarting.
6. In a disposable test, record labelled TEST ONLY PET_600 lots at 1.25 and 1.50 on different dates. Seven days shows both; Today shows today's lot. Updating items.unit_cost must not change these historic points. Do not describe test prices as real supplier prices.
7. Compare best sellers, sales and material consumption with order/production history.

See 04_Data_Sources_and_Requirement_Matrix.md for the source of each measure.

## R5 revised acceptance

1. Register a password of at least six characters; sign in immediately as User. Verify Back to login.
2. As admin, assign Production, Purchasing, Manager or a custom role in Team accounts.
3. Sign in again and verify permitted pages. Production completes allocated production; Purchasing manages orders/receipts.
4. Non-Managers cannot use Team accounts. Admin cannot be demoted; a signed-in user cannot disable itself.
5. Passwords are stored as salted hashes. Relaunching requires sign-in again.
6. Cross-device sync is outside revised R5; Account & storage states this accurately.

## Automated checks

```powershell
flutter test
flutter analyze
flutter build apk --debug
```

The 18 tests cover stock operations, navigation, B2B planning/lifecycle, shared materials, receipt-price history, foreign keys, dashboard refresh, version-7 migration and auth roles. Tests use disposable databases and do not add fake history to the running app.

Final observed verification is appended below. Passing fixtures do not verify real invoices or factory recipes.

### Observed verification - 2026-10-18

- `flutter test`: all 18 tests passed.
- `flutter analyze`: 16 informational lints, zero warnings and zero errors. Informational items include legacy print calls, deprecated form-field values and async-context suggestions.
- `flutter build apk --debug`: successful. The resulting APK was installed on emulator-5554 with existing app data preserved.
- Existing emulator database migrated to schema 8: integrity_check returned ok and foreign_key_check returned zero violations. Existing accounts and operational data were preserved; no invented receipts were inserted.
- Android smoke check: admin login and Manager dashboard rendered; Today, 7 days and 30 days filter choices were available and selection worked.
- Additional Android smoke checks passed: Production recipes list, empty receipt-history state, receipt entry form, B2B order list and new-order form with customer, delivery date and availability controls. No business records were saved during these UI checks.
- Repository/widget tests cover transactional production and fulfillment, receipt history, role assignment and dashboard refresh. Full manual factory acceptance using actual recipes and supplier invoices remains necessary.
