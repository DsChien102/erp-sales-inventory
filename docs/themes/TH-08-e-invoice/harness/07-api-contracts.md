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
| `ISSUANCE_NOT_READY` | Order readiness NOT_READY; nested `details.blockers[]` có thể chứa `SOURCE_SNAPSHOT_UNAVAILABLE`, `BUYER_SOURCE_UNAVAILABLE` (không phải top-level codes) | Blocker list trên order |
| `BUYER_DATA_INCOMPLETE` | Buyer field bắt buộc thiếu (sub-detail `BUYER_TAX_CODE_REQUIRED` khi org thiếu MST; `BUYER_ADDRESS_REQUIRED` khi org có MST thiếu địa chỉ) | Completion prompt |
| `BUYER_TAX_CODE_REQUIRED` | Org buyer thiếu MST — **sub-detail** của `BUYER_DATA_INCOMPLETE` trên `IssueInvoiceCommand`; vẫn top-level trên `CompleteBuyerInvoiceDataCommand` | Blocker trên order |
| `BUYER_ADDRESS_REQUIRED` | Org buyer có MST thiếu địa chỉ — sub-detail readiness/completion (hardening H1) | Completion prompt |
| `TEMPLATE_NOT_AVAILABLE` | Template đã chọn mất / đổi loại / không còn trong capability | Blocker SG-01 / order |
| `SIGNING_CONFIGURATION_NOT_AVAILABLE` | Signing config thiếu hoặc không tương thích template (MTT≠5, non-MTT≠2) | Blocker SG-01 / order |
| `UNSUPPORTED_TAX_DATA` | Nguồn Sales vi phạm contract `KCT-only` (line/total tax ≠ 0 hoặc tax snapshot không rỗng) | Fail closed trước preview/issue |
| `IDEMPOTENCY_CONFLICT` | Cùng `idempotencyKey` nhưng `intent_hash` khác | Refresh + new key |
| `ORDER_NOT_COMPLETED` | SalesOrder chưa Hoàn tất | Hide issue actions |
| `ALREADY_ISSUED` | Đã có ElectronicInvoice gốc | Hide issue, show view |
| `OPERATION_IN_PROGRESS` | Attempt/delivery đang chạy / reconciling | Show processing state |
| `RESULT_UNDETERMINED` | Unknown provider result | Processing + wait message |
| `DOCUMENT_UNAVAILABLE` | Capability preflight: loại tài liệu không trong `supported_document_types` — fail closed trước khi tạo operation/command | Không enqueue worker |
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
| `ConnectProviderCommand` | tenantId, actorId, username, password, expectedConnectionVersion? | `ProviderConnectionResultDto` (connectionId, status=`checkRequired`) — **async**: RPC encrypt credential + enqueue `einvoice.sync_capabilities`; auth errors surface via status reload | NO_PERMISSION, VALIDATION_ERROR, STATE_CHANGED |
| `VerifyProviderConnectionCommand` | tenantId, actorId, connectionId | `ProviderConnectionCheckResultDto` with current status; RPC only re-enqueues worker verification | NO_PERMISSION, NOT_FOUND |
| `ReconnectProviderCommand` | tenantId, actorId, connectionId, username, password, expectedConnectionVersion? | `ProviderConnectionResultDto` (status=`checkRequired`); worker later records terminal connection status | NO_PERMISSION, NOT_FOUND, VALIDATION_ERROR, INVALID_STATUS, STATE_CHANGED |
| `DisconnectProviderCommand` | tenantId, actorId, connectionId, confirm | `ProviderConnectionResultDto` (status=DISCONNECTED) | NO_PERMISSION, NOT_FOUND, INVALID_STATUS |
| `SyncProviderCapabilitiesCommand` | tenantId, connectionId, expectedConnectionVersion (internal serializable — worker) | `void` | PROVIDER_UNAVAILABLE (retry queue; no status change) |
| `RecordConnectionVerifiedCommand` | tenantId, connectionId, expectedConnectionVersion, status, capabilities?, verifiedAt?, correlationId? (internal/worker) | `void`; stale version/status is an idempotent no-op | NOT_FOUND, INVALID_STATUS, SYSTEM_ERROR |

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
| `connect_ok` | ConnectProviderCommand valid creds | CHECK_REQUIRED; worker later records CONNECTED or RECONNECT_REQUIRED |
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
| `IssueInvoiceCommand` | tenantId, actorId, salesOrderId, sourceVersion (opaque String), idempotencyKey, acknowledgeWarnings? | `IssueInvoiceResultDto` (issuanceId, attemptId, status: `IssuanceAttemptStatus` — `preparing` on a fresh start, or the existing attempt status on replay) | NO_PERMISSION, NOT_FOUND, ORDER_NOT_COMPLETED, CONFIG_NOT_READY, ISSUANCE_NOT_READY, BUYER_DATA_INCOMPLETE, ALREADY_ISSUED, OPERATION_IN_PROGRESS, STATE_CHANGED, IDEMPOTENCY_CONFLICT |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (displayState, actions[]) | NO_PERMISSION, NOT_FOUND |

> `status` on the command result is the `IssuanceAttemptStatus` enum (see `issue_invoice_result.dart`), **not** the string `PROCESSING`. `PROCESSING` is projection vocabulary only (`get_order_invoice_projection`); do not return it as a command-result status.
>
> This error list is the single canonical set (align design §9 to it). `BUYER_TAX_CODE_REQUIRED` is a **sub-detail** of `BUYER_DATA_INCOMPLETE`, not a separate top-level code. `CONFIG_NOT_READY` is included. `SOURCE_SNAPSHOT_UNAVAILABLE`/`BUYER_SOURCE_UNAVAILABLE` are nested `ISSUANCE_NOT_READY.details.blockers[]`, never top-level.

Nested blocker envelope (blocker values are **not** top-level exception codes):

```json
{"code":"ISSUANCE_NOT_READY","details":{"blockers":["SOURCE_SNAPSHOT_UNAVAILABLE","BUYER_SOURCE_UNAVAILABLE"]}}
```

FR-01..08: issue command orchestrates issuance + attempt + snapshot + enqueue publish. Idempotent replay returns existing attempt (EC-03). Sibling commands (`CompleteBuyerInvoiceDataCommand`, `RequestInvoicePreviewCommand`, `RetryIssuanceCommand`) retain `int expectedOrderVersion`; only `IssueInvoiceCommand` uses opaque `sourceVersion`.

### RPC mapping (BE) — drafted

