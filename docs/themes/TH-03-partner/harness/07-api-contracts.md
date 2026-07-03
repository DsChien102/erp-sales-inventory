# TH-03 — API contracts (FE ↔ BE)

Source of truth giữa presentation và application layer. Types live in `modules/partner/application/`. RPC mapping: [03-architecture-and-flows.md](03-architecture-and-flows.md).

Facade: `IPartnerModule` (`modules/partner/application/lib/src/contracts/i_partner_module.dart`).

**Access control:** commands/queries dùng `@RequiresPermission(PartnerPermissions.*)` + `@RequiresTenant()`; codegen emit `partner_access_metadata.g.dart` — xem [modules/partner/README.md](../../../../modules/partner/README.md).

**Quy tắc:** FE fake theo contract này — không fake RPC trực tiếp. Scenario ids dùng trong `FakePartnerModule` (`modules/partner/application/lib/src/testing/fake_partner_module.dart`, import `package:vet45_partner_application/testing.dart`).

---

## Epic-01 / US-02 — Ghi nhận đối tác mới

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `RegisterPartnerCommand` | tenantId, actorId, entityType, displayName, phone, roles, confirmDuplicate, optional profile fields | `RegisterPartnerResult` (businessPartnerId, hasTaxCodeWarning) | Validation, PermissionDenied, DuplicateNotConfirmed |
| `CheckDuplicatePartnersQuery` | tenantId, phone?, email?, taxCode? | `List<PartnerDuplicateMatchDto>` | PermissionDenied |

Package: `vet45_partner_application` — `register_partner/`, `check_duplicate/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Register | `partner.register_partner` |
| Dup check | `partner.check_duplicate` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `register_save_ok` | RegisterPartnerCommand valid | `RegisterPartnerResult(businessPartnerId: 'partner-new-1')` |
| `register_dup_warning` | CheckDuplicatePartnersQuery | non-empty `PartnerDuplicateMatchDto` list |
| `register_dup_confirmed` | RegisterPartnerCommand confirmDuplicate=true | `RegisterPartnerResult` |
| `register_validation_error` | invalid command | throws validation error |
| `register_permission_denied` | no partner.create | PermissionDenied |

### Parallel notes

- FE có thể fake: **yes** (sau CONTRACT)
- E2E prerequisite: —

---

## Epic-01 / US-01 — Tìm kiếm danh sách

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `SearchPartnersQuery` | tenantId, PartnerSearchCriteria, limit, offset | `PartnerSearchResultDto` (items, totalCount) | PermissionDenied |

Package: `vet45_partner_application` — `search_partners/`.

### RPC mapping (BE)

| Use case | RPC / view |
| -------- | ---------- |
| Search | `partner.search_partners` / `partner.v_partner_list` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `search_empty` | SearchPartnersQuery | empty items |
| `search_results` | SearchPartnersQuery | list of `PartnerListItemDto` |
| `search_filtered` | criteria with role/status | filtered subset |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-02 (data) — **chỉ lane E2E**

---

## Epic-01 / US-04 — Kiểm tra hồ sơ

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetPartnerDetailQuery` | tenantId, partnerId | `PartnerDetailDto?` | PermissionDenied, NotFound (null) |

Package: `vet45_partner_application` — `get_partner_detail/`.

### RPC mapping (BE)

| Use case | RPC / view |
| -------- | ---------- |
| Detail | `partner.get_partner_detail` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `detail_active` | GetPartnerDetailQuery | `PartnerDetailDto` status=active |
| `detail_inactive` | GetPartnerDetailQuery | `PartnerDetailDto` status=inactive |
| `detail_not_found` | GetPartnerDetailQuery | null |
| `detail_refresh` | sequential loads | version increments (edit return flow) |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-02 (partner id)

---

## Epic-01 / US-03 — Bổ sung và chỉnh sửa

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `UpdatePartnerProfileCommand` | tenantId, actorId, partnerId, expectedVersion, profile fields, confirmDuplicate | `UpdatePartnerProfileResult` | Validation, ConcurrencyConflict, DuplicateNotConfirmed |
| `CheckDuplicatePartnersForUpdateQuery` | tenantId, phone?, email?, taxCode?, excludePartnerId | `List<PartnerDuplicateMatchDto>` | PermissionDenied |
| `GetPartnerDetailQuery` | (load for edit) | `PartnerDetailDto?` | — |

Package: `vet45_partner_application` — `update_partner_profile/`, `check_duplicate/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Update | `partner.update_partner` |
| Dup check (update) | `partner.check_duplicate` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `update_save_ok` | UpdatePartnerProfileCommand valid | `UpdatePartnerProfileResult` |
| `update_dup_warning` | CheckDuplicatePartnersForUpdateQuery | non-empty matches |
| `update_concurrency` | stale expectedVersion | ConcurrencyConflict |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-02 (partner id)

---

## Epic-02 / US-01 — Dừng sử dụng / kích hoạt lại

> CONTRACT implemented — Epic-02/US-01 pilot for contract-first parallel lanes.

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `DeactivatePartnerCommand` | tenantId, actorId, partnerId, expectedVersion, currentStatus, statusNote? | `DeactivatePartnerResult` | Validation, NotFound, InvalidStatus, PermissionDenied |
| `ReactivatePartnerCommand` | tenantId, actorId, partnerId, expectedVersion, currentStatus | `ReactivatePartnerResult` | Validation, NotFound, InvalidStatus, PermissionDenied |
| `GetPartnerDetailQuery` | (reload after mutation) | `PartnerDetailDto?` | — |

Package: `vet45_partner_application` — `deactivate_partner/`, `reactivate_partner/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Deactivate | `partner.deactivate_partner` |
| Reactivate | `partner.reactivate_partner` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `deactivate_ok` | DeactivatePartnerCommand | success, status→inactive |
| `reactivate_ok` | ReactivatePartnerCommand | success, status→active |
| `deactivate_already_inactive` | DeactivatePartnerCommand | InvalidStatus |
| `reactivate_already_active` | ReactivatePartnerCommand | InvalidStatus |
| `status_permission_denied` | either command | PermissionDenied |
| `status_network_error` | either command | throws |

