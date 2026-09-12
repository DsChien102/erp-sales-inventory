# TH-05 — Traceability

<!-- exemplar-complete: deferred -->

Ma trận bao phủ **6 Epic, 34 US, 235 FR**. Hầu hết US dùng row `FR-01..07`; EP-04/US-01 dùng `FR-01..05`; EP-06/US-04 dùng `FR-01..06`.

```text
Requirement: TH-05/EP-{nn}/US-{nn}/FR-{nn}
BE test: scn_e{epic}_u{us}_fr{fr}_{case}
FE test: wgt_e{epic}_u{us}_fr{fr}_{case}
E2E test: e2e_e{epic}_u{us}_fr{fr}_{case}
```

Exemplar giữ `deferred` đến khi slice đầu tiên hoàn tất đủ bốn lane. CONTRACT đã hoàn tất cho S02–S34 (docs); BE/FE/E2E vẫn chưa bắt đầu. Slice IDs sau EP-04 đã renumber (cũ S27–S38 → S23–S34).

## S01 — [EP-01/US-01](../Epic-01-order-drafting-and-drafts/US-01.md) — Khởi tạo đơn hàng đang lập

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-01 | CONTRACT | §S01 | application contract | SalesOrderWorkingState (no Sales CQRS) | — | n/a |
| FR-01..07 | BE | §S01 | domain/application/infrastructure | aggregate rules + handlers/gateways for Khởi tạo đơn hàng đang lập | — | n/a |
| FR-01..07 | FE | §S01 | presentation | US screen-group manifest + ISalesModule/fake | wgt_e01_u01_fr01_01 | done |
| FR-01..07 | E2E | §S01 | integration | ERP DI + authoritative owner contracts | e2e_e01_u01_fr01_01 | todo |

## S02 — [EP-01/US-02](../Epic-01-order-drafting-and-drafts/US-02.md) — Xác định khách hàng cho đơn hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-02 | CONTRACT | §S02 | application contract | SearchPartnersQuery; CreatePartnerCommand (Partner-owned) | — | done |
| FR-01..07 | BE | §S02 | application/infrastructure runtime ports | `SalesOrderDraftingService` + `IPartnerCustomerPort`/fake; customer select/clear preserves lines and marks pricing stale | `group_a_order_drafting_service_test.dart` S02 cases | done |
| FR-01..07 | FE | §S02 | presentation | US screen-group manifest + ISalesModule/fake | wgt_e01_u02_fr01_01 | todo |
| FR-01..07 | E2E | §S02 | integration | ERP DI + authoritative owner contracts | e2e_e01_u02_fr01_01 | todo |

## S03 — [EP-01/US-03](../Epic-01-order-drafting-and-drafts/US-03.md) — Thêm và quản lý dòng hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-03 | CONTRACT | §S03 | Catalog application contract | `SearchSellableProductsQuery`; `ResolveSellableBarcodeQuery`; `ListSellableProductUnitsQuery` | — | done |
| FR-01..07 | BE | §S03 | Catalog infrastructure RPC | `catalog.search_sellable_products`; `catalog.resolve_sellable_barcode`; `catalog.list_sellable_product_units` | Catalog mapper/startup/SQL contract tests | done |
| FR-01..07 | FE | §S03 | Sales presentation + ERP adapter | required Catalog callbacks; no fake fallback | product picker/cubit + `sales_flow_pages_test.dart` | done |
| FR-01..07 | E2E | §S03 | guarded live integration | active IAM store + authoritative Catalog | `sales_group_a_s03_s05_live_test.dart` | blocked — drafts applied; missing live seed IDs/live pass |

## S04 — [EP-01/US-04](../Epic-01-order-drafting-and-drafts/US-04.md) — Kiểm tra và điều chỉnh giá bán

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-04 | CONTRACT | §S04 | Pricing application contract | `PreviewSalesWorkingStatePricingQuery`; `EvaluateSalesManualPriceQuery` | — | done |
| FR-01..07 | BE | §S04 | Pricing infrastructure RPC | strict line-set preview; manual floor/permission evaluation | Pricing application/mapper/startup/SQL tests | done |
| FR-01..07 | FE | §S04 | versioned Sales compose state machine | stale response drop; blocker-aware checkout; no local-success fallback | `sales_compose_pricing_cubit_test.dart`; sheet/adapter/page tests | done |
| FR-01..07 | E2E | §S04 | guarded live integration | authoritative Pricing preview/manual policy | `sales_group_a_s03_s05_live_test.dart` | blocked — draft applied; missing live seed IDs/live pass |

## S05 — [EP-01/US-05](../Epic-01-order-drafting-and-drafts/US-05.md) — Lưu giá riêng hoặc nhớ giá từ đơn hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-05 | CONTRACT | §S05 | Pricing owner contracts | `ResolveApplicableCustomerPriceRuleQuery`; `CreateCustomerPriceRuleCommand`; `UpdateCustomerPriceRuleCommand` | — | done |
| FR-01..07 | BE | §S05 | Pricing CQRS/RPC | create/update private rule immediately on Apply; stable idempotency and read-back recovery | Pricing existing rule suites + Sales adapter recovery tests | done |
| FR-01..07 | FE | §S05 | sheet + ERP orchestration | walk-in disabled; floor/overwrite confirm; BE succeeds before cubit mutation | sheet, adapter, compose page regressions | done |
| FR-01..07 | E2E | §S05 | guarded live integration | immediate create/update and owned-rule cleanup | `sales_group_a_s03_s05_live_test.dart` | blocked — draft applied; missing live seed IDs/live pass and cleanup evidence |