| Use case | RPC | Result |
| --- | --- | --- |
| Start/replay | `einvoice.issue_invoice` | fresh attempt (`preparing`) or replayed attempt status |
| Cross dispatch barrier | `einvoice.prepare_issuance_publish` | `callProvider` \| `reconcileOnly` \| `skip` |
| Success | `einvoice.record_issuance_success` | SUCCEEDED + COMPLETED/UNRESOLVED |
| Definite rejection | `einvoice.record_issuance_failure` | FAILED |
| Unknown | `einvoice.record_issuance_undetermined` | RECONCILING + pending case (`next_check_at` = durable handoff; no internal command) |
| Command integrity (dead-letter) | `einvoice.record_issuance_command_integrity_failure` | FAILED (`failure_code=COMMAND_INTEGRITY`) |
| Projection | `einvoice.get_order_invoice_projection` | display projection |

> `issuance_attempts.idempotency_key` maps to MISA `RefID` as the provider correlation/duplicate-lookup key. Same key + same `intent_hash` replays; same key + different intent returns `IDEMPOTENCY_CONFLICT`. A `WAITING_RESULT` replay never calls publish again.

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Publish after snapshot commit | `einvoice.publish_invoice` (internal command) | `IMeInvoiceProviderPort.publish` |
| Pre-barrier validation | — | `IMeInvoiceProviderPort.validateCanonical` |
| Barrier dispatch | `einvoice.prepare_issuance_publish` RPC | — |
| Immediate result landing | typed result RPCs above | — |

`idempotencyKey` on the command is a canonical UUID transported unchanged as MISA `RefID`.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `issue_ok` | IssueInvoiceCommand | `preparing` + attemptId |
| `issue_idempotency_conflict` | same idempotencyKey, different intent | IDEMPOTENCY_CONFLICT |
| `issue_source_unavailable` | authoritative snapshot missing | ISSUANCE_NOT_READY + nested blockers |
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
| Trigger bắt đầu | `IssueInvoiceCommand` trả non-terminal `IssuanceAttemptStatus` (e.g. `preparing`) → UI hiện `Đang xử lý` ngay qua projection mapping, không chờ vòng poll đầu |
| Interval khi `Đang xử lý` | 3–5s (`refetchInterval`) |
| Điều kiện dừng | `displayState` ∈ {`Đã phát hành`, `Phát hành lỗi`} → `refetchInterval = null` |
| Sau resume app | `AppLifecycleRefetch` — không cần logic riêng |

`refetchInterval` chưa có trong `vet45_async_query` — bổ sung vào `QueryOptions`/`QueryObserver` trong S2 FE lane.

---

## §S3a — EP-02/US-03 — Phát hành hóa đơn tự động

Spec: [Epic-02-issue-from-sales-order/US-03.md](../Epic-02-issue-from-sales-order/US-03.md)

**Server-only** — không có UI riêng (UF-04 contextual trên Theme 05).

### Event Triggers & Stable Identity

| Source Event | Payload | Handler / Hành động |
| ------------ | ------- | ------------------- |
| `sales_order_finalized.v1` | tenantId, salesOrderId, salesOrderVersion, occurredAt | `SalesOrderFinalizedIntegrationEventHandler` → `StartAutoIssuanceCommand` (tạo/load process record, kiểm tra readiness, tạo attempt nếu đủ điều kiện) |
| `partner.partner.profile_updated` | tenantId, partnerId, occurredAt | Tìm process `PENDING_REEVALUATION` đúng buyer và dispatch `ReevaluateAutoIssuanceCommand`; không tạo process mới |
| `einvoice.provider.issuance_result_received` | tenantId, attemptId, correlationId, typedEvidence | `RecordIssuanceResultCommand` (chuẩn hóa evidence trước khi dispatch) |

**Quy định Stable Identity:**
- Sales completion tạo process với `triggerKey = sales_order_finalized.v1:<eventId>:<salesOrderId>:<sourceVersion>`; provider `RefID` dùng UUIDv5 namespace `514eaf96-eed8-5f7b-9705-4a840c910684` trên chuỗi `<tenantId>|<salesOrderId>|<sourceVersion>`.
- Partner event chỉ dùng `sourceEventId = <eventId>` để dedupe inbox/re-evaluation; nó phải load `processId`, original `triggerKey` và provider idempotency key từ `AutomaticTriggerProcessRecord`, tuyệt đối không suy diễn business identity mới từ Partner event.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `StartAutoIssuanceCommand` | tenantId, salesOrderId, triggerKey, idempotencyKey | `AutoIssuanceResultDto` (processId, status, attemptId?, reason?) | ISSUANCE_NOT_READY, CONFIG_NOT_READY, ALREADY_ISSUED, OPERATION_IN_PROGRESS |
| `ReevaluateAutoIssuanceCommand` | tenantId, processId, sourceEventId | `AutoIssuanceResultDto` (processId, status, attemptId?, reason?) | NOT_FOUND, INVALID_STATUS, OPERATION_IN_PROGRESS |

Internal handler — không expose trực tiếp qua Flutter. Duplicate trigger → skip (FR-02).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Auto issue (internal) | `einvoice.start_auto_issuance` | drafted |
| Re-evaluate auto issue (internal) | `einvoice.reevaluate_auto_issuance` | drafted |

### Worker mapping

Same as manual issue — `einvoice.publish_invoice` job.

### Fake scenarios (BE/integration)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `auto_issue_started` | policy on + ready | started=true |
| `auto_issue_skipped_policy_off` | autoIssue=false | skipped reason=policy |
| `auto_issue_skipped_not_ready` | buyer incomplete | skipped reason=readiness |
| `auto_issue_duplicate_trigger` | same triggerId | idempotent skip |
| `auto_issue_reevaluation_ready` | partner updated + pending process | started=true |

---

## §S3b — EP-02/US-04 — Xác lập kết quả và hoàn tất ghi nhận hóa đơn

Spec: [Epic-02-issue-from-sales-order/US-04.md](../Epic-02-issue-from-sales-order/US-04.md)

**Server/worker-only** — SG-04 no UI MVP.

