# E-Invoice S2b Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây manual issuance engine cho US-02 và immediate-result subset của US-04: commit snapshot/hash trước MISA, publish tối đa một lần qua worker, land success/definite-failure/unknown an toàn, và tạo durable reconciliation handoff cho kết quả chưa xác định.

**Architecture:** `IssueInvoiceCommand` đi qua CQRS pipeline tới một authoritative Supabase RPC transaction. Canonical runtime payload chỉ nằm trong durable `einvoice.publish_invoice` command; attempt lưu immutable `AttemptSnapshot`, canonical model version và hash. `prepare_issuance_publish` là durable dispatch barrier trả `callProvider | reconcileOnly | skip`; sau barrier không technical replay nào được gọi MISA lần nữa. SQL RPC/constraints là production enforcement-of-record; không tạo Dart aggregate mirror không được runtime sử dụng.

**Tech Stack:** Dart >=3.11.1 <4.0.0, Melos, vet45_shared CQRS, vet45_generator, Supabase/Postgres schema `einvoice`, `packages/vet45_misa`, `apps/messaging_worker`, package:test.

**Spec:** `docs/superpowers/specs/2026-08-27-einvoice-s2b-be-design.md`

## Global Constraints

- BE lane only. Không sửa `apps/erp/**`, `modules/einvoice/presentation/**`, auto issuance, business retry, provider callback, reconciliation resolution hoặc recovery UI.
- Traceability là **EP-02/US-02 + immediate-result subset EP-02/US-04**. Không gán ElectronicInvoice/InvoiceSnapshot/result reconciliation cho riêng US-02.
- Unknown result phải atomically: set `RECONCILING`, create/continue một pending `ReconciliationCase` với `next_check_at` set sẵn. **Chính pending case (canonical §4.4.6, `next_check_at`) LÀ durable poll handoff — S2b KHÔNG enqueue internal command `einvoice.poll_issuance_status`.** S3b poll consumer discover các case `PENDING` (`next_check_at <= now()`) bằng scan; S3b sở hữu poll execution, callback, case resolution và explicit recovery.
- Vì handoff chỉ là data (pending case), S2b không tạo internal command chưa có consumer nên không có "poison row" khi deploy trước S3b. Không được enqueue bất kỳ `einvoice.poll_issuance_status` internal command nào trong S2b.
- `issuance_attempts.idempotency_key` là operation identity và MISA `RefID`: correlation, duplicate detection và status lookup identity; nó không phải bằng chứng publish retry-safe.
- Sau durable dispatch barrier, timeout, crash, malformed response, duplicate `RefID`, hoặc replay đều đi reconciliation; không automatic re-publish.
- Attempt dùng đúng canonical §4.4.3: `provider_connection_id`, `issuance_profile_id`, `idempotency_key`, `intent_hash`, `snapshot_schema_version`, `attempt_snapshot`, `canonical_model_version`, `canonical_payload_hash`, provider-result fields, `internal_finalization_state` và canonical timestamps. Không có cột/domain field `canonical_payload`; payload nằm trong durable command.
- `sourceVersion` là opaque non-empty `String` xuyên `IssueInvoiceCommand -> request DTO -> gateway -> RPC`. Không parse, increment, compare numerically hoặc cast từ `int`.
- `SOURCE_SNAPSHOT_UNAVAILABLE` và `BUYER_SOURCE_UNAVAILABLE` là entries của `ISSUANCE_NOT_READY.details.blockers[]`, không phải top-level `EInvoiceBlockedCodes`.
- Authoritative source re-check nằm trong `einvoice.issue_invoice`, sau same-idempotency replay lookup. Không tạo `IIssuanceSourceSnapshotPort`; không đọc private Sales/Partner tables.
- `record_issuance_success` dùng outer transaction + caught inner PL/pgSQL subtransaction. Finalization lỗi phải giữ evidence, commit `SUCCEEDED + UNRESOLVED`, enqueue processing và không rethrow.
- Không giữ DB transaction mở khi gọi provider. Không đưa credentials, tokens, headers hoặc unrestricted raw provider response vào snapshot, command, audit, log hay outbox.
- SQL chỉ sửa/tạo `supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql`; không timestamp/promote/apply/reset DB.
- Application không import infrastructure; domain không import Supabase/Flutter/GetIt/other-module domain. Không sửa tay generated `.g.dart`; chạy codegen.
- Trước sửa existing symbol, chạy GitNexus upstream impact và báo blast radius; dừng nếu HIGH/CRITICAL. Trước commit khi được user yêu cầu, chạy `detect_changes(scope: compare, base_ref: main)`.
- Workspace có S2a changes chưa commit; executor phải bảo toàn chúng. Commit blocks là review boundaries, không phải authorization.

---

## File Structure and Responsibilities

```text
docs/themes/TH-08-e-invoice/harness/
  07-api-contracts.md                    freeze sourceVersion/blockers/result/reconciliation contracts
  05-traceability.md                     US-02 + US-04 immediate-result ownership

modules/einvoice/application/lib/src/issuance/commands/issue_invoice/
  issue_invoice_command.dart             opaque sourceVersion public command
  issue_invoice_start_request.dart       typed gateway request
  issue_invoice_command_validator.dart   shape validation only
  issue_invoice_command_handler.dart     thin RPC orchestration

modules/einvoice/application/lib/src/issuance/commands/publish_invoice/
  publish_invoice_command.dart           durable canonical payload envelope
  publish_invoice_command_handler.dart   three-action dispatch and closed outcome routing

modules/einvoice/application/lib/src/issuance/shared/
  publish_preparation_action.dart        callProvider | reconcileOnly | skip
  issuance_result_evidence_dto.dart      allow-listed typed evidence
  issuance_blocker_codes.dart            nested blocker reasons only

modules/einvoice/application/lib/src/ports/
  i_issuance_command_gateway.dart
  i_issuance_result_gateway.dart
  i_order_invoice_projection_read_gateway.dart
  i_me_invoice_provider_port.dart
  me_invoice_publish_*.dart

modules/einvoice/infrastructure/lib/src/domain/issuance/
  issuance_rpc_mapper.dart
  supabase_issuance_command_gateway.dart
  supabase_issuance_result_gateway.dart
  supabase_order_invoice_projection_read_gateway.dart

modules/einvoice/infrastructure/lib/src/adapters/misa/
  me_invoice_canonical_mapper.dart
  me_invoice_provider_adapter.dart

supabase/migrations/_drafts/
  007_einvoice_s2b_schema_and_rpc.sql
```