## S06 — [EP-01/US-06](../Epic-01-order-drafting-and-drafts/US-06.md) — Lưu đơn hàng thành đơn nháp

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-06 | CONTRACT | §S06 | application contract | SaveSalesOrderDraftCommand; UpdateSalesOrderDraftCommand | — | done |
| FR-01..07 | BE | §S06 | application/infrastructure + draft SQL | Full working-state snapshot save/update (`storeId`, customer/order/line/pricing fields, no floor/stock); `ISalesOrderDraftGateway` + mapper/Supabase (+ stale in-memory residual); six stable errors; draft-only `001_sales_order_drafts_group_b.sql` (unpromoted) | Green: `sales_order_draft_handlers_test.dart`; `sales_order_draft_rpc_mapper_test.dart`; `sales_order_draft_sql_contract_test.dart`; `sales_group_b_startup_test.dart`. Residual red (not green evidence): `in_memory_sales_order_draft_gateway_test.dart`; `sales_authorization_test.dart` (stale pre-snapshot ctors / Task 4 out of scope) | done (green suites only; InMemory + auth suites residual red) |
| FR-01..07 | FE | §S06 | presentation + ERP orchestration | Compose persist via `SalesDraftBackend.bindPersist` (Catalog/Partner/Pricing mediators → Sales commands); no production fake draft store | `sales_compose_draft_backend_test.dart`; `sales_draft_backend_test.dart`; `group_b_no_fake_contract_test.dart`; `sales_flow_pages_test.dart` | done |
| FR-01..07 | E2E | §S06 | guarded live integration | `sales_group_b_s06_s07_live_test.dart` (`VET45_RUN_LIVE_GROUP_B`); requires applied draft RPCs + `VET45_E2E_*` seeds | `sales_group_b_s06_s07_live_test.dart` | blocked — disabled gate skips; live gate not run (missing seeds + draft `001` not promoted/applied) |

## S07 — [EP-01/US-07](../Epic-01-order-drafting-and-drafts/US-07.md) — Khôi phục và quản lý đơn nháp

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-07 | CONTRACT | §S07 | application contract | ListSalesOrderDraftsQuery; GetSalesOrderDraftForRestoreQuery; UpdateSalesOrderDraftCommand; CancelSalesOrderDraftCommand | — | done |
| FR-01..07 | BE | §S07 | application/infrastructure + draft SQL | Store-scoped list/restore/update/cancel; active-only list/restore; expected-version + idempotent update/cancel; same six stable errors + draft SQL `001` | Green: `sales_order_draft_handlers_test.dart`; `sales_order_draft_rpc_mapper_test.dart`; `sales_order_draft_sql_contract_test.dart`; `sales_group_b_startup_test.dart`. Residual red (not green evidence): `in_memory_sales_order_draft_gateway_test.dart`; `sales_authorization_test.dart` (same stale InMemory/auth residual as S06) | done (green suites only; InMemory + auth suites residual red) |
| FR-01..07 | FE | §S07 | presentation + ERP orchestration | Draft list cubit + compose restore via `SalesDraftBackend.bindRestore` with Catalog/Partner/Pricing revalidation issues | `sales_draft_list_live_test.dart`; `sales_compose_draft_backend_test.dart`; `sales_flow_pages_test.dart` | done |
| FR-01..07 | E2E | §S07 | guarded live integration | Same guarded live lifecycle as S06 (list/restore/update/idempotent/stale/cancel) | `sales_group_b_s06_s07_live_test.dart` | blocked — same seed + unpromoted draft RPC blockers as S06; do not claim E2E done |

## S08 — [EP-02/US-01](../Epic-02-checkout-and-completion/US-01.md) — Kiểm tra tổng tiền và nghĩa vụ thanh toán

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-01 | CONTRACT | §S08 | application contract | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand | — | done |
| FR-01..07 | BE | §S08 | application/infrastructure + draft SQL | `CheckoutPaymentIntentValidator`, `CheckoutPrecheckService`, `PrecheckSalesOrderCheckoutQueryHandler` (required `ICheckoutGateway`), `CheckoutPrecheckRpcMapper`, `SupabaseCheckoutGateway`, `_drafts/002_sales_checkout_group_c_precheck.sql`; integer-money totals, remaining amount, paid/partial/unpaid preview, overpayment/currency/amount blockers | `group_c_payment_intent_test.dart`; `checkout_precheck_rpc_mapper_test.dart`; `supabase_checkout_gateway_test.dart`; `sales_checkout_group_c_sql_contract_test.dart`; `sales_group_c_startup_test.dart` | done |
| FR-01..07 | FE | §S08 | presentation + ERP orchestration | SalesCheckoutDraftSnapshot; SalesCheckoutSnapshotMapper; SalesCheckoutCubit -> PrecheckSalesOrderCheckoutQuery -> required ICheckoutGateway; checkout precheck panel; typed GoRouter extra; stale-response guard; group_c_no_finalize_contract_test; sales_group_c_s08_s11_live_test | `sales_checkout_cubit_test.dart`; `sales_checkout_snapshot_mapper_test.dart`; `sales_checkout_page_test.dart`; `group_c_no_finalize_contract_test.dart` | done |
| FR-01..07 | E2E | §S08 | guarded live integration | `sales_group_c_s08_s11_live_test.dart` (`VET45_RUN_LIVE_GROUP_C`); requires applied draft RPC + `VET45_E2E_*` seeds; disabled gate skip is not a pass | `sales_group_c_s08_s11_live_test.dart` | blocked — 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required |