S2b owns the **immediate-result subset**: direct `publish` outcome normalization via typed result RPCs (`record_issuance_success`, `record_issuance_failure`, `record_issuance_undetermined`) and atomic pending-case handoff on unknown. S3b owns poll execution, callback ingestion, case resolution, and explicit recovery. The consolidated `einvoice.record_issuance_result` name is **not** used — typed RPCs make definite-failure vs undetermined impossible to confuse at the call site.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RecordIssuanceResultCommand` | tenantId, attemptId, `IssuanceResultEvidenceDto evidence`, correlationId | `RecordIssuanceResultDto` (attemptStatus, electronicInvoiceId?) | NOT_FOUND, INVALID_STATUS, IDEMPOTENCY_CONFLICT, SYSTEM_ERROR |
| `OpenReconciliationCaseCommand` | tenantId, attemptId, reason (S3b — S2b creates pending case atomically via `record_issuance_undetermined`) | `ReconciliationCaseDto` | NOT_FOUND, OPERATION_IN_PROGRESS |
| `ResolveReconciliationCaseCommand` | tenantId, caseId, outcome, allow-listed evidence? (required for SUCCESS/FAILURE) | `ReconciliationCaseDto` | NOT_FOUND, INVALID_STATUS, VALIDATION_ERROR |
| `RecoverInternalFinalizationCommand` | tenantId, attemptId | `ElectronicInvoiceDto` | NOT_FOUND, INVALID_STATUS, SYSTEM_ERROR |
| `GetIssuanceAttemptStatusQuery` | tenantId, actorId, salesOrderId | `IssuanceAttemptStatusDto` | NO_PERMISSION, NOT_FOUND |

**Access — `einvoice.get_issuance_attempt_status`:** User-session (`authenticated`) reads must match `auth.uid() = p_actor_id`, hold `einvoice.issue`, and pass `sales.can_access_sales_order`. Worker / service paths keep using `service_role` (no user JWT → access gates skipped). Returns only safe status/`failure_code` — `last_error_message` is always `null` (never `failure_message` / provider text). Presentation maps `failureCode` via allow-list copy only.

**Quy tắc Typed Evidence & Ranh giới:**
- Callbacks được chuẩn hóa thành `IssuanceResultEvidenceDto` (`IssuanceSuccessEvidenceDto`, `IssuanceDefiniteFailureEvidenceDto`, `IssuanceUndeterminedEvidenceDto`) trước khi dispatch.
- Raw provider payload không phải là input của command và không được lưu trữ trực tiếp vào evidence.

**Chính sách Đối soát (Reconciliation & Recovery):**
- **Lịch Poll cố định:** Các khoảng lùi `[30s, 2m, 10m, 30m, 2h]`. Worker claim case theo claim-token và thực hiện kiểm tra `IMeInvoiceClient.getStatus`. Sau lần kiểm tra thứ 5 không xác định, case chuyển sang `UNRESOLVED`, dừng poll tự động và tiếp tục giữ business lock.
- **Durable Handoff & Sweeper:** Bảng `invoice_reconciliation_cases` là nguồn authoritative của lịch đối soát; scheduled internal commands sử dụng due-time qua `internal_commands.enqueued_at` và được sweeper tự động seed idempotently.
- **Race Condition Invariant:** Callback và poll có thể race, nhưng chỉ một terminal transition thắng; bên đến sau nhận lại kết quả đã ghi trước đó (idempotent/no-op).
- **Late Callback Amendment:** Bổ sung state transition `ReconciliationCase UNRESOLVED -> RESOLVED` khi có callback terminal đã xác thực và correlate đúng danh tính từ provider đến muộn. Success muộn hoàn tất attempt/invoice/finalization mà không republish; definite failure muộn kết thúc attempt/case rồi projection mới mở lại action `issue`. Callback không xác định/không hợp lệ không đổi state `UNRESOLVED`.

FR-01..08: normalize success / definite failure / undetermined. Success path registers ElectronicInvoice + InvoiceSnapshot. Undetermined → RECONCILING + lock. S2b FR-01..07: immediate path only; S3b: poll consumer discovers pending cases via `next_check_at`, callbacks, resolution, finalization recovery.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Success (S2b immediate + S3b poll) | `einvoice.record_issuance_success` | drafted |
| Definite failure (S2b immediate + S3b poll) | `einvoice.record_issuance_failure` | drafted |
| Unknown / handoff (S2b immediate) | `einvoice.record_issuance_undetermined` | drafted |
| Command integrity dead-letter (S2b) | `einvoice.record_issuance_command_integrity_failure` | drafted |
| Dispatch barrier (S2b) | `einvoice.prepare_issuance_publish` | drafted |
| Mark provider call started (S2b/S3b) | `einvoice.mark_issuance_provider_call_started` | drafted |
| Retryable provider publish rejection (H1) | `einvoice.record_retryable_provider_publish_rejection` | drafted |
| Open reconciliation (S3b explicit) | `einvoice.open_reconciliation_case` | drafted |
| Resolve reconciliation | `einvoice.resolve_reconciliation_case` | drafted |
| Recover finalization | `einvoice.recover_internal_finalization` | drafted |
| Attempt status | `einvoice.get_issuance_attempt_status` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Poll status (S3b — **not enqueued by S2b**) | `einvoice.poll_issuance_status` | `IMeInvoiceClient.getStatus` |
| Callback ingest (S3b) | inbox → `RecordIssuanceResultCommand` | — |
| Immediate publish result (S2b) | `einvoice.publish_invoice` → typed result RPCs | `IMeInvoiceProviderPort.publish` |

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
| `RetryIssuanceCommand` | tenantId, actorId, salesOrderId, expectedOrderVersion, idempotencyKey, acknowledgeWarnings? | `IssueInvoiceResultDto` (new attemptId, status=PREPARING) | NO_PERMISSION, NOT_FOUND, INVALID_STATUS, ISSUANCE_NOT_READY, OPERATION_IN_PROGRESS, STATE_CHANGED |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (displayState=Phát hành lỗi, action=issue) | NO_PERMISSION, NOT_FOUND |
| `GetIssuanceAttemptStatusQuery` | tenantId, actorId, salesOrderId | `IssuanceAttemptStatusDto` (last error message) | NO_PERMISSION, NOT_FOUND |

**Quy tắc Projection & Retry:**
- Mọi latest attempt `FAILED` và không còn active operation trả `displayState = failed`, safe `failureCode`, và `actions = ['issue']`; command phát hành luôn recheck permission/readiness/no-invoice.
- `COMMAND_INTEGRITY` hoặc system failure chắc chắn trước provider call cũng tuân theo rule này sau khi technical retry cạn.
- Trạng thái `SUBMITTED`, `WAITING_RESULT`, `RECONCILING`, pending/`UNRESOLVED` reconciliation trả projection `displayState = processing` và `actions = []`. Không thêm `failureOrigin` hoặc provider-only retry gate.
- Phân nhánh SalesOrder version: Cùng version + completion `LOCKED` thì reuse đúng completion/`EffectiveBuyerInvoiceData` đã khóa và không gọi Theme 03; version mới thì từ chối `expectedOrderVersion` cũ và chỉ tạo attempt sau khi completion/readiness của version mới đạt điều kiện.

Chỉ khi attempt trước **definite FAILED** — không retry khi RECONCILING (FR-04). Prior attempts preserved (FR-05).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Retry | `einvoice.retry_issuance` | drafted |
| Projection | `einvoice.get_order_invoice_projection` | drafted |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `retry_after_fail_ok` | last attempt FAILED | new attempt PREPARING (displayState: Đang xử lý) |
| `retry_while_reconciling` | RECONCILING | OPERATION_IN_PROGRESS |
| `retry_projection_failed_state` | projection query | display=Phát hành lỗi + issue action |
| `retry_not_ready` | config lost | ISSUANCE_NOT_READY |

---

## §S4 async resource contract (frozen before BE)

- Command request chỉ ghi operation + enqueue `internal_commands` trong cùng DB transaction; handler/RPC không chờ hoặc gọi MISA.
- Kết quả request luôn có `operationId` và `status` (`PENDING`, `AVAILABLE`, `FAILED`, `CHECK_REQUIRED`). URL/token/fileRef/checksum chỉ có khi `AVAILABLE`.
- `CHECK_REQUIRED is an unresolved lock` on the same `operationId`/generation: replay re-arms that operation; only definite `FAILED` or expired AVAILABLE allows a new generation.
- Replay cùng invoice/resource identity trả operation hiện có; một invoice chỉ có một active official-view operation và một active document operation cho mỗi `documentType`.
- UI poll read model: official view qua `GetElectronicInvoiceDetailQuery`; PDF/XML qua `GetInvoiceDocumentsQuery`. Poll dừng ở `AVAILABLE` hoặc `FAILED`.
- URL tải/xem phải ngắn hạn; query recheck tenant + permission trước khi trả URL. Hết hạn thì request re-arm operation, không dùng URL cũ.
- Worker mới được gọi `previewPublished`, `download`, `getStatus`; raw provider payload không trả về client và observation không được đổi authoritative issuance state.

### Operation status transitions (frozen)

```text
PENDING --provider success--> AVAILABLE
PENDING --definite rejection/no document--> FAILED
PENDING --auth/config/content uncertain--> CHECK_REQUIRED
PENDING --timeout/5xx/transport ambiguous--> retry same operation
ambiguous retry exhaustion --> CHECK_REQUIRED; keep logical resource lock
Request replay at CHECK_REQUIRED re-arms the same operation; no competing generation
```

### Access scope (frozen)

Public S4 RPC nhận `salesOrderId` kiểm tra actor + E-invoice permission + source-owned `sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id)`. Ngoài scope trả `NOT_FOUND`.

### Document capability (frozen)

`supported_document_types = ['PDF','XML']` trong capability snapshot. Thiếu/unknown capability cho loại được yêu cầu fail closed trước khi tạo operation/document/command → `DOCUMENT_UNAVAILABLE`.

### Observation trigger (frozen)

Observation collection là explicit policy/support trigger với caller-owned `triggerId`. Replay same `triggerId` reuses one command. Distinct authorized triggers on the same day remain distinct. Không có tenant-wide scheduled observation scan hoặc due-command seeder RPC. Rate protection: max one in-flight observation call per provider connection + worker backoff/429; không phải daily uniqueness rule.

### S4 implementation evidence (Slice 4 BE + worker)

Verified in repo (không live MISA trong CI): `modules/einvoice/infrastructure/test/einvoice_slice4_integration_test.dart`, `modules/einvoice/application/test/electronic_invoice/s4_worker_handlers_test.dart`, `apps/messaging_worker/test/einvoice_worker_slice4_test.dart`. Internal commands: `einvoice.fetch_official_view` (max 2 attempts), `einvoice.download_invoice_document` (3), `einvoice.poll_provider_observation` (trigger-scoped). Worker injects `_worker_attempt_number` via `ProcessInternalCommandsCommandHandler`. Signed viewer/download URL TTL 5 phút; Storage bucket private, scoped SELECT only. BE DB lane `in_progress`: drafts `010`/`011`/`012`/`018` chưa promote; `sales.can_access_sales_order` chỉ stub trong draft 010.

### S4 implementation evidence (Slice 4 FE — app-owned presentation)

Verified in `apps/erp` (không gọi MISA/OS thật trong widget tests):

| Concern | Implementation | Test ids |
| ------- | -------------- | -------- |
| Official view poll + correlate `operationId` | `OrderEInvoiceCubit.openOfficialView` | `th08_scn_e03_u01_fr04_01`, `th08_scn_e03_u01_fr04_02` |
| Document command→read split + poll `AVAILABLE` không URL | `OrderEInvoiceCubit.downloadDocument` | `th08_scn_e03_u02_fr04_01` |
| SG-02 post-issued sheet (official loading locks siblings) | `apps/erp/.../einvoice/post_issue_einvoice_action_sheet.dart` | `th08_wgt_e03_u01_fr01_01` |
| SG-06 documents sheet (PDF/XML sibling lock) | `apps/erp/.../einvoice/invoice_documents_action_sheet.dart` | `th08_wgt_e03_u02_fr01_01` |
| Safe error surface (single SnackBar) | `OrderEInvoiceSection` `BlocListener` | `th08_wgt_e03_u01_fr08_01`, `th08_wgt_e03_u02_fr08_01` |
| Checksum handoff before native share | `IInvoiceDocumentExporter.expectedSha256` + cubit | `file_invoice_document_exporter_test`, cubit download tests |
| Theme 05 host — order detail official view | `SalesOrderDetailDocumentsSection` + `OrderEInvoiceSection` | `th08_e2e_e03_u01_sc01_01` |
| Theme 05 host — sales result PDF export | `SalesTransactionResultBody` → `SalesResultDocumentsSection` | `th08_e2e_e03_u02_sc01_01` |
| Observation | Worker/integration only; **no** ERP UI for `GetLatestProviderObservationQuery` | `th08_e2e_e03_u03_sc01_01` |

Fake module (`FakeEInvoiceModule`): `download_pdf_ok` / `download_xml_ok` trả command `PENDING` + `operationId`; signed URL/checksum qua `GetInvoiceDocumentsQuery` khi item `AVAILABLE`.

## §S4a — EP-03/US-01 — Xem hồ sơ và nội dung hóa đơn đã phát hành

Spec: [Epic-03-issued-invoice-documents/US-01.md](../Epic-03-issued-invoice-documents/US-01.md)

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetElectronicInvoiceDetailQuery` | tenantId, actorId, salesOrderId | `ElectronicInvoiceDetailDto` (identity, snapshot summary, providerRef, officialViewOperationId/status, viewer fields?) | NO_PERMISSION, NOT_FOUND |
| `RequestOfficialInvoiceViewCommand` | tenantId, actorId, salesOrderId | `OfficialInvoiceViewDto` (operationId, status, viewerUrl?/token?/expiresAt?) | NO_PERMISSION, NOT_FOUND, OPERATION_IN_PROGRESS, SYSTEM_ERROR |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (displayState=Đã phát hành, action=view) | NO_PERMISSION, NOT_FOUND |

