# Harness maturity progress

Checklist tiến độ Harness Engineering. Agent đọc file này ở đầu session để biết repo đang ở đâu.

## Phase 1 — Harness foundation

- [x] [AGENTS.md](../../AGENTS.md) — agent onboarding
- [x] Docs reconciled — modules = skeleton, interim references documented
- [x] [harness-engineering.md](../architecture/harness-engineering.md) — harness definition
- [x] CI `verify_workspace` — analyze + harness guards + package tests (worker test on deploy only)
- [x] `scripts/ci/verify_harness.sh` + layer import guards
- [x] `melos run test` — workspace package tests
- [x] Skills + MODULE template — PipelineTestHarness section
- [x] Pre-commit — guard scripts after `dart format`
- [x] `docs/ddd_domain_modeling_skill.md` — mirror DDD skill

## Phase 1.5 — TH-03 harness docs

- [x] TH-03 README + harness/ scaffold
- [x] Epic overview fixes (Epic-01 table, Epic-02/03, US-04 rename)
- [x] `guard_theme_structure.sh` + `guard_theme_traceability.sh` (stub)
- [x] Exemplar traceability (updated cho Epic-01 từ US-01 đến US-04)

## Phase 1.6 — Presentation harness

- [x] `presentation-layer` skill + `docs/presentation_layer_skill.md`
- [x] `vet45-presentation-ui.mdc` (scoped rule)
- [x] `guard_presentation_size.sh` + `guard_presentation_dialogs.sh`
- [x] TH-03 ritual + module-map presentation layout
- [x] Golden reference documented — `apps/erp/lib/features/dashboard/presentation/`

## Phase 1.7 — BE/FE harness lanes

- [x] `harness/07-api-contracts.md` + lane columns trong template + `guard_theme_structure.sh`
- [x] TH-03 backfill Epic-01 traceability (Role BE/FE/E2E)
- [x] `FakePartnerModule` + `package:vet45_partner_application/testing.dart`
- [x] Epic-02/US-01 contract-first pilot (deactivate/reactivate)
- [x] `guard_theme_traceability.sh` — Role column khi exemplar-complete
- [ ] Roll-up lane % trong `docs/themes/README.md` (optional)

## Phase 1.8 — TH-05 Sales Orders harness + CONTRACT completion (2026-07-27)

- [x] Canonical source `Theme-5-sales-orders.md` bootstrap SHA-256 `de032a818e7dbc3fe320f3008c46b30a2358320220cd044c4fb3e096948f179a`
- [x] Theme package `README.md` + `OVERVIEWS.md`; catalog renumber TH-05…TH-12
- [x] 6 Epic README tổng hợp + US phẳng; derived scenario chuẩn hóa `SCN-*`
- [x] Harness `00..07`: DDD boundaries, module map, flows, roadmap, traceability, notes và API catalog
- [x] Sales application public contracts/provider ports/testing barrel compile (legacy shape)
- [x] Payment intent S09 runtime-only; cancellation split; Receivable port; RPC contract-only/unimplemented
- [ ] Sales BE/FE/E2E implementation — domain đã landed; infrastructure/presentation vẫn skeleton và không phải golden reference

## Phase 1.8.1 — TH-05 re-harness Theme-5 Phase 1 (2026-07-30)

- [x] Canonical SHA-256 cập nhật `2b19694fa805a5d13c180c8982132c178f9b4a7bc7b66a5861916c88f9bc8c7f`
- [x] EP-04 → 1 US (`order_note`); EP-06 US-04 → session discard; **34 US / 235 FR / S01–S34**
- [x] Slice renumber: cũ S27–S38 → S23–S34; EP-04 = S22
- [x] Harness 00–07 + Epic tree đồng bộ
- [x] CONTRACT code pass: rewrite adjustment/return Dart DTOs + fake registry (234 scenarios)
- [x] Sales FE presentation implementation — 34/34 slices (S01–S34) complete in `modules/sales/presentation` & `apps/erp/lib/features/sales`
- [ ] Sales BE handlers/gateways/RPC drafts — Groups A–I landed through S34 (xem Phase 1.8.2 / 1.8.3 / 1.8.4)

## Phase 1.8.2 — TH-05 Sales BE Groups A–G (2026-08-10)

- [x] Group A S02–S05 BE — runtime working state, provider ports/fakes, pricing preview/precheck
- [x] Group B S06–S07 BE — draft persistence/restore handlers + gateway + draft RPC `001_sales_order_drafts_group_b.sql`
- [x] Group C S08–S11 BE — checkout precheck service, payment-intent validator, reference/receivable ports + fakes, finalize validation, draft RPC `002_sales_checkout_group_c_precheck.sql` (default reference precheck fails closed)
- [x] Group C S08–S11 BE–FE vertical integration — typed checkout snapshot + GoRouter extra; `SalesCheckoutCubit` → `PrecheckSalesOrderCheckoutQuery` → required `ICheckoutGateway`; precheck panel; no finalize; `group_c_no_finalize_contract_test`; guarded live `sales_group_c_s08_s11_live_test` (disabled skip ≠ pass; E2E remains `blocked` — `002` draft-only/unpromoted/unapplied, fail-closed RPC, owner contracts + live seed IDs)
- [x] Group D S12 BE — `FinalizeSalesOrderCommandHandler` → `ICheckoutGateway.finalize` (required/DI-injected); `GetCheckoutAttemptStatusQueryHandler` (explicit `sales.order.view`); `SupabaseCheckoutGateway` finalize/status; draft RPC `003_sales_checkout_group_d_finalize.sql`
- [x] Group E S13–S14 BE — S13 result-view read handlers (order/payment-summary/integration-status) + `ISalesOrderReadGateway`; S14 receipt handlers (generate/print/share/archive/get) + `ISalesReceiptGateway`; gateways required/DI-injected; draft RPCs `004_sales_read_group_e.sql` + `005_sales_receipt_group_e.sql`
- [x] Group F-read S15–S19 BE — order list/search + detail + settlement/transactions + timeline/return-summary via `ISalesOrderInquiryGateway`; S19 reuses Group E receipt surface; draft RPC `006_sales_inquiry_group_f.sql`
- [x] Group F-ops S20–S21 BE — integration command/impact status + retry/reconcile via `ISalesIntegrationGateway`; available-actions via `IPostSaleActionsGateway` (draft `008`); authoritative prechecks owned by `009`/`010`/`012`; draft RPCs `007_sales_integration_group_f.sql` + `008_sales_post_sale_actions_group_f.sql`
- [x] Group G S22 BE — checkout `orderNote` nullable/immutable source; note-only apply/history handlers + gateway/mapper/codegen; append-only draft RPC `009_sales_order_adjustment_group_g.sql`; S12 finalize retains existing impact/outbox semantics while S22 apply publishes no external event
- [ ] S22 E2E — blocked by authoritative store-scope owner contract + promoted/applied S12/S22 RPCs; Group G SQL remains draft-only