### Parallel notes

- FE có thể fake: **yes** (sau CONTRACT)
- E2E prerequisite: US-04 (partner detail context)

---

## Epic-02 / US-02 — Loại bỏ hồ sơ tạo nhầm

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `DeletePartnerCommand` | tenantId, actorId, partnerId, expectedVersion, hasBusinessData | `DeletePartnerResult` | Validation, NotFound, HasBusinessData, PermissionDenied |

Package: `vet45_partner_application` — `delete_partner/`.

### RPC mapping (BE)

| Use case | RPC |
| -------- | --- |
| Soft delete | `partner.delete_partner` |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `delete_ok` | DeletePartnerCommand | success |
| `delete_has_business_data` | DeletePartnerCommand or detail `hasBusinessData=true` | HasBusinessData error |

### Parallel notes

- FE có thể fake: **yes**
- E2E prerequisite: US-04

---

## Epic-03 / US-01 — Lịch sử giao dịch

> CONTRACT implemented — read path qua `GetPartnerTransactionHistoryQuery`; projection write qua application consumer handlers + `CommandBus` pipeline.

### Commands / Queries (FE-facing)

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `GetPartnerTransactionHistoryQuery` | tenantId, partnerId, `PartnerTransactionHistoryCriteria`, limit (default 100), offset (default 0) | `PartnerTransactionHistoryResultDto` (items, totalCount) | PermissionDenied (`partner.view_transaction_history`), partner not found / tenant mismatch (handler/gateway) |

**`PartnerTransactionHistoryCriteria`** (domain, passed on query):

| Field | Type | Notes |
| ----- | ---- | ----- |
| `keyword` | `String?` | Mã giao dịch / ghi chú; trimmed |
| `transactionTypes` | `Set<String>?` | Loại giao dịch (sales, purchase, invoice, …) |
| `transactionRole` | `PartnerRole?` | `customer` / `supplier` |
| `from` / `to` | `DateTime?` | Khoảng thời gian; `from` ≤ `to` |

**`PartnerTransactionHistoryItemDto`** (summary): id, partnerId, transactionRole, transactionType, occurredAt, transactionCode?, amount?, status?, description?, `sourceNavigation` (`PartnerTransactionSourceNavigationDto`).

Package: `vet45_partner_application` — `transaction_history/get_partner_transaction_history/`.

Permission: `PartnerPermissions.viewTransactionHistory` (`partner.view_transaction_history`).

### Internal command (BE / messaging — không gọi từ FE)

| Symbol | Input (summary) | Success | Notes |
| ------ | --------------- | ------- | ----- |
| `RecordPartnerTransactionHistoryCommand` | tenantId, businessPartnerId, transactionRole, sourceModule, sourceType, sourceId, transactionDate, optional sourceCode/amount/status/description | `void` | Internal command (`InternalCommandBase`); idempotent upsert vào projection; chạy qua `CommandBus` internal pipeline |

Package: `vet45_partner_application` — `transaction_history/record_transaction_history/`.

Consumer handlers (application layer) lắng nghe integration events (sales/inventory/accounting) và map → `RecordPartnerTransactionHistoryCommand`, thực thi qua `CommandBus`:
`application/lib/src/integration_events/*_integration_event_handler.dart` (implement `IIntegrationEventNotificationHandler`, wiring qua codegen `createGeneratedPartnerIntegrationEventDispatcher`). Inbox/internal-command drain qua `ProcessInboxCommand` / `ProcessInternalCommandsCommand` (`IRecurringCommand`) trong infrastructure; contract RPC schema `partner` giữ claim-token.

### RPC mapping (BE)

| Use case | RPC / view |
| -------- | ---------- |
| List + filter | `partner.get_partner_transaction_history` |
| Read projection | `partner.v_partner_transaction_history` |
| Upsert projection | `partner.upsert_transaction_history` |

Migrations: `20260701000002_partner_transaction_history_read.sql`, `20260701000003_partner_transaction_history_upsert.sql`.

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `history_empty` | `GetPartnerTransactionHistoryQuery` | `PartnerTransactionHistoryResultDto(items: [], totalCount: 0)` |
| `history_items` | `GetPartnerTransactionHistoryQuery` | non-empty `PartnerTransactionHistoryItemDto` list (sales/purchase mix) |
| `history_filtered` | query với `criteria.transactionTypes` / `from`–`to` | subset matching criteria |
| `history_permission_denied` | query | PermissionDenied |
| `history_error` | query | throws (network / gateway error) |

Presentation bloc test: `modules/partner/presentation/test/bloc/partner_transaction_history_test.dart` (inline `_FakePartnerModule`).

### Parallel notes

- FE có thể fake: **yes** (sau CONTRACT)
- E2E prerequisite: US-04 (partner detail tab) + **cross-module publish** (sales/inventory/accounting → inbox → projection). Lane E2E `blocked` cho đến khi source modules publish events; **không** block FE unit/widget test hay BE handler tests.