Entry từ Theme 05 row action — không standalone list (SG-05 no UI).

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Detail | `einvoice.get_electronic_invoice_detail` | drafted |
| Request/enqueue official view | `einvoice.request_official_invoice_view` | drafted |
| Record official-view result (worker) | `einvoice.record_official_invoice_view_result` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Resolve viewer (FR-04..06) | `einvoice.fetch_official_view` | `IMeInvoiceClient.previewPublished` |

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
| `GetInvoiceDocumentsQuery` | tenantId, actorId, salesOrderId | `InvoiceDocumentsDto` (pdf/xml item: operationId?, status, URL/fileRef/checksum?) | NO_PERMISSION, NOT_FOUND |
| `RequestInvoiceDocumentCommand` | tenantId, actorId, salesOrderId, documentType (`pdf` \| `xml`), idempotencyKey | `InvoiceDocumentRetrievalDto` (operationId, status, downloadUrl?/fileRef?/checksum?) | NO_PERMISSION, NOT_FOUND, OPERATION_IN_PROGRESS, SYSTEM_ERROR |

FR-03..08: separate operations per document type; metadata + checksum stored on success.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| List documents | `einvoice.get_invoice_documents` | drafted |
| Request/enqueue document | `einvoice.request_invoice_document` | drafted |
| Record document result (worker) | `einvoice.record_invoice_document_result` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Download | `einvoice.download_invoice_document` | `IMeInvoiceClient.download` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `download_pdf_ok` | RequestInvoiceDocumentCommand pdf | command `PENDING` + operationId (không signed URL); `GetInvoiceDocumentsQuery` trả PDF item cùng operation `AVAILABLE` + signed URL/fileRef/checksum |
| `download_xml_ok` | documentType=xml | cùng pattern command/read split như `download_pdf_ok` cho XML |
| `download_unavailable` | provider definite empty/no document after worker | operation `FAILED` (async read model), không phải sync `DOCUMENT_UNAVAILABLE` |
| `download_timeout_exhausted` | transport timeout 3x | operation `CHECK_REQUIRED` + `PROVIDER_RESULT_UNDETERMINED` |
| `download_permission_denied` | no downloadDocument | NO_PERMISSION |
| `documents_list_partial` | GetInvoiceDocumentsQuery | PDF item `AVAILABLE` + XML item `PENDING`, mỗi item có operationId riêng |

