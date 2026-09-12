# TH-05 — Harness notes

## Bootstrap decisions — 2026-07-27

| Decision | Chốt |
| --- | --- |
| Theme numbering | Chèn Đơn hàng tại TH-05; dịch Công nợ/Kho/E-invoice/Thuế/Báo cáo/Cảnh báo/Tích hợp thành TH-06…TH-12 |
| Canonical source | `Theme-5-sales-orders.md`, giữ byte-for-byte từ source người dùng |
| Canonical SHA-256 | `2b19694fa805a5d13c180c8982132c178f9b4a7bc7b66a5861916c88f9bc8c7f` (re-harness 2026-07-30) |
| Product decomposition | 6 Epic README tổng hợp, **34** file phẳng `US-xx.md`, **235** FR |
| Scenario IDs | Source `SC-xx` → derived `SCN-xx`; canonical source không sửa |
| Module ownership | Một owner module `sales` trong V1; 4 business domain; aggregate catalog xem `01-domain-model.md` (`OrderAdjustment` superseded) |
| Contract policy | **34** section docs `frozen`; S02–S34 CONTRACT `done`, S01 runtime `n/a`; slice IDs renumber sau EP-04 |
| Implementation status | Sales application Dart contracts Phase 1 synced; domain layer (aggregates excl. superseded OrderAdjustment); infra/UI; BE/FE lanes theo roadmap; **Group G / S22 superseded** |

## Group A BE runtime/provider-port completion — 2026-08-06

- S02-S05 BE marked `done` for the Group A scope: runtime order drafting state, provider ports/fakes, pricing preview/precheck facade and Sales startup runtime module.
- Artifacts: `modules/sales/application/lib/src/order_drafting/`, Group A provider fakes in `modules/sales/application/lib/src/testing/`, `SalesRuntimeModule`, and `SalesStartup.initialize()` returning the runtime module instead of a stub.
- Verification: `dart analyze modules/sales/application modules/sales/infrastructure`, `dart test modules/sales/application/test`, and `dart test modules/sales/infrastructure/test` passed.
- No Sales-owned SQL/RPC draft was added because S02-S05 are runtime/provider-owned. Partner/Catalog/Pricing authoritative integrations remain E2E blockers only.
- `melos run analyze --no-select` passed with existing warnings/info outside Group A. `melos run test --no-select` still fails on pre-existing non-Sales baseline issues (notably Pricing SQL draft expectations and presentation/toolchain failures).

## Group A gap-closure — S02–S05 functional completeness — 2026-08-06

Đóng các gap chức năng còn thiếu sau review commit `4e0b74a0` (giữ nguyên DTO/error frozen):

- **Price floor (US-04 SCN-05/06, EC-06):** `IPricingPreviewPort.canApplyManualPrice(bool)` → `evaluateManualPrice(...) : ManualPriceDecision {allowed, belowFloor, requiresOverride, hasOverridePermission, floorPrice?}`. Below-floor không override → gắn blocker **`PRICING_BELOW_FLOOR`** (advisory, trong line/`PricingPreviewDto.blockers`), precheck chặn finalize; override thiếu quyền → `PERMISSION_DENIED`; override có quyền → áp giá. Floor **không** có mã exception riêng (frozen exception vẫn chỉ `PERMISSION_DENIED/CONTEXT_INVALID/REFERENCE_UNAVAILABLE/STALE_DATA`).
- **Manual discount:** `applyManualDiscount` + `clearManualIntent` lộ qua `SalesOrderDraftingService`; discount vượt line total → `CONTEXT_INVALID` (thay cho clamp thầm).
- **Stale-by-version (US-04 SCN-02):** `markPricingApplied(requestedVersion:)` từ chối preview tính trên version working-state cũ → `STALE_DATA`. Version token là internal runtime, **không** nhét vào DTO frozen.
- **S05 reject/duplicate (SCN-04/05):** `saveRememberedPrice` chỉ invalidate pricing + bump version khi `outcome.resultType == 'saved'`; reject/duplicate giữ nguyên giá/total/version.
- **S02/S03:** lộ `updateQuantity`/`updateUnit` (revalidate qua Catalog → `REFERENCE_UNAVAILABLE`)/`removeLine` + `acceptQuickCreatedCustomer`; cleanup currency fallback + bỏ tham số `session` thừa.
- **Precheck advisory (stateless):** `PrecheckSalesOrderCheckoutQuery` bỏ "đóng dấu" — thêm structural blocker qty≤0 + lệch currency (ngoài missing-price/empty). Staleness **không** tái tạo được ở đường stateless; chỉ enforce ở đường stateful working-state (version token). Finalize vẫn authoritative.
- **Kiến trúc CQRS/bus (Phase 7) HOÃN:** chưa nhân bản scaffold mediation/codegen/permission-checker của IAM cho Sales — sẽ làm chung Group B để tránh đụng WIP chưa commit. Permission/tenant của 2 query S04 sẽ được enforce khi scaffold bus land.
- **Verification:** `dart test modules/sales/application` (38 xanh, gồm floor/override/EC-06/stale/discount/S05-reject/line-ops/precheck), `dart test modules/sales/infrastructure` (12 xanh).

## Sales CQRS bus scaffold — A+B wired + enforced — 2026-08-06

Đóng gap kiến trúc "handler chết + permission bypass" cho cả Group A (S04) và Group B (S06/S07):

- **Scaffold mirror `modules/partner/`** (module downstream sạch, không phải IAM): bật codegen
  `modules/sales/infrastructure/build.yaml` (4 builder), thêm `configuration/processing/{sales_command_pipeline,
  sales_module_definition, processing_module}.dart` + `internal_commands/*` (stub), `SalesModule` delegate ra
  `CommandBus`/`QueryBus`, `SalesDataAccessModule` (draft gateway + working-state + runtime pricing port),
  `SalesMediationModule` (registrar sinh), `SalesStartup.initialize({required IPermissionChecker,
  ITenantAccessChecker})` + `initializeForTesting` allow-all. Codegen sinh 5 file `.g`.