No new Dart `InvoiceIssuance`, `IssuanceAttempt`, `ElectronicInvoice`, or `ReconciliationCase` implementation is added. Their conceptual boundaries remain in harness/design; SQL RPCs and constraints enforce production mutations until a repository-backed Dart aggregate path exists.

## Frozen Interfaces

```dart
final class IssueInvoiceStartRequest {
  const IssueInvoiceStartRequest({
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.sourceVersion,
    required this.idempotencyKey,
    required this.acknowledgeWarnings,
  });
  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final String sourceVersion;
  final String idempotencyKey;
  final bool acknowledgeWarnings;
}

enum PublishPreparationAction { callProvider, reconcileOnly, skip }

final class PublishPreparationDto {
  const PublishPreparationDto({required this.action});
  final PublishPreparationAction action;
}

abstract interface class IIssuanceResultGateway {
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  });
  Future<RecordIssuanceResultDto> recordSuccess({required String tenantId, required String attemptId, required IssuanceResultEvidenceDto evidence});
  Future<RecordIssuanceResultDto> recordDefiniteFailure({required String tenantId, required String attemptId, required IssuanceResultEvidenceDto evidence});
  Future<RecordIssuanceResultDto> recordUndetermined({required String tenantId, required String attemptId, required IssuanceResultEvidenceDto evidence});
}

// ADD these two methods to the EXISTING `IMeInvoiceProviderPort`.
// DO NOT remove `authenticateAndListTemplates` or `previewUnpublished` —
// they are used by S1/S2a (capability sync, preview) and must remain.
abstract interface class IMeInvoiceProviderPort {
  // ...existing: authenticateAndListTemplates(...), previewUnpublished(...)

  void validateCanonical({
    required Map<String, Object?> canonicalInvoice,
  });
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  });
}
```

`IssuanceResultEvidenceDto` là closed factory-based DTO với `success`, `definiteFailure`, `undetermined`; chỉ nhận `idempotencyKey`, payload hash và allow-listed canonical provider/invoice identity, safe code/message hoặc reason code. Safe evidence map vào các cột canonical `provider_*`/`failure_*`, không vào JSON blob.

---

### Task 1: Freeze Corrected Harness Contracts and Traceability

**Files:**
- Modify: `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- Test: `scripts/ci/guard_theme_traceability.sh`
- Test: `scripts/ci/guard_theme_structure.sh`

**Interfaces:**
- Consumes: approved design §§3–7 and US-02/US-04.
- Produces: exact names/types/error nesting/deployment ownership used later.

- [ ] **Step 1: Record the pre-change contract evidence**

```bash
rg -n "IssueInvoiceCommand|record_issuance_result|record_issuance_undetermined|OpenReconciliationCaseCommand|poll_issuance_status" docs/themes/TH-08-e-invoice/harness/07-api-contracts.md
```

Expected: integer `expectedOrderVersion` and consolidated S3b result contract are visible.

- [ ] **Step 2: Freeze manual command and nested blocker envelope**

Use this command row:

```markdown
| `IssueInvoiceCommand` | tenantId, actorId, salesOrderId, sourceVersion (opaque String), idempotencyKey, acknowledgeWarnings? | `IssueInvoiceResultDto` (issuanceId, attemptId, status: `IssuanceAttemptStatus` — `preparing` on a fresh start, or the existing attempt status on replay) | NO_PERMISSION, NOT_FOUND, ORDER_NOT_COMPLETED, CONFIG_NOT_READY, ISSUANCE_NOT_READY, BUYER_DATA_INCOMPLETE, ALREADY_ISSUED, OPERATION_IN_PROGRESS, STATE_CHANGED, IDEMPOTENCY_CONFLICT |