---

## §S4c — EP-03/US-03 — Theo dõi trạng thái gần nhất tại nhà cung cấp

Spec: [Epic-03-issued-invoice-documents/US-03.md](../Epic-03-issued-invoice-documents/US-03.md)

**Server/worker-only** — observation không có màn riêng MVP. Không có tenant-wide scheduled observation scan hoặc due-command seeder RPC.

### Observation interaction semantics (frozen)

```text
Timeout/unavailable records interaction failure and creates no fabricated observation.
Each outbound provider-call attempt or inbound callback creates one ProviderInteractionRecord.
Provider fact creates append-only ProviderObservationRecord referencing the interaction.
NOT_FOUND/MISMATCH appends observation and outbox event einvoice.provider_observation_attention_required.
Observation collection is explicit policy/support trigger with caller-owned triggerId.
Replay of the same triggerId reuses one command; distinct authorized triggers on the same day remain distinct.
Rate protection is max one in-flight observation call per provider connection plus worker backoff/429 handling; it is not a daily uniqueness rule.
ProviderObservationRecord correlation is resolved through provider_interaction_reference; no correlation_id column on invoice_provider_observations.
```

SRS “Theme 11” alerts naming drift: repo harness là `TH-10-alerts-and-risk`. E-invoice emits neutral integration event `einvoice.provider_observation_attention_required`; không import alerts module.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RecordProviderObservationCommand` | tenantId, electronicInvoiceId, allow-listed typed fields + `providerInteractionReference`, source | `ProviderObservationDto` (source/providerStateCode; correlation derived from interaction) | NOT_FOUND, VALIDATION_ERROR, SYSTEM_ERROR |
| `GetLatestProviderObservationQuery` | tenantId, actorId, salesOrderId | `ProviderObservationDto?` | NO_PERMISSION, NOT_FOUND |

Append-only history (FR-02). Distinct from authoritative issuance state (FR-04).
`PROVIDER_UNAVAILABLE` / timeout fails/retries the internal command and does not append a fabricated observation.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Trigger (service-role) | `einvoice.request_provider_observation_refresh` | drafted |
| Record (internal) | `einvoice.record_provider_observation` | drafted |
| Latest | `einvoice.get_latest_provider_observation` | drafted |

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Poll provider status | `einvoice.poll_provider_observation` | `IMeInvoiceClient.getStatus` |

### Fake scenarios (BE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `observation_recorded` | poll success | new observation row |
| `observation_latest_query` | GetLatestProviderObservationQuery | latest payload |
| `observation_provider_unavailable` | timeout | interaction failure only, no observation |

---

## §S5a — EP-04/US-01 — Tự động gửi hóa đơn sau khi phát hành

Spec: [Epic-04-send-resend-einvoice/US-01.md](../Epic-04-send-resend-einvoice/US-01.md)

**Server-only** — trigger từ `einvoice.electronic_invoice.registered`.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `StartAutoDeliveryCommand` | tenantId, electronicInvoiceId, triggerId, idempotencyKey | `AutoDeliveryResultDto` (disposition, deliveryId?, skipReason?) | DELIVERY_NOT_SUPPORTED, NOT_FOUND, VALIDATION_ERROR, OPERATION_IN_PROGRESS |

`AutoDeliveryDisposition` = `started` \| `skipped`. `AutoDeliverySkipReason` = `policyOff` \| `invalidOrMissingEmail` \| `initialDeliveryAlreadyClaimed`. Skip tạo **không** delivery/attempt/provider call. Thiếu capability raise `DELIVERY_NOT_SUPPORTED` và không tạo row.

**Stable business idempotency key** (UUIDv5) — replay và duplicate registered event hội tụ cùng một delivery:

```text
namespace = 9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275
name      = <tenantId>|<electronicInvoiceId>|auto_initial
```

`triggerId` giữ event id chỉ để traceability, không phải business key.

**Eligibility đánh giá atomically tại thời điểm accept operation** (không phải lúc publish event):

| Check | Authoritative source | Failure |
| ----- | -------------------- | ------- |
| ElectronicInvoice tồn tại + đã registered | E-invoice authoritative row | `NOT_FOUND`, không delivery |
| Auto-send còn bật | `einvoice.automation_policies.auto_send_enabled` | skip `POLICY_OFF` |
| Connection active hỗ trợ email | `provider_connections.capabilities_snapshot.supports_email_delivery` | `DELIVERY_NOT_SUPPORTED` |
| Recipient hợp lệ | current Partner snapshot → immutable `BuyerInvoiceSnapshot` lineage | skip `INVALID_OR_MISSING_EMAIL` |

**Recipient fallback (automatic initial):** current Partner invoice email → `invoice_snapshot.attemptSnapshot.buyer_lineage.buyerInvoiceSnapshot.email`. `attemptSnapshot.buyer` là `EffectiveBuyerInvoiceData` và **không** được dùng thay cho base snapshot. Không có `buyerPartnerId` ổn định thì fallback duy nhất là `buyerInvoiceSnapshot.email`; cấm history tenant-wide / cross-customer.

Tối đa **một** `INITIAL_SEND` business delivery / invoice. Manual thắng race → auto trả `initialDeliveryAlreadyClaimed`.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Auto delivery (internal) | `einvoice.start_auto_delivery` | drafted |
| Recipient snapshot (source-owned) | `partner.get_einvoice_recipient_snapshot(p_tenant_id, p_partner_id)` → `(partner_id, invoice_email, recipient_name, source_version, is_active)` | drafted |

E-invoice **không** query bảng Partner/Sales; chỉ gọi public function source-owned `partner.get_einvoice_recipient_snapshot(...)` và `sales.can_access_sales_order(...)`. Partner draft: `service_role` (+ owner) execute only — **không** grant `authenticated`.

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
| `GetSendInvoiceSheetContextQuery` | tenantId, actorId, salesOrderId | `SendInvoiceSheetContextDto` (mode, suggestedEmail?, suggestedEmailSource?, history[], operationLocked, displayState) | NO_PERMISSION, NOT_FOUND |
| `SendElectronicInvoiceCommand` | tenantId, actorId, salesOrderId, recipientEmail, idempotencyKey | `SendInvoiceResultDto` (deliveryId, status=PROCESSING) | NO_PERMISSION, NOT_FOUND, VALIDATION_ERROR, DELIVERY_NOT_SUPPORTED, OPERATION_IN_PROGRESS, IDEMPOTENCY_CONFLICT, ALREADY_ISSUED (inverse: must be issued) |
| `GetInvoiceDeliveryHistoryQuery` | tenantId, actorId, salesOrderId | `InvoiceDeliveryHistoryDto` | NO_PERMISSION, NOT_FOUND |

**`DeliveryKind` là server-derived.** Command **không** nhận `deliveryKind`; server suy ra `INITIAL_SEND` / `RESEND` từ delivery history authoritative và từ chối mọi ý định chọn kind từ client. Manual start lặp lại check registered-invoice + provider capability trước khi insert; policy-off **không** chặn manual send. Email validation (FR-06).

**Suggested email + `DeliveryRecipientSource`:**

| Entry point | Priority | Khi không còn candidate |
| ----------- | -------- | ----------------------- |
| Manual initial | `currentPartnerProfile` → `lastSuccessfulPartnerDelivery` (cùng `buyerPartnerId` ổn định, trong tenant) | suggestion rỗng |
| Manual resend | `lastInvoiceDelivery` (recipient của delivery gần nhất cùng invoice) | suggestion rỗng |
| Manual confirmed send | input người dùng đã validate | persist source `userInput` |

Không có `buyerPartnerId` ổn định → tắt hẳn fallback history của manual initial. Cấm history tenant-wide / cross-customer.

`operationLocked = true` chỉ khi invoice có delivery `PROCESSING`. `UNKNOWN` được giữ trong history nhưng không khóa manual resend; worker không auto-retry sau `UNKNOWN`.

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
| `RecordDeliveryResultCommand` | tenantId, deliveryId, attemptId, expectedDeliveryVersion, expectedAttemptVersion, interactionReference, `DeliveryResultEvidence` | `RecordDeliveryResultDto` (deliveryStatus, displayState, hasSecondaryAttention) | NOT_FOUND, INVALID_STATUS, STATE_CHANGED, SYSTEM_ERROR |
| `ReconcileInvoiceDeliveryCommand` | tenantId, reconciliationCaseId, checkSequence | `DeliveryReconciliationResultDto` (caseStatus, deliveryStatus, nextCheckAt?, hasSecondaryAttention) | NOT_FOUND, INVALID_STATUS, STATE_CHANGED |
| `GetInvoiceDeliveryHistoryQuery` | tenantId, actorId, salesOrderId | `InvoiceDeliveryHistoryDto` (deliveries[], displayState, hasSecondaryAttention) | NO_PERMISSION, NOT_FOUND |
| `GetOrderInvoiceProjectionQuery` | tenantId, actorId, salesOrderId | `OrderInvoiceProjectionDto` (delivery display) | NO_PERMISSION, NOT_FOUND |

**Provider evidence là typed, không raw.** `RecordDeliveryResultCommand` **không** nhận `Map<String, Object?>` / raw provider payload.

```dart
enum DeliveryResultKind { success, definiteFailure, retryableFailure, undetermined }

