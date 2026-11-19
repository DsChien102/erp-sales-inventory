# TH-08 — Slice roadmap

Lane columns: **Contract** | **BE** (sub-lane **Worker**) | **FE** | **E2E**. Prerequisite chỉ bind **E2E**. Status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

Dependency epic: EP-01 → EP-02 → (EP-03 ∥ EP-04).

Contracts: [07-api-contracts.md](07-api-contracts.md) · Traceability: [05-traceability.md](05-traceability.md).


| #   | Slice                                                                                                                                                                                                                                                                             | Type     | Contract | BE   | FE   | E2E  | Parallel group | E2E blocked by      |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ---- | ---- | ---- | -------------- | ------------------- |
| S0  | Docs ingest (canonical → Epic/US + harness)                                                                                                                                                                                                                                       | docs     | done     | n/a  | n/a  | n/a  | —              | —                   |
| S1  | EP-01 — [US-01](../Epic-01-provider-connection-config/US-01.md) connection + [US-02](../Epic-01-provider-connection-config/US-02.md) profile + [US-03](../Epic-01-provider-connection-config/US-03.md) policy + [US-04](../Epic-01-provider-connection-config/US-04.md) readiness | vertical | done     | done | done | todo | A              | —                   |
| S2  | EP-02 — [US-01](../Epic-02-issue-from-sales-order/US-01.md) preview + [US-02](../Epic-02-issue-from-sales-order/US-02.md) manual issue                                                                                                                                            | vertical | done     | in_progress | done | in_progress | B              | S1 Contract+BE      |
| S3  | EP-02 — [US-03](../Epic-02-issue-from-sales-order/US-03.md) auto issue + [US-04](../Epic-02-issue-from-sales-order/US-04.md) result + [US-05](../Epic-02-issue-from-sales-order/US-05.md) retry                                                                                   | vertical | done     | in_progress | done        | done | B              | S2                  |
| S4  | EP-03 — [US-01](../Epic-03-issued-invoice-documents/US-01.md) official view + [US-02](../Epic-03-issued-invoice-documents/US-02.md) documents + [US-03](../Epic-03-issued-invoice-documents/US-03.md) observation                                                                 | vertical | done     | in_progress | done | in_progress | C              | S2 (issued invoice) |
| S5  | EP-04 — [US-01](../Epic-04-send-resend-einvoice/US-01.md) auto send + [US-02](../Epic-04-send-resend-einvoice/US-02.md) manual send + [US-03](../Epic-04-send-resend-einvoice/US-03.md) delivery result                                                                           | vertical | done     | done | done | in_progress | C              | S2 (issued invoice) |
| H1  | MISA V2 production hardening — template/SignType/KCT-only invariant/series lease/retry/status classification                                                                                                                                                                    | hardening | done | done | n/a  | in_progress | D              | S2–S5 Contract      |




## Lane semantics


| Lane            | Phạm vi                                                          | Done khi                                      |
| --------------- | ---------------------------------------------------------------- | --------------------------------------------- |
| **Contract**    | Symbol + DTO + error codes trong 07; fake scenario ids           | §S{n} frozen; FE có thể bắt đầu fake          |
| **BE**          | Domain, application handlers, draft RPC `_drafts/einvoice_*.sql` | Handler tests pass; RPC name khớp 07          |
| **BE → Worker** | Job types, idempotency keys, `IMeInvoiceClient` mapping          | Worker job tests + soft-fail thiếu credential |
| **FE**          | Presentation + Theme 05 embed (SG-02/03)                         | Widget tests + fake module scenarios          |
| **E2E**         | Mediator/integration qua `FakeMeInvoiceClient`                   | Không gọi MISA thật; scenario ids trong 05    |




## Parallel groups


| Group | Slices | Ghi chú                                                |
| ----- | ------ | ------------------------------------------------------ |
| A     | S1     | Foundation — unblock S2                                |
| B     | S2, S3 | Issuance vertical — S3 sau S2                          |
| C     | S4, S5 | Sau ElectronicInvoice từ S2/S3 — **parallel** với nhau |
| D     | H1     | MISA V2 hardening trên nền S2–S5; không mở tax product |