> `status` on the command result is the `IssuanceAttemptStatus` enum (see `issue_invoice_result.dart`), **not** the string `PROCESSING`. `PROCESSING` is projection vocabulary only (`get_order_invoice_projection`); do not return it as a command-result status.
>
> This error list is the single canonical set (align design §9 to it). `BUYER_TAX_CODE_REQUIRED` is a **sub-detail** of `BUYER_DATA_INCOMPLETE`, not a separate top-level code. `CONFIG_NOT_READY` is included. `SOURCE_SNAPSHOT_UNAVAILABLE`/`BUYER_SOURCE_UNAVAILABLE` are nested `ISSUANCE_NOT_READY.details.blockers[]`, never top-level.
```

Freeze this error shape and state that blocker values are not top-level exception codes:

```json
{"code":"ISSUANCE_NOT_READY","details":{"blockers":["SOURCE_SNAPSHOT_UNAVAILABLE","BUYER_SOURCE_UNAVAILABLE"]}}
```

- [ ] **Step 3: Freeze result/dispatch contract**

```markdown
| Use case | RPC | Result |
| --- | --- | --- |
| Start/replay | `einvoice.issue_invoice` | PROCESSING/replayed attempt |
| Cross dispatch barrier | `einvoice.prepare_issuance_publish` | `callProvider \| reconcileOnly \| skip` |
| Success | `einvoice.record_issuance_success` | SUCCEEDED + COMPLETED/UNRESOLVED |
| Definite rejection | `einvoice.record_issuance_failure` | FAILED |
| Unknown | `einvoice.record_issuance_undetermined` | RECONCILING + pending case (`next_check_at` = durable handoff; no internal command) |
| Projection | `einvoice.get_order_invoice_projection` | display projection |
```

Add: “`issuance_attempts.idempotency_key` maps to MISA `RefID` as the provider correlation/duplicate-lookup key. Same key + same `intent_hash` replays; same key + different intent returns `IDEMPOTENCY_CONFLICT`. A `WAITING_RESULT` replay never calls publish again.”

- [ ] **Step 4: Freeze ownership and traceability**

```markdown
| EP-02/US-02/FR-01..08 | BE | S2b | Manual start, immutable attempt snapshot/hash, durable publish command | todo |
| EP-02/US-04/FR-01..07 | BE | S2b immediate-result subset | Direct outcome normalization, success/failure landing, unknown case/handoff | todo |
| EP-02/US-04 reconciliation execution/recovery | BE | S3b | Poll consumer, callbacks, case resolution, finalization recovery | todo |
```

Keep S2b `in_progress` until its S3b poll-consumer deployment dependency is satisfied.

- [ ] **Step 5: Verify and commit boundary when authorized**

```bash
bash scripts/ci/guard_theme_traceability.sh
bash scripts/ci/guard_theme_structure.sh
git diff --check
git add docs/themes/TH-08-e-invoice/harness/07-api-contracts.md docs/themes/TH-08-e-invoice/harness/05-traceability.md
git commit -m "docs(einvoice): freeze corrected S2b result boundary"
```

Expected: guards pass; commit only with authorization.

---

### Task 2: Implement Opaque Source Version and Typed Application Contracts

**Files:**
- Modify: `modules/einvoice/application/lib/src/issuance/commands/issue_invoice/issue_invoice_command.dart`
- Create/Modify: `modules/einvoice/application/lib/src/issuance/commands/issue_invoice/{issue_invoice_start_request.dart,issue_invoice_command_validator.dart,issue_invoice_command_handler.dart}`
- Create: `modules/einvoice/application/lib/src/issuance/shared/{issuance_blocker_codes.dart,publish_preparation_action.dart,issuance_result_evidence_dto.dart}`
- Create: `modules/einvoice/application/lib/src/ports/{i_issuance_command_gateway.dart,i_issuance_result_gateway.dart}`
- Modify: `modules/einvoice/application/lib/application.dart`
- Test: `modules/einvoice/application/test/issuance/{issue_invoice_command_contract_test.dart,issue_invoice_command_handler_test.dart}`

**Interfaces:**
- Consumes: Task 1 frozen source/blocker/action contract.
- Produces: frozen Dart interfaces for gateways and worker.

- [ ] **Step 1: Run upstream impact**

Run GitNexus upstream impact for `IssueInvoiceCommand`, `EInvoiceBlockedCodes`, and the application barrel. Report callers/risk; stop on HIGH/CRITICAL.

- [ ] **Step 2: Write RED tests**

```dart
test('sourceVersion stays opaque', () async {
  final gateway = FakeIssuanceCommandGateway.processing();
  await IssueInvoiceCommandHandler(gateway: gateway).handle(IssueInvoiceCommand(
    tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'order-1',
    sourceVersion: 'etag:7f9d-opaque', idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
  ));
  expect(gateway.lastRequest!.sourceVersion, 'etag:7f9d-opaque');
});

test('source unavailable is a blocker, not top-level code', () {
  expect(EInvoiceBlockedCodes.issuanceNotReady, 'ISSUANCE_NOT_READY');
  expect(EInvoiceIssuanceBlockers.sourceSnapshotUnavailable, 'SOURCE_SNAPSHOT_UNAVAILABLE');
});

