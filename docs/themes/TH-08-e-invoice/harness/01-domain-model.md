# TH-08 — Domain model (v1)

> Bounded context: **einvoice** (`modules/einvoice/` — **greenfield, chưa implement**). Schema Postgres: `einvoice`.
> Product spec: [Theme-8-e-invoice.md](../Theme-8-e-invoice.md) §3–4.
> Analyze: [ddd-domain-modeling](../../../../.cursor/skills/ddd-domain-modeling/SKILL.md) · Implement: [domain-layer](../../../../.cursor/skills/domain-layer/SKILL.md)

**Harness 2026-08-17:** Chốt symbol, schema, state machine và CMD catalog từ canonical §3–4. Contract chi tiết: [07-api-contracts.md](07-api-contracts.md).

Theme 08 **không** sở hữu: Tenant, hồ sơ pháp lý, Partner, SalesOrder, dữ liệu thương mại. Không có danh sách HĐĐT độc lập (MVP).

```mermaid
erDiagram
    PROVIDER_CONNECTIONS ||--o| ISSUANCE_PROFILES : configures
    PROVIDER_CONNECTIONS ||--o| INVOICE_AUTOMATION_POLICIES : governs
    INVOICE_ISSUANCES ||--o{ ISSUANCE_ATTEMPTS : attempts
    INVOICE_ISSUANCES ||--o| BUYER_INVOICE_COMPLETIONS : completion
    ISSUANCE_ATTEMPTS ||--|| ELECTRONIC_INVOICES : succeeds_to
    ELECTRONIC_INVOICES ||--o{ INVOICE_DOCUMENTS : documents
    ELECTRONIC_INVOICES ||--o{ INVOICE_PROVIDER_OBSERVATIONS : observations
    ELECTRONIC_INVOICES ||--o{ INVOICE_DELIVERIES : deliveries
    INVOICE_DELIVERIES ||--o{ DELIVERY_ATTEMPTS : attempts
    INVOICE_RECONCILIATION_CASES }o--|| ISSUANCE_ATTEMPTS : reconciles

    PROVIDER_CONNECTIONS {
        uuid id PK
        uuid tenant_id FK
        enum provider_code "misa_meinvoice"
        enum status "disconnected|connected|check_required|reconnect_required"
        json capabilities_snapshot
        datetime last_verified_at
        datetime created_at
        uuid created_by
    }

    ISSUANCE_PROFILES {
        uuid id PK
        uuid tenant_id FK
        uuid provider_connection_id FK
        json default_template
        json default_signing
        enum compatibility_status
        datetime updated_at
    }

    INVOICE_AUTOMATION_POLICIES {
        uuid id PK
        uuid tenant_id FK
        boolean auto_issue_enabled
        boolean auto_send_enabled
        int policy_version
        datetime updated_at
    }

    BUYER_INVOICE_COMPLETIONS {
        uuid id PK
        uuid tenant_id FK
        uuid sales_order_id FK
        uuid sales_order_version
        enum status "open|locked"
        json completed_fields
        datetime locked_at
    }

    INVOICE_ISSUANCES {
        uuid id PK
        uuid tenant_id FK
        uuid sales_order_id FK
        enum issuance_type "original"
        enum display_state "not_issued|processing|issued|failed"
    }

    ISSUANCE_ATTEMPTS {
        uuid id PK
        uuid invoice_issuance_id FK
        enum status "preparing|submitted|waiting_result|reconciling|succeeded|failed"
        json attempt_snapshot
        json provider_result_snapshot
        string idempotency_key UK
    }

    ELECTRONIC_INVOICES {
        uuid id PK
        uuid tenant_id FK
        uuid sales_order_id FK
        uuid successful_attempt_id FK
        json invoice_snapshot
        string provider_invoice_reference
        enum document_status "pending|available|failed|check_required"
    }

    INVOICE_DOCUMENTS {
        uuid id PK
        uuid electronic_invoice_id FK
        enum document_type "pdf|xml"
        string provider_reference
        string checksum
        enum retrieval_status
    }

    INVOICE_PROVIDER_OBSERVATIONS {
        uuid id PK
        uuid electronic_invoice_id FK
        datetime observed_at
        string source
        json result_payload
    }

    INVOICE_DELIVERIES {
        uuid id PK
        uuid electronic_invoice_id FK
        enum status "processing|succeeded|failed|unknown"
        json recipient_snapshot
        enum delivery_kind "initial|resend"
    }

    DELIVERY_ATTEMPTS {
        uuid id PK
        uuid invoice_delivery_id FK
        enum status "queued|submitted|succeeded|failed|unknown"
        json provider_result
    }

    INVOICE_RECONCILIATION_CASES {
        uuid id PK
        uuid tenant_id FK
        enum target_type "issuance_attempt|delivery_attempt"
        uuid target_id FK
        enum status "pending|resolved|unresolved"
    }
```





## State machines

Canonical §3.2.5. Display state (Issuance / Delivery trên Theme 05) là **projection** — không phải lifecycle độc lập.

### Provider connection