- FE fake: cho phép theo [07-api-contracts.md](07-api-contracts.md) sau Contract lane `done`.
- S4 và S5 parallel sau khi có ElectronicInvoice từ S2/S3.
- UI entry Theme 05 (SG-02/03): coordinate với sales presentation — không block BE handler tests.

## H1 — MISA V2 production hardening (2026-09-16)

Plans: [MISA contract production hardening](../../../superpowers/plans/2026-09-16-th08-misa-contract-production-hardening.md) · [clean rebuild review fixes](../../../superpowers/plans/2026-09-16-th08-hardening-review-fixes-clean-rebuild.md).

| Sub | Nội dung | Status | Test id prefix |
| --- | --- | --- | --- |
| H1.0 | Contract freeze docs (SignType 2/5, KCT-only policy, series lease, retry policy) | done | — |
| H1.1 | Capability template có mã / không mã / MTT | done | `th08_hardening_capability_*` |
| H1.2 | Resolve template + SignType, bỏ fallback | done | `th08_hardening_resolve_*` |
| H1.3 | Bảo vệ invariant `KCT-only` + `UNSUPPORTED_TAX_DATA` | done | `th08_hardening_tax_*` |
| H1.4 | Buyer org MST bắt buộc địa chỉ | done | `th08_hardening_buyer_*` |
| H1.5 | Status/reconcile classification theo series | done | `th08_hardening_status_*` |
| H1.6 | Series publish lease atomic, fencing + heartbeat multi-worker | done | `th08_hardening_lease_*` |
| H1.7 | Provider retry có command identity riêng, replay idempotent, tối đa ba retry | done | `th08_hardening_retry_*` |
| H1.8 | Fail-closed parse/URL + delivery `UNKNOWN` unlock | done | `th08_hardening_parse_*` |
| H1.9a | Local fake/contract/regression gate | done | `th08_hardening_gate_*` |
| H1.9b | Reset/apply draft + live MISA acceptance | todo | live evidence |

**Aggregate H1:** `in_progress`. Local Dart/worker/ERP/SQL-contract gate đã pass; `verify_harness.sh` chỉ còn baseline ADR 11 tại `modules/einvoice/presentation/pubspec.yaml`. H1 chỉ chuyển `done` sau khi người dùng reset/apply chuỗi draft và hoàn tất live MISA acceptance. Không promote/apply SQL trong lane hardening trừ khi người dùng yêu cầu riêng.

**Không đụng:** endpoint set, token cache, RefID, preview/view, PDF/XML, send-email Product — regression bắt buộc.



## Status feedback (thuộc S2 FE lane)

ERP quan sát trạng thái async bằng **poll projection qua RPC**, không dùng realtime — quyết định và lý do: [03-architecture-and-flows.md §11](03-architecture-and-flows.md).

Việc cụ thể trong S2:

- [ ] `IssueInvoiceCommand` trả `PREPARING` (hoặc attempt status hiện tại khi replay) → UI hiện projection `Đang xử lý` ngay, không chờ vòng poll đầu
- [ ] Poll `GetOrderInvoiceProjectionQuery` 3–5s khi chưa terminal; dừng hẳn khi terminal
- [x] Thêm `refetchInterval` vào `packages/c45_async_query` (`QueryOptions` + `QueryObserver`) — mechanism dùng chung, không dựng `Timer.periodic` từng màn *(đã có sẵn tại `packages/c45_async_query/lib/src/query_options.dart` trước plan S2 complete)*

Deferred (chưa lên slice, đã ghi rationale trong §11): realtime broadcast signal → invalidate; kick worker tick server-side sau enqueue.

## S2b BE closeout (honest)

S2b verifies manual start and immediate provider-result landing through Dart fakes, RPC-shape/SQL contract tests and worker tests. Production remains fail-closed until authoritative Theme 05/Theme 03 source contracts and the approved SQL migrations land. Unknown-result cases hand off durably to the implemented S3b poll consumer; production activation still waits for draft promotion/application.