- **`SalesRuntimeModule` (hand-switch) đã xoá**; S04 tách thành `PreviewSalesPricingQueryHandler` +
  `PrecheckSalesOrderCheckoutQueryHandler` (`@QueryHandlerFor`) dùng `SalesWorkingSessionFactory`.
- **Enforcement:** command (save/update/cancel) enforce tự động qua `DefaultCommandPipeline` (access-metadata +
  IPermissionChecker + tenant); **QueryBus không guard** → S04 + list/restore enforce **tường minh** trong handler
  (`IPermissionChecker.require(...)`). Test `sales_authorization_test.dart` chứng minh command+query bị chặn khi
  checker từ chối.
- **Pitfall codegen — access-metadata:** builder `access_metadata` chỉ nhận diện message type qua **interface
  trực tiếp** (`classElement.interfaces`). Contract Sales hấp thụ `implements ICommand/IQuery` vào base
  `SalesMutationContract`/`SalesReadContract` nên bị bỏ sót → registry rỗng → không enforce. Fix: concrete
  contract cần enforce phải khai báo **redundant** `implements ICommand<T>/IQuery<T>, ITenantScopedCommand`
  (đã áp cho 5 contract Group B + 2 query S04). Contract mới của Sales phải theo quy ước này.
- **Codegen cache:** `build_runner` không track thay đổi cross-package (application) → sau khi sửa contract phải
  `dart run build_runner clean` trước `build`, nếu không builder `skip`.
- **Đính chính đợt review:** "SQL contract test không nằm trong suite" là **dương tính giả** — compact reporter
  của `dart test` ghi đè dòng (`\r`) làm grep bắt hụt; `--reporter json` xác nhận cả 5 file infra đều chạy.
- **customer/SCN-02:** `InMemorySalesOrderDraftGateway._DraftRecord` lưu `customerId` (parity với cột `customer_id`
  của SQL); `SalesOrderDraftDto` chưa expose customer → hoãn cho CONTRACT review.
- **Verification:** `dart analyze` sạch; `dart test modules/sales/application` (38) + `modules/sales/infrastructure`
  (14, gồm authorization + SQL contract).

## Group B BE draft persistence/restore completion — 2026-08-06

- S06-S07 BE marked `done`: application handlers/validators, `ISalesOrderDraftGateway`, contract mapper, in-memory runtime gateway, Supabase RPC mapper/gateway, startup runtime wiring, and draft-only SQL contract.
- Artifacts: `modules/sales/application/lib/src/sales_order_draft/`, `modules/sales/infrastructure/lib/src/domain/sales_order_draft/`, `SalesRuntimeModule` draft dispatch, `SalesStartup.initialize()` wiring, and `supabase/migrations/_drafts/001_sales_order_drafts_group_b.sql`.
- Verification: `dart analyze modules/sales/application modules/sales/infrastructure`, `dart test modules/sales/application/test/order_drafting/group_a_order_drafting_service_test.dart modules/sales/application/test/sales_order_draft/sales_order_draft_handlers_test.dart`, `dart test modules/sales/infrastructure/test/configuration/sales_group_b_startup_test.dart modules/sales/infrastructure/test/domain/sales_order_draft`, and `sales_order_draft_sql_contract_test.dart` passed.
- No timestamped migration was created; SQL remains under `_drafts/`. Group B creates/updates/cancels only draft data and does not create SalesOrder, payment, receivable, inventory, receipt, or e-invoice impacts.
- E2E remains `todo` until draft RPCs are promoted/applied and external live revalidation providers are ready.

## Group C BE checkout input/precheck completion — 2026-08-06

- S08-S11 BE marked `done`: application checkout precheck service, payment-intent validator, live reference precheck port/fake, receivable policy port/fake, finalize validation hook, RPC mapper/gateway, startup registration, typed fake fixtures, and draft-only SQL contract.
- Artifacts: `CheckoutPrecheckService`, `CheckoutPaymentIntentValidator`, `ICheckoutReferencePrecheckPort`, `ICheckoutReceivablePolicyPort`, `ICheckoutGateway`, `FinalizeSalesOrderCommandValidator`, `FinalizeSalesOrderCommandHandler`, `CheckoutPrecheckRpcMapper`, `SupabaseCheckoutGateway`, and `supabase/migrations/_drafts/002_sales_checkout_group_c_precheck.sql`.
- Scope boundary: Group C does **not** create `SalesOrder`, `SalesOrderSettlement`, payment transactions, receivable ledger entries, inventory impact, receipt, or outbox. `FinalizeSalesOrderCommandHandler` returns `blocked` when Group C precheck fails, otherwise `received` as the S12 handoff point.
- S09 payment intent remains runtime checkout input; no payment-intent persistence RPC/table was added.
- S10 due-date requirement is surfaced as `RECEIVABLE_DUE_DATE_REQUIRED` when policy requires it, because the frozen Group C query/command contract has no due-date field; changing that needs CONTRACT review.
- Verification: Sales domain/application/infrastructure focused tests, `dart analyze modules/sales/application modules/sales/infrastructure`, and `melos run migrate:verify-policy -- --strict` passed for Group C. E2E remains `todo` until provider contracts/RPC promotions are ready.

## Group C BE–FE vertical integration — 2026-08-11