| From                 | To                   | Allowed | Ghi chú                                    |
| -------------------- | -------------------- | ------- | ------------------------------------------ |
| `DISCONNECTED`       | `CONNECTED`          | Yes     | Sau verify + legal match + capability sync |
| `CONNECTED`          | `CHECK_REQUIRED`     | Yes     | Legal profile thay đổi hoặc cảnh báo       |
| `CONNECTED`          | `RECONNECT_REQUIRED` | Yes     | Credential hết hiệu lực                    |
| `CHECK_REQUIRED`     | `CONNECTED`          | Yes     | Re-verify thành công                       |
| `RECONNECT_REQUIRED` | `CONNECTED`          | Yes     | Reconnect thành công                       |
| `CONNECTED`          | `DISCONNECTED`       | Yes     | Admin disconnect                           |
| `*`                  | `DISCONNECTED`       | No      | Không xóa history khi disconnect           |




### Configuration readiness (read model)


| Value                 | Meaning                                                          |
| --------------------- | ---------------------------------------------------------------- |
| `NOT_READY`           | ≥1 blocker (legal, connection, template, signing, compatibility) |
| `READY_WITH_WARNINGS` | Cho phép phát hành thủ công; auto-issue có thể bị chặn           |
| `READY`               | Đủ điều kiện phát hành và auto-issue (nếu policy bật)            |




### Issuance readiness (read model, per SalesOrder)


| Value                 | Meaning                                                                   |
| --------------------- | ------------------------------------------------------------------------- |
| `NOT_READY`           | Blocker: order status, buyer data, config, duplicate, in-progress attempt |
| `READY_WITH_WARNINGS` | Preview/issue thủ công được phép                                          |
| `READY`               | Đủ điều kiện tạo attempt                                                  |




### Issuance attempt

```text
PREPARING --prepare_issuance_publish--> SUBMITTED
  status SUBMITTED is the durable no-republish barrier; does not set submitted_at
SUBMITTED --mark_issuance_provider_call_started immediately before HTTP--> SUBMITTED
  sets submitted_at once
provider accepted/pending --> WAITING_RESULT
replay at SUBMITTED/WAITING_RESULT --> RECONCILING; never publish again
```

| From             | To               | Allowed | Ghi chú                                |
| ---------------- | ---------------- | ------- | -------------------------------------- |
| `PREPARING`      | `SUBMITTED`      | Yes     | Snapshot saved, provider call enqueued |
| `SUBMITTED`      | `WAITING_RESULT` | Yes     | Request accepted                       |
| `WAITING_RESULT` | `SUCCEEDED`      | Yes     | Definite success                       |
| `WAITING_RESULT` | `FAILED`         | Yes     | Definite failure                       |
| `WAITING_RESULT` | `RECONCILING`    | Yes     | Timeout / unknown                      |
| `RECONCILING`    | `SUCCEEDED`      | Yes     | Reconciliation resolved success        |
| `RECONCILING`    | `FAILED`         | Yes     | Reconciliation resolved failure        |
| `RECONCILING`    | `RECONCILING`    | Yes     | Still pending                          |
| `SUCCEEDED`      | `*`              | No      | Terminal                               |
| `FAILED`         | `PREPARING`      | No      | Retry = new attempt                    |




### Internal finalization


| From         | To           | Allowed | Ghi chú                                                  |
| ------------ | ------------ | ------- | -------------------------------------------------------- |
| `PENDING`    | `COMPLETED`  | Yes     | ElectronicInvoice registered locally                     |
| `PENDING`    | `UNRESOLVED` | Yes     | Provider success but local commit failed — recovery only |
| `COMPLETED`  | `*`          | No      | Terminal                                                 |
| `UNRESOLVED` | `COMPLETED`  | Yes     | Internal recovery — **không** gọi lại publish            |

`IssuanceAttempt.providerResultSnapshot` lưu **allow-listed typed success/failure evidence** đã chuẩn hóa. Nó là nguồn recovery khi provider đã xác nhận nhưng local `ElectronicInvoice` commit thất bại; không lưu raw provider payload và không được dùng để publish lại.




### Invoice document


| Value            | Meaning                         |
| ---------------- | ------------------------------- |
| `PENDING`        | Chưa fetch                      |
| `AVAILABLE`      | Metadata + retrieval path known |
| `FAILED`         | Definite fetch failure          |
| `CHECK_REQUIRED` | Unknown / retry needed          |

Official view và PDF/XML đều dùng async resource operation. Request persist operation + enqueue job; query trả trạng thái và chỉ trả URL/token/fileRef khi `AVAILABLE`. Identity active là `{electronicInvoiceId}:official_view` hoặc `{electronicInvoiceId}:{documentType}`; generation mới chỉ dùng khi refresh resource hết hạn/retry terminal.




### Delivery & delivery attempt

**InvoiceDelivery:** `PROCESSING` → `SUCCEEDED` | `FAILED` | `UNKNOWN`. `UNKNOWN` → `SUCCEEDED` | `FAILED` chỉ khi có evidence authenticated/authoritative đến sau cho **cùng attempt**. `SUCCEEDED` không bao giờ đảo ngược; failure đến muộn không ghi đè success.

**DeliveryAttempt:** `QUEUED` → `SUBMITTED` → `SUCCEEDED` | `FAILED` | `UNKNOWN`. Attempt cạn kiệt trước dispatch được phép `QUEUED` → `FAILED`. `UNKNOWN` chỉ resolve bằng evidence authoritative đến sau cho cùng attempt.

**Invariant delivery (S5 frozen):**