- **BE lane `in_progress`:** draft SQL `007_einvoice_issuance_schema_and_publish_rpcs.sql` (và chuỗi S2 source/buyer drafts) chưa promote; S3b poll consumer đã implement/test nhưng chưa active trên production DB khi draft chưa promote. Source gate Sales (`get_einvoice_source_snapshot` / `can_access_sales_order`) + buyer snapshot đã có trong `_drafts/`.
- **FE lane `done`:** `OrderEInvoiceSection` gắn SG02-R01 (chi tiết đơn) + SG02-R02 (kết quả bán hàng); contract test `order_einvoice_mount_test`.
- **E2E lane `in_progress`:** canonical→wire MISA `einvoice_s2_end_to_end_real_source_test` đã có; UI flow thật trên đơn Theme 05 còn xác nhận live (Checkpoint Bước 5).
- **Traceability:** EP-02/US-01..02 FE = `done`; US-02 + US-04 immediate-result BE subset = `done` (focused package tests pass).
- **Out of scope S2b:** poll execution, callback ingestion, case resolution, finalization recovery → S3b.

## S3 Closeout & Lane Status (honest)

Slice 3 covers auto issuance trigger/re-evaluation (S3a), async result polling/reconciliation/recovery (S3b), and manual retry upon definite failure (S3c).

- **Contract lane `done`:** Symbol Dart, DTOs, RPC contracts, and error codes defined and frozen in `07-api-contracts.md`.
- **BE lane `in_progress`:** Dart handlers/gateways/worker và SQL contracts đều pass; các draft `007`, `008`, `009` vẫn chưa promote/apply.
- **Pre-S4 repair gate:** S3b now composes against the canonical S2b schema, persists typed provider-result evidence, closes terminal reconciliation cases, uses the frozen 30-second first poll, recovers a complete `ElectronicInvoice` without fabricated legal identity, and emits `einvoice.electronic_invoice.registered` through the outbox helper. Focused compatibility guards cover these invariants.
- **Worker sub-lane `done`:** Internal command processing, reconciliation polling ticks with backoff schedule `[30s, 2m, 10m, 30m, 2h]`, status queries, dead-letter routing, and fake client tests verified in `messaging_worker`.
- **FE lane `done`:** Cả hai host Theme 05 hiển thị trực tiếp `OrderEInvoiceSection`. Polling bằng async-query với tenant scope chạy mỗi năm giây khi nonterminal, pause khi route/app không active, dừng ở definite terminal state, đọc safe failure metadata qua `GetIssuanceAttemptStatusQuery` (không lộ raw provider message), bắt lỗi background poll, khóa tap tới snapshot authoritative, detail luôn mount để tự phục hồi, và chỉ gửi `RetryIssuanceCommand` từ definite failure. Evidence: suite S3 ERP + application/infra/worker S3 + migrate policy + theme guards. Full ERP suite / `verify_harness` (nợ `modules/einvoice/presentation`) ngoài DoD FE lane đã chốt.
- **E2E lane `done`:** All 11 boundary scenarios (`e2e_e02_u03_sc01_01`, `scn_e02_u03_fr09_01`, `e2e_e02_u04_sc01_01`, `pending_handoff_existing_case_01`, `scn_e02_u04_fr08_02`, `scn_e02_u04_fr08_03`, `scn_e02_u04_fr01_02`, `e2e_e02_u05_sc01_01`, `scn_e02_u05_sc11_01`, `scn_e02_u05_sc12_01`, `s2b_command_integrity_dead_letter_01`) pass against mediator, inbox, worker, and provider ports in `einvoice_slice3_integration_test.dart`. Cross-module auto-issue transport is covered by `sales_to_einvoice_auto_issue_flow_test.dart` (raw `sales.outbox` → shared bus → `einvoice.inbox` → `StartAutoIssuanceCommand` on `sales_order_finalized.v1`). Direct inbox inject in Slice 3 integration tests is component evidence only, not cross-module E2E.
- **Sales outbox repair:** Worker binds `iam` + `sales` + `einvoice` on one shared `IEventsBus`; canonical fact is `sales_order_finalized.v1` (payload includes `salesOrderVersion`); draft `017` owns finalize outbox payload.