- S08–S11 FE vertical path wired: compose → typed `SalesCheckoutDraftSnapshot` (GoRouter `extra`) → `SalesCheckoutCubit` → `PrecheckSalesOrderCheckoutQuery` through required `ICheckoutGateway`; checkout precheck panel; stale-response guard; no Group D finalize.
- Guarded live evidence: `apps/erp/integration_test/sales_group_c_s08_s11_live_test.dart` (`VET45_RUN_LIVE_GROUP_C`). Disabled gate without the flag is **not** a pass claim. Live gate expects fail-closed `DEPENDENCY_UNAVAILABLE` by default (`VET45_E2E_GROUP_C_EXPECT_UNAVAILABLE=true`) until draft `002` is promoted/applied and owner contracts/seeds exist.
- **Task 7 evidence (2026-08-11):** disabled gate on iOS Simulator → `All tests skipped` (+0 ~1). Live gate **not run**. Blockers: all five `VET45_E2E_*` seed IDs missing from profile `dschien-local`/`development.env`; `_drafts/002_sales_checkout_group_c_precheck.sql` still draft-only/unpromoted/unapplied; `melos run env:doctor` fails on missing `deploy/deploy.env` (unrelated to Sales seeds but recorded).
- Draft SQL `_drafts/002_sales_checkout_group_c_precheck.sql` remains **draft-only/unpromoted/unapplied**; do not claim live E2E success.
- S10 requires due-date policy, but frozen PrecheckSalesOrderCheckoutQuery has no
  dueDate field. Group C BE–FE integration renders fail-closed for stable
  `RECEIVABLE_DUE_DATE_REQUIRED` (alias `DUE_DATE_REQUIRED` still accepted in UI)
  and does not encode the date into another field. Resolving it requires a
  separate CONTRACT review.
- Roadmap E2E for S08–S11 set to `blocked` with exact blockers (draft RPC fail-closed + external owners + live seed IDs).

## Group D BE authoritative checkout commit completion — 2026-08-07

- S12 BE marked `done`: `FinalizeSalesOrderCommandHandler` runs the Group C final precheck then delegates the atomic commit to `ICheckoutGateway.finalize`; `GetCheckoutResultQueryHandler` recovers timeout/uncertain checkout by storeId + idempotencyKey and enforces `sales.order.view` explicitly (QueryBus skips the auth pipeline).
- **Gateway is a required, DI-injected dependency.** Codegen only injects `required` constructor params, so the finalize handler takes `required ICheckoutGateway checkoutGateway`; the regenerated `sales_cqrs_registrar.g.dart` wires `checkoutGateway: container.get<ICheckoutGateway>()` for both handlers. This closes the Group-C-style dead-wiring risk (a fabricated success can never reach production).
- Domain already owned S12 invariants (`SalesOrder.finalize`, `SalesOrderSettlement.initializeForOrder`, `SalesPaymentTransaction.recordInitial`, `SalesOrderFinalizedEvent`, `CommercialSnapshotMustBalanceRule`) with existing aggregate tests — no new domain code was needed.
- Infrastructure: `SupabaseCheckoutGateway.finalize/getResult` call `sales.finalize_sales_order` / `sales.get_checkout_result`, reusing the stable-error mapping (`IDEMPOTENCY_CONFLICT`, `STALE_VERSION`, `UNCERTAIN_RESULT`, `DEPENDENCY_UNAVAILABLE`, `CHECKOUT_BLOCKED`). Params are snake_case; the result envelope is camelCase (`idempotencyKey/salesOrderId/salesOrderVersion/status`) via `CheckoutPrecheckRpcMapper.checkoutResultFromJson` + a status string→enum helper.
- SQL: draft-only `supabase/migrations/_drafts/003_sales_checkout_group_d_finalize.sql` (`-- Kind: draft`) owns checkout-attempt/order/lines/settlement/payment/inventory+receivable impact-request/outbox in one transaction; Sales never writes Catalog/Partner/Pricing/Inventory/Accounting/E-invoice tables (cross-module effects are impact requests + outbox).
- **Runtime caveat:** the finalize command still short-circuits to `blocked` in the running module because the shared reference-precheck default fails closed (no live provider wired — Group C deferral). Gateway wiring is proven by codegen + unit/startup tests; end-to-end success needs the live reference-precheck provider and the promoted RPC.
- Verification: `dart analyze` + `dart test` for Sales domain/application/infrastructure green; `melos run migrate:verify-policy -- --strict` OK; `verify_harness.sh` fails only on pre-existing `guard_presentation_size` debt (no S12 file involved). E2E remains `todo` until Inventory/Receivable durable impacts are live and RPCs promoted/applied.

## Group E BE result-view + receipt completion — 2026-08-07

