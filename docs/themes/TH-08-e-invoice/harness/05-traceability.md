# TH-08 — Traceability

Role: `CONTRACT` | `BE` | `FE` | `E2E`. Test id pattern: `scn_e0x_u0y_fr0k_01` / `wgt_e0x_u0y_fr0k_01` / `e2e_e0x_u0y_sc0k_01`. Slice 4 FE/E2E evidence mới dùng prefix theme: `th08_scn_*` / `th08_wgt_*` / `th08_e2e_*` (cùng cấu trúc suffix). Hardening MISA V2 dùng prefix `th08_hardening_*`; local implementation/fake gate và live MISA gate được theo dõi riêng.

FR IDs **local theo US** — luôn qualify `EP-0n/US-0m/FR-0k`. Contracts: [07-api-contracts.md](07-api-contracts.md).

## Platform

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-08-WORKER | CONTRACT | global + §S2b worker | application | Worker-only MISA HTTP; ERP enqueue only | — | done |
| TH-08-ERRORS | CONTRACT | Error envelope | application | `modules/einvoice/application/lib/src/shared/einvoice_blocked_codes.dart` | — | done |
| TH-08-PROJECTION | CONTRACT | §S2b projection | application | `modules/einvoice/application/lib/src/shared/order_invoice_projection_dto.dart` | — | done |
| TH-08-MISA-V2 | CONTRACT | §H1 MISA V2 freeze | docs + application | SignType 2/5, KCT-only policy, series lease, retry policy | th08_hardening_contract_01 | done |

## S1 — EP-01 — Kết nối NCC & cấu hình phát hành

### EP-01 / US-01 — Kết nối và duy trì kết nối

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-01 | CONTRACT | §S1a | application | `ConnectProviderCommand`, `VerifyProviderConnectionCommand`, `GetProviderConnectionScreenQuery` | — | done |
| EP-01/US-01/FR-01..08 | BE | §S1a | domain + application + infrastructure | Handlers + RPC + worker `einvoice.sync_capabilities` | scn_e01_u01_fr01_01 | done |
| EP-01/US-01/FR-01..08 | FE | §S1a | presentation | SG-01 `provider_connection_page.dart` + connection form | wgt_e01_u01_fr03_01, wgt_e01_u01_fr02_01, wgt_e01_u01_fr08_01 | done |
| EP-01/US-01/SC-01 | E2E | §S1a | integration | Open settings → legal read-only + connect CTA | e2e_e01_u01_sc01_01 | todo |

### EP-01 / US-02 — Cấu hình phát hành mặc định

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-02 | CONTRACT | §S1b | application | `SetDefaultIssuanceConfigurationCommand`, `ListProviderTemplatesQuery` | — | done |
| EP-01/US-02/FR-01..08 | BE | §S1b | application + infrastructure | Profile handlers + gateways | scn_e01_u02_fr01_01 | done |
| EP-01/US-02/FR-01..08 | FE | §S1b | presentation | SG-01 `default_issuance_configuration_page.dart` | wgt_e01_u02_fr04_01 | done |
| EP-01/US-02/SC-01 | E2E | §S1b | integration | Save default HSM config | e2e_e01_u02_sc01_01 | todo |

### EP-01 / US-03 — Chính sách phát hành và gửi tự động

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-03 | CONTRACT | §S1c | application | `UpdateAutomationPolicyCommand`, `GetAutomationPolicyQuery` | — | done |
| EP-01/US-03/FR-01..07 | BE | §S1c | application + domain | `UpdateAutomationPolicyCommandHandler` | scn_e01_u03_fr02_01 | done |
| EP-01/US-03/FR-01..07 | FE | §S1c | presentation | SG-01 `automation_policy_page.dart` | wgt_e01_u03_fr02_01 | done |
| EP-01/US-03/SC-01 | E2E | §S1c | integration | Enable auto-issue when ready | e2e_e01_u01_sc01_01 | todo |

### EP-01 / US-04 — Kiểm tra mức sẵn sàng cấu hình

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-04 | CONTRACT | §S1d | application | `GetConfigurationReadinessQuery` | — | done |
| EP-01/US-04/FR-01..09 | BE | §S1d | domain + application | `ConfigurationReadinessEvaluator` + query handler | scn_e01_u04_fr01_01 | done |
| EP-01/US-04/FR-01..09 | FE | §S1d | presentation | SG-01 `einvoice_configuration_overview_page.dart` D01/D02 | wgt_e01_u04_fr09_01 | done |
| EP-01/US-04/SC-01 | E2E | §S1d | integration | Manual issue readiness = READY | e2e_e01_u04_sc01_01 | todo |

## S2 — EP-02 — Preview + manual issue + attempt lock