## S4 BE entry contract

S4 starts from the async resource contract frozen in [07-api-contracts.md](07-api-contracts.md): request RPC persists operation + internal command atomically, worker alone calls MISA, and UI polls detail/document read models. Official-view/document DTO additions are backward-compatible; migration promotion and live MISA sandbox evidence remain release/integration gates, not reasons to put provider HTTP inside S4 handlers.

## S5 Task 0 contract freeze (honest)

- [x] Frozen delivery enums + typed `DeliveryResultEvidence` (no client `deliveryKind`, no raw `Map` providerResult).
- [x] Public read DTOs expose trigger/actor/recipient-source + display-state secondary attention.
- [x] S2/S3 `attempt_snapshot.buyer_lineage.buyerInvoiceSnapshot` = source-owned Theme-05 base, captured before completion merge.
- [x] Theme + EP-04 US-01/US-03 + harness 01–05/07: BuyerInvoiceSnapshot fallback, one initial delivery, UNKNOWN lock, capability-aware reconciliation, MISA observation unsupported, max 3 technical attempts, display-state precedence, safe event payloads, source-owned `partner.get_einvoice_recipient_snapshot`.
- [x] Contract tests: `s5_contract_test.dart`, S2b/S3a SQL buyer_lineage assertions.

## S4 Task 0 repair gate (contract freeze)

- [x] `ProviderInteractionRecord` canonical schema in draft `001` (payload-free audit; UUID `correlation_id`).
- [x] S2 preview moved to `invoice_preview_operations` (draft `005`/`006`); preview RPC names unchanged.
- [x] `ProviderCapabilitiesSnapshot.supportedDocumentTypes` + fail-closed capability gate documented.
- [x] `CHECK_REQUIRED` unresolved lock + `sales.can_access_sales_order` scope gate in 07.
- [x] Observation explicit `triggerId` idempotency; no daily scan / due-command seeder RPC.
- [x] Executable contract tests in `modules/einvoice/infrastructure/test/electronic_invoice/`.

## S4 closeout (honest)

S4 BE Dart + worker paths verified: `einvoice_slice4_integration_test.dart` (17 scenarios), `s4_worker_handlers_test.dart`, `einvoice_worker_slice4_test.dart`, SQL contract tests `einvoice_s4a`/`s4b`/`s4c`. Internal commands: `einvoice.fetch_official_view` (attempt limit 2), `einvoice.download_invoice_document` (3), `einvoice.poll_provider_observation` (trigger-scoped). `CHECK_REQUIRED` unresolved lock; definite empty/rejection → `FAILED`; ambiguous timeout exhaustion → `CHECK_REQUIRED` + `PROVIDER_RESULT_UNDETERMINED`. Signed URL TTL 5 minutes; private bucket + scoped Storage SELECT.

| Sub-lane | Status | Evidence / blocker |
| -------- | ------ | ------------------ |
| Worker | done | Worker handler tests + `ProcessInternalCommandsCommandHandler` attempt injection |
| BE Dart | done | Integration harness + handler/registration tests |
| BE DB | in_progress | Drafts `010`/`011`/`012` in `_drafts/` only |
| FE | done | App-owned SG-02 post-issued + SG-06 sheets; `OrderEInvoiceSection` trên SG02-R01/R02; official view + PDF/XML + safe SnackBar; checksum exporter |
| E2E | in_progress | Local fake pass: `th08_e2e_e03_u01/u02_sc01_01` (Theme 05 hosts), `th08_e2e_e03_u03_sc01_01` (worker/integration); promoted DB + live MISA pending |

Aggregate **S4 BE** lane `in_progress` until drafts `010`/`011`/`012`/`018` promoted và `sales.can_access_sales_order` source-owned. **S4 FE** lane `done` (scoped Slice 4 BE–FE integration plan). **S4 E2E** `in_progress`: UI/runtime evidence trên fake boundary; không live MISA / promoted migration.

Observation: `triggerId` idempotency; `NOT_FOUND`/`MISMATCH` → observation + outbox `einvoice.provider_observation_attention_required`; no tenant-wide scan/seeder; **no ERP observation UI**.