## Phase 1.8.3 — TH-05 Sales BE Group H S23–S27 (2026-08-10)

- [x] Group H S23–S27 BE — authoritative cancellation precheck/confirm/detail via `ISalesOrderCancellationGateway`; domain reason/precheck/confirmation evidence + no reopen; S23 return-conflict adapter; S24 reason validation on confirm; S25 idempotent/versioned/refund-free confirm; S26 typed impact retries + cancellation-aware retry/reconcile; S27 detail reusing Group E/F reads; DI + codegen wiring
- [x] Draft-only SQL — `supabase/migrations/_drafts/010_sales_order_cancellation_group_h.sql` + `supabase/migrations/_drafts/011_sales_cancellation_impacts_group_h.sql` (unpromoted/unapplied; contract tests only)
- [x] Harness evidence — BE `done` for S23–S27 in roadmap/traceability; 35 scenario IDs mapped in §S23–§S27; E2E remains `todo`/blocked by external owner contracts, store-scope ownership, and unpromoted/unapplied Group D/G/H drafts
- [x] Sales BE Group I (S28–S34) — xem Phase 1.8.4
- [ ] S23–S27 E2E — blocked by external Pricing/Inventory/Receivable/E-invoice owner contracts, authoritative store-scope ownership, and unpromoted/unapplied Group D/G/H drafts

## Phase 1.8.4 — TH-05 Sales BE Group I S28–S34 (2026-08-10)

- [x] Group I S28–S34 BE — return/exchange eligibility, technical session, line editing, versioned valuation, settlement difference, confirm/complete, return-status projection via focused ports/handlers/gateways; DI + codegen wiring
- [x] Draft-only SQL — `012_sales_return_exchange_group_i_session.sql`, `013_sales_return_exchange_group_i_settlement.sql`, `014_sales_return_exchange_group_i_confirmation.sql` (unpromoted/unapplied; contract tests only)
- [x] Harness evidence — BE `done` for S28–S34; 47 scenario IDs mapped in §S28–§S34; documented sign convention, server-only reference decisions, frozen reason/condition/entrySource limitation, Group F summary/integration reuse, draft-only/no-live-E2E
- [x] Sales Group I BE–FE integration — xem Phase 1.8.8
- [ ] S28–S34 E2E — blocked by unavailable Inventory/Pricing/Receivable/E-invoice owner contracts, authoritative store-scope ownership, and unpromoted/unapplied Group I drafts (`012`/`013`/`014`/`020`)

## Phase 1.8.8 — TH-05 Sales Group I BE–FE integration S28–S34 (2026-08-13)

- [x] Group I S28–S34 FE — session/settlement/detail cubits; ERP identity-only create/settle/result/detail/preview; Catalog exchange picker; read-only SG-12 plan; authoritative slip/PDF; `group_i_no_demo_contract_test`
- [x] Contract extension — application DTOs/queries for form policy + detail; draft `020` + in-place `012`/`013`/`014`; infrastructure mapper/gateways
- [x] Legacy god VM/cubit/demo pages + settlement payment widgets deleted
- [x] Harness evidence — roadmap/traceability/notes updated; E2E remains `todo`/`blocked` (no live E2E claimed)
- [ ] S28–S34 E2E — same blockers as Phase 1.8.4 + tenant reason/condition policy seed

## Phase 1.8.5 — TH-05 Sales Group E BE–FE integration S13–S14 (2026-08-12)

- [x] Group E S13 FE — `SalesTransactionResultCubit` authoritative load path; SG-06 state-driven widgets; identity-only `SalesCheckoutResultArgs`; ERP result route + invalid-entry guard
- [x] Group E S14 FE — typed `SalesReceiptDocumentDto` PDF/preview; receipt device ops with audit ordering; `SalesPdfRunner` print/share binding
- [x] Harness evidence — S13/S14 FE traceability + §S13/§S14 contract notes; draft RPCs `004`/`005` remain unpromoted/unapplied
- [ ] S13–S14 E2E — remains `todo`/blocked by unpromoted Group D/E draft RPCs, live projections, and physical device print/share verification

## Phase 1.8.6 — TH-05 Sales Group F BE–FE integration S15–S21 (2026-08-12)

- [x] Group F S15–S21 FE — authoritative list/detail cubits, section loaders, payment/history/integration/post-sale entry; ERP list/detail + slip preview wiring; `group_f_no_demo_contract_test`
- [x] Ownership documented — `004` summary; `006` inquiry; `007` recovery; `008` available-actions only; `009`/`010`/`012` authoritative prechecks (Option b)
- [x] Harness evidence — roadmap/traceability/notes/§S15–§S21 BE–FE notes; PROGRESS workspace verify delta vs baseline
- [ ] S15–S21 E2E — remains `blocked` by unpromoted/unapplied drafts `004`/`006`/`007`/`008` (+ owner prechecks), live projections, and seed IDs

Residual debts (out of Group F scope): draft `011` envelope; baseline analyze/test noise outside Sales.

Focused verification (2026-08-12 Task 12 — NO COMMIT):

- Guard: `flutter test apps/erp/test/features/sales/group_f_no_demo_contract_test.dart` — **pass**
- `melos run codegen --no-select` — wrote 0 outputs (no hand-edit `.g.dart`)
- Focused Group F app/infra suites — **pass** (inquiry/payment/integration/post-sale + SQL contracts)
- `flutter test modules/sales/presentation` — **182 pass / 1 fail**: `sales_receipt_pdf_generator_test` PathNotFound (doubled package path when cwd=package) — Group E receipt guard path bug, not Group F demo regression
- `flutter test apps/erp/test/features/sales` — **103/103 pass** (includes new no-demo guard)
- `melos run analyze --no-select` — exit non-zero only if fatal errors; after Task 12 catalog `const` fix, `vet45_sales_presentation` analyze SUCCESS with warnings/info baseline only
- `melos run migrate:verify-policy -- --strict` — **OK**
- `bash scripts/ci/verify_harness.sh` — exit **1** from `guard_presentation_size` (baseline Catalog/Partner + additional pre-existing Sales oversized files: compose page/cubit, slip PDF, Group I return-detail). Not introduced by Group F Task 12 guard/docs.
- `melos run test --no-select` — exit **1**; **14** packages failed. Fail set dominated by Flutter packages under `dart test` (presentation toolchain), SQL draft contract environment, and known non-Sales debt. Sales-application **185 pass**. Sales-infrastructure **259 pass / 1 fail**: `SalesStartup S12 finalize…` → `DEPENDENCY_UNAVAILABLE` fail-closed checkout precheck (Group D runtime caveat; not Group F). Sales-presentation fails under `dart test` load (needs `flutter test`).
- `cd apps/erp && flutter test` — **341 pass / 59 fail**; Sales feature suite green; failures are non-Sales (auth/catalog/tenant_context/invitations/…).
- `git diff --check` — **clean**
- GitNexus `detect_changes(scope: all)` — risk **critical**, ~84 changed files / 185 symbols / 177 affected processes; overwhelmingly `modules/sales` + TH-05 harness + ERP sales routes/tests (Tasks 1–12 working tree). `compare` vs `main` is whole-branch noise (~4k files) — not used as Task 12 scope signal.