## S09 — [EP-02/US-02](../Epic-02-checkout-and-completion/US-02.md) — Ghi nhận một hoặc nhiều khoản thanh toán

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-02 | CONTRACT | §S09 | application contract | FinalizeSalesOrderCommand; InitializeSalesOrderSettlementCommand; RecordSalesPaymentCommand | — | done |
| FR-01..07 | BE | §S09 | application/infrastructure | `FinalizeSalesOrderCommandValidator`, `FinalizeSalesOrderCommandHandler`, `CheckoutPaymentIntentValidator`; payment intents remain runtime checkout input, no persisted payment-intent RPC/table; the finalize handler validation surface stays frozen; handler commit behavior lands in S12 (delegates to `ICheckoutGateway.finalize`, no transactions on `blocked`) | `group_c_finalize_validation_test.dart`; `contract_catalog_test.dart` Group C fixture coverage | done |
| FR-01..07 | FE | §S09 | presentation + ERP orchestration | SalesCheckoutDraftSnapshot; SalesCheckoutSnapshotMapper; SalesCheckoutCubit -> PrecheckSalesOrderCheckoutQuery -> required ICheckoutGateway; checkout precheck panel; typed GoRouter extra; stale-response guard; group_c_no_finalize_contract_test; sales_group_c_s08_s11_live_test | `sales_checkout_cubit_test.dart`; `sales_checkout_page_test.dart`; `group_c_no_finalize_contract_test.dart` | done |
| FR-01..07 | E2E | §S09 | guarded live integration | Same guarded live precheck gate as S08 (`VET45_RUN_LIVE_GROUP_C`); payment intents runtime-only; no finalize in Group C path | `sales_group_c_s08_s11_live_test.dart` | blocked — 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required |

## S10 — [EP-02/US-03](../Epic-02-checkout-and-completion/US-03.md) — Xử lý đơn hàng còn phải thu

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-03 | CONTRACT | §S10 | application contract | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand; InitializeSalesOrderSettlementCommand | — | done |
| FR-01..07 | BE | §S10 | domain/application/infrastructure | `ICheckoutReceivablePolicyPort`/fake + `CheckoutPrecheckService`; outstanding calculation, walk-in receivable blocker, eligible identified customer requirement, due-date-required contract gap surfaced as blocker; Sales does not write Theme 6 ledger | `group_c_receivable_requirement_test.dart`; `settlement_and_receipt_aggregate_test.dart`; `calculators_and_policy_test.dart` | done |
| FR-01..07 | FE | §S10 | presentation + ERP orchestration | SalesCheckoutDraftSnapshot; SalesCheckoutSnapshotMapper; SalesCheckoutCubit -> PrecheckSalesOrderCheckoutQuery -> required ICheckoutGateway; checkout precheck panel; typed GoRouter extra; stale-response guard; group_c_no_finalize_contract_test; sales_group_c_s08_s11_live_test; DUE_DATE_REQUIRED rendered fail-closed (no dueDate field on frozen query) | `sales_checkout_cubit_test.dart`; `sales_checkout_page_test.dart`; `group_c_no_finalize_contract_test.dart` | done |
| FR-01..07 | E2E | §S10 | guarded live integration | Same guarded live precheck gate as S08; due-date gap remains CONTRACT review | `sales_group_c_s08_s11_live_test.dart` | blocked — 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required |

## S11 — [EP-02/US-04](../Epic-02-checkout-and-completion/US-04.md) — Kiểm tra điều kiện checkout

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-04 | CONTRACT | §S11 | application contract | PrecheckSalesOrderCheckoutQuery; FinalizeSalesOrderCommand | — | done |
| FR-01..07 | BE | §S11 | application/infrastructure + draft SQL | `ICheckoutReferencePrecheckPort`/fake + `CheckoutPrecheckService`; product/sellability, pricing-changed, inventory, dependency unavailable and in-handler permission enforcement; `sales.precheck_sales_order_checkout` draft remains unapplied | `group_c_checkout_precheck_test.dart`; `sales_authorization_test.dart`; `sales_checkout_group_c_sql_contract_test.dart`; `sales_group_c_startup_test.dart` | done |
| FR-01..07 | FE | §S11 | presentation + ERP orchestration | SalesCheckoutDraftSnapshot; SalesCheckoutSnapshotMapper; SalesCheckoutCubit -> PrecheckSalesOrderCheckoutQuery -> required ICheckoutGateway; checkout precheck panel; typed GoRouter extra; stale-response guard; group_c_no_finalize_contract_test; sales_group_c_s08_s11_live_test | `sales_checkout_cubit_test.dart`; `sales_checkout_page_test.dart`; `group_c_no_finalize_contract_test.dart` | done |
| FR-01..07 | E2E | §S11 | guarded live integration | Same guarded live precheck gate as S08 (`VET45_RUN_LIVE_GROUP_C`); disabled gate skip is not a pass | `sales_group_c_s08_s11_live_test.dart` | blocked — 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required |

## S12 — [EP-02/US-05](../Epic-02-checkout-and-completion/US-05.md) — Hoàn tất đơn hàng an toàn

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-05 | CONTRACT | §S12 | application contract | FinalizeSalesOrderCommand; GetCheckoutResultQuery | — | done |
| FR-01..07 | BE | §S12 | domain/application/infrastructure | domain `SalesOrder.finalize` + settlement/payment invariants; finalize handler → `ICheckoutGateway`; draft `008_sales_checkout_rpcs.sql` + shared helper `006` (`sales.enqueue_impact_handoff`); Model B handoff = impact request + `integration_commands` (`sales.inventory.apply_impact.v1` / `sales.receivable.apply_impact.v1`) — **no** typed impact outbox; draft `016_sales_normalize_outbox_and_commands.sql` authority for normalized RPC bodies | `group_d_finalize_checkout_commit_test.dart`; `supabase_checkout_gateway_test.dart`; `sales_checkout_group_d_sql_contract_test.dart`; `sales_shared_rpc_helpers_sql_contract_test.dart`; `sales_apply_impact_command_payload_test.dart`; `sales_startup_test.dart` S12 wiring | done |
| FR-01..07 | FE | §S12 | presentation | US screen-group manifest + ISalesModule/fake | wgt_e02_u05_fr01_01 | done |
| FR-01..07 | E2E | §S12 | integration | ERP DI + live TH-06/TH-07 owner consumption (handoff backlog ready) | e2e_e02_u05_fr01_01 | todo |