## S5 closeout (honest)

S5 covers EP-04 auto send after registration (S5a), manual send/resend (S5b), and delivery result + capability-aware reconciliation (S5c). BE Dart + worker paths verified in-process with fake RPC/state, real handlers, inbox/outbox/internal-command loop, and `FakeMeInvoiceClient`.

Verified: `einvoice_slice5_integration_test.dart` (26), `fake_einvoice_scenarios_e04_test.dart` (6), SQL contract tests `einvoice_s5_*` + partner recipient snapshot (84), config `einvoice_s5_*.dart` (17), `messaging_worker` (32). Internal commands: `einvoice.send_invoice_email`, `einvoice.reconcile_invoice_delivery`. Auto trigger via `electronic_invoice.registered` inbox handler; server derives INITIAL/RESEND; current MISA observation unsupported → first reconciliation `UNRESOLVED` + one attention event.

| Sub-lane | Status | Evidence / blocker |
| -------- | ------ | ------------------ |
| Contract | done | Task 0 freeze + `s5_contract_test.dart`; §S5 in 07 |
| Worker | done | `enableMisaHttp` MISA send adapter; dead-letter handlers; `einvoice_s5_worker_composition_test` |
| BE Dart | done | Integration (26) + application (192) + domain (96) + fake EP-04 (6) |
| BE DB | in_progress | Drafts `013`/`014`/`015` + `016_partner_einvoice_recipient_snapshot.sql` in `_drafts/` only |
| FE | done | App-owned SG-07 Send/Resend/History trên `OrderEInvoiceSection` (SG02-R01/R02); `OrderInvoiceDeliveryCubit` + history cubit; catalog specimens const/fake |
| E2E (UI) | in_progress | Fake/runtime Theme 05 hosts pass (`th08_e2e_e04_*`); promoted DB + MISA Product live email + simulator manual AC còn mở |

- **Traceability:** BE six trace ids (`scn_e04_u01_fr01_01`, `e2e_e04_u01_sc01_01`, `scn_e04_u02_fr08_01`, `e2e_e04_u02_sc01_01`, `scn_e04_u03_fr04_01`, `e2e_e04_u03_sc01_01`) + FE/UI ids `th08_e2e_e04_u01_sc01_01`, `th08_e2e_e04_u02_sc01_01`, `th08_e2e_e04_u02_sc06_01`, `th08_e2e_e04_u02_sc08_01`, `th08_e2e_e04_u03_sc04_01`.
- **Production gate:** draft promotion `013`–`016`; MISA Product live send evidence (không dùng testapi email as proof of mailbox delivery).
- **Manual AC (simulator):** CV10 B6–B8 còn mở — không đánh aggregate Slice 5 `done`.
- **Follow-up hardening (non-blocking):** submitted dead-letter depth, auto/manual race proxy, UNRESOLVED late-terminal.

Aggregate **S5 BE** lane `done` for Dart/worker implementation; **BE DB** remains `in_progress` until draft SQL promotes. **S5 FE** lane `done` (scoped Slice 5 BE–FE plan). **S5 E2E** `in_progress`: UI/runtime fake boundary; không live promoted DB / MISA Product.

## Dev Live Acceptance & Verification

Quy trình kiểm thử live acceptance end-to-end trên môi trường dev (đơn hàng cố định `TEST-HDDT-001`, MISA sandbox, Supabase dev, worker) được theo dõi tại [DEV-LIVE-ACCEPTANCE-CHECKLIST.md](DEV-LIVE-ACCEPTANCE-CHECKLIST.md).