**Delta vs baseline (PROGRESS historical):** same class of workspace noise (non-Sales packages + presentation size + Flutter-under-dart-test). No new Group F production demo-marker failures. Residual debts unchanged: draft `011` envelope, Group I demo pages, unpromoted drafts blocking E2E.

## Phase 1.8.7 — TH-05 Sales Group G BE–FE integration S22 (2026-08-12)

- [x] Group G S22 BE–FE — SG-09 authoritative precheck/version; `SalesOrderAdjustmentAttemptFactory` idempotent apply (context correlation + deterministic payload hash); explicit stale/conflict handling; typed outcome + SG-08 refresh; Phase 1 note-only (no reason); `group_g_no_hardcode_contract_test`
- [x] Harness evidence — roadmap/traceability/notes/§S22 BE–FE notes; `_drafts/009` remains draft-only/unpromoted in repo (manual local SQL apply is environment-only, not migration evidence)
- [ ] S22 E2E — remains `todo`/blocked by authoritative store-scope owner contract + promoted/applied S12/S22 RPCs
- [x] Task 7 final workspace verification (2026-08-12 — NO COMMIT) — evidence below; full report `.superpowers/sdd/task-7-report.md`

Focused verification (2026-08-12 Task 7 — NO COMMIT):

- Format: `dart format` on Group G touched Dart files — **0 changed**
- Focused FE: factory **3/3**, cubit **18/18**, SG-09 **8/8**, detail **17/17**, `group_g_no_hardcode_contract_test` **1/1** — all pass
- Existing Group G BE regression: application **4/4**, mapper **7/7**, gateway **13/13**, SQL contract **7/7** — all pass; no SQL file changed
- `flutter test modules/sales/presentation` — **204/204 pass** (delta vs Group F Task 12: was 182 pass / 1 fail on receipt PDF path; now green under `flutter test`)
- `flutter test apps/erp/test/features/sales` — **113/113 pass** (delta vs Group F 103/103; +Group G suites)
- `flutter analyze modules/sales/presentation` — exit **0**, 27 info/warning baseline (none on Group G adjust files)
- `flutter analyze apps/erp` — exit **0**, 5 info/warning (1 unused_element_parameter in detail page test optional)
- `melos run codegen --no-select` — wrote **0** outputs; no `.g.dart` diffs
- `melos run analyze --no-select` — **SUCCESS** (`dart analyze --no-fatal-warnings`)
- `melos run test --no-select` — exit **1**; **14** packages failed (same count class as Group F Task 12). Sales-application **185 pass**. Sales-infrastructure **259 pass / 1 fail**: `SalesStartup S12 finalize…` → `DEPENDENCY_UNAVAILABLE` (Group D caveat; not Group G). Flutter presentation packages fail under `dart test` (toolchain/`dart:ui`; needs `flutter test`)
- `bash scripts/ci/verify_harness.sh` — exit **1** solely from `guard_presentation_size` baseline (same 8 oversized files as Task 6; no new Group G page over limit: adjust page 136 / body 146)
- `git diff --check` — **clean**
- Forbidden scope for Group G — **clean**: no dirty/untracked under `modules/sales/domain/`, `modules/sales/application/lib/src/sales_order_adjustment/`, `modules/sales/infrastructure/`, `supabase/migrations/`
- GitNexus `detect_changes(scope: all)` — risk **low**, changed_files **14** (index under-reports untracked), affected_processes **empty**. `SalesOrderAdjustState.orderNumber` listed as touched but **absent** in current source (stale index residual; page/body do not display fake order number)

Docs-guard check (2026-08-12 Task 6 — NO COMMIT):

- `bash scripts/ci/verify_harness.sh` — exit **1** solely from `guard_presentation_size` baseline (no new Group G page):
  - `apps/erp/lib/features/sales/presentation/pages/sales_order_compose_page.dart` (518)
  - `apps/erp/lib/features/catalog/presentation/pages/settings/upsert_custom_field_page.dart` (564)
  - `apps/erp/lib/features/catalog/presentation/pages/settings/store_price_rule_settings_page.dart` (523)
  - `apps/erp/lib/features/catalog/presentation/pages/product_measurement_units_page.dart` (533)
  - `modules/sales/presentation/lib/src/support/sales_slip_pdf_generator.dart` (537)
  - `modules/sales/presentation/lib/src/pages/sales_return_exchange_detail_page.dart` (516)
  - `modules/sales/presentation/lib/src/bloc/sales_compose_cubit.dart` (518)
  - `modules/catalog/presentation/lib/src/bloc/product_guided_create_cubit.dart` (752)
- `git diff --check` — **clean**

## Phase 1.8.8 — TH-05 Sales Group H BE–FE integration S23–S27 (2026-08-13)

- [x] Group H S23–S27 BE–FE — SG-10 cancellation and S26/S27 on SG-08 connected to authoritative backend; hardcodes removed (`CUSTOMER_CHANGE_MIND`, `idemp_/hash_/corr_`, `expectedVersion:1`, `orderId.toUpperCase()`, restock/refund); `group_h_no_hardcode_contract_test` guards the 7 production files
- [x] S24 reason-policy read contract added — `ListSalesOrderCancellationReasonsQuery` + handler + `ISalesOrderCancellationGateway.listReasons`; mapper strict allowlist + gateway + codegen registration + startup reachability. SG-10 renders reasons from backend policy only (empty catalog → configuration state, no confirm; no Dart fallback catalog)
- [x] S27 detail extension — `SalesOrderCancellationDetailDto.cancelledByActorId`/`netConfirmedCollectionMinor`; SG-08 composes an independent cancellation section (idle/loading/loaded/projectionPending/error), `NOT_FOUND`/`IMPACT_PENDING` → projection-pending without discarding core; no refund status/action; actor shown as-is
- [x] SG-10 immutable confirm attempt — `SalesOrderCancellationAttemptFactory` (UUID id, `sales-order-cancellation:<id>` key, canonical SHA-256 payload hash, real tenant/user/correlation, both authoritative versions); retry reuses the same attempt, editing reason/note/version creates a new one; typed `SalesOrderCancelOutcome` pop drives SG-08 `refresh()`
- [x] S26 typed retry — `SalesIntegrationAttemptFactory` (UUID + canonical SHA-256); retry routed by `SalesImpactKind` to `RetryInventory/Receivable/EInvoiceImpactCommand` (`impactRequestId`, never generic `integrationCommandId`); reconcile stays the single generic `ReconcileIntegrationResultCommand`; cubit-owned attempt cache reuses an unchanged retry, a fresh source version yields a new attempt; removed `defaultSalesIntegrationCommandKeys`/`RetryIntegrationCommand` from the retry path
- [x] SQL — Option (A) single-owner (draft-only, unpromoted/unapplied): created `_drafts/019_sales_cancellation_reason_catalog_group_h.sql` (owns `list_sales_order_cancellation_reasons` only: `display_name`/`sort_order` columns + nonblank-active check + tenant/permission-scoped active-ordered list RPC); extended `_drafts/010_sales_order_cancellation_group_h.sql` in place (`get_sales_order_cancellation` returns the 2 S27 fields; `-- Touches` unchanged). `migrate:verify-policy --strict` OK
- [ ] S23–S27 E2E — remains `todo`/blocked by external Pricing/Inventory/Receivable/E-invoice owner contracts, authoritative store-scope ownership, and unpromoted/unapplied Group D/G/H drafts; SG-10 also requires seeded tenant reason policies (nonblank `display_name`) or intentionally shows catalog-empty