### EP-02 / US-01 — Kiểm tra điều kiện và xem trước

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-01 | CONTRACT | §S2a | application | `RequestInvoicePreviewCommand`, `GetIssuanceReadinessQuery` | — | done |
| EP-02/US-01/FR-01..09 | BE | §S2a | application + worker | Readiness/Buyer/Preview handlers + `previewUnpublished` job; real Sales source + canonical→MISA wire | scn_e02_u01_fr01_01, scn_e02_u01_fr04_01, scn_e02_u01_fr07_01, scn_e02_u01_fr08_01, einvoice_s2_end_to_end_real_source_test | done |
| EP-02/US-01/FR-01..09 | FE | §S2a | presentation | SG-02 preview entry on order detail / sales result (`OrderEInvoiceSection`) | wgt_e02_u01_fr09_01, order_einvoice_mount_test | done |
| EP-02/US-01/SC-01 | E2E | §S2a | integration | Open preview when ready | e2e_e02_u01_sc01_01 | todo |

### EP-02 / US-02 — Phát hành thủ công

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-02 | CONTRACT | §S2b | application | `IssueInvoiceCommand`, `GetOrderInvoiceProjectionQuery` | — | done |
| EP-02/US-02/FR-01..08 | BE | §S2b / S2b | application + worker | Manual start, immutable attempt snapshot/hash, durable publish command; real Sales source wire check | scn_e02_u02_fr04_01, einvoice_s2_end_to_end_real_source_test | done |
| EP-02/US-02/FR-01..08 | FE | §S2b | presentation | SG-03 confirmation sheet + processing state trên host Theme 05 | wgt_e02_u02_fr01_01, order_einvoice_mount_test | done |
| EP-02/US-02/SC-01 | E2E | §S2b | integration | Confirm issue → processing projection | e2e_e02_u02_sc01_01 | todo |

## S3 — EP-02 — Auto issue + reconcile + retry

### EP-02 / US-03 — Phát hành tự động

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-03 | CONTRACT | §S3a | application | `StartAutoIssuanceCommand`, `ReevaluateAutoIssuanceCommand` | — | done |
| EP-02/US-03/FR-01..09 | BE | §S3a | application + integration | Inbox `sales_order_finalized.v1` handler + `partner.partner.profile_updated` re-evaluation | scn_e02_u03_fr01_01, scn_e02_u03_fr09_01 | done |
| EP-02/US-03/FR-01..09 | FE | §S3a | presentation | n/a — server-only; UF-04 contextual on Theme 05 row | — | done |
| EP-02/US-03/SC-01 | E2E | §S3a | integration | Sales checkout → `sales.outbox` → worker Sales binding → shared bus → `einvoice.inbox` → `StartAutoIssuanceCommand` → publish | e2e_e02_u03_sc01_01, sales_to_einvoice_auto_issue_flow | done |

### EP-02 / US-04 — Xác lập kết quả phát hành

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-04 | CONTRACT | §S3b | application | `RecordIssuanceResultCommand`, reconciliation commands | — | done |
| EP-02/US-04/FR-01..07 | BE | §S2b / S2b immediate-result subset | application + worker | Direct outcome normalization, success/failure landing, unknown case/handoff, command integrity dead-letter | scn_e02_u04_fr02_01, s2b_command_integrity_dead_letter_01 | done |
| EP-02/US-04 reconciliation execution/recovery | BE | §S3b / S3b | application + worker | Poll consumer ([30s, 2m, 10m, 30m, 2h]), callbacks, case resolution, finalization recovery, late-callback amendment | scn_e02_u04_fr08_01, scn_e02_u04_fr08_02, scn_e02_u04_fr08_03, scn_e02_u04_fr01_02 | done |
| EP-02/US-04/FR-01..08 | FE | §S3b | presentation | n/a — SG-04 reconciliation server-side only | — | done |
| EP-02/US-04/SC-01 | E2E | §S3b | integration | Success path registers ElectronicInvoice via poll | e2e_e02_u04_sc01_01 | done |

### EP-02 / US-05 — Phát hành lại sau thất bại

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-05 | CONTRACT | §S3c | application | `RetryIssuanceCommand` | — | done |
| EP-02/US-05/FR-01..09 | BE | §S3c | application | Retry handler preserves prior attempts, version-bound completion check | scn_e02_u05_fr04_01, scn_e02_u05_sc11_01, scn_e02_u05_sc12_01 | done |
| EP-02/US-05/FR-01..09 | FE | §S3c | presentation | SG-02/03 live projection + definite-failure retry | wgt_e02_u05_fr02_01 | done |
| EP-02/US-05/SC-01 | E2E | §S3c | integration | Definite failure → retry creates new attempt | e2e_e02_u05_sc01_01 | done |