- S13-S14 BE marked `done`. **S13** adds three read handlers (`GetSalesOrderQueryHandler`, `GetSalesOrderPaymentSummaryQueryHandler`, `GetOrderIntegrationStatusQueryHandler`) that enforce their view permission explicitly (QueryBus skips the auth pipeline) and delegate to `ISalesOrderReadGateway`; `GetCheckoutResultQuery` is reused from S12. `CheckoutResultViewDto(checkout, order, payment, integration)` is **client-composed** — no BE query returns it, so no aggregating handler was added.
- **S14** adds `GenerateSalesReceiptCommandHandler` + `RecordSalesReceiptPrinted/Shared/ArchiveSalesReceiptCommandHandler` + `GetSalesReceiptQueryHandler` (explicit `sales.receipt.view`), all wired to a required `ISalesReceiptGateway`. Domain `SalesReceipt` already implements generate/print/share/archive, so no new domain code.
- **Gateways are required, DI-injected** (`ISalesOrderReadGateway`, `ISalesReceiptGateway` registered in `SalesDataAccessModule`); the regenerated `sales_cqrs_registrar.g.dart` injects them into every Group E handler — no dead-wiring.
- Infrastructure: `SupabaseSalesOrderReadGateway` → `sales.get_sales_order` / `sales.get_sales_order_payment_summary` / `sales.get_order_integration_status`; `SupabaseSalesReceiptGateway` → `sales.generate_sales_receipt` / `sales.get_sales_receipt` / `sales.record_sales_receipt_activity`. Params snake_case; result envelopes camelCase (enum wire values = Dart enum `.name`). Error families `NOT_FOUND`/`PERMISSION_DENIED`/`PROJECTION_PENDING`/`DATA_SCOPE_DENIED`/`STALE_VERSION`/`IDEMPOTENCY_CONFLICT`/`DEPENDENCY_UNAVAILABLE` map to `SalesContractException`; malformed result → `DEPENDENCY_UNAVAILABLE`.
- SQL: draft-only `004_sales_read_group_e.sql` (read RPCs over committed Group D tables) and `005_sales_receipt_group_e.sql` (`sales.sales_receipts`/`sales.sales_receipt_activities` + idempotent generate from committed snapshot, append-only activities), both `-- Kind: draft`. Sales never reads/writes Catalog/Partner/Pricing/Inventory tables.
- **Runtime caveat:** read/receipt handlers return `DEPENDENCY_UNAVAILABLE` in the running module until the S12/S13/S14 draft RPCs are promoted and read projections exist; wiring is proven by codegen + unit/startup tests.
- Contract note: FR-03 (ngày hẹn thanh toán trên màn kết quả) is not carried by the frozen `SalesOrderPaymentSummaryDto` (no `dueDate` field); surfacing it needs a CONTRACT review — not added here.
- Verification: `dart analyze` + `dart test` for Sales domain/application/infrastructure green (144 tests); `melos run migrate:verify-policy -- --strict` OK; `verify_harness.sh` fails only on pre-existing `guard_presentation_size` debt (no Group E file is presentation). E2E remains `todo` until S12 RPCs are promoted and projections/providers are live.

## Group E BE–FE result + receipt integration — 2026-08-12

- S13–S14 FE marked `done` for BE–FE integration (E2E remains `todo`). **S13:** `SalesTransactionResultCubit.load()` resolves tenant/actor via `IExecutionContext`, then executes `GetCheckoutResultQuery` + concurrent `GetSalesOrderQuery`/`GetSalesOrderPaymentSummaryQuery`/`GetOrderIntegrationStatusQuery` through `ISalesModule`; composes `CheckoutResultViewDto` locally; SG-06 widgets are state-driven (no constructor booleans/hardcoded sample literals); uncertain checkout never shows assumed success.
- **S14:** receipt generate/get/print/share/archive on the same cubit; device action (`SalesReceiptPdfGenerator` + `SalesPdfRunner`) runs before `RecordSalesReceiptPrinted/SharedCommand`; activity-warning state preserves pending print audit when user retries share/ensure.
- **Routing:** Group D checkout navigates with identity-only `SalesCheckoutResultArgs` (`CheckoutResultDto` envelope); ERP `/sales/result/:orderId` requires matching typed extra or renders `SalesResultInvalidEntryPage`; `SalesTransactionResultPage` owns cubit lifecycle via GetIt `ISalesModule`/`IExecutionContext` (injectable for tests).
- **Typed documents:** sales receipt PDF/preview uses `SalesReceiptDocumentDto` only; order slip preview no longer falls back to sales receipt shape.
- **S12 commercial snapshot correction surfaced in UI:** authoritative order header/customer/payment read `SalesOrderResultDto` + `SalesOrderPaymentSummaryDto` (including nullable `dueAt` on payment summary when present).
- **Runtime caveat:** same as BE — draft RPCs `004`/`005` unpromoted/unapplied; handlers return `DEPENDENCY_UNAVAILABLE` until promoted projections exist. Device print/share not verified on physical hardware in this slice.
- Verification: `sales_transaction_result_cubit_test.dart` (28); `sales_transaction_result_body_test.dart`; `sales_receipt_pdf_generator_test.dart`; `sales_receipt_card_test.dart`; `sales_transaction_result_page_test.dart`; `group_e_result_receipt_contract_test.dart`; focused `flutter analyze` on touched presentation/ERP paths green.

## Group F-read BE order inquiry completion — 2026-08-07

- S15–S19 BE marked `done`. **S15–S18** add read handlers via one `ISalesOrderInquiryGateway`: `ListSalesOrders`/`SearchSalesOrders` (viewOrder, cursor paging via `OpaqueCursorPageDto`), `GetSalesOrderDetail` (viewOrder), `GetSalesOrderSettlement`/`GetSalesOrderPaymentTransactions` (viewPayment, transactions paged), `GetSalesOrderTimeline` (viewOrderHistory), `GetSalesOrderReturnSummary` (viewReturnExchange). Each enforces its view permission explicitly (QueryBus skips the auth pipeline). `GetSalesOrder`/`GetSalesOrderPaymentSummary` reused from S13.
- **S19** requires no new BE — it reuses the Group E/S14 receipt surface (`GetSalesReceiptQuery` + generate/print/share/archive handlers via `ISalesReceiptGateway`), verified registered.
- **Gateway is required, DI-injected** (`ISalesOrderInquiryGateway` registered in `SalesDataAccessModule`); the regenerated `sales_cqrs_registrar.g.dart` injects it into all seven inquiry handlers — no dead-wiring.
- Infrastructure: `SupabaseSalesOrderInquiryGateway` + `SalesOrderInquiryRpcMapper` (reuses `SalesOrderReadRpcMapper.salesOrderFromJson`) → `sales.list_sales_orders`/`search_sales_orders`/`get_sales_order_detail`/`get_sales_order_settlement`/`get_sales_order_payment_transactions`/`get_sales_order_timeline`/`get_sales_order_return_summary`. Params snake_case; result camelCase; cursor pages `{items, hasMore, nextCursor}`; error families `NOT_FOUND`/`PERMISSION_DENIED`/`PROJECTION_PENDING`/`DATA_SCOPE_DENIED`/`STALE_VERSION`/`DEPENDENCY_UNAVAILABLE` → `SalesContractException`; malformed → `DEPENDENCY_UNAVAILABLE`.
- SQL: draft-only `006_sales_inquiry_group_f.sql` (`-- Kind: draft`) reads committed Group D projections; Sales never reads Catalog/Partner/Pricing/Inventory tables (snapshots come from committed order rows).
- **Runtime caveat:** inquiry reads return `DEPENDENCY_UNAVAILABLE` until the draft RPCs are promoted and projections exist; wiring proven by codegen + unit/startup tests.
- Verification: `dart analyze` + `dart test` Sales application/infrastructure green (144 tests); `melos run migrate:verify-policy -- --strict` OK; `verify_harness.sh` fails only on pre-existing `guard_presentation_size` debt. E2E remains `todo`.