## Phase 2 — IAM golden module

- [x] IAM minimal foundation — DB schema `iam` + RPC session/permission + access checkers
- [x] Codegen enabled — `registerGeneratedIamHandlers`, `IamCommandPipeline`, `iam_access_metadata.g.dart`
- [x] Tenant/membership interim — `SwitchActiveTenant`, `ListTenantMembers`, `AssignMemberRole` + RPC migration
- [x] `GUARD_CODEGEN_STRICT=1` trong `verify_harness.sh`
- [x] AGENTS.md + `modules/iam/README.md` — IAM là reference chính thức
- [x] Permission code constants — `IamPermissions` / `InterimPermissionCodes` trong domain; chuẩn hóa trong skills + codegen docs
- [ ] Permission manifest ownership — gỡ `partner.*`, `settings.einvoice.*` khỏi `IamModuleDefinition`; partner đã có `PartnerModuleDefinition` — còn gỡ placeholder khỏi IAM khi modules khác bật manifest
- [ ] IAM vertical slice đầy đủ (SRS Theme 1): aggregates, onboarding, role catalog UI

## Phase 2.1 — Partner codegen (TH-03)

- [x] Partner codegen enabled (2026-07-02) — 4 builders, generated handlers, `PartnerModuleDefinition`
- [x] Partner messaging worker wired (2026-07-02)
- [ ] **Reboot 2026-07-07** — gỡ code partner cũ + migrations schema v1; harness v2 (Partner/Person/Organization); rebuild greenfield từ `modules/iam/` theo slice S1..S9

## Phase 2.2 — Pricing S1 CONTRACT + BE (TH-04)

- [x] Greenfield `modules/pricing/{domain,application,infrastructure}` + generated CQRS/access metadata
- [x] S1 create-manual contract, fake matrix, domain/handler/gateways and three SQL drafts
- [x] Focused Pricing analyze/tests/codegen green; SQL remains draft-only and unapplied
- [x] S1 CONTRACT/BE marked `done` using lane-scoped completion

Workspace technical debt (does not block Pricing S1 CONTRACT/BE):

- The latest S1 workspace-wide `melos run test --no-select` run recorded failures in Sales domain, Partner infrastructure, Design System, Catalog presentation and Partner presentation.
- The latest S1 `scripts/ci/verify_harness.sh` run recorded five pre-existing oversized presentation files outside Pricing.
- GitNexus MCP/runtime issue was resolved on 2026-07-16 with a pinned arm64 repo-local runtime and global Codex MCP registration; `impact` and `detect-changes` CLI are available again.

## Phase 2.3 — Pricing S2 CONTRACT + BE (TH-04)

- [x] Search query/result/list-item/cursor contracts, typed filters/status/source and four fake scenarios frozen
- [x] Pricing-local query access guard binds tenant and checks generated view metadata before scoped QueryBus execution
- [x] Read gateway/mapper, snapshot search RPC draft, stable cursor, derived status and floor-redaction tests implemented
- [x] Catalog/S1 drafts extended with product reference/SKU snapshots; drafts remain unapplied
- [x] Pricing domain 8/8, application 31/31 and infrastructure/SQL 31/31 tests green; all Pricing analyzers clean
- [x] S2 CONTRACT/BE marked `done` using lane-scoped completion; FE/E2E remain `todo`

Workspace technical debt (does not block Pricing S2 CONTRACT/BE):

- Full `melos run analyze --no-select` passes with existing warnings/info outside Pricing.
- Full `melos run test --no-select` still fails in Partner infrastructure, Sales domain, Design System, Catalog presentation and Partner presentation.
- `scripts/ci/verify_harness.sh` still reports five pre-existing oversized Catalog/Partner presentation files; all preceding architecture/layout/docs/traceability guards pass.

## Phase 2.4 — Pricing S3 CONTRACT + BE (TH-04)

- [x] Detail query/validator/handler, typed detail DTO, reference-health/source-trace, and four fake scenarios frozen
- [x] Read gateway/detail mapper share create-result decoding; NOT_FOUND + leak rejection covered
- [x] Query access guard + generated CQRS/access metadata for `GetCustomerPriceRuleDetailQuery`
- [x] Detail RPC draft with live provider enrichment, action/trace/floor redaction; S1 create helper expanded for shared decoder
- [x] Pricing domain 8/8, application 44/44 and infrastructure 60/60 tests green; all Pricing analyzers clean
- [x] Focused layer/layout/docs/traceability guards pass; SQL remains draft-only and unapplied
- [x] S3 CONTRACT/BE marked `done` using lane-scoped completion; FE/E2E remain `todo`

Workspace technical debt (does not block Pricing S3 CONTRACT/BE):

- GitNexus MCP unavailable in this Cursor session; CLI impact hung — blast radius assessed via Pricing-scoped grep (MEDIUM, Pricing-only callers).
- Full workspace `melos run test --no-select` / oversized presentation files remain as tracked outside Pricing (same debt as S1/S2).

## Phase 2.5 — Pricing S5 CONTRACT + BE (TH-04)