## S4 — EP-03 — Official view + documents + observation

**S4 Task 0 repair:** frozen `ProviderInteractionRecord`, `invoice_preview_operations`, capability `supportedDocumentTypes`, scope gate `sales.can_access_sales_order`, observation `triggerId` idempotency — see [04-slice-roadmap.md](04-slice-roadmap.md) §S4 Task 0 repair gate.

### EP-03 / US-01 — Xem hồ sơ hóa đơn đã phát hành

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-03/US-01 | CONTRACT | §S4a | application | `RequestOfficialInvoiceViewCommand` | — | done |
| EP-03/US-01/FR-01..08 | BE | §S4a | application + worker | View handler + `previewPublished`; official-view operation lock + CHECK_REQUIRED | scn_e03_u01_fr06_01, einvoice_slice4_integration_official_view | done |
| EP-03/US-01/FR-01..08 | FE | §S4a | presentation | SG-02 view action from order row (app-owned sheet + loading lock) | th08_wgt_e03_u01_fr01_01 | done |
| EP-03/US-01/SC-01 | E2E | §S4a | integration | Open official view from order detail (Theme 05 host, fake launcher) | th08_e2e_e03_u01_sc01_01 | in_progress |

### EP-03 / US-02 — Tải tài liệu PDF/XML

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-03/US-02 | CONTRACT | §S4b | application | `RequestInvoiceDocumentCommand` | — | done |
| EP-03/US-02/FR-01..08 | BE | §S4b | application + worker | Document handler + `download` job; PDF/XML checksum + generation | scn_e03_u02_fr03_01, einvoice_slice4_integration_documents | done |
| EP-03/US-02/FR-01..08 | FE | §S4b | presentation | SG-06 document action sheet (sibling lock while loading) | th08_wgt_e03_u02_fr01_01 | done |
| EP-03/US-02/SC-01 | E2E | §S4b | integration | Save PDF from action sheet (Sales result host, fake exporter) | th08_e2e_e03_u02_sc01_01 | in_progress |

### EP-03 / US-03 — Trạng thái tại nhà cung cấp

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-03/US-03 | CONTRACT | §S4c | application | `RecordProviderObservationCommand` | — | done |
| EP-03/US-03/FR-01..07 | BE | §S4c | application + worker | Observation append + poll; attention outbox on NOT_FOUND | scn_e03_u03_fr02_01, einvoice_slice4_integration_observation | done |
| EP-03/US-03/FR-01..07 | FE | §S4c | presentation | n/a — no dedicated observation UI MVP | — | n/a |
| EP-03/US-03/SC-01 | E2E | §S4c | integration | Worker/integration records observation row (fake boundary, not live MISA) | th08_e2e_e03_u03_sc01_01 | done |

## S5 — EP-04 — Auto/manual send + delivery result

### EP-04 / US-01 — Tự động gửi sau phát hành

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-04/US-01 | CONTRACT | §S5a | application | `StartAutoDeliveryCommand` (internal) | — | done |
| EP-04/US-01/FR-01..08 | BE | §S5a | application + integration | Handler on `electronic_invoice.registered` | scn_e04_u01_fr01_01 | done |
| EP-04/US-01/FR-01..08 | FE | §S5a | presentation | n/a — server-only; projection consumed by shared Theme 05 row | th08_e2e_e04_u01_sc01_01 | done |
| EP-04/US-01/SC-01 | E2E | §S5a | integration | Registered event → delivery started (BE fake) | e2e_e04_u01_sc01_01 | done |
| EP-04/US-01/SC-01 | E2E | §S5a | presentation | Auto-send never emits FE `StartAutoDeliveryCommand`; badge from projection | th08_e2e_e04_u01_sc01_01 | done |

### EP-04 / US-02 — Gửi và gửi lại thủ công

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-04/US-02 | CONTRACT | §S5b | application | `SendElectronicInvoiceCommand`, `GetSendInvoiceSheetContextQuery` | — | done |
| EP-04/US-02/FR-01..12 | BE | §S5b | application + worker | Send handler + `sendEmail` job | scn_e04_u02_fr08_01 | done |
| EP-04/US-02/FR-01..12 | FE | §S5b | presentation | App-owned SG-07 Send/Resend + History (`OrderInvoiceDeliveryCubit`) | wgt_e04_u02_fr01_01, send/resend/history sheet tests | done |
| EP-04/US-02/SC-01 | E2E | §S5b | integration | Manual send with buyer email (BE fake) | e2e_e04_u02_sc01_01 | done |
| EP-04/US-02/SC-01 | E2E | §S5b | presentation | Order detail send sheet submit + keep host | th08_e2e_e04_u02_sc01_01 | done |
| EP-04/US-02/SC-06 | E2E | §S5b | presentation | Sales result resend → history → back | th08_e2e_e04_u02_sc06_01 | done |
| EP-04/US-02/SC-08 | E2E | §S5b | presentation | UNKNOWN unlocks manual resend once | th08_e2e_e04_u02_sc08_01 | done |