## Group F-ops BE integration + post-sale entry completion — 2026-08-07

- S20–S21 BE marked `done`. **S20** adds `GetIntegrationCommandStatus`/`GetImpactRequestStatus` reads (viewIntegrationStatus) + `RetryIntegrationCommand`/`ReconcileIntegrationResultCommand` (commands) via `ISalesIntegrationGateway`; `GetOrderIntegrationStatusQuery` reused from S13 (**owner draft `004`**). **S21** adds `GetAvailablePostSaleActions` (viewOrder) via `IPostSaleActionsGateway`. Authoritative prechecks live on later owners: adjustment `009`, cancellation `010`, return `012` — **not** on `008` after Option (b) ownership correction. Query handlers enforce their permission explicitly (QueryBus skips the auth pipeline); commands go through the pipeline.
- **Boundary discipline:** retry/reconcile **enqueue integration work and return the recomputed order integration status** — they never write Inventory/Receivable/E-invoice owner tables. Available-actions is **read-only advisory**; authoritative prechecks are owned by Group H/I drafts (~~Group G~~ superseded).
- **Gateways are required, DI-injected** (`ISalesIntegrationGateway`, `IPostSaleActionsGateway` registered in `SalesDataAccessModule`); the regenerated `sales_cqrs_registrar.g.dart` injects them — no dead-wiring.
- Infrastructure: `SupabaseSalesIntegrationGateway` + `SalesIntegrationRpcMapper` → `sales.get_integration_command_status`/`get_impact_request_status`/`retry_integration_command`/`reconcile_integration_result`; `SupabasePostSaleActionsGateway` + `PostSaleActionsRpcMapper` → `sales.get_available_post_sale_actions` (008). Error families incl. `IMPACT_PENDING`/`STALE_VERSION`/`IDEMPOTENCY_CONFLICT` (integration) map to `SalesContractException`; malformed → `DEPENDENCY_UNAVAILABLE`.
- SQL: draft-only `007_sales_integration_group_f.sql` + `008_sales_post_sale_actions_group_f.sql` (`-- Kind: draft`); `008 -- Touches:` = `sales.get_available_post_sale_actions` only.
- **Runtime caveat:** returns `DEPENDENCY_UNAVAILABLE` until integration adapters + projections are live; wiring proven by codegen + unit/startup tests.
- Verification: `dart analyze` + `dart test` Sales application/infrastructure green; `melos run migrate:verify-policy -- --strict` OK; `verify_harness.sh` fails only on pre-existing `guard_presentation_size` debt. E2E remains `todo`/`blocked`.

## Group F BE–FE integration — 2026-08-12

- S15–S21 FE marked `done` for BE–FE integration (E2E remains `blocked`). **S15:** `SalesOrderListCubit` → `ListSalesOrdersQuery`/`SearchSalesOrdersQuery` with server cursor + typed filters; active-store scope via `ISalesActiveStoreContext`; no `so-demo-*` / fixed `DateTime(2026, 7, 29` production markers.
- **S16–S18:** `SalesOrderDetailCubit` core + independent payment/history/return section loaders; blocked/not-found/projection-pending/error UI; typed mappers/VMs.
- **S19:** slip preview/print/share reuses Group E receipt surface (`SalesReceiptOperationHandler`).
- **S20:** integration section + retry/reconcile enqueue-only; summary status from draft `004`, command/impact ops from `007`.
- **S21:** available-actions (cancel + return; ~~adjust~~ superseded); authoritative prechecks before navigation intents.
- **Static guard:** `apps/erp/test/features/sales/group_f_no_demo_contract_test.dart` covers explicit Group F production file list only.
- **Ownership:** `004` integration summary; `006` inquiry; `007` recovery; `008` available-actions only; `009`/`010`/`012` authoritative prechecks. Residual debts: draft `011` envelope, baseline analyze/test noise outside Sales.
- **E2E blockers:** draft promote/apply for `004`/`006`/`007`/`008` (+ owner prechecks), live projections, and seed IDs — do not claim live E2E pass.
- Verification evidence recorded in `docs/harness/PROGRESS.md` Phase 1.8.6 (workspace delta vs baseline).

## Group G BE order-note adjustment — **superseded** (was 2026-08-10)

> EP-04 / S22 / SG-09 **out of scope**. Implementation removed. Historical notes below are archival only — do not treat as live status.

- ~~S22 BE marked `done`~~ → lanes `n/a`. OrderAdjustment CQRS/RPC/table gỡ khỏi deliver.
- Historical: note-only domain, apply/history handlers, gateway, draft SQL `009` — **withdrawn**.

