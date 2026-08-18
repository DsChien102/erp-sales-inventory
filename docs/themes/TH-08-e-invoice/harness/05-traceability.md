# TH-08 — Traceability

Role: `CONTRACT` | `BE` | `FE` | `E2E`. Test id pattern: `scn_e0x_u0y_fr0k_01` / `wgt_e0x_u0y_fr0k_01` / `e2e_e0x_u0y_fr0k_01`.

FR IDs **local theo US** — luôn qualify `EP-0n/US-0m/FR-0k`. Contracts: [07-api-contracts.md](07-api-contracts.md).

## Platform

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-08-WORKER | CONTRACT | global + §S2b worker | application | Worker-only MISA HTTP; ERP enqueue only | — | done |
| TH-08-ERRORS | CONTRACT | Error envelope | application | `modules/einvoice/application/lib/src/shared/einvoice_blocked_codes.dart` | — | done |
| TH-08-PROJECTION | CONTRACT | §S2b projection | application | `modules/einvoice/application/lib/src/shared/order_invoice_projection_dto.dart` | — | done |

## S1 — EP-01 — Kết nối NCC & cấu hình phát hành

### EP-01 / US-01 — Kết nối và duy trì kết nối

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-01 | CONTRACT | §S1a | application | `ConnectProviderCommand`, `VerifyProviderConnectionCommand`, `GetProviderConnectionScreenQuery` | — | done |
| EP-01/US-01/FR-01..08 | BE | §S1a | domain + application + infrastructure | Handlers + RPC + worker `einvoice.sync_capabilities` | scn_e01_u01_fr01_01 | done |
| EP-01/US-01/FR-01..08 | FE | §S1a | presentation | SG-01 `einvoice_settings_page.dart` + connection form | wgt_e01_u01_fr01_01 | todo |
| EP-01/US-01/SC-01 | E2E | §S1a | integration | Open settings → legal read-only + connect CTA | e2e_e01_u01_sc01_01 | todo |

### EP-01 / US-02 — Cấu hình phát hành mặc định

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-02 | CONTRACT | §S1b | application | `SetDefaultIssuanceConfigurationCommand`, `ListProviderTemplatesQuery` | — | done |
| EP-01/US-02/FR-01..08 | BE | §S1b | application + infrastructure | Profile handlers + gateways | scn_e01_u02_fr01_01 | done |
| EP-01/US-02/FR-01..08 | FE | §S1b | presentation | SG-01 issuance profile section | wgt_e01_u02_fr04_01 | todo |
| EP-01/US-02/SC-01 | E2E | §S1b | integration | Save default HSM config | e2e_e01_u02_sc01_01 | todo |

### EP-01 / US-03 — Chính sách phát hành và gửi tự động

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-03 | CONTRACT | §S1c | application | `UpdateAutomationPolicyCommand`, `GetAutomationPolicyQuery` | — | done |
| EP-01/US-03/FR-01..07 | BE | §S1c | application + domain | `UpdateAutomationPolicyCommandHandler` | scn_e01_u03_fr02_01 | done |
| EP-01/US-03/FR-01..07 | FE | §S1c | presentation | SG-01 automation toggles | wgt_e01_u03_fr02_01 | todo |
| EP-01/US-03/SC-01 | E2E | §S1c | integration | Enable auto-issue when ready | e2e_e01_u01_sc01_01 | todo |

### EP-01 / US-04 — Kiểm tra mức sẵn sàng cấu hình

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-01/US-04 | CONTRACT | §S1d | application | `GetConfigurationReadinessQuery` | — | done |
| EP-01/US-04/FR-01..09 | BE | §S1d | domain + application | `ConfigurationReadinessEvaluator` + query handler | scn_e01_u04_fr01_01 | done |
| EP-01/US-04/FR-01..09 | FE | §S1d | presentation | SG-01 readiness banner + blockers | wgt_e01_u04_fr09_01 | todo |
| EP-01/US-04/SC-01 | E2E | §S1d | integration | Manual issue readiness = READY | e2e_e01_u04_sc01_01 | todo |

## S2 — EP-02 — Preview + manual issue + attempt lock

### EP-02 / US-01 — Kiểm tra điều kiện và xem trước

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-01 | CONTRACT | §S2a | application | `RequestInvoicePreviewCommand`, `GetIssuanceReadinessQuery` | — | done |
| EP-02/US-01/FR-01..09 | BE | §S2a | application + worker | Preview handler + `previewUnpublished` job | scn_e02_u01_fr07_01 | todo |
| EP-02/US-01/FR-01..09 | FE | §S2a | presentation | SG-02 preview entry on order detail | wgt_e02_u01_fr09_01 | todo |
| EP-02/US-01/SC-01 | E2E | §S2a | integration | Open preview when ready | e2e_e02_u01_sc01_01 | todo |

### EP-02 / US-02 — Phát hành thủ công

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-02 | CONTRACT | §S2b | application | `IssueInvoiceCommand`, `GetOrderInvoiceProjectionQuery` | — | done |
| EP-02/US-02/FR-01..08 | BE | §S2b | application + worker | Issue handler + `publish` job + idempotency | scn_e02_u02_fr04_01 | todo |
| EP-02/US-02/FR-01..08 | FE | §S2b | presentation | SG-03 confirmation sheet + processing state | wgt_e02_u02_fr01_01 | todo |
| EP-02/US-02/SC-01 | E2E | §S2b | integration | Confirm issue → processing projection | e2e_e02_u02_sc01_01 | todo |

## S3 — EP-02 — Auto issue + reconcile + retry