- Tối đa **một** business delivery `INITIAL_SEND` / ElectronicInvoice. Auto và manual race hội tụ về cùng invariant; các lần gửi có chủ đích sau đó là `RESEND`.
- `DeliveryKind` là **server-derived** — client không chọn initial/resend.
- Delivery ở `PROCESSING` hoặc `UNKNOWN` **khóa** business delivery khác cho invoice đó. `UNKNOWN` nghĩa là kết quả chưa xác lập; reconciliation case của nó bắt đầu ở `PENDING` (không phải `UNRESOLVED`) và delivery không được coi là retryable failure.
- Một attempt kỹ thuật active (`QUEUED` hoặc `SUBMITTED`) / delivery. Rejection retryable, chắc chắn chưa gửi, hoàn tất attempt hiện tại là failed và có thể thêm đúng một attempt queued kế tiếp trong cùng business delivery — **tối đa 3 attempt**.
- Recipient email/name là snapshot bất biến trên delivery; retry attempt không bao giờ resolve lại hay ghi đè recipient.
- Result trùng lặp / đảo thứ tự là idempotent và không bao giờ đảo ngược success.
- Recipient fallback tự động: current Partner invoice email → `attemptSnapshot.buyer_lineage.buyerInvoiceSnapshot.email` (base snapshot Theme-05 bất biến). `attemptSnapshot.buyer` là `EffectiveBuyerInvoiceData`, **không** thay thế được base snapshot. Không có `buyerPartnerId` ổn định → chỉ còn fallback base snapshot; cấm history tenant-wide / cross-customer.
- Delivery state không mutate issuance status, registration fact, số hóa đơn, mã tra cứu hay official document state.

### Reconciliation case


| From         | To           | Allowed | Ghi chú                                                                                     |
| ------------ | ------------ | ------- | ------------------------------------------------------------------------------------------- |
| `PENDING`    | `RESOLVED`   | Yes     | Poll/callback xác lập kết quả terminal (success hoặc definite failure)                      |
| `PENDING`    | `UNRESOLVED` | Yes     | Hết 5 lần poll ([30s, 2m, 10m, 30m, 2h]) mà kết quả vẫn không xác định; giữ business lock  |
| `UNRESOLVED` | `RESOLVED`   | Yes     | **Contract amendment**: Callback terminal hợp lệ từ provider đến muộn; tuyệt đối không republish |
| `RESOLVED`   | `*`          | No      | Terminal                                                                                    |

**Quy tắc đối soát & Invariant:**
- Lịch poll cố định gồm 5 lần kiểm tra với khoảng lùi: `[30s, 2m, 10m, 30m, 2h]`. Worker claim case theo claim-token và kiểm tra qua `IMeInvoiceClient.getStatus`.
- Bảng `invoice_reconciliation_cases` là nguồn authoritative của lịch đối soát; scheduled internal commands dùng due-time qua `internal_commands.enqueued_at` và có thể tái tạo tự động (idempotent seed/sweeper).
- Invariant race condition: Callback và poll có thể diễn ra đồng thời, nhưng chỉ một transition terminal đầu tiên thắng; bên đến sau nhận lại kết quả đã ghi (idempotent/no-op) và không đảo ngược kết quả.
- Trạng thái `UNRESOLVED` kết thúc chu kỳ poll tự động nhưng không loại bỏ evidence; nếu callback terminal hợp lệ đến muộn, case chuyển `UNRESOLVED -> RESOLVED` và hoàn tất kết quả mà không gọi lại provider.

**Amendment — delivery reconciliation là capability-aware (S5):**