## Group G BE–FE note-adjustment integration — **superseded** (was 2026-08-12)

> Same as above — SG-09 / `SalesOrderAdjustCubit` / Group G guards removed from active deliver.

## Group H BE cancellation completion — 2026-08-10

- S23–S27 BE marked `done`: cancellation domain decision model (`CancellationReason`, expanded precheck snapshot, confirmation evidence, no reopen), focused `ISalesOrderCancellationGateway` + precheck/confirm/detail handlers, S23 return-conflict adapter over inquiry return summary, S24 reason validation on confirm (no separate mutation), S25 atomic confirm (idempotent/versioned/refund-free), S26 typed impact retries + cancellation-aware retry/reconcile draft, S27 authoritative cancellation detail reusing Group E/F inquiry/timeline/payment/receipt/integration reads, Supabase mapper/gateway, DI + generated CQRS wiring, and focused tests. CONTRACT/FE unchanged; E2E remains `todo`.
- SQL remains **draft-only and unapplied**: `supabase/migrations/_drafts/010_sales_order_cancellation_group_h.sql` (precheck/confirm/detail) and `supabase/migrations/_drafts/011_sales_cancellation_impacts_group_h.sql` (typed retry/reconcile). Draft contract tests do **not** claim live Postgres execution or promotion.
- Live E2E is blocked by: external Pricing/Inventory/Receivable/E-invoice owner contracts; unresolved authoritative store-scope ownership; unpromoted/unapplied Group D/H drafts (and dependent Group F advisory precheck replacement ordering).
- Thirty-five scenario IDs in §S23–§S27 now have concrete domain/application/infrastructure/SQL evidence mappings (payment/return/cancellation blockers + read-only precheck; reason/no-refund/stale settlement; idempotency/version/processing/atomic impacts; not-required vs pending + typed retry/reconciliation/no reopen; authoritative detail + reused projections).

## Group I BE return/exchange completion — 2026-08-10

- S28–S34 BE marked `done`: eligibility/precheck + technical session (I1), versioned valuation/settlement difference (I2), confirm/complete + return-status projection (I3). Ports: `IReturnExchangeReadGateway` / `IReturnExchangeCommandGateway` / `IReturnExchangeSettlementGateway` / `IReturnExchangeReferencePort` (server-only Catalog/Pricing/Inventory decisions). CONTRACT/FE unchanged; E2E remains `todo`.
- SQL remains **draft-only and unapplied**: `012_sales_return_exchange_group_i_session.sql`, `013_sales_return_exchange_group_i_settlement.sql`, `014_sales_return_exchange_group_i_confirmation.sql`. Draft contract tests do **not** claim live Postgres execution or promotion.
- Binding decisions recorded in §S28–§S34: sign convention `settlementDifference = returnValue - exchangeValue`; server-only `reference_decision` inputs; frozen public DTOs omit user reason/condition/entrySource (nullable server-only storage); Group F return-summary + integration reads reused (014 does not own `get_sales_order_return_summary`).
- Forty-seven scenario IDs mapped (S28:7 S29:7 S30:7 S31:5 S32:7 S33:7 S34:7). S31 SCN-01..03 are runtime/FE working-state evidence; BE covers discard + reservation release + no draft list/restore.
- Live E2E blocked by: unavailable Inventory/Pricing/Receivable/E-invoice owner contracts; unresolved authoritative store-scope ownership; unpromoted/unapplied Group I (and dependent) drafts.

## FE preview entry (2026-07-31)

- Sales FE **widget preview** sống tại `modules/sales/presentation/example/` — chạy `vet45 run sales_presentation debug` (hoặc `debug:web` / `debug:ios`).
- Example = catalog + `PreviewSection` stubs (order note / blocker placeholders); **không** thay ERP pages và **không** claim FE slice roadmap `done`.
- ERP `features/sales` pages vẫn `todo`; khi ship public widget trong `presentation/lib` → cùng PR thêm section trong example.
- Phân biệt: `vet45 run design_system debug` (hoặc `melos run design-system:example`) = DS primitives; `sales_presentation` = BC Sales widgets.

## Domain layer (2026-07-30)

- `modules/sales/domain` implements aggregates from `01-domain-model.md` (+ calculators/policies); ~~`OrderAdjustment`~~ superseded.
- Kernel `Money` / `Quantity` live in `vet45_shared_domain` (pricing/accounting local Money chưa migrate).
- Status enums exist under `lib/src/enums/` and are exported via `package:vet45_sales_domain/enums.dart` — **not** from `domain.dart` — để tránh đụng tên với application `sales_contract_enums.dart` (CONTRACT freeze). Migration gộp enum = follow-up khi BE handlers land.
- Repository ports hoãn sang BE/application slice.

## Source gap

Canonical source nhiều lần tham chiếu “Appendix 6.1” cho route/request/response/error contract nhưng file kết thúc tại §5.5.14. Harness xử lý bằng contract catalog có symbol/owner/permission/idempotency/RPC target/error family/fake scenario; không tự bịa field-level wire shape.

Khi một BE/FE slice bắt đầu:

1. Review US + canonical data/UI sections.
2. Đọc field/nullability/error semantics đã frozen trong `07-api-contracts.md`.
3. Dùng public symbols/provider ports/fake scenario definition hiện có.
4. Nếu evidence buộc đổi contract, quay lại CONTRACT review; không thêm nullable placeholder.

## Guards áp dụng

| Guard | Mục đích |
| --- | --- |
| `guard_theme_structure.sh` | README/OVERVIEWS/harness/Epic/US structure |
| `guard_theme_traceability.sh` | Role/test-id shape; exemplar deferred ở bootstrap |
| `guard_docs_reference.sh` | Agent/reference docs không stale |
| `guard_layer_imports.sh` | Layer boundary khi code bắt đầu |
| `guard_codegen_fresh.sh` | Generated registrars/access metadata |
| `guard_presentation_size.sh` | Page ≤ 500 dòng |
| `guard_presentation_dialogs.sh` | Không inline dialog trong page |