## S13 — [EP-02/US-06](../Epic-02-checkout-and-completion/US-06.md) — Xem kết quả giao dịch

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-06 | CONTRACT | §S13 | application contract | GetCheckoutResultQuery; GetSalesOrderQuery; GetSalesOrderPaymentSummaryQuery; GetOrderIntegrationStatusQuery | — | done |
| FR-01..07 | BE | §S13 | application/infrastructure | read handlers `GetSalesOrderQueryHandler` (viewOrder), `GetSalesOrderPaymentSummaryQueryHandler` (viewPayment), `GetOrderIntegrationStatusQueryHandler` (viewIntegrationStatus) — each enforces its permission explicitly and delegates to `ISalesOrderReadGateway`; `GetCheckoutResultQuery` reused from S12; `CheckoutResultViewDto` is client-composed (no aggregating query); `SupabaseSalesOrderReadGateway` + `SalesOrderReadRpcMapper`; draft-only `supabase/migrations/_drafts/004_sales_read_group_e.sql` | `group_e_result_view_test.dart`; `supabase_sales_order_read_gateway_test.dart`; `sales_read_group_e_sql_contract_test.dart`; `sales_startup_test.dart` S13 wiring | done |
| FR-01..07 | FE | §S13 | presentation + ERP orchestration | `SalesTransactionResultCubit.load()` → four frozen Group E queries via `ISalesModule`; client-composed `CheckoutResultViewDto`; identity-only `SalesCheckoutResultArgs`; SG-06 state-driven widgets (loading/uncertain/loaded/partial/failure); ERP `SalesTransactionResultPage` wires GetIt `ISalesModule`/`IExecutionContext`; route mismatch → `SalesResultInvalidEntryPage` | `sales_transaction_result_cubit_test.dart`; `sales_transaction_result_body_test.dart`; `sales_transaction_result_page_test.dart`; `group_e_result_receipt_contract_test.dart` | done |
| FR-01..07 | E2E | §S13 | integration | ERP DI + authoritative owner contracts | e2e_e02_u06_fr01_01 | todo |

## S14 — [EP-02/US-07](../Epic-02-checkout-and-completion/US-07.md) — Xem, in hoặc chia sẻ phiếu bán hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-07 | CONTRACT | §S14 | application contract | GenerateSalesReceiptCommand; RecordSalesReceiptPrintedCommand; RecordSalesReceiptSharedCommand; ArchiveSalesReceiptCommand; GetSalesReceiptQuery | — | done |
| FR-01..07 | BE | §S14 | domain/application/infrastructure | domain `SalesReceipt` generate/print/share/archive invariants (verify-only, already implemented); handlers `GenerateSalesReceiptCommandHandler`, `RecordSalesReceiptPrinted/Shared/ArchiveSalesReceiptCommandHandler`, `GetSalesReceiptQueryHandler` (explicit `sales.receipt.view`), all wired to required `ISalesReceiptGateway`; `SupabaseSalesReceiptGateway` + `SalesReceiptRpcMapper`; draft-only `supabase/migrations/_drafts/005_sales_receipt_group_e.sql` (idempotent generate from committed snapshot, append-only activities) | `group_e_sales_receipt_test.dart`; `supabase_sales_receipt_gateway_test.dart`; `sales_receipt_group_e_sql_contract_test.dart`; `sales_startup_test.dart` S14 wiring; `settlement_and_receipt_aggregate_test.dart` | done |
| FR-01..07 | FE | §S14 | presentation + ERP orchestration | receipt ops on cubit (`ensureReceipt`/`printReceipt`/`shareReceipt`) with device action → audit ordering; typed `SalesReceiptDocumentDto` + `SalesReceiptPdfGenerator`/`SalesReceiptPreviewPage`; print/share via `SalesPdfRunner`; no synthetic e-invoice actions | `sales_transaction_result_cubit_test.dart`; `sales_receipt_pdf_generator_test.dart`; `sales_receipt_card_test.dart`; `group_e_result_receipt_contract_test.dart` | done |
| FR-01..07 | E2E | §S14 | integration | ERP DI + authoritative owner contracts | e2e_e02_u07_fr01_01 | todo |

## S15 — [EP-03/US-01](../Epic-03-order-inquiry-and-tracking/US-01.md) — Tra cứu danh sách đơn hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-01 | CONTRACT | §S15 | application contract | ListSalesOrdersQuery; SearchSalesOrdersQuery | — | done |
| FR-01..07 | BE | §S15 | application/infrastructure | `ListSalesOrdersQueryHandler` + `SearchSalesOrdersQueryHandler` (viewOrder, cursor paging via `OpaqueCursorPageDto`) → `ISalesOrderInquiryGateway`; `SupabaseSalesOrderInquiryGateway` + `SalesOrderInquiryRpcMapper`; draft `006_sales_inquiry_group_f.sql` | `group_f_inquiry_test.dart`; `supabase_sales_order_inquiry_gateway_test.dart`; `sales_inquiry_group_f_sql_contract_test.dart`; `sales_startup_test.dart` S15-S18 wiring | done |
| FR-01..07 | FE | §S15 | presentation | `SalesOrderListCubit` + cursor/filter via `ListSalesOrdersQuery`/`SearchSalesOrdersQuery`; `SalesOrderListMapper`; ERP `SalesOrderListPage`; `group_f_no_demo_contract_test` | `sales_order_list_cubit_test.dart`; `sales_order_list_mapper_test.dart`; `sales_flow_pages_test.dart`; `group_f_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S15 | integration | ERP DI + authoritative owner contracts | e2e_e03_u01_fr01_01 | blocked |

## S16 — [EP-03/US-02](../Epic-03-order-inquiry-and-tracking/US-02.md) — Xem chi tiết giao dịch gốc

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-02 | CONTRACT | §S16 | application contract | GetSalesOrderDetailQuery; GetSalesOrderQuery | — | done |
| FR-01..07 | BE | §S16 | application/infrastructure | `GetSalesOrderDetailQueryHandler` (viewOrder → `SalesOrderDetailDto`) via `ISalesOrderInquiryGateway`; `GetSalesOrderQuery` reused from S13 | `group_f_inquiry_test.dart`; `supabase_sales_order_inquiry_gateway_test.dart` | done |
| FR-01..07 | FE | §S16 | presentation | `SalesOrderDetailCubit` core load + `SalesOrderDetailMapper`; ERP `SalesOrderDetailPage`; error states; `group_f_no_demo_contract_test` | `sales_order_detail_cubit_test.dart`; `sales_order_detail_mapper_test.dart`; `sales_order_detail_page_test.dart`; `group_f_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S16 | integration | ERP DI + authoritative owner contracts | e2e_e03_u02_fr01_01 | blocked |