- [x] Update command/validator, `PricingBlockedCodes.stateChanged`/`invalidStatus`, and all eight `updateRule*` fake scenarios frozen (`update_customer_price_rule_contract_test.dart`)
- [x] `CustomerPriceRule.reconstitute`/`hasSameMutableValues`/`updateMutableFields` + `CustomerPriceRuleUpdatedDomainEvent`; currency immutable via `RuleCurrencyMustNotChangeRule`
- [x] `CustomerPriceRuleUpdateContext`/`ICustomerPriceRuleUpdateContextPort` + `UpdateCustomerPriceRuleCommandHandler` (advisory precheck, always calls authoritative gateway even on no-op)
- [x] `PricingUpdateRpcMapper`, `SupabasePricingUpdateContextGateway`, `SupabaseCustomerPriceRuleCommandGateway.update`; `STATE_CHANGED`/`INVALID_STATUS` allow-listed in error mapper
- [x] Startup wiring — `PricingDataAccessModule` registers the update-context port, `PricingModule` binds execution context for `UpdateCustomerPriceRuleCommand`, codegen regenerated (registrar/access-metadata/manifest)
- [x] Draft-only SQL `pricing_customer_price_rule_update_s5.sql` — advisory `get_customer_price_rule_update_context` + authoritative `update_customer_price_rule` (row lock, version/status check, no-op short-circuit, single `updated` activity); `activity_type` check constraint widened in this file only
- [x] `07-api-contracts.md` §S5 frozen (exact command/RPC param lists, error list, all 8 fake scenarios, no-op/disabled/fixed-needs-review semantics); `US-06.md` design reference corrected SG-04 → SG-03 with SCN-01/02/03 evidence notes
- [x] S5 CONTRACT/BE marked `done` using lane-scoped completion (2026-07-16); FE/E2E remain `todo`

Focused verification (2026-07-16):