Umbrella: `scripts/ci/verify_harness.sh`.

## Known E2E blockers

| Capability | Blocker | Lane policy |
| --- | --- | --- |
| Checkout với no-negative-stock | Inventory authoritative availability/commit chưa hoàn chỉnh | Chỉ E2E blocked; fake port cho BE/FE |
| Checkout còn phải thu | TH-06 Accounting/Receivable contract + ledger owner còn skeleton | Chỉ E2E blocked |
| Cancellation impacts | Pricing/Inventory/Receivable/E-invoice coordinated outcomes; Group H BE is draft-backed only (`010_sales_order_cancellation_group_h.sql`, `011_sales_cancellation_impacts_group_h.sql` unpromoted/unapplied); authoritative store-scope ownership unresolved | Contract/BE/FE vẫn actionable; E2E blocked |
| Return/exchange settlement | Inventory + Pricing + Receivable owner contracts; Group I BE/FE is draft-backed only (`012`/`013`/`014`/`020` unpromoted/unapplied); authoritative store-scope ownership unresolved | Contract/BE/FE vẫn actionable; E2E blocked |
| E-invoice projection/policy | TH-08 chưa có owner module | Catalog contract; không giả định provider |
| Reporting projections | TH-10 consumer chưa có contract | Sales publish catalog; không block transaction |

Blocker ngoài module không được biến thành lý do block toàn slice.

## Pitfalls

- Không dùng Sales implementation skeleton làm golden module; application contract docs + Dart Phase 1 sync là boundary truth; implementation pattern mirror IAM.
- ~~Phase 1 EP-04 chỉ `order_note`~~ — **EP-04 superseded / out of scope** (không deliver adjust).
- Phase 1 EP-06 US-04 là session working state + discard — không ship user draft list / “Lưu và đóng”.
- ~~Lock không chặn sửa note (EP-04 US BR-03)~~ — superseded cùng EP-04.
- Không gom order/payment/return/integration vào một status hoặc aggregate.
- Không coi working state là persisted draft (order drafting hoặc return session).
- Không coi precheck là authoritative commit validation.
- Không dùng read projection làm input authoritative cho mutation.
- Không ghi payment/refund bằng update/delete transaction gốc.
- Không update bảng Catalog/Partner/Pricing/Inventory/Accounting từ Sales RPC.
- Không dùng `double` cho tiền.
- Không ghi outbox/impact sau commit theo best effort.
- Không coi RPC draft là migration đã apply.
- Không phát `sales_receipt_generated.v1` khi chưa có consumer nghiệp vụ. (~~`order_adjustment_applied.v1`~~ superseded với EP-04.)

## Verify chain cho harness bootstrap

```bash
./scripts/ci/guard_theme_structure.sh
./scripts/ci/guard_theme_traceability.sh
./scripts/ci/guard_docs_reference.sh
./scripts/ci/verify_harness.sh
```

Coverage checks (sau CONTRACT code sync 2026-07-30):

```text
6 Epic README
34 flat US files
235 FR definitions
34 roadmap slices (S01–S34)
34 API contract sections
234 canonical fake scenario IDs (Dart registry synced)
8 harness files
```

## Re-harness Theme-5 Phase 1 — 2026-07-30

- Canonical Theme-5 từng thu hẹp EP-04 → 1 US (`order_note_update`); EP-06 US-04 → session discard. **EP-04 / S22 sau đó superseded (2026-09-07).**
- Product tree + harness 00–07 đồng bộ; **slice renumber:** cũ S27–S38 → S23–S34; EP-04 = S22 (nay out of scope).
- **CONTRACT code sync (historical):** note-only adjustment fakes — withdrawn với S22.
- Không “fix” wording lệch còn lại trong chính Theme-5 (§4.1 vs §4.5).

## Contract completion — 2026-07-27

- `SalesPermissions` dùng canonical permission code; refund chỉ có `sales.payment.refund`.
- Public application barrel export Money/Quantity/snapshot/status DTOs, provider ports và Sales-owned CQRS symbols (số lượng/shape có thể lệch Phase 1 docs).
- Provider-owned Partner/Catalog/Pricing/Receivable commands không bị sao chép vào Sales.
- Payment intent S09 là runtime input của `FinalizeSalesOrderCommand`, không có persisted payment-intent RPC.
- RPC trong contract đều `contract-only / unimplemented`; phase docs không tạo SQL, handler, gateway hoặc UI.

## Group I BE–FE return/exchange integration — 2026-08-13

- S28–S34 FE marked `done` for BE–FE production integration (E2E remains `todo`/`blocked`). Cubits: `SalesReturnExchangeSessionCubit` / `SettlementCubit` / `DetailCubit` + attempt factory + mapper; ERP thin pages for create/settle/result/detail/preview; identity routes include `:returnExchangeId`.
- **Contract extension (draft-only):** `_drafts/020_sales_return_exchange_fe_contract_group_i.sql` owns `get_return_exchange_form_policy` + `get_return_exchange_detail`; in-place extensions on `012`/`013`/`014` for reason/condition/entrySource/settlement plan. Sign: `settlementDifference = returnValue - exchangeValue`.
- **SG-12:** read-only settlement plan UI — no payment/debt/due-date controls.
- **Slip/PDF:** `SalesSlipPdfGenerator.generateReturnExchange` requires `SalesReturnExchangeDetailVm`; preview loads detail by ID before PDF.
- **Legacy deleted:** god `SalesReturnExchangeCubit`/`SalesReturnExchangeVm`, module demo result/detail pages, settlement payment/debt widgets.
- **Static guard:** `apps/erp/test/features/sales/group_i_no_demo_contract_test.dart` (explicit Group I file list + route `:returnExchangeId` assertions). Group F guard no longer lists deleted VM / demo-page exclusions.
- **Do not claim live E2E:** drafts unpromoted/unapplied; Inventory/Pricing/Receivable/E-invoice owner adapters + store-scope + tenant policy seed still required. Manual SQL Editor apply ≠ migration promotion.

