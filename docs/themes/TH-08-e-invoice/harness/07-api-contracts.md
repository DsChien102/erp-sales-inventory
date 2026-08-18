# TH-08 — API contracts

Source of truth FE↔BE khi implement. Domain symbols: [01-domain-model.md](01-domain-model.md). Worker/runtime: [03-architecture-and-flows.md](03-architecture-and-flows.md).

**ERP không HTTP tới MISA** — mọi vendor call qua `messaging_worker` + `IMeInvoiceClient`.

## Error envelope

| Code | Meaning | UI guidance |
| ---- | ------- | ----------- |
| `NO_PERMISSION` | Thiếu quyền trong tenant/data scope | Toast + ẩn action |
| `NOT_FOUND` | Entity hoặc SalesOrder không tồn tại / ngoài scope | Empty / back |
| `VALIDATION_ERROR` | Input không hợp lệ | Inline field errors |
| `INVALID_STATUS` | Trạng thái entity không cho phép operation | Disable action + message |
| `STATE_CHANGED` | Optimistic version / order version stale | Refresh + retry |
| `SYSTEM_ERROR` | Lỗi không phân loại | Generic error toast |
| `PROVIDER_NOT_CONNECTED` | Connection DISCONNECTED hoặc chưa setup | Link SG-01 |
| `PROVIDER_AUTH_FAILED` | Credential bị từ chối | Reconnect flow |
| `PROVIDER_UNAVAILABLE` | Vendor timeout / 5xx tạm thời | Retry later message |
| `CONFIG_NOT_READY` | Configuration readiness NOT_READY | Blocker list SG-01 |
| `ISSUANCE_NOT_READY` | Order readiness NOT_READY | Blocker list trên order |
| `BUYER_DATA_INCOMPLETE` | Buyer field bắt buộc thiếu | Completion prompt |
| `BUYER_TAX_CODE_REQUIRED` | Org buyer thiếu MST | Blocker trên order |
| `ORDER_NOT_COMPLETED` | SalesOrder chưa Hoàn tất | Hide issue actions |
| `ALREADY_ISSUED` | Đã có ElectronicInvoice gốc | Hide issue, show view |
| `OPERATION_IN_PROGRESS` | Attempt/delivery đang chạy / reconciling | Show processing state |
| `RESULT_UNDETERMINED` | Unknown provider result | Processing + wait message |
| `DOCUMENT_UNAVAILABLE` | Provider không trả PDF/XML | Retry download |
| `DELIVERY_NOT_SUPPORTED` | Provider capability thiếu send email | Hide send actions |

## CMD catalog overview

| CMD | Symbol | Epic/US |
| --- | ------ | ------- |
| CMD-01..05 | Provider connection commands | EP-01/US-01 |
| CMD-06 | `SetDefaultIssuanceConfigurationCommand` | EP-01/US-02 |
| CMD-07 | `UpdateAutomationPolicyCommand` | EP-01/US-03 |
| Q-06 | `GetConfigurationReadinessQuery` | EP-01/US-04 |
| CMD-08..09, Q-07..08 | Preview + completion | EP-02/US-01 |
| CMD-10 | `IssueInvoiceCommand` | EP-02/US-02 |
| CMD-11 | `StartAutoIssuanceCommand` | EP-02/US-03 |
| CMD-12..16 | Result + reconciliation + recovery | EP-02/US-04 |
| CMD-13 | `RetryIssuanceCommand` | EP-02/US-05 |
| CMD-17..19, Q-11..13 | View + documents + observation | EP-03 |
| CMD-20..22, Q-14..15 | Delivery | EP-04 |

---

## §S1a — EP-01/US-01 — Kết nối và duy trì kết nối nhà cung cấp