## S17 — [EP-03/US-03](../Epic-03-order-inquiry-and-tracking/US-03.md) — Kiểm tra thanh toán và công nợ của đơn

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-03 | CONTRACT | §S17 | application contract | GetSalesOrderPaymentSummaryQuery; GetSalesOrderSettlementQuery; GetSalesOrderPaymentTransactionsQuery | — | done |
| FR-01..07 | BE | §S17 | application/infrastructure | `GetSalesOrderSettlementQueryHandler` + `GetSalesOrderPaymentTransactionsQueryHandler` (viewPayment, cursor) via `ISalesOrderInquiryGateway`; `GetSalesOrderPaymentSummaryQuery` reused from S13 | `group_f_payment_detail_test.dart`; `supabase_sales_order_inquiry_gateway_test.dart` | done |
| FR-01..07 | FE | §S17 | presentation | Independent payment section loader + `SalesOrderPaymentVm` / payment summary card / debt page | `sales_order_detail_sections_test.dart`; `sales_order_detail_cubit_test.dart`; `group_f_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S17 | integration | ERP DI + authoritative owner contracts | e2e_e03_u03_fr01_01 | blocked |

## S18 — [EP-03/US-04](../Epic-03-order-inquiry-and-tracking/US-04.md) — Theo dõi timeline và lịch sử sau bán

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-04 | CONTRACT | §S18 | application contract | GetSalesOrderTimelineQuery; GetSalesOrderReturnSummaryQuery | — | done |
| FR-01..07 | BE | §S18 | application/infrastructure | `GetSalesOrderTimelineQueryHandler` (viewOrderHistory) + `GetSalesOrderReturnSummaryQueryHandler` (viewReturnExchange) via `ISalesOrderInquiryGateway` | `group_f_inquiry_test.dart`; `supabase_sales_order_inquiry_gateway_test.dart` | done |
| FR-01..07 | FE | §S18 | presentation | Timeline/history + returns section VMs/widgets (independent section status) | `sales_order_detail_sections_test.dart`; `sales_order_detail_cubit_test.dart`; `group_f_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S18 | integration | ERP DI + authoritative owner contracts | e2e_e03_u04_fr01_01 | blocked |

## S19 — [EP-03/US-05](../Epic-03-order-inquiry-and-tracking/US-05.md) — Xem lại phiếu bán hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-05 | CONTRACT | §S19 | application contract | GetSalesReceiptQuery; GenerateSalesReceiptCommand; RecordSalesReceiptPrintedCommand; RecordSalesReceiptSharedCommand; ArchiveSalesReceiptCommand | — | done |
| FR-01..07 | BE | §S19 | application/infrastructure | reuses Group E/S14 receipt surface — `GetSalesReceiptQueryHandler` + generate/print/share/archive handlers via `ISalesReceiptGateway`; no new BE (verified registered in `sales_cqrs_registrar.g.dart`) | `group_e_sales_receipt_test.dart`; `supabase_sales_receipt_gateway_test.dart` | done |
| FR-01..07 | FE | §S19 | presentation | `SalesReceiptOperationHandler` + `SalesOrderSlipPreviewPage` reuse Group E receipt surface | `sales_order_slip_preview_page_test.dart`; `sales_order_detail_cubit_test.dart`; `group_f_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S19 | integration | ERP DI + authoritative owner contracts | e2e_e03_u05_fr01_01 | blocked |

## S20 — [EP-03/US-06](../Epic-03-order-inquiry-and-tracking/US-06.md) — Theo dõi trạng thái xử lý liên quan

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-06 | CONTRACT | §S20 | application contract | GetOrderIntegrationStatusQuery; GetIntegrationCommandStatusQuery; GetImpactRequestStatusQuery; RetryIntegrationCommand; ReconcileIntegrationResultCommand | — | done |
| FR-01..07 | BE | §S20 | application/infrastructure | integration status/retry/reconcile via `ISalesIntegrationGateway`; draft `015_sales_integration_rpcs.sql` — pending+created/queued/sent → `IMPACT_PENDING`; status projects pending/queued from real rows; E-invoice read `notRequired` fallback | `group_f_integration_test.dart`; `supabase_sales_integration_gateway_test.dart`; `sales_integration_group_f_sql_contract_test.dart`; `sales_order_integration_status_sql_contract_test.dart`; `sales_startup_test.dart` S20 wiring | done |
| FR-01..07 | FE | §S20 | presentation | pending/queued labels “Đang chờ module xử lý”; retry/reconcile hidden for backlog; no fake accepted | `sales_order_integration_section_test.dart`; `sales_order_detail_mapper_test.dart`; `sales_order_detail_cubit_test.dart`; `group_f_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S20 | integration | ERP DI + live TH-06/TH-07 owner consumption (handoff backlog ready) | e2e_e03_u06_fr01_01 | blocked |