### EP-02 / US-03 — Phát hành tự động

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-03 | CONTRACT | §S3a | application | `StartAutoIssuanceCommand` (internal) | — | done |
| EP-02/US-03/FR-01..09 | BE | §S3a | application + integration | Inbox `sales.order.completed` handler | scn_e02_u03_fr01_01 | todo |
| EP-02/US-03/FR-01..09 | FE | §S3a | presentation | n/a — server-only; UF-04 contextual on Theme 05 row | — | todo |
| EP-02/US-03/SC-01 | E2E | §S3a | integration | Order complete → auto issue started | e2e_e02_u03_sc01_01 | todo |

### EP-02 / US-04 — Xác lập kết quả phát hành

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-04 | CONTRACT | §S3b | application | `RecordIssuanceResultCommand`, reconciliation commands | — | done |
| EP-02/US-04/FR-01..08 | BE | §S3b | application + worker | Result handler + `getStatus` poll job | scn_e02_u04_fr02_01 | todo |
| EP-02/US-04/FR-01..08 | FE | §S3b | presentation | n/a — SG-04 reconciliation server-side only | — | todo |
| EP-02/US-04/SC-01 | E2E | §S3b | integration | Success path registers ElectronicInvoice | e2e_e02_u04_sc01_01 | todo |

### EP-02 / US-05 — Phát hành lại sau thất bại

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-02/US-05 | CONTRACT | §S3c | application | `RetryIssuanceCommand` | — | done |
| EP-02/US-05/FR-01..09 | BE | §S3c | application | Retry handler preserves prior attempts | scn_e02_u05_fr04_01 | todo |
| EP-02/US-05/FR-01..09 | FE | §S3c | presentation | SG-02/03 issue action after failed state | wgt_e02_u05_fr02_01 | todo |
| EP-02/US-05/SC-01 | E2E | §S3c | integration | Retry after definite failure | e2e_e02_u05_sc01_01 | todo |

## S4 — EP-03 — Official view + documents + observation

### EP-03 / US-01 — Xem hồ sơ hóa đơn đã phát hành

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-03/US-01 | CONTRACT | §S4a | application | `RequestOfficialInvoiceViewCommand` | — | done |
| EP-03/US-01/FR-01..08 | BE | §S4a | application + worker | View handler + `previewPublished` | scn_e03_u01_fr06_01 | todo |
| EP-03/US-01/FR-01..08 | FE | §S4a | presentation | SG-02 view action from order row | wgt_e03_u01_fr01_01 | todo |
| EP-03/US-01/SC-01 | E2E | §S4a | integration | Open official view from order detail | e2e_e03_u01_sc01_01 | todo |

### EP-03 / US-02 — Tải tài liệu PDF/XML

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-03/US-02 | CONTRACT | §S4b | application | `RequestInvoiceDocumentCommand` | — | done |
| EP-03/US-02/FR-01..08 | BE | §S4b | application + worker | Document handler + `download` job | scn_e03_u02_fr03_01 | todo |
| EP-03/US-02/FR-01..08 | FE | §S4b | presentation | SG-06 document action sheet | wgt_e03_u02_fr01_01 | todo |
| EP-03/US-02/SC-01 | E2E | §S4b | integration | Save PDF from action sheet | e2e_e03_u02_sc01_01 | todo |

### EP-03 / US-03 — Trạng thái tại nhà cung cấp

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-03/US-03 | CONTRACT | §S4c | application | `RecordProviderObservationCommand` | — | done |
| EP-03/US-03/FR-01..07 | BE | §S4c | application + worker | Observation append + poll | scn_e03_u03_fr02_01 | todo |
| EP-03/US-03/FR-01..07 | FE | §S4c | presentation | n/a — no dedicated observation UI MVP | — | todo |
| EP-03/US-03/SC-01 | E2E | §S4c | integration | Poll records observation row | e2e_e03_u03_sc01_01 | todo |

## S5 — EP-04 — Auto/manual send + delivery result

### EP-04 / US-01 — Tự động gửi sau phát hành

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-04/US-01 | CONTRACT | §S5a | application | `StartAutoDeliveryCommand` (internal) | — | done |
| EP-04/US-01/FR-01..08 | BE | §S5a | application + integration | Handler on `electronic_invoice.registered` | scn_e04_u01_fr01_01 | todo |
| EP-04/US-01/FR-01..08 | FE | §S5a | presentation | n/a — server-only auto-send | — | todo |
| EP-04/US-01/SC-01 | E2E | §S5a | integration | Registered event → delivery started | e2e_e04_u01_sc01_01 | todo |

### EP-04 / US-02 — Gửi và gửi lại thủ công

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-04/US-02 | CONTRACT | §S5b | application | `SendElectronicInvoiceCommand`, `GetSendInvoiceSheetContextQuery` | — | done |
| EP-04/US-02/FR-01..12 | BE | §S5b | application + worker | Send handler + `sendEmail` job | scn_e04_u02_fr08_01 | todo |
| EP-04/US-02/FR-01..12 | FE | §S5b | presentation | SG-07 send/resend sheet | wgt_e04_u02_fr01_01 | todo |
| EP-04/US-02/SC-01 | E2E | §S5b | integration | Manual send with buyer email | e2e_e04_u02_sc01_01 | todo |

### EP-04 / US-03 — Xác lập kết quả gửi

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| EP-04/US-03 | CONTRACT | §S5c | application | `RecordDeliveryResultCommand` | — | done |
| EP-04/US-03/FR-01..08 | BE | §S5c | application + worker | Delivery result + display state projection | scn_e04_u03_fr04_01 | todo |
| EP-04/US-03/FR-01..08 | FE | §S5c | presentation | n/a — display state via Theme 05 projection only | — | todo |
| EP-04/US-03/SC-01 | E2E | §S5c | integration | Delivery success updates projection | e2e_e04_u03_sc01_01 | todo |

Mở rộng từng dòng FR khi slice chuyển `in_progress` (pattern TH-03 S4).