Spec: [Epic-01-provider-connection-config/US-01.md](../Epic-01-provider-connection-config/US-01.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetProviderConnectionScreenQuery` | tenantId, actorId | `ProviderConnectionScreenDto` (legal profile read-only, connection status, last check) | NO_PERMISSION, SYSTEM_ERROR |
| `ConnectProviderCommand` | tenantId, actorId, appId, username, password, expectedConnectionVersion? | `ProviderConnectionResultDto` (connectionId, status=`checkRequired`) — **async**: RPC encrypt credential + enqueue `einvoice.sync_capabilities`; auth errors surface via poll | NO_PERMISSION, VALIDATION_ERROR, STATE_CHANGED |
| `VerifyProviderConnectionCommand` | tenantId, actorId, connectionId | `ProviderConnectionCheckResultDto` | NO_PERMISSION, NOT_FOUND, PROVIDER_UNAVAILABLE, PROVIDER_AUTH_FAILED |
| `ReconnectProviderCommand` | tenantId, actorId, connectionId, appId, username, password | `ProviderConnectionResultDto` | NO_PERMISSION, NOT_FOUND, VALIDATION_ERROR, PROVIDER_AUTH_FAILED, STATE_CHANGED |
| `DisconnectProviderCommand` | tenantId, actorId, connectionId, confirm | `ProviderConnectionResultDto` (status=DISCONNECTED) | NO_PERMISSION, NOT_FOUND, INVALID_STATUS |
| `SyncProviderCapabilitiesCommand` | tenantId, connectionId (internal serializable — worker) | `void` | PROVIDER_UNAVAILABLE (soft-fail; no status change) |
| `RecordConnectionVerifiedCommand` | tenantId, connectionId, status, capabilities?, verifiedAt?, correlationId? (internal/worker) | `void` | NOT_FOUND, INVALID_STATUS, SYSTEM_ERROR |

FR-01..08 map: screen query (FR-01,02); connect (FR-03,04,05); verify (FR-06); reconnect (FR-07); disconnect (FR-08). Legal mismatch → `VALIDATION_ERROR` với subcode legal_mismatch (không CONNECTED).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Screen | `einvoice.get_provider_connection_screen` | drafted |
| Connect | `einvoice.connect_provider` | drafted |
| Verify | `einvoice.verify_provider_connection` | drafted |
| Reconnect | `einvoice.reconnect_provider` | drafted |
| Disconnect | `einvoice.disconnect_provider` | drafted |
| Sync capabilities | `einvoice.enqueue_internal_command` (`command_type = einvoice.sync_capabilities`) — RPC do `platform.install_module_messaging('einvoice')` cài | drafted |
| Record verified | `einvoice.record_connection_verified` | drafted |
| Read credentials (worker) | `einvoice.read_provider_credentials` (service role) | drafted |
| Claim/complete/fail queues | `einvoice.claim_*` / `complete_*` / `fail_*` — installer, không draft riêng | drafted |

### Worker mapping

| Step | Job / client |
| ---- | ------------- |
| Auth + legal match on connect/reconnect/verify | Worker: login via `MeInvoiceAuth` → `IMeInvoiceClient` (tenant-scoped factory) |
| Capability sync (FR-05) | Worker: `listInvoiceTemplates` + capability probe |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `connection_screen_ok` | GetProviderConnectionScreenQuery | connected + legal profile |
| `connection_screen_disconnected` | GetProviderConnectionScreenQuery | DISCONNECTED + connect CTA |
| `connect_ok` | ConnectProviderCommand valid creds | CONNECTED |
| `connect_auth_failed` | ConnectProviderCommand bad password | PROVIDER_AUTH_FAILED |
| `connect_legal_mismatch` | ConnectProviderCommand MST mismatch | VALIDATION_ERROR |
| `verify_provider_unavailable` | VerifyProviderConnectionCommand | PROVIDER_UNAVAILABLE |
| `disconnect_ok` | DisconnectProviderCommand | DISCONNECTED |
| `connect_permission_denied` | no manageConfiguration | NO_PERMISSION |

---

## §S1b — EP-01/US-02 — Thiết lập cấu hình phát hành mặc định

Spec: [Epic-01-provider-connection-config/US-02.md](../Epic-01-provider-connection-config/US-02.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `ListProviderTemplatesQuery` | tenantId, actorId, invoiceWithCode?, year? | `List<ProviderTemplateDto>` | NO_PERMISSION, PROVIDER_NOT_CONNECTED, PROVIDER_UNAVAILABLE |
| `GetIssuanceProfileQuery` | tenantId, actorId | `IssuanceProfileDto` (current default + compatibility warnings) | NO_PERMISSION, NOT_FOUND |
| `SetDefaultIssuanceConfigurationCommand` | tenantId, actorId, templateId, signingConfigId, expectedProfileVersion? | `IssuanceProfileDto` | NO_PERMISSION, VALIDATION_ERROR, INVALID_STATUS, PROVIDER_NOT_CONNECTED, STATE_CHANGED |

FR-01..02: list + display templates/signing. FR-03..05: set default + compatibility check. FR-06..08: stale template warnings surfaced in DTO.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| List templates | `einvoice.list_provider_templates` | drafted |
| Get profile | `einvoice.get_issuance_profile` | drafted |
| Set default | `einvoice.set_default_issuance_configuration` | drafted |

### Worker mapping

| Step | Client method |
| ---- | ------------- |
| List templates (FR-01) | `IMeInvoiceClient.listInvoiceTemplates` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `list_templates_ok` | ListProviderTemplatesQuery | 2 templates |
| `set_default_hsm_ok` | SetDefaultIssuanceConfigurationCommand HSM | IssuanceProfileDto updated |
| `set_default_incompatible` | incompatible template+signing | VALIDATION_ERROR |
| `set_default_not_connected` | no connection | PROVIDER_NOT_CONNECTED |
| `list_templates_permission_denied` | no manageConfiguration | NO_PERMISSION |

---

## §S1c — EP-01/US-03 — Thiết lập chính sách phát hành và gửi tự động

Spec: [Epic-01-provider-connection-config/US-03.md](../Epic-01-provider-connection-config/US-03.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetAutomationPolicyQuery` | tenantId, actorId | `AutomationPolicyDto` (autoIssue, autoSend, policyVersion, blockers) | NO_PERMISSION |
| `UpdateAutomationPolicyCommand` | tenantId, actorId, autoIssueEnabled?, autoSendEnabled?, expectedPolicyVersion | `AutomationPolicyDto` | NO_PERMISSION, VALIDATION_ERROR, CONFIG_NOT_READY, STATE_CHANGED |

FR-01..04: read/update flags. FR-05..07: readiness gate when enabling auto-issue; policy version bump on save.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Get policy | `einvoice.get_automation_policy` | drafted |
| Update policy | `einvoice.update_automation_policy` | drafted |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `automation_policy_ok` | GetAutomationPolicyQuery | both disabled |
| `enable_auto_issue_ok` | UpdateAutomationPolicyCommand autoIssue=true | policy v+1 |
| `enable_auto_issue_not_ready` | config NOT_READY | CONFIG_NOT_READY |
| `enable_auto_send_ok` | autoSend=true | policy v+1 |
| `automation_state_changed` | stale version | STATE_CHANGED |

---

## §S1d — EP-01/US-04 — Kiểm tra mức sẵn sàng của cấu hình phát hành

Spec: [Epic-01-provider-connection-config/US-04.md](../Epic-01-provider-connection-config/US-04.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetConfigurationReadinessQuery` | tenantId, actorId, purpose? (`manual_issue` \| `auto_issue` \| `auto_send`) | `ConfigurationReadinessDto` (level, blockers[], warnings[]) | NO_PERMISSION |

FR-01..09: aggregate checks legal, connection, template, signing, compatibility, auto-issue capability — returned in single DTO.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Readiness | `einvoice.get_configuration_readiness` | drafted |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `config_readiness_ready` | all checks pass | READY |
| `config_readiness_warnings` | template deprecated warning | READY_WITH_WARNINGS |
| `config_readiness_blocked` | missing signing | NOT_READY + blockers |
| `config_readiness_auto_issue_blocked` | purpose=auto_issue, warnings only | NOT_READY for auto |

---

## §S2a — EP-02/US-01 — Kiểm tra điều kiện và xem trước hóa đơn

Spec: [Epic-02-issue-from-sales-order/US-01.md](../Epic-02-issue-from-sales-order/US-01.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetIssuanceReadinessQuery` | tenantId, actorId, salesOrderId | `IssuanceReadinessDto` (level, blockers, warnings, buyerCompletionState) | NO_PERMISSION, NOT_FOUND, ORDER_NOT_COMPLETED |
| `CompleteBuyerInvoiceDataCommand` | tenantId, actorId, salesOrderId, expectedOrderVersion | `BuyerCompletionResultDto` (locked?, effectiveBuyer preview) | NO_PERMISSION, NOT_FOUND, BUYER_DATA_INCOMPLETE, BUYER_TAX_CODE_REQUIRED, STATE_CHANGED |
| `RequestInvoicePreviewCommand` | tenantId, actorId, salesOrderId, expectedOrderVersion | `InvoicePreviewResultDto` (viewerRef \| previewPayload, warnings[]) | NO_PERMISSION, NOT_FOUND, ISSUANCE_NOT_READY, ORDER_NOT_COMPLETED, CONFIG_NOT_READY, PROVIDER_NOT_CONNECTED, PROVIDER_UNAVAILABLE |
| `GetInvoicePreviewQuery` | tenantId, actorId, salesOrderId | `InvoicePreviewResultDto` (cached if fresh) | same as preview command |

Preview **không** tạo IssuanceAttempt / ElectronicInvoice (DR-02).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Readiness | `einvoice.get_issuance_readiness` | drafted |
| Complete buyer | `einvoice.complete_buyer_invoice_data` | drafted |
| Preview | `einvoice.request_invoice_preview` | drafted |

### Worker mapping

| Step | Client method |
| ---- | ------------- |
| Build preview (FR-07..09) | `IMeInvoiceClient.previewUnpublished` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `readiness_ready` | order complete + buyer ok | READY |
| `readiness_buyer_incomplete` | missing buyer email | NOT_READY + BUYER_DATA_INCOMPLETE |
| `preview_ok` | RequestInvoicePreviewCommand | preview URL |
| `preview_config_not_ready` | CONFIG_NOT_READY | blocker |
| `preview_provider_unavailable` | worker timeout | PROVIDER_UNAVAILABLE |
| `complete_buyer_locks` | CompleteBuyerInvoiceDataCommand | locked=true |
| `preview_permission_denied` | no issue permission | NO_PERMISSION |

---

## §S2b — EP-02/US-02 — Phát hành hóa đơn thủ công

Spec: [Epic-02-issue-from-sales-order/US-02.md](../Epic-02-issue-from-sales-order/US-02.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `IssueInvoiceCommand` | tenantId, actorId, salesOrderId, expectedOrderVersion, idempotencyKey, acknowledgeWarnings? | `IssueInvoiceResultDto` (issuanceId, attemptId, status=PROCESSING) | NO_PERMISSION, NOT_FOUND, ORDER_NOT_COMPLETED, CONFIG_NOT_READY, ISSUANCE_NOT_READY, BUYER_DATA_INCOMPLETE, ALREADY_ISSUED, OPERATION_IN_PROGRESS, STATE_CHANGED |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (displayState, actions[]) | NO_PERMISSION, NOT_FOUND |

FR-01..08: issue command orchestrates issuance + attempt + snapshot + enqueue publish. Idempotent replay returns existing attempt (EC-03).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Issue | `einvoice.issue_invoice` | drafted |
| Projection | `einvoice.get_order_invoice_projection` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Publish after snapshot commit | `einvoice.publish_invoice` | `IMeInvoiceClient.publish` |

Idempotency key: `{tenantId}:{salesOrderId}:original:{attemptSequence}`.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `issue_ok` | IssueInvoiceCommand | PROCESSING + attemptId |
| `issue_already_issued` | has ElectronicInvoice | ALREADY_ISSUED |
| `issue_in_progress` | reconciling attempt | OPERATION_IN_PROGRESS |
| `issue_not_ready` | ISSUANCE_NOT_READY | blockers |
| `issue_idempotent_replay` | same idempotencyKey | existing attempt |
| `issue_state_changed` | stale order version | STATE_CHANGED |
| `projection_processing` | GetOrderInvoiceProjectionQuery | display=Đang xử lý |
| `projection_issued` | poll sau khi worker finalize | display=Đã phát hành, action=view |
| `projection_failed` | poll sau definite failure | display=Phát hành lỗi, action=issue |

### Status polling contract (FE)

Quyết định kiến trúc: [03-architecture-and-flows.md §11](03-architecture-and-flows.md).

| Khía cạnh | Giá trị |
| --------- | ------- |
| Query | `GetOrderInvoiceProjectionQuery` |
| Query key | `['einvoice', 'orderInvoice', salesOrderId]` |
| Trigger bắt đầu | `IssueInvoiceCommand` trả `status=PROCESSING` (không chờ poll để hiện `Đang xử lý`) |
| Interval khi `Đang xử lý` | 3–5s (`refetchInterval`) |
| Điều kiện dừng | `displayState` ∈ {`Đã phát hành`, `Phát hành lỗi`} → `refetchInterval = null` |
| Sau resume app | `AppLifecycleRefetch` — không cần logic riêng |

`refetchInterval` chưa có trong `vet45_async_query` — bổ sung vào `QueryOptions`/`QueryObserver` trong S2 FE lane.

---

## §S3a — EP-02/US-03 — Phát hành hóa đơn tự động

Spec: [Epic-02-issue-from-sales-order/US-03.md](../Epic-02-issue-from-sales-order/US-03.md)

**Server-only** — không có UI riêng (UF-04 contextual trên Theme 05).

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `StartAutoIssuanceCommand` | tenantId, salesOrderId, triggerId (from `sales.order.completed`), idempotencyKey | `AutoIssuanceResultDto` (started \| skipped, reason?) | ISSUANCE_NOT_READY, CONFIG_NOT_READY, ALREADY_ISSUED, OPERATION_IN_PROGRESS |

Internal handler — không expose trực tiếp qua Flutter. Duplicate trigger → skip (FR-02).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Auto issue (internal) | `einvoice.start_auto_issuance` | drafted |

### Worker mapping

Same as manual issue — `einvoice.publish_invoice` job.

### Fake scenarios (BE/integration)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `auto_issue_started` | policy on + ready | started=true |
| `auto_issue_skipped_policy_off` | autoIssue=false | skipped reason=policy |
| `auto_issue_skipped_not_ready` | buyer incomplete | skipped reason=readiness |
| `auto_issue_duplicate_trigger` | same triggerId | idempotent skip |

---

## §S3b — EP-02/US-04 — Xác lập kết quả và hoàn tất ghi nhận hóa đơn

Spec: [Epic-02-issue-from-sales-order/US-04.md](../Epic-02-issue-from-sales-order/US-04.md)

**Server/worker-only** — SG-04 no UI MVP.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RecordIssuanceResultCommand` | tenantId, attemptId, providerResult, correlationId | `RecordIssuanceResultDto` (attemptStatus, electronicInvoiceId?) | NOT_FOUND, INVALID_STATUS, SYSTEM_ERROR |
| `OpenReconciliationCaseCommand` | tenantId, attemptId, reason | `ReconciliationCaseDto` | NOT_FOUND, OPERATION_IN_PROGRESS |
| `ResolveReconciliationCaseCommand` | tenantId, caseId, outcome | `ReconciliationCaseDto` | NOT_FOUND, INVALID_STATUS |
| `RecoverInternalFinalizationCommand` | tenantId, attemptId | `ElectronicInvoiceDto` | NOT_FOUND, INVALID_STATUS, SYSTEM_ERROR |
| `GetIssuanceAttemptStatusQuery` | tenantId, actorId, salesOrderId | `IssuanceAttemptStatusDto` | NO_PERMISSION, NOT_FOUND |

FR-01..08: normalize success / definite failure / undetermined. Success path registers ElectronicInvoice + InvoiceSnapshot. Undetermined → RECONCILING + lock.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Record result | `einvoice.record_issuance_result` | drafted |
| Open reconciliation | `einvoice.open_reconciliation_case` | drafted |
| Resolve reconciliation | `einvoice.resolve_reconciliation_case` | drafted |
| Recover finalization | `einvoice.recover_internal_finalization` | drafted |
| Attempt status | `einvoice.get_issuance_attempt_status` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Poll status | `einvoice.poll_issuance_status` | `IMeInvoiceClient.getStatus` |
| Callback ingest | inbox → RecordIssuanceResultCommand | — |

### Fake scenarios (BE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `record_issuance_success` | provider success payload | SUCCEEDED + invoiceId |
| `record_issuance_definite_fail` | provider reject | FAILED |
| `record_issuance_undetermined` | timeout | RECONCILING |
| `recover_finalization_ok` | provider ok, local pending | ElectronicInvoice registered |
| `reconcile_resolved_success` | poll finds invoice | SUCCEEDED |

---

## §S3c — EP-02/US-05 — Phát hành lại sau thất bại xác định

Spec: [Epic-02-issue-from-sales-order/US-05.md](../Epic-02-issue-from-sales-order/US-05.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RetryIssuanceCommand` | tenantId, actorId, salesOrderId, expectedOrderVersion, idempotencyKey, acknowledgeWarnings? | `IssueInvoiceResultDto` (new attemptId) | NO_PERMISSION, NOT_FOUND, INVALID_STATUS, ISSUANCE_NOT_READY, OPERATION_IN_PROGRESS, STATE_CHANGED |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (displayState=Phát hành lỗi, action=issue) | NO_PERMISSION, NOT_FOUND |
| `GetIssuanceAttemptStatusQuery` | tenantId, actorId, salesOrderId | `IssuanceAttemptStatusDto` (last error message) | NO_PERMISSION, NOT_FOUND |

Chỉ khi attempt trước **definite FAILED** — không retry khi RECONCILING (FR-04). Prior attempts preserved (FR-05).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Retry | `einvoice.retry_issuance` | drafted |
| Projection | `einvoice.get_order_invoice_projection` | drafted |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `retry_after_fail_ok` | last attempt FAILED | new attempt PROCESSING |
| `retry_while_reconciling` | RECONCILING | OPERATION_IN_PROGRESS |
| `retry_projection_failed_state` | projection query | display=Phát hành lỗi + issue action |
| `retry_not_ready` | config lost | ISSUANCE_NOT_READY |

---

## §S4a — EP-03/US-01 — Xem hồ sơ và nội dung hóa đơn đã phát hành

Spec: [Epic-03-issued-invoice-documents/US-01.md](../Epic-03-issued-invoice-documents/US-01.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetElectronicInvoiceDetailQuery` | tenantId, actorId, salesOrderId | `ElectronicInvoiceDetailDto` (identity, snapshot summary, providerRef) | NO_PERMISSION, NOT_FOUND |
| `RequestOfficialInvoiceViewCommand` | tenantId, actorId, salesOrderId | `OfficialInvoiceViewDto` (viewerUrl \| token, expiresAt) | NO_PERMISSION, NOT_FOUND, PROVIDER_UNAVAILABLE, DOCUMENT_UNAVAILABLE |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (displayState=Đã phát hành, action=view) | NO_PERMISSION, NOT_FOUND |

Entry từ Theme 05 row action — không standalone list (SG-05 no UI).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Detail | `einvoice.get_electronic_invoice_detail` | drafted |
| Official view | `einvoice.request_official_invoice_view` | drafted |

### Worker mapping

| Step | Client method |
| ---- | ------------- |
| Resolve viewer (FR-04..06) | `IMeInvoiceClient.previewPublished` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `official_view_ok` | RequestOfficialInvoiceViewCommand | viewerUrl |
| `official_view_not_issued` | no invoice | NOT_FOUND |
| `official_view_provider_down` | PROVIDER_UNAVAILABLE | error state |
| `official_view_permission_denied` | no view permission | NO_PERMISSION |

---

## §S4b — EP-03/US-02 — Xem và tải tài liệu hóa đơn

Spec: [Epic-03-issued-invoice-documents/US-02.md](../Epic-03-issued-invoice-documents/US-02.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetInvoiceDocumentsQuery` | tenantId, actorId, salesOrderId | `InvoiceDocumentsDto` (pdf?, xml?, retrievalStatus) | NO_PERMISSION, NOT_FOUND |
| `RequestInvoiceDocumentCommand` | tenantId, actorId, salesOrderId, documentType (`pdf` \| `xml`), idempotencyKey | `InvoiceDocumentRetrievalDto` (downloadUrl \| fileRef, checksum) | NO_PERMISSION, NOT_FOUND, DOCUMENT_UNAVAILABLE, PROVIDER_UNAVAILABLE, OPERATION_IN_PROGRESS |

FR-03..08: separate operations per document type; metadata + checksum stored on success.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| List documents | `einvoice.get_invoice_documents` | drafted |
| Request document | `einvoice.request_invoice_document` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Download | `einvoice.download_invoice_document` | `IMeInvoiceClient.download` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `download_pdf_ok` | RequestInvoiceDocumentCommand pdf | downloadUrl |
| `download_xml_ok` | documentType=xml | downloadUrl |
| `download_unavailable` | provider empty | DOCUMENT_UNAVAILABLE |
| `download_permission_denied` | no downloadDocument | NO_PERMISSION |
| `documents_list_partial` | GetInvoiceDocumentsQuery | pdf available, xml pending |

---

## §S4c — EP-03/US-03 — Theo dõi trạng thái gần nhất tại nhà cung cấp

Spec: [Epic-03-issued-invoice-documents/US-03.md](../Epic-03-issued-invoice-documents/US-03.md)

**Server/worker-only** — observation không có màn riêng MVP.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RecordProviderObservationCommand` | tenantId, electronicInvoiceId, observationPayload, source | `ProviderObservationDto` | NOT_FOUND, PROVIDER_UNAVAILABLE, SYSTEM_ERROR |
| `GetLatestProviderObservationQuery` | tenantId, actorId, salesOrderId | `ProviderObservationDto?` | NO_PERMISSION, NOT_FOUND |

Append-only history (FR-02). Distinct from authoritative issuance state (FR-04).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Record (internal) | `einvoice.record_provider_observation` | drafted |
| Latest | `einvoice.get_latest_provider_observation` | drafted |

### Worker mapping

| Step | Client method |
| ---- | ------------- |
| Poll provider status | `IMeInvoiceClient.getStatus` |

### Fake scenarios (BE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `observation_recorded` | poll success | new observation row |
| `observation_latest_query` | GetLatestProviderObservationQuery | latest payload |
| `observation_provider_unavailable` | timeout | PROVIDER_UNAVAILABLE |

---

## §S5a — EP-04/US-01 — Tự động gửi hóa đơn sau khi phát hành

Spec: [Epic-04-send-resend-einvoice/US-01.md](../Epic-04-send-resend-einvoice/US-01.md)

**Server-only** — trigger từ `einvoice.electronic_invoice.registered`.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `StartAutoDeliveryCommand` | tenantId, electronicInvoiceId, triggerId, idempotencyKey | `AutoDeliveryResultDto` (started \| skipped, reason?) | DELIVERY_NOT_SUPPORTED, VALIDATION_ERROR, OPERATION_IN_PROGRESS |

Skip reasons: policy off, invalid email, capability missing (FR-02..05).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Auto delivery (internal) | `einvoice.start_auto_delivery` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Send email | `einvoice.send_invoice_email` | `IMeInvoiceClient.sendEmail` |

### Fake scenarios (BE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `auto_send_started` | policy on + valid email | started=true |
| `auto_send_skipped_no_email` | missing email | skipped |
| `auto_send_skipped_policy_off` | autoSend=false | skipped |
| `auto_send_not_supported` | no capability | DELIVERY_NOT_SUPPORTED |

---

## §S5b — EP-04/US-02 — Gửi và gửi lại hóa đơn thủ công

Spec: [Epic-04-send-resend-einvoice/US-02.md](../Epic-04-send-resend-einvoice/US-02.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetSendInvoiceSheetContextQuery` | tenantId, actorId, salesOrderId | `SendInvoiceSheetContextDto` (mode=send\|resend, suggestedEmail, history[]) | NO_PERMISSION, NOT_FOUND |
| `SendElectronicInvoiceCommand` | tenantId, actorId, salesOrderId, recipientEmail, idempotencyKey, deliveryKind? | `SendInvoiceResultDto` (deliveryId, status=PROCESSING) | NO_PERMISSION, NOT_FOUND, VALIDATION_ERROR, DELIVERY_NOT_SUPPORTED, OPERATION_IN_PROGRESS, ALREADY_ISSUED (inverse: must be issued) |
| `GetInvoiceDeliveryHistoryQuery` | tenantId, actorId, salesOrderId | `InvoiceDeliveryHistoryDto` | NO_PERMISSION, NOT_FOUND |

Resend: `deliveryKind=resend` when prior delivery exists (FR-02). Email validation (FR-06).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Sheet context | `einvoice.get_send_invoice_sheet_context` | drafted |
| Send / resend | `einvoice.send_electronic_invoice` | drafted |
| History | `einvoice.get_invoice_delivery_history` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Send | `einvoice.send_invoice_email` | `IMeInvoiceClient.sendEmail` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `send_sheet_initial` | no prior delivery | mode=send, suggestedEmail from buyer |
| `send_sheet_resend` | prior delivery | mode=resend, suggestedEmail from last |
| `send_ok` | SendElectronicInvoiceCommand | PROCESSING |
| `send_invalid_email` | bad email format | VALIDATION_ERROR |
| `send_permission_denied` | no send permission | NO_PERMISSION |
| `send_in_progress` | delivery reconciling | OPERATION_IN_PROGRESS |

---

## §S5c — EP-04/US-03 — Theo dõi và xác lập kết quả gửi hóa đơn

Spec: [Epic-04-send-resend-einvoice/US-03.md](../Epic-04-send-resend-einvoice/US-03.md)

**Server/worker-primary** — UI chỉ hiển thị display state từ projection.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RecordDeliveryResultCommand` | tenantId, deliveryId, attemptId, providerResult | `RecordDeliveryResultDto` (deliveryStatus, displayState) | NOT_FOUND, INVALID_STATUS, SYSTEM_ERROR |
| `GetInvoiceDeliveryHistoryQuery` | tenantId, actorId, salesOrderId | `InvoiceDeliveryHistoryDto` (deliveries[], displayState) | NO_PERMISSION, NOT_FOUND |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (delivery display) | NO_PERMISSION, NOT_FOUND |

FR-04: `DeliveryDisplayState` derived from authoritative history. Undetermined → auto reconciliation (FR-06).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Record result | `einvoice.record_delivery_result` | drafted |
| History | `einvoice.get_invoice_delivery_history` | drafted |
| Projection | `einvoice.get_order_invoice_projection` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Send result / poll | `einvoice.send_invoice_email` completion | `IMeInvoiceClient.sendEmail` response |

### Fake scenarios (BE/FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `delivery_success` | RecordDeliveryResultCommand ok | display=Đã gửi |
| `delivery_failed` | provider reject | display=Gửi lỗi |
| `delivery_undetermined` | timeout | display=Đang gửi + UNKNOWN |
| `delivery_history_multi` | resend after success | 2 deliveries, latest wins display |

---

## Parallel notes (global)

- FE có thể fake sau khi Contract lane chốt symbol — dùng `FakeEInvoiceModule` scenarios ở trên.
- E2E blocked by: [04-slice-roadmap.md](04-slice-roadmap.md).
- E2E vendor: `FakeMeInvoiceClient` — không gọi MISA thật.
- BE lane viết draft SQL: `supabase/migrations/_drafts/einvoice_*.sql` — không timestamp migration cho đến khi user promote. Messaging tables/RPC đi qua `einvoice_s1_install_module_messaging.sql` (`install_module_messaging('einvoice')`), không DDL queue tự viết.