## S21 — [EP-03/US-07](../Epic-03-order-inquiry-and-tracking/US-07.md) — Khởi tạo thao tác sau bán

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-07 | CONTRACT | §S21 | application contract | GetSalesOrderDetailQuery; GetAvailablePostSaleActionsQuery; PrecheckSalesOrderCancellationQuery; PrecheckReturnExchangeQuery | — | done |
| FR-01..07 | BE | §S21 | application/infrastructure | `GetAvailablePostSaleActionsQueryHandler` (viewOrder) via `IPostSaleActionsGateway`; available-actions (cancel + return; ~~adjust~~ superseded). Authoritative prechecks: cancellation + return. | `group_f_post_sale_actions_test.dart`; `supabase_post_sale_actions_gateway_test.dart`; `sales_startup_test.dart` S21 wiring | done |
| FR-01..07 | FE | §S21 | presentation | Post-sale action bar/sheet + navigation intents (cancel/return only); authoritative precheck before route | `sales_order_detail_cubit_test.dart`; `group_f_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S21 | integration | ERP DI + authoritative owner contracts | e2e_e03_u07_fr01_01 | blocked |

## S22 — [EP-04/US-01](../Epic-04-post-sale-order-adjustments/US-01.md) — Cập nhật ghi chú đơn hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-01 | CONTRACT | §S22 | — | **Superseded / out of scope** — symbols withdrawn | — | n/a |
| FR-01..05 | BE | §S22 | — | Implementation removed | — | n/a |
| FR-01..05 | FE | §S22 | — | SG-09 / adjust UI removed | — | n/a |
| FR-01..05 | E2E | §S22 | — | — | — | n/a |

## S23 — [EP-05/US-01](../Epic-05-post-sale-order-cancellation/US-01.md) — Kiểm tra điều kiện và tác động hủy đơn

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-01 | CONTRACT | §S23 | application contract | PrecheckSalesOrderCancellationQuery; GetSalesOrderSettlementQuery; GetReturnExchangeOrdersBySalesOrderQuery | — | done |
| FR-01..07 | BE | §S23 | domain/application/infrastructure | `SalesOrderCancellation` + `CancellationPrecheckSnapshot` / `CancellationMustPassPrecheckRule`; `PrecheckSalesOrderCancellationQueryHandler`; `GetReturnExchangeOrdersBySalesOrderQueryHandler`; `ISalesOrderCancellationGateway`; `SalesOrderCancellationRpcMapper`; `SupabaseSalesOrderCancellationGateway`; `SalesDataAccessModule` + generated CQRS wiring; draft-only `supabase/migrations/_drafts/010_sales_order_cancellation_group_h.sql` | `group_h_cancellation_test.dart`; `postsale_aggregate_test.dart`; `sales_order_cancellation_rpc_mapper_test.dart`; `supabase_sales_order_cancellation_gateway_test.dart`; `sales_order_cancellation_group_h_sql_contract_test.dart`; `sales_startup_test.dart` Group H wiring | done |
| FR-01..07 | FE | §S23 | presentation | US screen-group manifest + ISalesModule/fake | wgt_e05_u01_fr01_01 | done |
| FR-01..07 | E2E | §S23 | integration | ERP DI + authoritative owner contracts | e2e_e05_u01_fr01_01 | todo |

## S24 — [EP-05/US-02](../Epic-05-post-sale-order-cancellation/US-02.md) — Xác định lý do hủy

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-02 | CONTRACT | §S24 | application contract | PrecheckSalesOrderCancellationQuery; ConfirmSalesOrderCancellationCommand | — | done |
| FR-01..07 | BE | §S24 | domain/application/infrastructure | `CancellationReason`; `ConfirmSalesOrderCancellationCommandValidator`; confirm handler reason wire-through; default reason catalog + confirm reason guards in `011_sales_adjustment_cancellation_rpcs.sql` (no separate S24 mutation/RPC, no Sales table backing the catalog in the current flow) | `postsale_aggregate_test.dart`; `group_h_cancellation_test.dart` S24 validator cases; `sales_order_cancellation_group_h_sql_contract_test.dart` reason-catalog / no-refund asserts | done |
| FR-01..07 | FE | §S24 | presentation | US screen-group manifest + ISalesModule/fake | wgt_e05_u02_fr01_01 | done |
| FR-01..07 | E2E | §S24 | integration | ERP DI + authoritative owner contracts | e2e_e05_u02_fr01_01 | todo |

## S25 — [EP-05/US-03](../Epic-05-post-sale-order-cancellation/US-03.md) — Xác nhận hủy toàn bộ đơn hàng

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-03 | CONTRACT | §S25 | application contract | ConfirmSalesOrderCancellationCommand; CancelSalesOrderCommand; GetSalesOrderCancellationQuery | — | done |
| FR-01..07 | BE | §S25 | domain/application/infrastructure | confirm cancellation + `sales.enqueue_impact_handoff` for inventory/receivable (no E-invoice write); initial command `v1/queued/attempt=0/max=5`; no wait on owner acceptance | `group_h_cancellation_test.dart`; `postsale_aggregate_test.dart`; `sales_order_cancellation_rpc_mapper_test.dart`; `supabase_sales_order_cancellation_gateway_test.dart`; `sales_order_cancellation_group_h_sql_contract_test.dart`; `sales_cancellation_impacts_group_h_sql_contract_test.dart` | done |
| FR-01..07 | FE | §S25 | presentation | US screen-group manifest + ISalesModule/fake | wgt_e05_u03_fr01_01 | done |
| FR-01..07 | E2E | §S25 | integration | ERP DI + live TH-06/TH-07 owner consumption (handoff backlog ready) | e2e_e05_u03_fr01_01 | todo |

## S26 — [EP-05/US-04](../Epic-05-post-sale-order-cancellation/US-04.md) — Theo dõi các tác động hoàn nguyên

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-04 | CONTRACT | §S26 | application contract | GetOrderIntegrationStatusQuery; RetryIntegrationCommand; RetryInventoryImpactCommand; RetryReceivableImpactCommand; RetryEInvoiceImpactCommand; ReconcileIntegrationResultCommand | — | done |
| FR-01..07 | BE | §S26 | domain/application/infrastructure | typed retries + Group F status/reconcile; pending backlog retry → `IMPACT_PENDING`; draft `015` + cancellation impact SQL contracts | `group_f_integration_test.dart` S26 routing; `supabase_sales_integration_gateway_test.dart`; `sales_integration_group_f_sql_contract_test.dart`; `sales_cancellation_impacts_group_h_sql_contract_test.dart`; `postsale_aggregate_test.dart` no reopen | done |
| FR-01..07 | FE | §S26 | presentation | shared integration section pending/queued UI (S20); no retry on owner backlog | `sales_order_integration_section_test.dart`; `sales_order_detail_mapper_test.dart`; wgt_e05_u04_fr01_01 | done |
| FR-01..07 | E2E | §S26 | integration | ERP DI + live TH-06/TH-07 owner consumption (handoff backlog ready) | e2e_e05_u04_fr01_01 | todo |

## S27 — [EP-05/US-05](../Epic-05-post-sale-order-cancellation/US-05.md) — Xem kết quả và lịch sử hủy đơn

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-05 | CONTRACT | §S27 | application contract | GetSalesOrderCancellationQuery; GetSalesOrderDetailQuery; GetSalesOrderTimelineQuery; GetSalesOrderPaymentSummaryQuery; GetOrderIntegrationStatusQuery | — | done |
| FR-01..07 | BE | §S27 | domain/application/infrastructure | `GetSalesOrderCancellationQueryHandler`; gateway/mapper detail envelope; draft-only `sales.get_sales_order_cancellation`; reuses Group E/F inquiry/timeline/payment/receipt/integration reads (no new owner RPCs) | `group_h_cancellation_test.dart` S27 detail; `sales_order_cancellation_rpc_mapper_test.dart`; `supabase_sales_order_cancellation_gateway_test.dart`; `sales_order_cancellation_group_h_sql_contract_test.dart` detail envelope; Group E/F inquiry/receipt/integration tests for reused projections | done |
| FR-01..07 | FE | §S27 | presentation | US screen-group manifest + ISalesModule/fake | wgt_e05_u05_fr01_01 | done |
| FR-01..07 | E2E | §S27 | integration | ERP DI + authoritative owner contracts | e2e_e05_u05_fr01_01 | todo |

## S28 — [EP-06/US-01](../Epic-06-returns-exchanges-and-settlement/US-01.md) — Khởi tạo phiếu đổi/trả từ đơn hàng gốc

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-01 | CONTRACT | §S28 | application contract | PrecheckReturnExchangeQuery; GetReturnableOrderLinesQuery; StartReturnExchangeCommand | — | done |
| FR-01..07 | BE | §S28 | domain/application/infrastructure | `ReturnExchangeOrder` start/idempotency rules; `PrecheckReturnExchangeQueryHandler`; `GetReturnableOrderLinesQueryHandler`; `StartReturnExchangeCommandHandler` + validator; `IReturnExchangeReadGateway` / `IReturnExchangeCommandGateway` / `IReturnExchangeReferencePort`; `ReturnExchangeRpcMapper`; `SupabaseReturnExchange*Gateway`; promoted session owners `20260827012` / `20260830012` (empty form-policy catalogs + no reservation-ref persistence) | `group_i_session_test.dart`; `postsale_aggregate_test.dart`; `return_exchange_rpc_mapper_test.dart`; `supabase_return_exchange_gateways_test.dart`; `sales_return_exchange_group_i_session_sql_contract_test.dart`; `sales_remove_unused_policy_tables_sql_contract_test.dart`; `sales_startup_test.dart` Group I wiring | done |
| FR-01..07 | FE | §S28 | presentation | `SalesReturnExchangeSessionCubit` + ERP create page (SG-11); form policy + returnable lines via `ISalesModule`; UUID attempt factory; identity navigate to settle | `sales_return_exchange_session_cubit_test.dart`; `sales_flow_pages_test.dart` SG-11; `group_i_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S28 | integration | ERP DI + authoritative owner contracts | e2e_e06_u01_fr01_01 | todo |