final class DeliveryResultEvidence {
  final DeliveryResultKind kind;
  final String? providerReference;
  final String? safeCode;
}
```

Không persist access token, credential, HTTP header, signature, raw response, raw exception text hay recipient payload không giới hạn — chỉ allow-listed outcome/error code + canonical reference.

**Phân loại kết quả:**

| Điều kiện | Có thể đã dispatch? | Provider outcome | Delivery result |
| --------- | ------------------: | ---------------- | --------------- |
| MISA ack thành công tin cậy | Yes | success | `SUCCEEDED` |
| Auth/credential/validation/business rejection tin cậy | No | definiteFailure | `FAILED` |
| HTTP 429 trước khi provider accept | No | retryableFailure | attempt kỹ thuật kế tiếp, **tối đa 3** |
| Timeout, mất kết nối sau ghi, HTTP 5xx, body success malformed | Possibly | undetermined | `UNKNOWN` + case `PENDING` |
| Dead-letter khi attempt còn `QUEUED` | No | definiteFailure | `FAILED` |
| Dead-letter/replay sau `SUBMITTED` | Possibly | undetermined | `UNKNOWN` + case `PENDING` |

**Không bao giờ suy ra kết quả gửi email từ trạng thái phát hành invoice của MISA.** `getStatus` không phải delivery-status API và **không** được gọi từ delivery reconciliation.

**Capability-aware reconciliation.** Ghi `UNKNOWN` tạo/reuse atomically một case `PENDING` `VERIFY_DELIVERY` (`attempt_count = 0`, `next_check_at = now() + interval '30 seconds'`) cùng command `einvoice.reconcile_invoice_delivery` đầu tiên (UUIDv5 từ `<caseId>|<checkSequence>`). Không enqueue thêm lần gửi email nào sau `UNKNOWN`.

| `supports_delivery_result_observation` | Hành vi |
| -------------------------------------- | ------- |
| `true` | Một typed observation / check sequence. Evidence terminal → resolve delivery/attempt/case. Undetermined → lịch `[30s, 2m, 10m, 30m, 2h]`; check thứ 5 undetermined → `UNRESOLVED` + attention |
| `false` | **Không** outbound HTTP. Check đầu tiên ghi safe code `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, chuyển case sang `UNRESOLVED`, clear `next_check_at`, emit attention |