| Milestones / Thành phần | Trạng thái | Bằng chứng kiểm thử & Ghi chú |
| :--- | :---: | :--- |
| **Fixed Fixture & Seed** | `removed` | Fixture tồn tại khi Theme 05 chưa có; Theme 05 đã có nên nguồn đơn hàng là `sales.sales_orders`. (Cũ: `sales.einvoice_acceptance_orders` / `TEST-HDDT-001`; scripts seed/trigger đã gỡ khỏi `scripts/supabase/`.) |
| **SQL Parity & Bundle** | `done` | RPC helper `einvoice.build_canonical_invoice` (draft 006); bundle scripts `build_theme8_bundle.sh` & `apply_einvoice_dev_acceptance_bundle.sh`; 17/17 SQL contract tests passed |
| **MISA Provider Adapter** | `done` | Truthful capabilities (`enableMisaHttp`), meInvoice sandbox preview mapper, email flagged as unsupported on test host; 483/483 infra tests passed |
| **Live Sales Section** | `done` | `OrderEInvoiceSection` hỗ trợ `orderCode` linh hoạt, `OrderEInvoiceCubit` đầy đủ lifecycle + URL viewer + Document exporter; 7 cubit tests + 4 section widget tests passed |
| **Dev Acceptance Page** | `removed` | UI ERP retired — `EinvoiceDevAcceptancePage` / checklist / diagnostics widgets đã gỡ; nghiệm thu tiếp tục qua checklist docs + `OrderEInvoiceSection` |
| **Route & Dev Gate** | `removed` | Route `/dev/einvoice-acceptance` và `EinvoiceDevTaskCard` trên Dashboard đã gỡ |

> **Lưu ý kiến trúc:** Nghiệm thu live chạy trên đơn hàng Theme 05 thật (`sales.sales_orders` qua `get_einvoice_source_snapshot`); không còn bảng fixture `sales.einvoice_acceptance_orders`. UI entry production là `OrderEInvoiceSection` gắn trên chi tiết đơn / kết quả bán hàng (SG02-R01/R02).

## Definition of Done




### Contract lane

- [x] §S sections trong 07 có symbol Dart, input summary, success DTO, error codes
- [x] RPC names `einvoice.*` liệt kê status `drafted`
- [x] Worker mapping + fake scenarios ≥ happy + error path
- [x] Row CONTRACT trong 05-traceability cập nhật



### BE lane

- [x] Handlers registered via codegen (`modules/einvoice/`)
- [x] Validators trong pipeline — không inline trong handler
- [x] Draft SQL trong `_drafts/` — không file timestamp migration
- [x] Domain invariants covered by unit tests
- [x] 05 traceability BE rows có `scn_*` test id



### BE → Worker sub-lane

- [x] Job type + payload documented trong [03-architecture-and-flows.md §8](03-architecture-and-flows.md)
- [x] Idempotency key stable per operation
- [x] Per-tenant credential load + token cache keyed by `tenantId`
- [x] Soft-fail khi thiếu credential tenant (không crash worker tick)
- [x] `FakeMeInvoiceClient` trong worker/integration tests



### FE lane

- [ ] Example catalog scaffolded — [modules/einvoice/presentation/example/README.md](../../../modules/einvoice/presentation/example/README.md) (38 specimen audit; BC widgets pending per slice)
- [ ] Pages/widgets tách file — không God Widget
- [ ] `IModuleMediator` wiring — không direct PostgREST
- [ ] Fake scenarios khớp 07 `scenario_id`
- [ ] SG-04/05: không implement UI



### E2E lane

- [ ] Integration test qua mediator + fake RPC/worker
- [ ] `FakeMeInvoiceClient` — **không** live MISA
- [ ] Theme 05 projection consume verified (khi sales slice sẵn sàng)
- [ ] `e2e_*` ids trong 05



### Chung

- [ ] `melos run analyze && melos run test`
- [ ] `./scripts/ci/verify_harness.sh`



## Slice done

Contract + BE (+ Worker) + FE + E2E đều `done` (hoặc `n/a`).

Khi bắt đầu S1: cập nhật [README.md](../README.md) **Trạng thái deliver** sang đang giao.

## Epic → module mapping


| Epic  | Primary package folders               |
| ----- | ------------------------------------- |
| EP-01 | `application/.../configuration/`      |
| EP-02 | `application/.../issuance/`           |
| EP-03 | `application/.../electronic_invoice/` |
| EP-04 | `application/.../delivery/`           |


Golden reference CQRS: `modules/iam/` — không copy `modules/sales/` scaffold.