- Delivery case dùng lại chính bảng `invoice_reconciliation_cases` với `target_type = 'DELIVERY_ATTEMPT'`, `target_id = delivery_attempts.id`, `reconciliation_purpose = 'VERIFY_DELIVERY'`. **Không** tạo bảng case riêng cho delivery.
- Lifecycle delivery case đúng bằng `PENDING -> RESOLVED | UNRESOLVED`, cộng amendment evidence-đến-muộn `UNRESOLVED -> RESOLVED`.
- Nếu `provider_connections.capabilities_snapshot.supports_delivery_result_observation = true`: mỗi check sequence thực hiện đúng một typed observation. Evidence terminal resolve delivery/attempt/case; evidence undetermined lên lịch sequence kế theo `[30s, 2m, 10m, 30m, 2h]`, lần thứ 5 undetermined chuyển `UNRESOLVED` + emit attention.
- Nếu `supports_delivery_result_observation = false`: **không** outbound HTTP. Check đầu tiên ghi safe code `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, chuyển case sang `UNRESOLVED`, clear `next_check_at`, emit attention.
- **MISA hiện tại luôn `supports_delivery_result_observation = false`.** Không bao giờ suy ra kết quả gửi email từ trạng thái phát hành invoice: `getStatus` không phải delivery-status API và không được gọi từ delivery reconciliation; `/invoice/status` hay API invoice/document khác cũng không phải evidence gửi email.
- Sau `UNKNOWN` tuyệt đối không enqueue thêm một lần gửi email nào nữa.




### Display projections (Theme 05)

**Issuance display:** Chưa phát hành | Đang xử lý | Đã phát hành | Phát hành lỗi.

**Delivery display:** Chưa gửi | Đang gửi | Đã gửi | Gửi lỗi (+ phụ khi resend sau đã gửi thành công).

## Aggregates


| Aggregate / process      | Folder                               | Application folder                                        | Ghi chú                                      |
| ------------------------ | ------------------------------------ | --------------------------------------------------------- | -------------------------------------------- |
| `ProviderConnection`     | `domain/lib/src/provider_connection/` | `application/lib/src/configuration/commands/`, `queries/` | AR — một connection hoạt động / tenant (MVP) |
| `IssuanceProfile`        | `domain/lib/src/issuance_profile/`    | `application/lib/src/configuration/`                      | AR — template + signing default              |
| `AutomationPolicy`       | `domain/lib/src/automation_policy/`   | `application/lib/src/configuration/`                      | AR — auto-issue / auto-send                  |
| `BuyerInvoiceCompletion` | `domain/lib/src/issuance/`           | `application/lib/src/issuance/`                           | Process — OPEN → LOCKED                      |
| `InvoiceIssuance`        | `domain/lib/src/issuance/`           | `application/lib/src/issuance/`                           | AR — một ORIGINAL / SalesOrder               |
| `IssuanceAttempt`        | `domain/lib/src/issuance/`           | `application/lib/src/issuance/`                           | Process — attempt + AttemptSnapshot          |
| `ElectronicInvoice`      | `domain/lib/src/electronic_invoice/` | `application/lib/src/electronic_invoice/`                 | AR — authoritative invoice                   |
| `InvoiceDocument`        | `domain/lib/src/electronic_invoice/` | `application/lib/src/electronic_invoice/`                 | Child — PDF/XML metadata                     |
| `InvoiceDelivery`        | `domain/lib/src/delivery/`           | `application/lib/src/delivery/`                           | AR — send/resend intent                      |
| `DeliveryAttempt`        | `domain/lib/src/delivery/`           | `application/lib/src/delivery/`                           | Process                                      |
| `ReconciliationCase`     | `domain/lib/src/reconciliation/`     | internal handlers                                         | Process — cross-cutting                      |
| `OrderInvoiceProjection` | — (read model)                       | `application/lib/src/issuance/queries/`                   | Projection cho Theme 05                      |


**Không phải aggregate:** `ConfigurationReadiness`, `IssuanceReadiness`, `ProviderObservationRecord` (append-only history), shared technical records (§4.3.5).

## Database tables


| Table                           | Ghi chú                                      |
| ------------------------------- | -------------------------------------------- |
| `provider_connections`          | Connection + embedded capabilities snapshot  |
| `issuance_profiles`             | Default template/signing per tenant          |
| `invoice_automation_policies`   | Auto-issue / auto-send flags + version       |
| `buyer_invoice_completions`     | Controlled completion per SalesOrder/version |
| `invoice_issuances`             | Issuance root per SalesOrder ORIGINAL        |
| `issuance_attempts`             | 32 canonical fields (5 convention + 27 business) + immutable AttemptSnapshot |
| `electronic_invoices`           | Authoritative invoice + InvoiceSnapshot      |
| `invoice_documents`             | PDF/XML retrieval metadata                   |
| `invoice_provider_observations` | Append-only provider status history          |
| `invoice_preview_operations`    | S2 technical preview operation (not interaction audit) |
| `invoice_deliveries`            | Business delivery intent                     |
| `delivery_attempts`             | Technical send attempts                      |
| `invoice_reconciliation_cases`  | Result reconciliation process state          |


Shared technical (không authoritative business state): `provider_interaction_records`, `invoice_preview_operations`, `idempotency_records`, `inbox_messages`, `outbox_messages`, `automatic_trigger_process_records`, `audit_logs`, `order_invoice_projections`.

### ProviderInteractionRecord (frozen S4 repair)

Cardinality: one row per outbound provider-call attempt or inbound callback. Immutable after start: tenant, provider connection, direction, operation type, target, correlation (`uuid`), request reference, started time. Finalize once: response reference, provider reference, outcome, safe error code, completed time, status and optimistic version. `request_reference` = Vet45 command/message ID; `response_reference` = provider HTTP trace when safely available; `provider_reference` = provider business identity (never credential/token). Không lưu request/response body, headers, viewer payload, credential hoặc token. S2 preview state lives in `invoice_preview_operations`, not this table.

**S4 implementation:** handlers wrap outbound MISA calls via `IProviderInteractionGateway`; worker-only path verified in `s4_worker_handlers_test` + `einvoice_slice4_integration_test`. Observation append references interaction via `provider_interaction_reference`; attention outbox `einvoice.provider_observation_attention_required` on NOT_FOUND/MISMATCH.

### ProviderCapabilitiesSnapshot.document types

`supported_document_types = ['PDF','XML']` wire values; missing field deserializes to empty set (fail closed before document operation creation).

### Canonical fields: `issuance_attempts` (32 fields)

1. **Convention (5):** `id`, `tenant_id`, `created_at`, `updated_at`, `version` (bigint).
2. **Business (27):** `invoice_issuance_id`, `attempt_no`, `trigger_type`, `status`, `provider_connection_id`, `issuance_profile_id`, `idempotency_key`, `intent_hash`, `snapshot_schema_version`, `attempt_snapshot`, `canonical_model_version`, `canonical_payload_hash`, `provider_interaction_reference`, `provider_request_reference`, `provider_invoice_reference`, `provider_result_code`, `provider_result_message`, `provider_result_snapshot`, `failure_code`, `failure_message`, `internal_finalization_state`, `started_at`, `submitted_at`, `provider_confirmed_at`, `completed_at`, `initiated_by_actor_type`, `initiated_by_actor_id`.

*Không thêm field barrier hoặc failure-origin vào entity.* `status = SUBMITTED` đóng vai trò dispatch barrier; `submitted_at` được ghi một lần duy nhất ngay trước HTTP call qua RPC `mark_issuance_provider_call_started`.

### Embedded `AttemptSnapshot` (11 components)

1. `source_order` (SalesOrder reference, version, status)
2. `seller` (Seller snapshot từ Theme 01)
3. `buyer` (Buyer snapshot từ EffectiveBuyerInvoiceData)
4. `buyer_lineage` (BuyerInvoiceSnapshot source, buyer_partner_id, BuyerInvoiceCompletion reference khi có)
5. `invoice_context` (Loại hóa đơn, mẫu, ký hiệu, tax authority code mode, signing method)
6. `lines` (Dòng hàng và source line references)
7. `totals` (Tiền hàng, chiết khấu, thuế, làm tròn, thanh toán)
8. `payment_information` (Thông tin thanh toán, optional)
9. `automation_policy` (Policy version & flags áp dụng)
10. `readiness_result` (Readiness level, warnings, blockers)
11. `mapping_schema_version` (Phiên bản canonical mapping)

### Shared technical: `AutomaticTriggerProcessRecord`

Record kỹ thuật chia sẻ trước attempt, lưu trữ: `id`, `version`, `tenant_id`, `process_type`, `sales_order_id`, `sales_order_version`, `trigger_key`, `process_status`, `retry_count`, `next_retry_at`, `blocker_code`, `buyer_invoice_completion_id` (khi có), `claim_lock`, `idempotency_key` (stable provider idempotency key), `created_at`, `updated_at`.
- Chỉ `sales.order.completed` được insert record này.
- Tín hiệu cập nhật từ Partner (`partner.partner.profile_updated`) hoặc readiness chỉ claim/update record ở trạng thái `PENDING_REEVALUATION` hiện có, tuyệt đối không tạo record hoặc business identity mới.

## Value objects & enums


| Symbol                           | Values / mô tả                                                                  |
| -------------------------------- | ------------------------------------------------------------------------------- |
| `ProviderCode`                   | `misaMeinvoice` (Phase 1)                                                       |
| `ProviderConnectionStatus`       | `disconnected`, `connected`, `checkRequired`, `reconnectRequired`               |
| `ConfigurationReadinessLevel`    | `notReady`, `readyWithWarnings`, `ready`                                        |
| `IssuanceReadinessLevel`         | `notReady`, `readyWithWarnings`, `ready`                                        |
| `BuyerCompletionStatus`          | `open`, `locked`                                                                |
| `IssuanceType`                   | `original` (MVP)                                                                |
| `IssuanceAttemptStatus`          | `preparing`, `submitted`, `waitingResult`, `reconciling`, `succeeded`, `failed` |
| `InternalFinalizationStatus`     | `pending`, `completed`, `unresolved`                                            |
| `InvoiceDocumentStatus`          | `pending`, `available`, `failed`, `checkRequired`                               |
| `InvoiceDocumentType`            | `pdf`, `xml`                                                                    |
| `DeliveryStatus`                 | `processing`, `succeeded`, `failed`, `unknown`                                  |
| `DeliveryAttemptStatus`          | `queued`, `submitted`, `succeeded`, `failed`, `unknown`                         |
| `DeliveryKind`                   | `initial`, `resend` — **server-derived**, không nhận từ client                  |
| `DeliveryTriggerType`            | `automatic`, `manual`                                                           |
| `DeliveryActorType`              | `system`, `user`                                                                |
| `DeliveryRecipientSource`        | `currentPartnerProfile`, `buyerInvoiceSnapshot`, `lastSuccessfulPartnerDelivery`, `lastInvoiceDelivery`, `userInput` |
| `DeliveryResultKind`             | `success`, `definiteFailure`, `retryableFailure`, `undetermined` (application)  |
| `ReconciliationCaseStatus`       | `pending`, `resolved`, `unresolved`                                             |
| `IssuanceDisplayState`           | projection — 4 giá trị hiển thị                                                 |
| `DeliveryDisplayState`           | projection — 4+ giá trị hiển thị                                                |
| `ProviderCapabilitiesSnapshot`   | Embedded, replaceable on sync                                                   |
| `AttemptSnapshot`                | Embedded, immutable after attempt start                                         |
| `InvoiceSnapshot`                | Embedded, immutable after registration                                          |
| `DeliveryRecipientSnapshot`      | Embedded, immutable per delivery                                                |
| `CanonicalInvoiceModel`          | Runtime — provider-neutral payload                                              |
| `EffectiveBuyerInvoiceData`      | Runtime — BuyerInvoiceSnapshot ⊕ completion                                     |
| `ProviderIssuanceResult`         | Embedded result on attempt                                                      |
| `ProviderDeliveryResult`         | Embedded result on delivery/attempt                                             |
| `ProviderTemplateRef`            | Template id, serial, symbol, invoice form                                       |
| `SigningConfigurationRef`        | HSM / MTT mapping                                                               |
| `EffectiveIssuanceConfiguration` | Compatible template + signing combo                                             |




## Commands (CMD catalog → CQRS)


| Command                                  | CMD    | Epic/US        | Ghi chú                                     |
| ---------------------------------------- | ------ | -------------- | ------------------------------------------- |
| `ConnectProviderCommand`                 | CMD-01 | EP-01/US-01    | Thiết lập / cập nhật credential             |
| `VerifyProviderConnectionCommand`        | CMD-02 | EP-01/US-01    | Kiểm tra lại connection                     |
| `ReconnectProviderCommand`               | CMD-03 | EP-01/US-01    | Kết nối lại khi credential invalid          |
| `DisconnectProviderCommand`              | CMD-04 | EP-01/US-01    | Ngắt connection                             |
| `SyncProviderCapabilitiesCommand`        | CMD-05 | EP-01/US-01    | Đồng bộ capability sau connect/verify       |
| `SetDefaultIssuanceConfigurationCommand` | CMD-06 | EP-01/US-02    | Chọn template + signing default             |
| `UpdateAutomationPolicyCommand`          | CMD-07 | EP-01/US-03    | Bật/tắt auto-issue / auto-send              |
| `RequestInvoicePreviewCommand`           | CMD-08 | EP-02/US-01    | Preview — không tạo attempt                 |
| `CompleteBuyerInvoiceDataCommand`        | CMD-09 | EP-02/US-01,02 | Controlled completion → LOCKED              |
| `IssueInvoiceCommand`                    | CMD-10 | EP-02/US-02    | Phát hành thủ công                          |
| `StartAutoIssuanceCommand`               | CMD-11 | EP-02/US-03    | Internal — trigger từ sales.order.completed |
| `ReevaluateAutoIssuanceCommand`          | CMD-11b| EP-02/US-03    | Internal — re-evaluate process PENDING_REEVALUATION từ partner update |
| `RecordIssuanceResultCommand`            | CMD-12 | EP-02/US-04    | Internal/worker — finalize attempt với typed evidence |
| `RetryIssuanceCommand`                   | CMD-13 | EP-02/US-05    | Attempt mới sau definite failure            |
| `OpenReconciliationCaseCommand`          | CMD-14 | EP-02/US-04,05 | Internal — unknown result                   |
| `ResolveReconciliationCaseCommand`       | CMD-15 | EP-02/US-04,05 | Internal — apply reconciled outcome         |
| `RecoverInternalFinalizationCommand`     | CMD-16 | EP-02/US-04    | Internal — provider success, local pending  |
| `RequestOfficialInvoiceViewCommand`      | CMD-17 | EP-03/US-01    | Resolve viewer URL/token                    |
| `RequestInvoiceDocumentCommand`          | CMD-18 | EP-03/US-02    | Fetch PDF hoặc XML                          |
| `RecordProviderObservationCommand`       | CMD-19 | EP-03/US-03    | Internal/worker — append observation        |
| `SendElectronicInvoiceCommand`           | CMD-20 | EP-04/US-02    | Manual send hoặc resend                     |
| `StartAutoDeliveryCommand`               | CMD-21 | EP-04/US-01    | Internal — trigger sau registered           |
| `RecordDeliveryResultCommand`            | CMD-22 | EP-04/US-03    | Internal/worker — finalize delivery         |




## Queries


| Query                               | CMD  | Epic/US        | Ghi chú                                     |
| ----------------------------------- | ---- | -------------- | ------------------------------------------- |
| `GetProviderConnectionScreenQuery`  | Q-01 | EP-01/US-01    | Legal profile read-only + connection status |
| `GetProviderConnectionStatusQuery`  | Q-02 | EP-01/US-01    | **Deprecated** — merged into Q-01 screen query (07 §S1a); không implement symbol riêng |
| `ListProviderTemplatesQuery`        | Q-03 | EP-01/US-02    | Templates từ provider                       |
| `GetIssuanceProfileQuery`           | Q-04 | EP-01/US-02    | Current default config                      |
| `GetAutomationPolicyQuery`          | Q-05 | EP-01/US-03    | Auto flags + policy version                 |
| `GetConfigurationReadinessQuery`    | Q-06 | EP-01/US-04    | Readiness + blockers/warnings               |
| `GetIssuanceReadinessQuery`         | Q-07 | EP-02/US-01    | Per-order readiness                         |
| `GetInvoicePreviewQuery`            | Q-08 | EP-02/US-01    | Preview payload / viewer ref                |
| `GetOrderInvoiceProjectionQuery`    | Q-09 | EP-02/US-02,05 | Status + actions cho Theme 05               |
| `GetIssuanceAttemptStatusQuery`     | Q-10 | EP-02/US-04,05 | Attempt detail + error                      |
| `GetElectronicInvoiceDetailQuery`   | Q-11 | EP-03/US-01    | Invoice profile for view                    |
| `GetInvoiceDocumentsQuery`          | Q-12 | EP-03/US-02    | Document list + retrieval state             |
| `GetLatestProviderObservationQuery` | Q-13 | EP-03/US-03    | Latest observation                          |
| `GetInvoiceDeliveryHistoryQuery`    | Q-14 | EP-04/US-02,03 | Deliveries + display state                  |
| `GetSendInvoiceSheetContextQuery`   | Q-15 | EP-04/US-02    | Suggested email + sheet mode                |




## Domain events


| Event                           | Khi                                       |
| ------------------------------- | ----------------------------------------- |
| `ProviderConnected`             | Connection → CONNECTED                    |
| `ProviderDisconnected`          | Admin disconnect                          |
| `IssuanceConfigurationUpdated`  | Profile default saved                     |
| `AutomationPolicyUpdated`       | Policy version bumped                     |
| `BuyerInvoiceCompletionLocked`  | First-time buyer data ready               |
| `IssuanceAttemptStarted`        | AttemptSnapshot persisted                 |
| `IssuanceAttemptSucceeded`      | Provider + local pre-finalization         |
| `IssuanceAttemptFailed`         | Definite failure                          |
| `IssuanceResultUndetermined`    | Timeout / unknown → reconciling           |
| `ElectronicInvoiceRegistered`   | Local authoritative commit complete       |
| `InternalFinalizationRecovered` | UNRESOLVED → COMPLETED without re-publish |
| `InvoiceDocumentAvailable`      | PDF/XML metadata stored                   |
| `ProviderObservationRecorded`   | New observation appended                  |
| `InvoiceDeliveryStarted`        | Delivery + recipient snapshot             |
| `InvoiceDeliverySucceeded`      | Definite send success                     |
| `InvoiceDeliveryFailed`         | Definite send failure                     |
| `InvoiceDeliveryUndetermined`   | Unknown send result                       |




## Integration events — publish


| Type                                       | Khi                                                                 |
| ------------------------------------------ | ------------------------------------------------------------------- |
| `einvoice.electronic_invoice.registered`   | ElectronicInvoiceRegistered — Theme 05 projection + EP-04 auto-send |
| `einvoice.issuance.failed`                 | Definite issuance failure — Theme 05 projection                     |
| `einvoice.issuance.processing`             | Attempt in progress — Theme 05 projection                           |
| `einvoice.delivery.result_recorded`        | Delivery terminal or updated — payload safe: `salesOrderId`, `deliveryId`, `deliveryStatus`, `deliveryDisplayState`, `deliveryVersion`, `hasSecondaryAttention` |
| `einvoice.delivery.attention_required`     | Chỉ khi delivery reconciliation đạt `UNRESOLVED` — payload: tenant/invoice/SalesOrder/delivery/attempt/case id + safe error code |
| `einvoice.configuration.readiness_changed` | Config readiness level changed (optional)                           |




## Integration events — consume


| Source | Event | Payload | Mục đích |
| ------ | ----- | ------- | -------- |
| sales  | `sales.order.completed`     | tenantId, salesOrderId, sourceVersion, occurredAt | Auto-issue trigger (EP-02/US-03) → `StartAutoIssuanceCommand` |
| partner| `partner.partner.profile_updated` | tenantId, partnerId, occurredAt | Tìm process `PENDING_REEVALUATION` đúng buyer và dispatch `ReevaluateAutoIssuanceCommand`; không tạo process mới |
| provider (inbox) | `einvoice.provider.issuance_result_received` | tenantId, attemptId, correlationId, typedEvidence | Finalize attempt (EP-02/US-04) → `RecordIssuanceResultCommand` |
| einvoice (inbox) | `einvoice.electronic_invoice.registered` | tenantId, electronicInvoiceId, salesOrderId, occurredAt | Auto initial delivery (EP-04/US-01) → `StartAutoDeliveryCommand`; business key UUIDv5 `<tenantId>\|<electronicInvoiceId>\|auto_initial`, event id chỉ là `triggerId` traceability |
| iam    | `iam.legal_profile.updated` | tenantId, occurredAt | Mark connection CHECK_REQUIRED (không mutate snapshots) |

**Quy định Stable Identity:**
- Sales completion tạo process với `triggerKey = sales.order.completed:<eventId>:<salesOrderId>:<sourceVersion>`; provider `RefID` dùng UUIDv5 namespace `514eaf96-eed8-5f7b-9705-4a840c910684` trên chuỗi `<tenantId>|<salesOrderId>|<sourceVersion>`.
- Partner event chỉ dùng `sourceEventId = <eventId>` để dedupe inbox/re-evaluation; nó phải load `processId`, original `triggerKey` và provider idempotency key từ `AutomaticTriggerProcessRecord`, tuyệt đối không suy diễn business identity mới từ Partner event.




## Data rules


| Rule ID | Rule                                                                                                           |
| ------- | -------------------------------------------------------------------------------------------------------------- |
| DR-01   | Một SalesOrder ≤ một `InvoiceIssuance` ORIGINAL và ≤ một `ElectronicInvoice` gốc (MVP)                         |
| DR-02   | Preview / configuration readiness **không** tạo IssuanceAttempt / ElectronicInvoice / InvoiceDelivery          |
| DR-03   | Phase 1: tối đa một `ProviderConnection` hoạt động / tenant                                                    |
| DR-04   | Connection → CONNECTED chỉ sau verify + legal match + mandatory capability sync                                |
| DR-05   | Credential/secret không round-trip về client sau lưu                                                           |
| DR-06   | Disconnect không xóa invoice, snapshot, document, delivery history                                             |
| DR-07   | `BuyerInvoiceSnapshot` precedence > Theme 03 — không overwrite field đã có                                     |
| DR-08   | Theme 03 resolve chỉ khi completion OPEN và field bắt buộc thiếu                                               |
| DR-09   | `BuyerInvoiceCompletion` → LOCKED khi `EffectiveBuyerInvoiceData` lần đầu đủ — terminal cho SalesOrder/version |
| DR-10   | Sau LOCKED, không auto-resolve Theme 03                                                                        |
| DR-11   | Khách tổ chức thiếu MST → blocker issuance (`BUYER_TAX_CODE_REQUIRED`)                                         |
| DR-12   | Chỉ SalesOrder Hoàn tất được phát hành                                                                         |
| DR-13   | AttemptSnapshot bất biến sau attempt start; technical retry giữ snapshot                                       |
| DR-14   | InvoiceSnapshot bất biến sau ElectronicInvoice registration                                                    |
| DR-15   | Seller snapshot từ legal profile tại attempt start — không cập nhật ngược                                      |
| DR-16   | Idempotency: cùng business identity → trả operation hiện có                                                    |
| DR-17   | Timeout ≠ definite failure; unknown → RECONCILING, khóa operation cạnh tranh                                   |
| DR-18   | Provider success + local finalization pending → recovery nội bộ, **không** re-publish                          |
| DR-19   | Không giữ DB transaction mở trong provider call                                                                |
| DR-20   | MISA HTTP chỉ từ messaging_worker — không từ Flutter                                                           |
| DR-21   | Token cache keyed by `tenantId` — cấm singleton client mọi tenant                                              |
| DR-22   | Official view / PDF / XML từ provider — không tự dựng tài liệu pháp lý                                         |
| DR-23   | Delivery display state tính từ authoritative delivery history                                                  |
| DR-24   | Resend tạo `InvoiceDelivery` mới với kind `resend` **server-derived** — giữ history cũ                         |
| DR-25   | `OrderInvoiceProjection` là read model — không thuộc aggregate issuance                                        |
| DR-26   | ≤ một business delivery `INITIAL_SEND` / ElectronicInvoice; auto và manual race hội tụ cùng invariant          |
| DR-27   | Delivery `PROCESSING` hoặc `UNKNOWN` khóa business delivery khác; `UNKNOWN` không phải retryable failure       |
| DR-28   | Success trước đó giữ display chính `sent`; failure/unknown sau đó lộ qua secondary attention                   |
| DR-29   | `attemptSnapshot.buyer_lineage.buyerInvoiceSnapshot` giữ nguyên base snapshot Theme 05 (source-owned `p_buyer_snapshot`), tách khỏi `attemptSnapshot.buyer` effective; giữ `buyerPartnerId`, completion id, source version |
| DR-30   | Recipient snapshot bất biến / delivery — technical retry không resolve lại recipient; tối đa 3 attempt         |
| DR-31   | Không suy ra kết quả gửi email từ trạng thái phát hành invoice của provider (`getStatus` ≠ delivery status)    |




## Blocked response codes (presentation boundary)

Base: `NO_PERMISSION`, `NOT_FOUND`, `VALIDATION_ERROR`, `INVALID_STATUS`, `STATE_CHANGED`, `SYSTEM_ERROR`.

TH-08 extensions: `PROVIDER_NOT_CONNECTED`, `PROVIDER_AUTH_FAILED`, `PROVIDER_UNAVAILABLE`, `CONFIG_NOT_READY`, `ISSUANCE_NOT_READY`, `BUYER_DATA_INCOMPLETE`, `BUYER_TAX_CODE_REQUIRED`, `ORDER_NOT_COMPLETED`, `ALREADY_ISSUED`, `OPERATION_IN_PROGRESS`, `RESULT_UNDETERMINED`, `DOCUMENT_UNAVAILABLE`, `DELIVERY_NOT_SUPPORTED`.

Chi tiết mapping: [07-api-contracts.md](07-api-contracts.md).

## Anti-patterns

- ERP client HTTP trực tiếp tới `*.meinvoice.vn`.
- Cross-module import domain/repository (chỉ `integration_events` / published contracts).
- Theme 05 mutate `ElectronicInvoice` / `InvoiceSnapshot` / `BuyerInvoiceSnapshot`.
- Theme 08 overwrite hồ sơ pháp lý / partner authoritative data.
- Singleton `MeInvoiceClient` / token cache không keyed by tenant.
- Preview tạo IssuanceAttempt hoặc ElectronicInvoice.
- Re-publish sau provider success khi local finalization fail.
- God aggregate gộp configuration + issuance + delivery.
- Danh sách HĐĐT độc lập trong MVP.
- Either/Result bên trong command handlers.



## Implement

Code domain: [domain-layer skill](../../../../.cursor/skills/domain-layer/SKILL.md) → `modules/einvoice/domain/lib/src/`.
Commands/handlers: [application-layer](../../../../.cursor/skills/application-layer/SKILL.md).
SQL draft: `supabase/migrations/_drafts/einvoice_*.sql` (BE lane).
Worker: `apps/messaging_worker` + `packages/vet45_misa` — xem [03-architecture-and-flows.md](03-architecture-and-flows.md).