## Remove unused policy / reservation tables — 2026-09-07

- **Decision:** xoá bốn bảng không còn phục vụ tính năng hiện tại trên môi trường test (chấp nhận mất data, không backfill): `return_exchange_reason_policy`, `return_exchange_condition_policy`, `return_exchange_reservation_refs`, `checkout_store_policies`.
- **Evidence (source):** intent `016_sales_remove_unused_policy_tables` đã được re-baseline vào hai generation `20260827*` / `20260830*` và owner `20260904001`; contract test `sales_remove_unused_policy_tables_sql_contract_test.dart`; focused return-exchange mapper/gateway/application + ERP cubit tests xanh. Không khôi phục requested-event/outbox command cũ.
- **Dart Task 5–6:** start/update `reserveExchangeStock: false`; mapper bỏ `reservation_ids`; cancel chỉ `commandGateway`; UI message không đòi lý do/tình trạng; port/DTO reservation giữ tương thích nhưng không còn caller production reserve/release trong flow này.
- **Live evidence:** transaction đã apply thành công qua SQL Editor theo xác nhận người dùng; smoke scenarios vẫn chưa chạy. Verification checklist: `docs/operations/sales-remove-unused-policy-tables-verification.md`.

## Durable impact handoff preparation — 2026-08-26 (normalize 2026-09-04)

- TH-05 stops at durable backlog: impact `business_status = pending`, initial `integration_commands` `queued` (`command_version=1`, `attempt_count=0`, `max_attempts=5`, `command_name` `sales.inventory.apply_impact.v1` / `sales.receivable.apply_impact.v1`) — **no** typed impact outbox; backlog **not** consumed yet.
- **No fake `accepted`:** nothing in Sales marks owner ledger success; UI shows “Đang chờ module xử lý” for pending/queued.
- **No worker binding:** Sales/Inventory/Accounting not added to `messaging_worker` default bindings; impact **commands** remain intentional pending backlog.
- **TH-08 E-invoice deferred:** no new `sales.e_invoice_impact_requests` inserts from checkout/cancellation/return-exchange drafts in scope; read path falls back to `notRequired`.
- Helper `sales.enqueue_impact_handoff` in draft `006`; mutations in drafts `008`/`011`/`012`–`014`; retry guard + status projection in draft `015`; Model B normalize (facts-only outbox + apply_impact command names) in draft `016_sales_normalize_outbox_and_commands.sql`. All remain **draft-only / unpromoted**.
- Boundary: Sales never `insert into inventory.*` / `accounting.*`. Live owner consumption + E2E await canonical TH-06/TH-07.
- Spec: `docs/superpowers/specs/2026-08-26-sales-impact-messaging-design.md`; plan: `docs/superpowers/plans/2026-08-26-th05-impact-handoff-preparation.md` (outbox `*.requested` approach superseded by Model B / draft `016`).

## Flywheel log

| Date | Observation | Harness response |
| --- | --- | --- |
| 2026-07-27 | Catalog cũ dùng TH-05 cho Công nợ | Renumber toàn catalog đến TH-12 |
| 2026-07-27 | Source monolith khó đọc theo slice | Tách file `US-xx.md`, giữ canonical nguyên vẹn |
| 2026-07-27 | Mỗi US nằm trong một thư mục riêng làm cây tài liệu sâu | Chuyển sang `Epic-*/US-xx.md`; Epic `README.md` là trang tổng hợp |
| 2026-07-27 | Scenario format không đồng nhất (`SC\-xx`, `Scenario: SC-xx`) | Chuẩn hóa derived docs thành `SCN-xx`; fake ID ổn định |
| 2026-07-27 | Appendix 6.1 bị thiếu | Catalog contract trước, freeze field-level theo slice |
| 2026-07-27 | DDD example trỏ file Sales không tồn tại | Chuyển reference sang TH-05 `01-domain-model.md` |
| 2026-07-27 | Section mới chỉ catalog, chưa có compile boundary | Freeze application contract theo wave; giữ BE/FE/E2E `todo` |
| 2026-07-30 | Theme-5 thu hẹp EP-04 note-only + EP-06 session discard | Re-harness docs; renumber S23+ |
| 2026-07-30 | Dart contracts còn whitelist/draft CRUD | Sync application DTOs/fakes → 234 scenarios; đóng debt |
| 2026-07-31 | Cần preview FE Sales trước ERP pages | Module `presentation/example` + `vet45.target.json` (`sales_presentation`); FE roadmap vẫn `todo` |
| 2026-08-12 | ~~Group G S22 BE–FE production integration~~ | **Superseded 2026-09-07** — EP-04/S22 out of scope; lanes `n/a` |
| 2026-09-07 | EP-04 / S22 order-note adjustment withdrawn | Roadmap/traceability/contracts/domain: Group G superseded; product US kept with banner |
| 2026-08-26 | TH-05 durable Inventory/Receivable impact handoff (typed events + enqueue helper + pending/queued UI); no owner consumer | Sync §S12/S20/S25/S26/S34 contracts; roadmap blockers → handoff done / E2E chờ TH-06/TH-07; no fake accepted; no worker binding; TH-08 deferred; drafts unpromoted |