## S29 — [EP-06/US-02](../Epic-06-returns-exchanges-and-settlement/US-02.md) — Ghi nhận hàng khách trả

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-02 | CONTRACT | §S29 | application contract | GetReturnableOrderLinesQuery; UpdateReturnExchangeCommand; EvaluateReturnPricingImpactQuery | — | done |
| FR-01..07 | BE | §S29 | domain/application/infrastructure | returned-line ownership + original-snapshot qty rules; `UpdateReturnExchangeCommandHandler` + validator; returnable/read + evaluate ports; draft-only `sales.update_return_exchange` / `sales.get_returnable_order_lines` / evaluate path in `012`/`013` | `group_i_session_test.dart`; `postsale_aggregate_test.dart` over-return/original-line; `sales_return_exchange_group_i_session_sql_contract_test.dart`; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` original-price | done |
| FR-01..07 | FE | §S29 | presentation | Session body return qty/reason/condition from backend policy; no Dart policy fallback | `sales_return_exchange_session_body_test.dart`; session cubit tests; SG-11 flow | done |
| FR-01..07 | E2E | §S29 | integration | ERP DI + authoritative owner contracts | e2e_e06_u02_fr01_01 | todo |

## S30 — [EP-06/US-03](../Epic-06-returns-exchanges-and-settlement/US-03.md) — Ghi nhận hàng khách nhận đổi

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-03 | CONTRACT | §S30 | application contract | UpdateReturnExchangeCommand | — | done |
| FR-01..07 | BE | §S30 | domain/application/infrastructure | exchange-line current-price rules + no exchange-only confirm; `UpdateReturnExchangeCommandHandler` with `IReturnExchangeReferencePort` (reserve=true); draft-only update/evaluate RPCs | `group_i_session_test.dart` inventory blocker; `postsale_aggregate_test.dart` exchange-only reject; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` current-price; mapper reference_decision | done |
| FR-01..07 | FE | §S30 | presentation | Exchange via live Catalog `SalesProductPickerPage` (no `_demoCatalog`); unit identity on start/update | session cubit + SG-11 flow; picker sheet | done |
| FR-01..07 | E2E | §S30 | integration | ERP DI + authoritative owner contracts | e2e_e06_u03_fr01_01 | todo |