MISA hiện tại luôn `supports_delivery_result_observation = false`. Evidence terminal xác thực đến muộn cho cùng attempt có thể chuyển `PENDING` hoặc `UNRESOLVED` → `RESOLVED` mà không tạo delivery mới hay gửi lại email.

**Display-state precedence (FR-04).** `DeliveryDisplayState` derive từ authoritative history: một delivery thành công trước đó giữ display chính là `sent` kể cả khi resend sau đó `FAILED`/`UNKNOWN`; vấn đề mới lộ ra qua `hasSecondaryAttention`, không ghi đè display chính. Delivery state không bao giờ đổi issuance status, registration fact, số hóa đơn, mã tra cứu hay official document state.

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Load attempt context | `einvoice.load_delivery_attempt_context` | drafted |
| Prepare provider call (barrier) | `einvoice.prepare_delivery_provider_call` | drafted |
| Record result | `einvoice.record_delivery_result` | drafted |
| Command dead-letter | `einvoice.record_delivery_command_dead_letter` | drafted |
| Load reconciliation context | `einvoice.load_delivery_reconciliation_context` | drafted |
| Record reconciliation check | `einvoice.record_delivery_reconciliation_check` | drafted |
| History | `einvoice.get_invoice_delivery_history` | drafted |
| Projection | `einvoice.get_order_invoice_projection` | drafted |

Delivery case dùng lại bảng canonical `einvoice.invoice_reconciliation_cases` (`target_type = 'DELIVERY_ATTEMPT'`, `reconciliation_purpose = 'VERIFY_DELIVERY'`) — **không** tạo bảng case riêng cho delivery.

### Worker mapping

| Step | Job type | Client method |
| ---- | -------- | ------------- |
| Send | `einvoice.send_invoice_email` (tenantId, deliveryId, attemptId) | `IMeInvoiceClient.sendEmail` |
| Reconcile | `einvoice.reconcile_invoice_delivery` (tenantId, reconciliationCaseId, checkSequence) | none khi capability = false |

Mỗi outbound call thực tế có đúng một `ProviderInteractionRecord` target `DELIVERY_ATTEMPT` (reuse contract S4 nguyên vẹn): `start` trước HTTP, finalize một lần với outcome allow-listed.

### Integration events

| Event | Payload (safe) |
| ----- | -------------- |
| `einvoice.delivery.result_recorded` | + `salesOrderId`, `deliveryId`, `deliveryStatus`, `deliveryDisplayState`, `deliveryVersion`, `hasSecondaryAttention` |
| `einvoice.delivery.attention_required` | tenant/invoice/SalesOrder/delivery/attempt/case id + safe error code — chỉ khi reconciliation đạt `UNRESOLVED` |

`UNKNOWN` + tạo case `PENDING` + command reconciliation đầu tiên + result event là atomic. Chuyển `UNRESOLVED` + attention event là atomic.

### Fake scenarios (BE/FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `delivery_success` | RecordDeliveryResultCommand ok | display=Đã gửi |
| `delivery_failed` | provider reject | display=Gửi lỗi |
| `delivery_undetermined` | timeout | display=Đang gửi + UNKNOWN |
| `delivery_history_multi` | resend after success | 2 deliveries, prior success giữ display=Đã gửi |

---

## §H1 — MISA V2 production hardening (contract freeze)

Baseline: tài liệu AIO V2 (16/09/2026) + `packages/vet45_misa/doc/misa-meinvoice-open-api.md`.
Plan: `docs/superpowers/plans/2026-09-16-th08-misa-contract-production-hardening.md`.
Test id prefix: `th08_hardening_*`. Status aggregate `in_progress` tới gate Công việc 10.

### SignType & template

| Rule | Contract |
| --- | --- |
| Wire SignType | Chỉ `2` (HSM có CKS) hoặc `5` (MTT không CKS). Không `3`/`4`/`6`. |
| Resolve | Signing config → wire value **trước** attempt có thể dispatch; mapper fail closed nếu thiếu. |
| Template | Resolve đúng `templateId`/`InvSeries` trong capability hiện hành. Không fallback template đầu / không bịa `1C26TAA`. |
| MTT | Template/series capability `isMtt=true` → bắt buộc `SignType=5`; non-MTT HSM → `2`. |
| Classification | `invoiceWithCode` + MTT suy từ `InvSeries`; status/download/delivery dùng cùng classification từ attempt snapshot. |

### Chính sách KCT-only (BA 16/09/2026)

| Condition | Canonical wire | Blocker |
| --- | --- | --- |
| Sales: mọi `taxAmountMinor=0`, `totals.taxMinor=0`, tax snapshot null/rỗng | `VATRateName=KCT`, VAT=0, một `TaxRateInfo` KCT | — (business policy tại `build_canonical_invoice` only) |
| Bất kỳ line/totals tax ≠ 0 hoặc tax snapshot không rỗng | Không preview/publish | `UNSUPPORTED_TAX_DATA` |