test('same key with changed intent is a top-level idempotency conflict', () {
  expect(EInvoiceBlockedCodes.idempotencyConflict, 'IDEMPOTENCY_CONFLICT');
});
```

Validator tests assert blank sourceVersion invalid and `sales-v:abc/42` valid. Validator also asserts a non-UUID `idempotencyKey` (e.g. `issue-1`) is **invalid** and a canonical UUID (e.g. `88d18970-380a-4138-bbce-e25049ca9e3c`) is valid — it becomes the MISA GUID `RefID` unchanged (per the MISA doc: `RefID` is a globally-unique GUID, the duplicate-detection key, and status-lookup input). A source-text contract assertion verifies `einvoice_blocked_codes.dart` does not declare either issuance blocker reason.

- [ ] **Step 3: Verify RED**

```bash
cd modules/einvoice/application
dart test test/issuance/issue_invoice_command_contract_test.dart test/issuance/issue_invoice_command_handler_test.dart
```

Expected: compile/test failure because current command uses integer version.

- [ ] **Step 4: Implement minimal contract**

Set `IssueInvoiceCommand.sourceVersion` and `IssueInvoiceStartRequest.sourceVersion` to `String`; forward unchanged. Define:

```dart
abstract final class EInvoiceIssuanceBlockers {
  static const sourceSnapshotUnavailable = 'SOURCE_SNAPSHOT_UNAVAILABLE';
  static const buyerSourceUnavailable = 'BUYER_SOURCE_UNAVAILABLE';
}
```

Do not add them to `EInvoiceBlockedCodes`. Add `PublishPreparationAction` and the frozen result DTO/gateway interfaces above.
Add the separate top-level `EInvoiceBlockedCodes.idempotencyConflict = 'IDEMPOTENCY_CONFLICT'`; unlike source/buyer unavailable, this is a command-response code.

- [ ] **Step 5: Format, verify, commit boundary when authorized**

```bash
dart format modules/einvoice/application/lib/src/issuance modules/einvoice/application/lib/src/ports modules/einvoice/application/test/issuance
cd modules/einvoice/application
dart test test/issuance/issue_invoice_command_contract_test.dart test/issuance/issue_invoice_command_handler_test.dart
dart analyze
git add .
git commit -m "feat(einvoice): freeze opaque issuance source contract"
```

Expected: tests pass, analyzer 0 issues; commit only with authorization.

---

### Task 3: Draft Schema, Dispatch Barrier, Result Landing, and Reconciliation Handoff

**Files:**
- Create/Modify: `supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql`
- Create: `modules/einvoice/infrastructure/test/einvoice_s2b_sql_contract_test.dart`

**Interfaces:**
- Consumes: Tasks 1–2 contracts.
- Produces: atomic persistence/state transitions for Tasks 4–7.

- [ ] **Step 1: Write RED SQL contract tests**

```dart
expect(sql, contains('p_source_version text'));
expect(sql, isNot(contains('p_expected_order_version')));
expect(sql, isNot(contains('canonical_payload jsonb not null')));
expect(sql, contains('canonical_model_version text not null'));
expect(sql, contains('canonical_payload_hash varchar(128) not null'));
expect(sql, contains('intent_hash varchar(128) not null'));
expect(sql, contains('provider_connection_id uuid not null'));
expect(sql, contains('issuance_profile_id uuid not null'));
expect(sql, contains('internal_finalization_state'));
expect(sql, isNot(contains('provider_correlation_key')));
expect(sql, isNot(contains('safe_provider_evidence')));
expect(sql, contains("'CALL_PROVIDER'"));
expect(sql, contains("'RECONCILE_ONLY'"));
expect(sql, contains("'SKIP'"));
expect(sql, contains("target_type = 'ISSUANCE_ATTEMPT'"));
expect(sql, contains("reconciliation_purpose = 'DETERMINE_RESULT'"));
expect(sql, contains('next_check_at'));
expect(sql, isNot(contains("'einvoice.poll_issuance_status'"))); // case-scan handoff: no internal command enqueued in S2b
expect(sql, contains('exception when others then'));
expect(sql, contains("'UNRESOLVED'"));
expect(sql, contains('record_issuance_command_integrity_failure'));
expect(sql, contains("'COMMAND_INTEGRITY'"));
expect(sql, contains('created_at timestamptz not null default now()'));
expect(sql, contains('updated_at timestamptz not null default now()'));
```

Add DB hash-contract cases: an equivalent `jsonb` object with reordered keys produces the stored hash; changing one scalar or array order produces `STATE_CHANGED`. Also assert no private `sales.*`/`partner.*` reads; blocker values only occur in `ISSUANCE_NOT_READY` details; and the same idempotency key with a different `intent_hash` raises `IDEMPOTENCY_CONFLICT`.

- [ ] **Step 2: Verify RED**

```bash
cd modules/einvoice/infrastructure
dart test test/einvoice_s2b_sql_contract_test.dart
```

- [ ] **Step 3: Add persistence without canonical payload duplication**

Use the exact canonical §4.4.3 fields. The S2b-specific SQL must not rename, omit, or add parallel equivalents:

```sql
provider_connection_id uuid not null,
issuance_profile_id uuid not null,
idempotency_key varchar(150) not null,
intent_hash varchar(128) not null,
snapshot_schema_version integer not null,
attempt_snapshot jsonb not null,
canonical_model_version text not null,
canonical_payload_hash varchar(128) not null,
provider_interaction_reference varchar(255) null,
provider_request_reference varchar(255) null,
provider_invoice_reference varchar(255) null,
provider_result_code varchar(100) null,
provider_result_message text null,
failure_code varchar(100) null,
failure_message text null,
internal_finalization_state text not null default 'PENDING',
submitted_at timestamptz null,
provider_confirmed_at timestamptz null,
completed_at timestamptz null,
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
```

Every new S2b table (`invoice_issuances`, `issuance_attempts`, `electronic_invoices`, `invoice_reconciliation_cases`) carries the repo-standard common audit columns `created_at`/`updated_at` (`timestamptz not null default now()`), matching S2a (`005_einvoice_s2a_schema.sql`). These are convention columns, not the parallel business aliases forbidden above.

Add tenant-aware FKs, one ORIGINAL issuance, one-active-attempt partial index, `(tenant_id, idempotency_key)` uniqueness, one original invoice, and state CHECKs. Do not add `canonical_payload`, `provider_correlation_key`, a generic evidence JSON blob, or a duplicate dispatch timestamp.

Use the canonical §4.4.6 `invoice_reconciliation_cases` shape; do not create an S2b-specific simplified table:

```sql
create table einvoice.invoice_reconciliation_cases (
  id uuid primary key,
  tenant_id uuid not null,
  target_type text not null check (target_type in ('ISSUANCE_ATTEMPT','ELECTRONIC_INVOICE','INVOICE_DOCUMENT','DELIVERY_ATTEMPT')),
  target_id uuid not null,
  reconciliation_purpose text not null check (reconciliation_purpose in ('DETERMINE_RESULT','VERIFY_DOCUMENT','SYNC_PROVIDER_STATE','VERIFY_DELIVERY')),
  provider_connection_id uuid not null,
  provider_reference varchar(255) null,
  idempotency_key varchar(150) null,
  reason_code varchar(100) not null,
  status text not null check (status in ('PENDING','RESOLVED','UNRESOLVED')),
  attempt_count integer not null default 0,
  next_check_at timestamptz null,
  last_checked_at timestamptz null,
  latest_provider_interaction_reference varchar(255) null,
  resolved_at timestamptz null,
  resolution_code varchar(100) null,
  resolution_snapshot jsonb null,
  last_error_code varchar(100) null,
  last_error_message text null,
  correlation_id varchar(100) not null,
  opened_by_actor_type text not null,
  opened_by_actor_id uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index invoice_reconciliation_cases_one_pending
  on einvoice.invoice_reconciliation_cases (tenant_id, target_type, target_id, reconciliation_purpose)
  where status = 'PENDING';
```

- [ ] **Step 4: Implement replay-first `issue_invoice`**

Ordered algorithm: validate; build `v_intent jsonb := jsonb_build_object('operation','ISSUE_ORIGINAL','sales_order_id',p_sales_order_id,'source_version',p_source_version,'acknowledge_warnings',p_acknowledge_warnings)` and compute `intent_hash := encode(digest(convert_to(v_intent::text, 'UTF8'), 'sha256'), 'hex')`; lock same tenant/idempotency row before upstream reads; return it only when stored `intent_hash` equals computed hash, otherwise raise `IDEMPOTENCY_CONFLICT`; call only owned `einvoice.load_issuance_source_snapshot`; compare `source_version` by exact text equality; complete/lock buyer or return nested blockers; reject issued/active competition; build snapshot and runtime canonical JSON; persist the canonical §4.4.3 fields; enqueue canonical JSON plus the same `idempotency_key` as MISA `RefID` in `einvoice.publish_invoice` and processing outbox atomically.

- [ ] **Step 5: Implement one-way dispatch barrier**

`prepare_issuance_publish` recomputes command JSON SHA-256 and locks attempt:

It must calculate both start and replay values inside PostgreSQL as `encode(digest(convert_to(payload_jsonb::text, 'UTF8'), 'sha256'), 'hex')`. Dart only transports decoded JSON and the previously stored hash; it must not hash `jsonEncode`, map iteration, or HTTP bytes.

```text
PREPARING                    -> WAITING_RESULT + submitted_at; CALL_PROVIDER
SUBMITTED or WAITING_RESULT  -> RECONCILE_ONLY
RECONCILING/SUCCEEDED/FAILED -> SKIP
mismatch                     -> STATE_CHANGED
```

No `WAITING_RESULT` branch returns `CALL_PROVIDER`.

- [ ] **Step 6: Implement caught nested success finalization**

```sql
update einvoice.issuance_attempts
set provider_interaction_reference = v_provider_interaction_reference,
    provider_request_reference = v_provider_request_reference,
    provider_invoice_reference = v_provider_invoice_reference,
    provider_result_code = v_provider_result_code,
    provider_result_message = v_provider_result_message,
    provider_confirmed_at = now()
where id = p_attempt_id;
begin
  -- idempotent ElectronicInvoice/InvoiceSnapshot + COMPLETED + registered outbox
exception when others then
  update einvoice.issuance_attempts
  set status = 'SUCCEEDED', internal_finalization_state = 'UNRESOLVED'
  where id = p_attempt_id;
  -- enqueue issuance.processing; do not rethrow
end;
```

Completed replay returns the same invoice. Unresolved recovery is local-only in S3b.

- [ ] **Step 7: Implement failure and unknown contracts**

Failure (`record_issuance_failure`) accepts only explicit no-side-effect provider rejection and stores only canonical `provider_result_*`/`failure_*` fields. Add the separate system-origin RPC `record_issuance_command_integrity_failure(p_tenant_id, p_attempt_id, p_reason_code)` that sets the attempt `FAILED` with `failure_code = 'COMMAND_INTEGRITY'`, leaves all `provider_*` fields null, and enqueues a failed event — it makes no provider assertion and is never reachable from a MISA response, only from the processing dead-letter handler. Unknown atomically sets `RECONCILING`, generates `v_case_id := gen_random_uuid()` and `v_case_correlation_id := 'einvoice:reconcile:' || v_case_id::text` for a new case, then upserts the canonical pending case with `target_type=ISSUANCE_ATTEMPT`, `target_id=attemptId`, `reconciliation_purpose=DETERMINE_RESULT`, attempt `provider_connection_id`, `idempotency_key`, and case `correlation_id`. The pending case is written with `next_check_at` set (the durable handoff itself) plus the attempt `idempotency_key` (the MISA `RefID`) needed by S3b lookup; `latest_provider_interaction_reference` stays null in S2b (S3b populates it from provider-observation). On conflict it returns the stored pending case and its existing correlation ID and leaves `next_check_at` as-is. **No `einvoice.poll_issuance_status` internal command is enqueued** — S3b's poll consumer discovers pending cases by scanning `next_check_at <= now()`. Repeated landing reuses the same pending case (idempotent).

- [ ] **Step 8: Add RLS/projection and verify**

Projection maps active/reconciling/`SUCCEEDED+UNRESOLVED` to processing/no action, invoice to issued/view, definite failure to failed/issue.

```bash
cd modules/einvoice/infrastructure
dart test test/einvoice_s2b_sql_contract_test.dart
cd ../../..
melos run migrate:verify-policy -- --strict
git diff --check
```

Expected: tests/policy pass; draft is not applied.

- [ ] **Step 9: Commit boundary when authorized**

```bash
git add supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql modules/einvoice/infrastructure/test/einvoice_s2b_sql_contract_test.dart
git commit -m "feat(einvoice): draft safe S2b issuance transactions"
```

---

### Task 4: Implement Supabase Gateways and Error Mapping

**Files:**
- Create: `modules/einvoice/infrastructure/lib/src/domain/issuance/{issuance_rpc_mapper.dart,supabase_issuance_command_gateway.dart,supabase_issuance_result_gateway.dart,supabase_order_invoice_projection_read_gateway.dart}`
- Create/Modify: `modules/einvoice/infrastructure/test/support/fake_einvoice_rpc_supabase.dart`
- Create: `modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_gateways_test.dart`

**Interfaces:**
- Consumes: Tasks 2–3.
- Produces: scoped RPC-backed application ports.

- [ ] **Step 1: Write RED mapping tests**

Assert exact start params:

```dart
{'p_tenant_id':'tenant-1','p_actor_id':'actor-1','p_sales_order_id':'order-1',
 'p_source_version':'etag:7f9d-opaque','p_idempotency_key':'88d18970-380a-4138-bbce-e25049ca9e3c',
 'p_acknowledge_warnings':true}
```

Assert exhaustive mapping of `CALL_PROVIDER`, `RECONCILE_ONLY`, `SKIP`; nested blockers map to `IssuanceNotReadyException.blockers`; no `IIssuanceSourceSnapshotPort` exists.

- [ ] **Step 2: Verify RED, implement and fail closed**

```bash
cd modules/einvoice/infrastructure
dart test test/domain/issuance/supabase_issuance_gateways_test.dart
```

Use `SupabaseSchemaRpcClient(schema: 'einvoice')`, one RPC per method, allow-listed evidence only. Unknown action/malformed evidence/missing projection state throws contract/system exception; never default to provider call.

- [ ] **Step 3: Format, verify, commit boundary when authorized**

```bash
dart format modules/einvoice/infrastructure/lib/src/domain/issuance modules/einvoice/infrastructure/test/domain/issuance modules/einvoice/infrastructure/test/support
cd modules/einvoice/infrastructure
dart test test/domain/issuance/supabase_issuance_gateways_test.dart
dart analyze
git add .
git commit -m "feat(einvoice): add typed S2b RPC gateways"
```

Expected: pass, 0 issues; commit only with authorization.

---

### Task 5: Implement MISA Mapping with RefID as Correlation Identity

**Files:**
- Create/Modify: `modules/einvoice/application/lib/src/ports/me_invoice_publish_*.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/{me_invoice_canonical_mapper.dart,me_invoice_provider_adapter.dart}`
- Modify as required: `packages/vet45_misa/lib/src/e_invoice/**`
- Test: `modules/einvoice/infrastructure/test/me_invoice_provider_adapter_publish_test.dart`
- Test: `packages/vet45_misa/test/e_invoice/me_invoice_client_test.dart`

**Interfaces:**
- Consumes: provider-neutral command and attempt `idempotencyKey`.
- Produces: closed safe outcomes.

- [ ] **Step 1: Run impact and write RED classification tests**

Impact: `IMeInvoiceProviderPort`, `MeInvoiceClient`, `MeInvoiceHttp`, response parser. Tests:

```text
correlated success                  -> success
explicit proven no-side-effect      -> definiteFailure
timeout/reset/malformed/uncorrelated -> undetermined
DuplicateInvoiceRefID               -> undetermined, never definiteFailure
```

Assert MISA `RefID` equals the persisted attempt `idempotencyKey`; it is a provider correlation/lookup identity, not proof that repeated publish is safe.

**Frozen (B2):** `DuplicateInvoiceRefID` always classifies as `undetermined` in S2b — even if the duplicate response carries a correlatable invoice identity for the same `RefID`. S2b never auto-maps a duplicate to `success`/`definiteFailure`; S3b upgrades it via `RefID` status-lookup. Add a test asserting a duplicate response *with* an embedded invoice number still yields `undetermined`.

- [ ] **Step 2: Verify RED and implement closed classification**

```bash
cd packages/vet45_misa
dart test test/e_invoice/me_invoice_client_test.dart
cd ../../modules/einvoice/infrastructure
dart test test/me_invoice_provider_adapter_publish_test.dart
```

Implement `IMeInvoiceProviderPort.validateCanonical(...)` as a synchronous pure preflight backed by `MeInvoiceCanonicalMapper`. Validate canonical schema/series/signing/buyer/lines/totals before the handler crosses the dispatch barrier. Invalid canonical payload is an internal pre-dispatch command-integrity failure: during bounded retries it does not call MISA and does not call the provider-rejection `record_issuance_failure` path, keeping the attempt non-terminal so a transient fault can retry. Because `validateCanonical` is deterministic, retries will not recover a genuinely corrupt payload; to avoid a permanently stuck `PREPARING` attempt, define a terminal dead-letter landing with its own mutation contract: the dedicated RPC `einvoice.record_issuance_command_integrity_failure(p_tenant_id, p_attempt_id, p_reason_code)` (added in Task 3) is invoked by the processing dead-letter handler when bounded retries for a canonical-integrity fault are exhausted. It transitions the attempt to `FAILED` with `failure_code = 'COMMAND_INTEGRITY'` and null `provider_*` fields, and enqueues a system-origin failed event. This is a system fault, explicitly distinct from a provider rejection (no MISA call ever occurred, no provider evidence): it is a **separate RPC from `record_issuance_failure`**, so the two are never conflated. After HTTP invocation, anything not proven no-side-effect is undetermined. Outcomes/logs exclude tokens, headers, credentials and raw maps.

- [ ] **Step 3: Format, verify, commit boundary when authorized**

```bash
dart format packages/vet45_misa/lib packages/vet45_misa/test modules/einvoice/infrastructure/lib/src/adapters/misa modules/einvoice/infrastructure/test/me_invoice_provider_adapter_publish_test.dart
cd packages/vet45_misa
dart test
dart analyze
cd ../../modules/einvoice/infrastructure
dart test test/me_invoice_provider_adapter_publish_test.dart
dart analyze
git add packages/vet45_misa modules/einvoice/application/lib/src/ports modules/einvoice/infrastructure
git commit -m "feat(einvoice): classify MISA publish outcomes safely"
```

Expected: pass, 0 issues; commit only with authorization.

---

### Task 6: Implement Durable Publish Command and No-Republish Worker

**Files:**
- Create: `modules/einvoice/application/lib/src/issuance/commands/publish_invoice/{publish_invoice_command.dart,publish_invoice_command_handler.dart}`
- Create: `modules/einvoice/application/test/issuance/{publish_invoice_command_json_test.dart,publish_invoice_command_handler_test.dart}`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/processing_module.dart`
- Regenerate: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/*.g.dart`
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_publish_invoice_worker_test.dart`

**Interfaces:**
- Consumes: Tasks 2, 4, 5.
- Produces: durable at-most-one-provider-call orchestration.

- [ ] **Step 1: Write RED serialization/action tests**

Command JSON has exactly the AD-03 fields: `commandType`, `tenantId`, `attemptId`, `canonicalInvoice`, `payloadHash`, `idempotencyKey` — no `correlation` or `invoice series` field. The command carries a JSON value, not serialized canonical bytes; hash calculation remains DB-side. Assert:

```text
callProvider    -> provider once, one typed result
reconcileOnly   -> provider zero, undetermined once with DISPATCH_STATE_UNCERTAIN
skip            -> provider/result zero
invalid canonical -> validateCanonical throws before prepare; provider/result zero
timeout         -> undetermined, normal completion
duplicate RefID -> undetermined, never definite failure
```

- [ ] **Step 2: Verify RED and implement exhaustive routing**

```dart
providerPort.validateCanonical(canonicalInvoice: command.canonicalInvoice);
final preparation = await resultGateway.preparePublish(
  tenantId: command.tenantId,
  attemptId: command.attemptId,
  idempotencyKey: command.idempotencyKey,
  payloadHash: command.payloadHash,
  canonicalInvoice: command.canonicalInvoice,
);

switch (preparation.action) {
  case PublishPreparationAction.skip:
    return;
  case PublishPreparationAction.reconcileOnly:
    await resultGateway.recordUndetermined(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
      evidence: IssuanceResultEvidenceDto.undetermined(
        idempotencyKey: command.idempotencyKey,
        payloadHash: command.payloadHash,
        reasonCode: 'DISPATCH_STATE_UNCERTAIN',
      ),
    );
    return;
  case PublishPreparationAction.callProvider:
    break;
}
```

Only `callProvider` invokes MISA; map its closed outcome exhaustively. `IssuanceResultEvidenceDto` and all result gateways correlate by tenant + attemptId + persisted idempotencyKey + payloadHash; no attempt-level correlation-id column is introduced.

**Existing `RecordIssuanceResultCommand` (raw `Map providerResult` + `correlationId`) stays DORMANT in S2b.** The immediate-result path calls `IIssuanceResultGateway` directly; it does not dispatch `RecordIssuanceResultCommand`. Do not delete it (its generated access metadata is entangled with uncommitted S2a work) and do not wire it into the publish path. S3b will retype it (raw Map → typed evidence) per design §6.3/§7.2. Add a test asserting the publish handler never dispatches `RecordIssuanceResultCommand`, and a `// dormant until S3b` marker on the command.

- [ ] **Step 3: Preserve same-series sequential execution**

Use existing sequential worker loop; do not add parallel E-Invoice dispatch. Test two same-series commands and assert `prepare-1,publish-1,result-1,complete-1,prepare-2,publish-2,result-2,complete-2`.

- [ ] **Step 4: Generate, verify, commit boundary when authorized**

```bash
cd /Users/macbook/Documents/vet45
melos run codegen
rg -n "PublishInvoiceCommandHandler|einvoice.publish_invoice" modules/einvoice/infrastructure/lib/src/configuration/processing/generated
cd modules/einvoice/application
dart test test/issuance/publish_invoice_command_json_test.dart test/issuance/publish_invoice_command_handler_test.dart
cd ../infrastructure
dart test test/configuration/einvoice_publish_invoice_worker_test.dart
git add modules/einvoice/application modules/einvoice/infrastructure
git commit -m "feat(einvoice): add no-republish publish worker"
```

Expected: registry entry present and tests pass; generated files not hand-edited; commit only when authorized.

---

### Task 7: Add Projection, DI, Outbox, and S3b Handoff Composition

**Files:**
- Create/Modify: `modules/einvoice/application/lib/src/issuance/queries/get_order_invoice_projection/**`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/{data_access,processing,outbox}/**`
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_s2b_composition_test.dart`
- Modify: `apps/messaging_worker/test/messaging_worker_loop_test.dart`

**Interfaces:**
- Consumes: Tasks 3–6.
- Produces: resolvable engine and explicit poll-handoff boundary.

- [ ] **Step 1: Run impact and write RED composition tests**

Impact `EinvoiceDataAccessModule`, `EinvoiceProcessingModule`, `EinvoiceOutboxModule`. Assert isolated container registers three gateways, deserializes publish, maps processing/failed/registered events, and that the generated internal-command registry contains **no** `einvoice.poll_issuance_status` entry (the unknown-result handoff is a pending ReconciliationCase, not an internal command).

- [ ] **Step 2: Implement projection and registrations**

Projection handler delegates only to its read gateway. Register command/result/projection gateways against module-private schema RPC client. Use generated CQRS/internal-command registration. Do not register a Dart source-snapshot port.

- [ ] **Step 3: Verify S3b deployment boundary**

Because the unknown-result handoff is a pending `ReconciliationCase` (data), not an internal command, the shared worker never claims/deserializes an unknown `einvoice.poll_issuance_status` type, so there is no poison-row hazard. Assert in composition/worker tests that: (a) no `einvoice.poll_issuance_status` internal command is ever enqueued by `record_issuance_undetermined`; (b) `record_issuance_undetermined` writes a pending case with `next_check_at`; (c) the internal-command registry does not recognize `einvoice.poll_issuance_status`. Pending cases simply wait, unread, until the S3b poll consumer scans them.

- [ ] **Step 4: Verify and commit boundary when authorized**

```bash
cd modules/einvoice/infrastructure
dart test test/configuration/einvoice_s2b_composition_test.dart
cd ../../../apps/messaging_worker
dart test test/messaging_worker_loop_test.dart
git add modules/einvoice/application modules/einvoice/infrastructure apps/messaging_worker/test/messaging_worker_loop_test.dart
git commit -m "feat(einvoice): compose S2b issuance engine"
```

Expected: pass; publish route and poll-handoff ownership are explicit.

---

### Task 8: Full Verification and Honest Closeout

**Files:**
- Modify: `docs/themes/TH-08-e-invoice/harness/{04-slice-roadmap.md,05-traceability.md}`
- Modify: `docs/themes/TH-08-e-invoice/README.md`

**Interfaces:**
- Consumes: Tasks 1–7 evidence.
- Produces: status without overclaiming production readiness.

- [ ] **Step 1: Verify touched formatting and focused packages**

Run `dart format --output=none --set-exit-if-changed` on explicit touched Dart files, then:

```bash
cd modules/einvoice/application && dart test && dart analyze
cd ../infrastructure && dart test && dart analyze
cd ../../../packages/vet45_misa && dart test && dart analyze
cd ../../apps/messaging_worker && dart test && dart analyze
```

Expected: focused tests pass; analyzers 0 issues.

- [ ] **Step 2: Run workspace/harness verification**

```bash
cd /Users/macbook/Documents/vet45
melos bootstrap
melos run codegen
melos run analyze
melos run test
melos run migrate:verify-policy -- --strict
bash scripts/ci/verify_harness.sh
git diff --check
```

Record exact exits; do not hide unrelated baseline failures.

- [ ] **Step 3: Run GitNexus change-scope review**

Run `detect_changes(scope: compare, base_ref: main)`. Expected scope: TH-08 docs, E-Invoice application/infrastructure, MISA, messaging-worker tests, one draft SQL.

- [ ] **Step 4: Close traceability honestly**

Mark US-02 and US-04 immediate-result rows done only after focused verification. Keep S2b BE `in_progress` while authoritative source contracts, migration promotion, or S3b poll consumer deployment remains absent. Record:

```markdown
S2b verifies manual start and immediate provider-result landing through Dart fakes,
RPC-shape/SQL contract tests and worker tests. Production remains fail-closed until
authoritative Theme 05/Theme 03 source contracts and the approved SQL migration land.
Unknown-result cases land as pending ReconciliationCases with next_check_at and are
inert until the S3b poll consumer scans them, so S2b carries no poison-row risk; those
cases are only acted on once S3b ships its poll consumer.
```

- [ ] **Step 5: Re-run guards and commit boundary when authorized**

```bash
bash scripts/ci/guard_theme_traceability.sh
bash scripts/ci/guard_theme_structure.sh
git diff --check
git add docs/themes/TH-08-e-invoice modules/einvoice packages/vet45_misa apps/messaging_worker supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql
git commit -m "feat(einvoice): complete corrected S2b backend slice"
```

---

## DDD Boundary Summary

1. **Lifecycle:** start -> dispatch barrier -> success/definite failure/reconciling; unknown owns a pending reconciliation process.
2. **Bounded contexts:** E-Invoice owns issuance/result/invoice; Sales/Partner own source data; MISA is external.
3. **Aggregates/process:** conceptual issuance + attempts, ElectronicInvoice, and ReconciliationCase; no unused Dart mirror in S2b.
4. **Rules:** one active attempt, canonical §4.4 field set, same-key/same-intent replay, same-key/different-intent conflict, immutable snapshot/hash, opaque version equality, one dispatch, one pending case, idempotent finalization.
5. **Commands:** IssueInvoice is US-02; direct result is US-04 subset; polling/resolution/recovery is S3b.
6. **Queries:** order projection returns DTO; provider status lookup belongs to S3b.
7. **Domain events:** started, undetermined, failed, succeeded, registered.
8. **Integration events:** processing, failed, registered. The S3b poll handoff is a pending ReconciliationCase (`next_check_at`), not an enqueued internal command.
9. **Services:** canonical mapping and outcome classification are policies/adapters, not mutation authorities.
10. **Snapshots/ports:** canonical AttemptSnapshot/intent/hash fields; payload in command; source access SQL-owned; JSON hash is DB-side `jsonb` only.
11. **Anti-patterns rejected:** persisted runtime canonical, parallel schema fields, numeric external version, raw result map, retry-by-RefID, provider-failure classification for corrupt command, unused aggregate.
12. **Review:** boundaries pass after Tasks 1–3; readiness remains conditional on source contracts, migration and S3b deployment.

## Self-Review Notes

- **Coverage:** US-02 FR-01..08 plus named direct-result US-04 responsibilities map to Tasks 1–7; poll execution/callback/resolution/recovery remain outside.
- **No provider retry assumption:** post-barrier replay is `reconcileOnly`/`skip`; RefID never authorizes publish.
- **Persistence:** no `canonical_payload` attempt field or parallel schema field; the exact Theme §4.4.3/§4.4.6 models are used.
- **Idempotency:** equal key/equal `intent_hash` replays; equal key/different hash is `IDEMPOTENCY_CONFLICT` before upstream reads.
- **Hashing:** PostgreSQL creates and verifies `sha256(jsonb::text)`; Dart transports JSON only, and regression tests cover reordered object keys versus changed arrays/scalars.
- **Authority:** no dead Dart aggregate task; RPCs/constraints enforce runtime mutations.
- **Types/errors:** opaque String sourceVersion; blocker reasons nested under `ISSUANCE_NOT_READY.details.blockers[]`.
- **Success durability:** outer evidence + caught inner finalization has explicit contract tests.
- **Deployment:** S2b deploys safely ahead of S3b because the unknown-result handoff is a pending ReconciliationCase (data), not an internal command; those cases stay inert until the S3b poll consumer scans them. No queue-hold policy or poison-row handling is required.
- **Schema:** one draft SQL file, no apply/promotion/timestamped migration.