## S31 — [EP-06/US-04](../Epic-06-returns-exchanges-and-settlement/US-04.md) — Giữ và bỏ thay đổi chưa xác nhận trong phiên đổi/trả

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-04 | CONTRACT | §S31 | application contract | session working state; CancelReturnExchangeCommand (technical discard) | — | done |
| FR-01..06 | BE | §S31 | domain/application/infrastructure | technical discard (no user draft list/restore); `CancelReturnExchangeCommandHandler` chỉ `commandGateway.cancel` (không release reservation phía Dart); draft-only `sales.cancel_return_exchange` | `group_i_session_test.dart` cancel; `postsale_aggregate_test.dart` idempotent discard; `sales_return_exchange_group_i_session_sql_contract_test.dart` no list/restore | done |
| FR-01..06 | FE | §S31 | presentation | Discard before start = no write; after start = `CancelReturnExchangeCommand` once; leave/discard sheets | session cubit discard tests; `sales_return_discard_dialog` | done |
| FR-01..06 | E2E | §S31 | integration | ERP DI + cancel không phụ thuộc reservation release | e2e_e06_u04_fr01_01 | todo |

## S32 — [EP-06/US-05](../Epic-06-returns-exchanges-and-settlement/US-05.md) — Xem giá trị và chênh lệch đổi/trả

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-05 | CONTRACT | §S32 | application contract | EvaluateReturnPricingImpactQuery; UpdateReturnExchangeCommand; GetSalesOrderSettlementQuery | — | done |
| FR-01..07 | BE | §S32 | domain/application/infrastructure | `ReturnExchangeValuation` + `ReturnExchangeSettlementPlan` (sign `returnValue - exchangeValue`); `EvaluateReturnPricingImpactQueryHandler`; `IReturnExchangeReadGateway.evaluate`; draft-only `013`/`sales.evaluate_return_exchange_valuation` | `group_i_valuation_settlement_test.dart`; `postsale_aggregate_test.dart` valuation/plan/stale clear; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` | done |
| FR-01..07 | FE | §S32 | presentation | Settlement cubit evaluates backend plan; sign `returnValue - exchangeValue`; mapper VMs | `sales_return_exchange_settlement_cubit_test.dart`; mapper test | done |
| FR-01..07 | E2E | §S32 | integration | ERP DI + authoritative owner contracts | e2e_e06_u05_fr01_01 | todo |

## S33 — [EP-06/US-06](../Epic-06-returns-exchanges-and-settlement/US-06.md) — Quyết toán chênh lệch đổi/trả

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-06 | CONTRACT | §S33 | application contract | RecordSalesPaymentCommand; RecordSalesRefundCommand; IReceivableImpactPort (Receivable-owned collection) | — | done |
| FR-01..07 | BE | §S33 | domain/application/infrastructure | payment/refund handlers → `IReturnExchangeSettlementGateway`; draft-only `sales.settle_return_exchange_difference` (Sales transactions + receivable impact requests only); walk-in / partial-payment capacity; SCN-07 Theme-6 owner BUSINESS_REJECTION delivery is runtime/blocked-by-TH-06 (Sales evidences durable requests + IMPACT_PENDING only) | `group_i_valuation_settlement_test.dart` (`S33 payment/refund handler delegates exactly once…`); `sales_return_exchange_group_i_settlement_sql_contract_test.dart` (`settle locks rows…`); confirmation `complete requires accepted impacts…` / `S34 complete passes… IMPACT_PENDING` | done |
| FR-01..07 | FE | §S33 | presentation | SG-12 read-only plan UI (no payment/debt/due-date); confirm sheet from plan DTO; idempotent confirm attempt | settlement body/cubit + confirm sheet tests; SG-12 flow | done |
| FR-01..07 | E2E | §S33 | integration | ERP DI + authoritative owner contracts | e2e_e06_u06_fr01_01 | todo |

## S34 — [EP-06/US-07](../Epic-06-returns-exchanges-and-settlement/US-07.md) — Xác nhận và theo dõi kết quả đổi/trả

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| --- | --- | --- | --- | --- | --- | --- |
| US-07 | CONTRACT | §S34 | application contract | ConfirmReturnExchangeCommand; CompleteReturnExchangeCommand; GetSalesOrderReturnSummaryQuery; GetOrderIntegrationStatusQuery | — | done |
| FR-01..07 | BE | §S34 | domain/application/infrastructure | single-phase confirm + `enqueue_impact_handoff` (inventory/receivable; E-invoice write deferred); complete legacy `IMPACT_PENDING` gate retained off normal FE path; draft `014` | `group_i_confirmation_test.dart`; `postsale_aggregate_test.dart`; `sales_return_exchange_group_i_confirmation_sql_contract_test.dart`; `sales_return_exchange_group_i_settlement_sql_contract_test.dart`; `group_f_integration_test.dart` S34 reuse | done |
| FR-01..07 | FE | §S34 | presentation | Detail cubit + ERP result/detail/preview; pending integration labels via S20 section | detail cubit/page/slip tests; `sales_order_integration_section_test.dart`; `group_i_no_demo_contract_test.dart` | done |
| FR-01..07 | E2E | §S34 | integration | ERP DI + live TH-06/TH-07 owner consumption (handoff backlog ready) | e2e_e06_u07_fr01_01 | todo |