- `dart format modules/pricing/domain modules/pricing/application modules/pricing/infrastructure` — exit 0. It reformatted 7 files left over from Tasks 1–6 (implementation, dart-format-version drift, not a Task 7 concern); those formatting changes were reverted (`git checkout`) to keep this docs-only task's diff limited to harness/doc files, so Tasks 1–6 commits are unchanged.
- Pricing domain `dart test`: 14/14 passed.
- Pricing application `dart test`: 62/62 passed.
- Pricing infrastructure `dart test`: 72/72 passed.
- `melos run codegen` from root: "wrote 0 outputs" (same pub-workspace quirk as S5 Task 5); per-package `dart run build_runner build` in `modules/pricing/infrastructure` also reports "wrote 0 outputs" — all generated files (registrar/access-metadata/manifest) are already current, confirmed via `git status` showing no diff under `generated/`.
- `melos run analyze` (workspace): exits 0; `vet45_pricing_domain`, `vet45_pricing_application`, `vet45_pricing_infrastructure` all report "No issues found!". Pre-existing warnings/info remain in Design System, ERP, Partner application/presentation/domain — unrelated to Pricing.
- `melos run test` (workspace): Pricing packages all green (domain 14/14, application 62/62, infrastructure 72/72, embedded in the workspace run). `dart test` script fails overall (non-zero) due to pre-existing, Pricing-unrelated failures in `vet45_sales_domain` (no tests found), `vet45_partner_infrastructure`, `vet45_catalog_presentation`, `vet45_design_system`, and `vet45_partner_presentation` — same tracked technical debt as S1–S3, not caused by this slice.
- `bash scripts/ci/verify_harness.sh`: overall exit 0. `guard_infra_dart_only`, `guard_layer_imports`, `guard_application_use_case_layout`, `guard_application_dto_colocation`, `guard_docs_reference`, `guard_theme_structure`, `guard_theme_traceability` all OK for TH-04. `guard_presentation_size` reports the same five pre-existing oversized Catalog/Partner presentation files as prior slices (none in Pricing).
- GitNexus `detect_changes`/`impact` MCP tools unavailable in this session (confirmed via `GetMcpTools`, no matching server). Scope asserted instead via `git log --oneline 5c36b25c..HEAD` (Tasks 1–6's 7 commits) and `git diff --stat 5c36b25c..HEAD` (32 files, all under `modules/pricing/**` plus one new `supabase/migrations/_drafts/**.sql` — no ERP presentation, Sales, Partner domain, or Catalog domain files touched).

## Phase 2.6 — Pricing S6 CONTRACT + BE (TH-04)

- [x] Disable command/validator, detail DTO lifecycle fields (`disabledAt`/`disabledBy`/`disabledReason`), and all six `disableRule*` fake scenarios frozen (`disable_customer_price_rule_contract_test.dart`)
- [x] `CustomerPriceRule.disable` + `CustomerPriceRuleCanBeDisabledRule` + `CustomerPriceRuleDisabledDomainEvent`; already-disabled no-op; deleted invalid
- [x] `DisableCustomerPriceRuleCommandHandler` → single `ICustomerPriceRuleCommandGateway.disable` (no advisory/precheck)
- [x] `PricingDisableRpcMapper`, `SupabaseCustomerPriceRuleCommandGateway.disable`; lifecycle fields on detail mapper; `STATE_CHANGED`/`INVALID_STATUS` allow-listed
- [x] Startup wiring — `PricingModule` binds execution context for `DisableCustomerPriceRuleCommand`; codegen regenerated (registrar/access-metadata/manifest)
- [x] Draft-only SQL `pricing_customer_price_rule_disable_s6.sql` — `disable_customer_price_rule` (row lock, already-disabled before version check, single `disabled` activity) + detail wrapper for disable audit columns; `activity_type` check constraint widened in this file only
- [x] `07-api-contracts.md` §S6 frozen (exact command/RPC params, lifecycle fields, error list, six fakes, idempotent-before-version ordering); `US-07.md` resolved decisions recorded
- [x] S6 CONTRACT/BE marked `done` using lane-scoped completion (2026-07-16); FE/E2E remain `todo`

Focused verification (2026-07-16 Task 7 harness close):

- `bash scripts/ci/verify_harness.sh`: `guard_infra_dart_only`, `guard_layer_imports`, `guard_application_use_case_layout`, `guard_application_dto_colocation`, `guard_docs_reference`, `guard_theme_structure`, `guard_theme_traceability` all OK (TH-04 included). Overall exit **1** solely from `guard_presentation_size` — five pre-existing oversized Catalog/Partner files (none in Pricing / no S6 presentation file).
- GitNexus MCP unavailable in this session (`GetMcpTools` — no `gitnexus` server). Docs scope asserted via `git diff --stat` on the eight Task 7 harness/PROGRESS paths only.
- SQL remains draft-only and unapplied; no claim that disable RPC is live on a local DB.

Focused verification (2026-07-16 Task 8 final VERIFY ONLY — no commit):

- `dart format` Pricing domain/application/infrastructure: exit 0 (10 files reformatted; whitespace/`dart format` wrap only). `git diff --check`: clean.
- Pricing `dart test`: domain **18/18**, application **73/73**, infrastructure **80/80** — all passed (includes disable domain/contract/mapper/startup/SQL draft contract).
- `melos run codegen`: wrote 0 outputs; `git diff --exit-code` on `modules/pricing/infrastructure/.../generated` — no drift.
- `melos run analyze`: exit 0; `vet45_pricing_{domain,application,infrastructure}` — No issues found. Non-Pricing warnings remain (Catalog/ERP/Partner/Design System/env) — lane-external baseline.
- `melos run test`: exit **1**; Pricing packages green (18/73/80). FAILED packages (lane-external, same S1–S5 debt): `vet45_sales_domain` (exit 79, no tests), `vet45_partner_infrastructure` (+39 -1), `vet45_design_system` (+0 -13), `vet45_catalog_presentation` (+0 -3), `vet45_partner_presentation` (+0 -29).
- `bash scripts/ci/verify_harness.sh`: exit **1** solely from `guard_presentation_size` (five Catalog/Partner files below); all other guards OK including TH-04.
- Forbidden scope (working tree): no `apps/erp/`, no Pricing presentation, no Partner/Catalog/Sales module code, no timestamped migrations, no `REGISTRY.yaml`. SQL only `_drafts/pricing_customer_price_rule_disable_s6.sql`.
- GitNexus: MCP server absent; CLI `gitnexus detect_changes --scope compare --base-ref main` too broad (whole branch vs main). Working-tree `detect_changes --scope all`: 33 files, 16 symbols, risk **low**, Pricing/TH-04 focused, 0 affected processes.
- Handoff: **uncommitted** S6 work intentionally left for user commit; AGENTS.md/CLAUDE.md dirty but out of S6 staging scope.

Workspace technical debt (does not block Pricing S6 CONTRACT/BE):

- `guard_presentation_size`: `upsert_custom_field_page.dart` (566), `store_price_rule_settings_page.dart` (535), `product_measurement_units_page.dart` (551), `partner_contacts_page.dart` (533), `product_guided_create_cubit.dart` (783) — same Catalog/Partner debt as S1–S5.
- Full workspace `melos run test` failures outside Pricing remain as tracked technical debt (same baseline as S1–S5).

## Phase 2.7 — Pricing S7 CONTRACT + BE (TH-04)

- [x] Precheck query/command/DTO/validators + 16 `reenable*` fake scenarios frozen (`reenable_customer_price_rule_contract_test.dart`)
- [x] `CustomerPriceRule.reenable` + `CustomerPriceRuleCanBeReenabledRule` + `CustomerPriceRuleReenabledDomainEvent`
- [x] `PrecheckCustomerPriceRuleReenableQueryHandler` → `ICustomerPriceRuleReenablePrecheckPort`; `ReenableCustomerPriceRuleCommandHandler` → `ICustomerPriceRuleCommandGateway.reenable`
- [x] `PricingReenableRpcMapper`, precheck gateway, command gateway `reenable`; startup wiring + codegen regenerated
- [x] Draft-only SQL `pricing_customer_price_rule_reenable_s7.sql` — private `_customer_price_rule_reenable_context`, `precheck_customer_price_rule_reenable`, `reenable_customer_price_rule` (Vault-backed HMAC-SHA-256 fingerprint, S1/S5-compatible rule-key advisory lock, token stale precedence, internal floor-status persistence, one `reenabled` activity)
- [x] `07-api-contracts.md` §S7 frozen; US-08/harness traceability/roadmap updated; S7 CONTRACT/BE `done`; FE/E2E `todo`

Focused verification (2026-07-16 Task 7–8):

- Pricing `dart test`: domain **23/23**, application **97/97**, infrastructure **94/94** — all passed.
- `dart analyze` Pricing packages: No issues found.
- `melos run codegen` + generated drift check: no unexpected drift after `build_runner clean` in infrastructure.
- `bash scripts/ci/verify_harness.sh`: TH-04 structure/traceability guards OK; overall exit may remain **1** from pre-existing `guard_presentation_size` (Catalog/Partner) — lane-external.
- SQL remains draft-only and unapplied; no timestamped migration or `REGISTRY.yaml` change.
- GitNexus MCP unavailable in this session; scope limited to Pricing module + `_drafts/pricing_customer_price_rule_reenable_s7.sql` + TH-04 harness docs.

## Flywheel log

Ghi các cải tiến harness sau khi agent fail (ngày + mô tả ngắn):

| Date | Improvement |
| ---- | ----------- |
| 2026-06-29 | Initial harness phase — AGENTS.md, guards, CI, doc reconcile |
| 2026-06-30 | Presentation harness — skill, UI guards, TH-03 ritual, dashboard golden ref |
| 2026-06-30 | IAM Phase 2 golden — codegen, tenant/membership interim, CI strict codegen guard |
| 2026-06-30 | Permission constants — `IamPermissions` domain class; skills/docs anti-pattern hardcode strings |
| 2026-06-30 | IAM minimal — DB RBAC, access checkers, ERP auth migration via IIamModule |
| 2026-06-30 | Implemented Presentation Layer for TH-03 Epic-01 US-03 (Bổ sung và chỉnh sửa) |
| 2026-07-01 | BE/FE harness lanes — 07-api-contracts, FakePartnerModule, Epic-02/US-01 contract-first |
| 2026-06-30 | Updated 05-traceability.md with presentation artifacts mapping for TH-03 Epic-01 (US-01 to US-04) |
| 2026-07-01 | Implemented BE and updated Traceability Matrix for TH-03 Epic-03 US-01 (Theo dõi lịch sử làm việc) |
| 2026-07-02 | Partner codegen — hand-wired mediation/access → generated registrars; TH-03 harness + README updated |
| 2026-07-02 | Partner messaging worker wired — `PartnerMessagingModule` in `messaging_worker` bootstrap |
| 2026-07-02 | Partner messaging realigned to standard flow — consumer handlers moved to application layer (`IIntegrationEventNotificationHandler` + codegen dispatcher); inbox/internal-command processed via `CommandBus`/`IRecurringCommand`; removed hand-rolled processors/ingestor; RPC claim-token contract kept |
| 2026-07-07 | TH-03 partner reboot — product spec v2 (Person/Organization) lệch code cũ; gỡ `modules/partner/`, ERP partner UI, migrations v1; viết lại harness 00-07; slice S1..S9 reset todo |
| 2026-07-16 | TH-04 S1 áp dụng lane-scoped gate: CONTRACT/BE `done` sau khi focused Pricing verification xanh; lỗi workspace ngoài Pricing được theo dõi như technical debt riêng |
| 2026-07-16 | TH-04 S2 hoàn tất snapshot search contract/BE, cursor pagination và query access guard; CONTRACT/BE `done` theo lane-scoped gate, FE/E2E giữ `todo` |
| 2026-07-16 | TH-04 S3 hoàn tất detail query/health/trace/actions + draft RPC provider enrichment; CONTRACT/BE `done`, FE/E2E giữ `todo` |
| 2026-07-16 | TH-04 S5 hoàn tất update command/handler/reconstitution + advisory/authoritative RPC drafts; §S5 contract freeze + US-06 design reference fix (SG-04→SG-03); CONTRACT/BE `done` theo lane-scoped gate, FE/E2E giữ `todo` |
| 2026-07-16 | TH-04 S6 hoàn tất disable command/handler/domain + authoritative RPC draft (already-disabled trước version check); §S6 contract freeze; CONTRACT/BE `done` theo lane-scoped gate, FE/E2E giữ `todo` |
| 2026-07-23 | TH-01 S15 FE/E2E — Admin `IIamModule` wiring (platform users + onboarding); `FakeIamModule` scenarios §S15; roadmap/traceability done |
| 2026-07-30 | TH-01 Contract Gaps Task 11 — semantic guard TH-01 xanh; roadmap/traceability/§S14 status corrected (S1–S3 FE/E2E done; S14 E2E done; S6–S9 BE giữ todo vì Unavailable invitation adapters; dual S14 surface documented). Draft SQL unpromoted. |
| 2026-08-12 | TH-05 Group F BE–FE integration S15–S21 — no-demo guard (explicit Group F file list; Group I demo pages excluded as known debt); ownership `004`/`006`/`007`/`008`/`009`/`010`/`012`; E2E remains blocked on draft promote/seed |
| 2026-08-12 | TH-05 Group G BE–FE integration S22 — SG-09 authoritative precheck/apply + SG-08 refresh; `009` draft-only/unpromoted; E2E remains `todo`; Task 7 pending full verify counts |

## Phase 2.8 — Pricing S8 CONTRACT + BE (TH-04)

- Contracts: five import use cases + template query, validators, 14 fake scenarios, `customer_price_rule_import_contract_test`.
- Domain: `CustomerPriceRuleImport` aggregate lifecycle (`customer_price_rule_import_test`).
- Application: parser result DTO, file/import gateway ports, thin handlers (`customer_price_rule_import_handler_test`).
- Infrastructure: `CustomerPriceRuleImportXlsxCodec` (`archive`+`xml`; no `excel` dependency), LibreOffice fixture, `ExcelCustomerPriceRuleImportFileAdapter`, RPC mapper/gateway, codegen registration, startup test.
- SQL drafts (unapplied): `pricing_customer_price_rule_import_s8.sql`, `catalog_pricing_import_product_unit_resolver.sql`; text contract tests in `pricing_customer_price_rule_import_s8_contract_test`.
- Current corrective verification: domain package (32), application package (111), infrastructure package (127), including domain lifecycle (9), bounded OOXML adapter (17), RPC mapper (5) and SQL contract (7), are green. Pricing domain/application/infrastructure analysis and strict migration policy are green; workspace analyze exits 0.
- Repository baselines outside S8 remain: `verify_harness.sh` stops at five pre-existing presentation files above 500 lines; `melos run test --no-select` fails in five non-Pricing Flutter packages on the current Flutter SDK/tool invocation; strict codegen freshness cannot be green before the intentionally uncommitted generated S8 files are committed. Generated output itself is current (`melos run codegen --no-select` writes 0 outputs).
- GitNexus index refreshed successfully; upstream impact recorded before symbol changes. Final working-tree `detect_changes(scope: all)` reports 32 changed indexed symbols, no affected execution process, and low risk. Branch-wide comparison to `main` is intentionally not used as the S8 scope signal because this long-lived feature branch already differs by 2,214 files.
- Lane: CONTRACT/BE `in_progress`; FE/E2E `todo`; no Pricing presentation changes.

## Phase 2.9 — Pricing S9 CONTRACT + BE (TH-04)

- [x] Domain `RememberedPriceRequest` aggregate + outcome consistency rules (`remembered_price_request_test`)
- [x] Application command/validator/handler/port + 11 fake scenarios (`save_remembered_price_from_order_contract_test`, `save_remembered_price_from_order_handler_test`, `fake_pricing_module_test`)
- [x] Infrastructure `RememberedPriceRpcMapper`, `SupabaseRememberedPriceGateway`, startup wiring + codegen (`remembered_price_rpc_mapper_test`, `supabase_remembered_price_gateway_test`, `pricing_remembered_price_startup_test`)
- [x] `CustomerPriceRuleSourceTraceDto.sourceMemoryRequestId` + detail mapper redaction (`customer_price_rule_detail_rpc_mapper_test`)
- [x] Draft-only SQL `pricing_remembered_price_from_order_s9.sql` — `remembered_price_requests` table, `_remembered_price_outcome`, `save_remembered_price_from_order`, `get_customer_price_rule_detail` source-trace projection; text contract tests in `pricing_remembered_price_from_order_s9_contract_test`
- [x] `07-api-contracts.md` §S9 frozen (drafted/unapplied); US-09 Q-02 resolved; harness roadmap/traceability/architecture updated; S9 CONTRACT/BE `done`; FE `todo`, E2E `blocked`

Focused verification (2026-07-16 Tasks 7–9):

- Focused S9 suites: **84/84** passed (domain remembered_price_request, application contract/handler/fake, infrastructure mapper/gateway/startup/SQL contract, detail mapper).
- Pricing `dart analyze`: domain/application/infrastructure — No issues found.
- `melos run migrate:verify-policy -- --strict`: OK (no violations).
- SQL remains draft-only and unapplied; no timestamped migration or `REGISTRY.yaml` change.
- GitNexus MCP unavailable in this session; upstream callers for `CustomerPriceRuleSourceTraceDto` / `CustomerPriceRuleDetailRpcMapper` recorded via grep (fake_pricing_module, contract tests, pricing_rpc_mapper, read/disable/reenable/update gateways) — low blast radius, additive field only.

Workspace technical debt (does not block Pricing S9 CONTRACT/BE):

- Full `melos run test --no-select` may still fail in non-Pricing packages (same baseline as S1–S8).
- S8 LibreOffice fixture / import interoperability failures remain lane-external if present in workspace test runs.
- `verify_harness.sh` may still exit **1** from pre-existing `guard_presentation_size` (Catalog/Partner oversized pages).

## Phase 2.10 — Pricing S10 CONTRACT + BE (TH-04)

- [x] Application `GetCustomerPriceRuleHistoryQuery` + activity DTOs/validator/handler + 8 fake scenarios (`get_customer_price_rule_history_contract_test`, `get_customer_price_rule_history_handler_test`)
- [x] Infrastructure history RPC mapper + `IPricingReadGateway.getCustomerPriceRuleHistory` + query access guard + startup (`customer_price_rule_history_rpc_mapper_test`, `pricing_history_startup_test`)
- [x] Draft-only SQL `pricing_customer_price_rule_history_s10.sql` — covering keyset index, `_customer_price_rule_history_snapshot`, `get_customer_price_rule_history`; text contract tests in `pricing_customer_price_rule_history_s10_contract_test`
- [x] `07-api-contracts.md` §S10 frozen (drafted/unapplied); US-10 Q-02/Q-03/Q-04 resolved; harness roadmap/traceability updated; S10 CONTRACT/BE `done`; FE/E2E `todo`

Focused verification evidence recorded in Task 8 below after Pricing package gates.

Focused verification (2026-07-16 Task 8):

- Pricing application: `dart analyze` clean; `dart test` **158/158** passed.
- Pricing infrastructure focused S10 suites: history mapper/gateway + startup + SQL contract **27/27** passed.
- Full infrastructure `dart test`: **175** passed, **1** failed — pre-existing S8 LibreOffice fixture path (`customer_price_rules_v1_libreoffice.xlsx` PathNotFound when cwd is package root); outside S10 scope.
- `melos run analyze`: SUCCESS (partner_presentation warnings baseline only).
- `scripts/ci/verify_harness.sh`: exits non-zero on five pre-existing oversized presentation files (Catalog/Partner) — same baseline as S1–S9; all Pricing/theme structure/traceability guards OK.
- GitNexus `detect_changes(scope: all)`: risk **low**, 0 affected execution processes.
- SQL draft `pricing_customer_price_rule_history_s10.sql` remains unapplied; no timestamped migration / REGISTRY edit.
- No FE / apps/erp / design-system changes.

## Phase 2.11 — Pricing S8 explicit product/unit import V1 (2026-07-23)

- [x] Breaking Template V1 headers: `product_id` + `product_unit_id` (no V2; old header → `TEMPLATE_HEADER_INVALID`)
- [x] Application DTOs/enum/`importProductUnitMismatch` + Fake conversion-unit evidence
- [x] Excel adapter 8-column + fixtures (`gia_rieng_import_test_mixed.xlsx`, LibreOffice fixture)
- [x] RPC mapper wire keys + `explicit_selection`
- [x] Draft SQL `016_pricing_customer_price_rule_import_explicit_unit.sql` (**unapplied / unpromoted**)
- [x] Presentation preview unit kind + in-memory ERP persistence by exact IDs
- [x] TH-04 harness docs (07/01/05/US-05) updated

Focused verification (2026-07-23, no auto-commit):

- `modules/pricing/application`: contract + fake tests pass
- `modules/pricing/infrastructure`: import adapter/mapper/gateway + explicit-unit SQL contract pass
- `modules/pricing/presentation`: `price_rule_import_widgets_test` pass
- `apps/erp`: `pricing_import_history_e2e_test` pass
- Draft `016` remains unapplied; workbook regenerations required for old V1 files
- `melos run migrate:verify-policy -- --strict`: existing Catalog/Partner WARN baseline (not introduced by draft `016`)

## Pricing S8 auto-match upsert verification — 2026-07-23

- Blank-`rule_id` `upsert`: zero/create, one/update, many/`AMBIGUOUS_OVERLAPPING_RULES`.
- Confirm rematches under the rule-key advisory lock and rejects ID/count/version drift.
- Stable single match overwrites price, effective interval and note; increments version; writes one `import_updated` activity.
- SQL remains draft-only in `017_pricing_customer_price_rule_import_auto_match_upsert.sql`; no timestamped migration was created or applied.

- No commit created per user request.

## Phase 2.12 — IAM Tenant Audit History V2 (TH-01 S13) — 2026-08-20

- [x] Application contract freeze: `SearchTenantAuditLogsQuery` V2 (`query`, `eventCategory`, `eventCodes`, `subjectType`), `TenantAuditActorDto`, `TenantAuditSubjectDto`, `TenantAuditLogDetailDto` with typed `beforeState`/`afterState`, `beforeRedacted`/`afterRedacted`, `TenantAuditDisplayOrigin` enum (`snapshot`, `current`, `system`, `unavailable`), `FakeIamModule` updated with totalCount and V2 search matching.
- [x] Draft SQL storage: `iam_tenant_audit_history_v2_storage.sql` with immutable snapshot columns (`actor_snapshot`, `subject_snapshot`, `event_category`), trigram GIN index for search_document, deterministic `event_category` backfill for known legacy event codes, and no actor/subject snapshot backfill.
- [x] Draft SQL read RPCs: `iam_tenant_audit_history_v2_read.sql` with `search_tenant_audit_logs_v2` (UTC `fromUtc < toUtc`, `total_count` pre-pagination, OR free text + AND structured filters) and `get_tenant_audit_log`.
- [x] Infrastructure adapter: `SupabaseTenantAuditReadPort` mapping nested actor/subject DTOs and totalCount.
- [x] Presentation state: `TenantAuditLogsCubit`, `TenantAuditFilterCriteria`, `TenantAuditEventCategory` chips.
- [x] Catalogs & UI mappers: `TenantAuditEventCatalog` (19 event codes with Vietnamese titles/icons/search aliases), `TenantAuditFieldCatalog` (field names, enum values, sensitive key detection), `TenantAuditUiMapper` computing typed diff rows without UUID guessing.
- [x] Presentation UI: `OrganizationAuditLogsPage` (debounced query search, category chips, totalCount in subtitle), `AuditLogItemCard` (actor role, subject line, legacy provenance badge), `AuditLogDetailPage` (two-column diff item cards, copy buttons, redaction banner).
- [x] Draft SQL payload builders: `iam_tenant_audit_history_v2_payloads.sql` capturing surgical `v_audit_before` / `p_after` for `update_tenant_profile`, `upsert_legal_profile`, `update_my_platform_user_profile`, `resend_tenant_invitation`, `revoke_tenant_invitation`, `accept_invitation`.
- [x] E2E & Documentation: `e2e_e02_u01_u03_u07_test.dart` deterministically proves count, localized search inclusion/exclusion, activation detail forensic fields/provenance, changed-only diff and authorization; `07-api-contracts.md` and `US-07.md` freeze the V2 and no-backfill contracts.
- [!] SQL remains draft-only in `supabase/migrations/_drafts/`; no timestamped migration created or applied. `event_category` is deterministically backfilled for known legacy event codes; legacy actor/subject snapshots are never backfilled.

Focused acceptance verification evidence (fresh, no auto-commit):
- `modules/iam/application`: selected audit contract/handler/event mapping suites **18/18** passed.
- `modules/iam/infrastructure`: audit V2 storage/read/payload, adapter and legacy producer/read/storage regression suites **62/62** passed.
- `modules/iam/presentation`: audit catalog/Cubit/mapper/list/detail suites **43/43** passed.
- `apps/erp`: E2E suite `e2e_e02_u01_u03_u07_test.dart` **5/5** passed.
- Focused E2E `flutter analyze`: no issues.
- `melos run migrate:verify-policy -- --strict`: OK (no violations).
- `git diff --check`: clean.