Không hard-code `KCT` ở Catalog, Sales DTO, UI, hoặc nhiều adapter. Đổi chính sách chỉ sau quyết định BA/sản phẩm mới và plan riêng.

### Field map — MISA → nội bộ → blocker

| Trường MISA | Nguồn nội bộ | Blocker khi thiếu / sai |
| --- | --- | --- |
| `InvSeries` | Capability template đã chọn → bất biến trên attempt | `TEMPLATE_NOT_AVAILABLE` |
| `SignType` | Signing config resolve → `2` \| `5` | `SIGNING_CONFIGURATION_NOT_AVAILABLE` / invalid-canonical |
| `IsInvoiceSummary` | Template `IsSendSummary` từ capability MISA | Fail closed khi thiếu dữ liệu provider |
| `VATRateName` | Business policy Theme 8 → `KCT` (khi invariant pass) | `UNSUPPORTED_TAX_DATA` khi nguồn vi phạm contract |
| `VATAmount` / `VATAmountOC` | Canonical `0` dưới policy `KCT` | Cùng blocker thuế |
| `TaxRateInfo` | Một group `KCT` nhất quán | Cùng blocker thuế |
| Buyer identity (MST, tên pháp lý, địa chỉ) | `EffectiveBuyerInvoiceData` | `BUYER_TAX_CODE_REQUIRED` / `BUYER_DATA_INCOMPLETE` / `BUYER_ADDRESS_REQUIRED` |

### Series lease & retry

| Concern | Contract |
| --- | --- |
| Serialization | ≤ 1 publish foreground / `(tenant, provider_connection, InvSeries)` qua lease DB |
| Busy lease | Reschedule command; không dead-letter; không mở reconciliation |
| Retry persistence | `issuance_attempts.provider_publish_retry_count`, `next_provider_publish_retry_at`, `last_provider_publish_code`; RPC enqueue lại `einvoice.publish_invoice` cùng RefID/canonical (draft `020`) |
| `InvoiceNumberNotCotinuous` | Retry giới hạn (≤3), cùng RefID + canonical + lease |
| `InvoiceDuplicated` | Reconcile-first (`claim_issuance_reconciliation_case.reconciliation_reason_code`); poll bằng RefID; retry chỉ sau `STATUS_EMPTY_DATA` ở check cuối |
| `DuplicateInvoiceRefID` | Reconciliation-only |
| Transport 5xx/timeout sau dispatch | Undetermined + reconcile — không xếp chung definite rejection |
| Preview / official view URL | Chỉ HTTPS absolute trên host `meinvoice.vn` / `*.meinvoice.vn`; `Data` non-string fail closed |
| Delivery active lock | Chỉ `PROCESSING`; `UNKNOWN` không khóa (đồng bộ SQL Slice 5) |

### Preserved flows (regression bắt buộc)

Endpoint set, token cache per-tenant, `RefID` ổn định, preview/official view, PDF/XML download + Share Sheet, `/invoice/sendemail` Product envelope (`success=true`, `data=""`). Delivery: chỉ `PROCESSING` khóa; `UNKNOWN` cho phép manual resend (Slice 5).

### Fake / test ids (H1)

| scenario / test id | Mục |
| --- | --- |
| `th08_hardening_contract_01` | Docs/harness freeze |
| `th08_hardening_capability_*` | List templates có mã + không mã + MTT |
| `th08_hardening_resolve_*` | Stale template / missing SignType / MTT+2 |
| `th08_hardening_tax_*` | KCT happy + invariant block tax ≠ 0 / snapshot |
| `th08_hardening_buyer_*` | Org MST thiếu địa chỉ |
| `th08_hardening_status_*` | Status flags theo series |
| `th08_hardening_lease_*` | Hai worker cùng series serialize |
| `th08_hardening_retry_*` | Ba mã retry MISA |
| `th08_hardening_parse_*` | Malformed view URL + UNKNOWN unlock |
| `th08_hardening_gate_*` | Aggregate verification + live evidence |

---

## Parallel notes (global)

- FE có thể fake sau khi Contract lane chốt symbol — dùng `FakeEInvoiceModule` scenarios ở trên.
- E2E blocked by: [04-slice-roadmap.md](04-slice-roadmap.md).
- E2E vendor: `FakeMeInvoiceClient` — không gọi MISA thật.
- BE lane viết draft SQL: `supabase/migrations/_drafts/00N_einvoice_s1_*.sql` (001 schema → 002 messaging → 003 rpc connection → 004 rpc profile) — không timestamp migration cho đến khi user promote. Messaging tables/RPC đi qua `002_einvoice_s1_install_module_messaging.sql` (`install_module_messaging('einvoice')`), không DDL queue tự viết.

### S5 — Delivery payload compatibility + pending projection (2026-09-07)

Draft-only update in `013_einvoice_delivery_schema_and_start_rpcs.sql` and
`014_einvoice_delivery_results_and_projection_rpcs.sql`; not applied/promoted.
Email mock / `is_simulated` provenance has been removed (Option B).

- `einvoice.send_invoice_email` produces `tenant_id`, `delivery_id`, `attempt_id`.
  Delivery deserializer/dead-letter parser accept legacy camelCase aliases, reject
  missing/non-string/blank identities and conflicting aliases. Claimed tenant must
  match payload tenant; dead-letter may use claimed tenant when legacy payload omits it.
- `prepare_delivery_provider_call(uuid, uuid, uuid, bigint, bigint, text)` is the
  only signature (boolean `p_is_simulated` overload dropped). At the atomic
  `QUEUED → SUBMITTED` barrier it bumps versions and stores the request reference.
  Only worker service role may call.
- `get_order_invoice_projection` exposes `delivery_pending boolean` (true while any
  delivery is `PROCESSING`, including pending resends when sticky
  display is already `SENT`). UI polls and locks duplicate send using it.
  No `delivery_is_simulated` field.
- History JSON from `get_invoice_delivery_history` and
  `get_send_invoice_sheet_context` does not include simulation flags.
- An unchanged recipient snapshot, result code, or provider reference does not
  constitute inbox delivery evidence.
- Recovery tool: `scripts/supabase/recover_einvoice_email_dev_job.sh` defaults to
  read-only. Explicit apply requires independently confirmed development PGHOST and
  stopped workers; SQL validates the exact known command/error, untouched queued
  attempt and absence of provider interactions under table locks.
  Recovery retains payload/IDs/retry_count and audits previous failure time/error.
  Recovery and draft application are separate, explicitly requested operations.