### EP-04 / US-03 — Xác lập kết quả gửi

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-04/US-03 | CONTRACT | §S5c | application | `RecordDeliveryResultCommand` | — | done |
| EP-04/US-03/FR-01..08 | BE | §S5c | application + worker | Delivery result + display state projection | scn_e04_u03_fr04_01 | done |
| EP-04/US-03/FR-01..08 | FE | §S5c | presentation | Theme 05 projection + secondary attention + history rows (safe actor labels) | th08_e2e_e04_u03_sc04_01, invoice_delivery_history_* | done |
| EP-04/US-03/SC-01 | E2E | §S5c | integration | Delivery success updates projection (BE fake) | e2e_e04_u03_sc01_01 | done |
| EP-04/US-03/SC-04 | E2E | §S5c | presentation | Prior sent + secondary attention keeps sent badge | th08_e2e_e04_u03_sc04_01 | done |

> **S5 E2E honesty:** UI fake/runtime rows above = `done`. Live promoted DB + MISA Product email + iPhone Simulator manual AC (CV10 B4/B6–B8) = `in_progress` — không đánh aggregate Slice 5 `done`.

## H1 — MISA V2 production hardening

Plans: [MISA contract production hardening](../../../superpowers/plans/2026-09-16-th08-misa-contract-production-hardening.md) · [clean rebuild review fixes](../../../superpowers/plans/2026-09-16-th08-hardening-review-fixes-clean-rebuild.md). Aggregate **chưa hoàn tất** cho tới khi draft được reset/apply và có live MISA evidence.

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| H1/CONTRACT | CONTRACT | §H1 | docs | Field map + SignType 2/5 + KCT policy + preserved flows | th08_hardening_contract_01 | done |
| H1/CAPABILITY | BE | §H1 | domain + infrastructure | Template có mã / không mã / MTT capability | th08_hardening_capability_01 | done |
| H1/RESOLVE | BE | §H1 | application + infrastructure | Template + SignType resolve; no fallback | th08_hardening_resolve_01 | done |
| H1/TAX | BE | §H1 | application (canonical) | `KCT-only` boundary + `UNSUPPORTED_TAX_DATA` | th08_hardening_tax_01 | done |
| H1/BUYER | BE | §H1 | domain + application + SQL canonical | Org MST → địa chỉ bắt buộc (`BUYER_ADDRESS_REQUIRED`) | th08_hardening_buyer_01 | done |
| H1/STATUS | BE | §H1 | application + adapter | Strict `InvSeries`; malformed input thành `INVOICE_SERIES_INVALID` trước HTTP | th08_hardening_status_01 | done |
| H1/LEASE | BE | §H1 | application + SQL draft | Atomic acquire, fencing version, renew heartbeat, stale release no-op | th08_hardening_lease_01 | done |
| H1/RETRY | BE | §H1 | classifier + worker + SQL draft | Command-scoped idempotent retry; ba child retry rồi terminal failure chuẩn | th08_hardening_retry_01 | done |
| H1/PARSE | BE | §H1 | c45_misa + delivery domain | Fail-closed parser/URL; `UNKNOWN` unlock | th08_hardening_parse_01 | done |
| H1/GATE-LOCAL | E2E | §H1 | domain + application + infrastructure + worker + ERP | Fake/contract/regression suites pass; harness còn đúng baseline ADR 11 | th08_hardening_gate_01 | done |
| H1/GATE-LIVE | E2E | §H1 | reset/apply + live MISA | Draft SQL applied from clean DB; multi-worker/retry/live provider acceptance | live evidence | todo |

Mở rộng từng dòng FR khi slice chuyển `in_progress` (pattern TH-03 S4).

**S2b deployment note:** S2b verifies manual start and immediate provider-result landing through Dart fakes, RPC-shape/SQL contract tests and worker tests. Production remains fail-closed until authoritative Theme 05/Theme 03 source contracts and the approved SQL migration land. Unknown-result cases land as pending ReconciliationCases with `next_check_at` and are inert until the S3b poll consumer scans them, so S2b carries no poison-row risk; those cases are only acted on once S3b ships its poll consumer. Slice S2 **BE lane** stays `in_progress` until migration promotion and S3b poll-consumer deployment; US-02 + US-04 immediate-result BE rows above are `done` after focused verification.
