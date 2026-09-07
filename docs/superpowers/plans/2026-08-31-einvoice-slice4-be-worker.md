# TH-08 Slice 4 BE and Worker Implementation Plan

> **For agentic workers:** Thực thi trên **branch hiện tại** (working tree hiện tại). **Không** dùng `superpowers:using-git-worktrees`, không tạo worktree isolated, không checkout branch mới. **Không** `git commit` sau mỗi task — commit chỉ khi người dùng yêu cầu rõ. Dùng `superpowers:subagent-driven-development` (recommended) hoặc `superpowers:executing-plans` để thực thi task-by-task. Dùng `superpowers:test-driven-development` cho mọi behavior change và `superpowers:verification-before-completion` trước khi báo hoàn thành.

**Goal:** Hoàn tất lane BE + Worker của TH-08 Slice 4 cho ba capability: xem bản hóa đơn chính thức, tải PDF/XML, và ghi nhận trạng thái quan sát từ MISA; ambiguous provider outcomes không tạo operation cạnh tranh, mọi resource access kiểm tra SalesOrder scope, và mọi provider interaction được audit/correlate an toàn.

**Architecture:** Public S4 RPCs kiểm tra actor, E-invoice permission và source-owned `sales.can_access_sales_order` trước khi resolve ElectronicInvoice. Official view và document request có versioned technical operation; document capability được kiểm tra trước insert/enqueue, retry kỹ thuật giữ nguyên operation, và ambiguous exhaustion chuyển `CHECK_REQUIRED` thay vì `FAILED`. Mỗi provider-call attempt có một canonical `ProviderInteractionRecord`; chỉ provider fact thực nhận mới tạo append-only `ProviderObservationRecord`, còn timeout ghi interaction failure và mismatch/not-found phát reliable attention event qua outbox. Observation chỉ được enqueue bởi explicit policy/support trigger, idempotent theo trigger identity chứ không theo ngày, và không quét toàn bộ invoice.

**Tech Stack:** Dart >=3.11.1 <4.0.0, Vet45 CQRS/codegen, Supabase/Postgres draft SQL, Supabase private Storage, `packages/vet45_misa`, `apps/messaging_worker`, `crypto` SHA-256, package:test.

**Spec:** `docs/themes/TH-08-e-invoice/harness/01-domain-model.md`, `02-module-map.md`, `03-architecture-and-flows.md`, `04-slice-roadmap.md`, `05-traceability.md`, `07-api-contracts.md`, và EP-03 US-01/US-02/US-03 trong `docs/themes/TH-08-e-invoice/Theme-8-e-invoice.md`.

**Global Constraints:**

- Phạm vi chỉ gồm S4 BE + Worker. Không làm SG-06/FE, delivery S5, adjustment/replacement S6, hoặc migration production.
- Chỉ tạo SQL trong `supabase/migrations/_drafts/`; không tạo file timestamp, không promote, không chạy `supabase db reset`, không tuyên bố production DB đã ship.
- ERP host không được gọi MISA HTTP. `enableMisaHttp: false` phải tiếp tục đăng ký worker-only guard; chỉ `apps/messaging_worker` dùng adapter thật.
- CI không gọi MISA live. Integration dùng `FakeMeInvoiceClient` và fake/in-memory document storage.
- Application không import Infrastructure/Supabase; Domain không import Supabase, Flutter, GetIt hoặc module khác; UI không ghi PostgREST trực tiếp.
- RPC từ ERP phải kiểm tra `auth.uid()`, `p_actor_id = auth.uid()` và `iam.has_permission(...)`. RPC worker phải kiểm tra JWT role là `service_role` và không nhận `actorId` giả.
- Mọi public S4 RPC nhận `salesOrderId` phải gọi source-owned `sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id)` và trả `NOT_FOUND` khi ngoài scope. Không đọc bảng Sales trực tiếp từ E-invoice.
- `RequestInvoiceDocumentCommand` phải fail closed trước khi tạo operation nếu `supported_document_types` thiếu loại được yêu cầu; trả `DOCUMENT_UNAVAILABLE` và không insert document/internal command.
- Không lưu credential, access token, HTTP header, chữ ký, raw MISA response hoặc raw observation payload. Chỉ lưu allow-listed provider evidence.
- Observation request dùng caller-owned `triggerId` làm idempotency identity. Replay cùng trigger reuses command; hai trigger hợp lệ khác nhau trong cùng ngày không được collapse. Rate protection là technical concurrency/backoff policy, không phải daily business uniqueness.
- `ProviderInteractionRecord` có cardinality một record cho mỗi outbound provider-call attempt hoặc inbound callback. Identity/request metadata immutable; finalize terminal fields đúng một lần bằng optimistic version. Không dùng record này làm preview operation/read model.
- Official viewer URL/token và document signed URL chỉ được trả khi resource `AVAILABLE`, có TTL 5 phút và được sinh sau permission check. Không lưu signed document URL lâu dài. Private Storage chỉ cấp authenticated `SELECT` qua policy tenant + `einvoice.download_document`; không cấp client `INSERT`/`UPDATE`/`DELETE`.
- Request replay khi operation đang `PENDING`, `CHECK_REQUIRED` hoặc resource còn `AVAILABLE` phải trả lại operation hiện hữu. `CHECK_REQUIRED` là unresolved lock: re-arm/retry cùng `operationId`; chỉ definite `FAILED` mới cho phép generation/version mới.
- `InvoiceDocumentStatus` dùng đúng Dart enum `pending`, `available`, `failed`, `checkRequired`; wire/SQL dùng `PENDING`, `AVAILABLE`, `FAILED`, `CHECK_REQUIRED` và mapper chịu trách nhiệm chuyển đổi.
- Không sửa thủ công file `.g.dart`; chạy `melos run codegen` rồi review generated diff.
- Thực thi trên **branch hiện tại**; không tạo worktree isolated, không checkout branch mới, không stash/copy/bỏ thay đổi uncommitted.
- Working tree hiện có nhiều thay đổi người dùng/S1-S3. Giữ nguyên chúng; chỉ sửa file liên quan task. **Không** tự `git commit` sau mỗi task — các task gate chỉ verify; commit khi người dùng yêu cầu (gợi ý message nằm ở mỗi gate nếu cần).
- S4 bắt đầu từ state S1-S3 hiện tại (draft 007/008/009 và code worker, kể cả uncommitted). Nếu dependency chỉ tồn tại uncommitted, tiếp tục trên branch hiện tại; không tự stash, commit hoặc bỏ thay đổi — hỏi người dùng nếu base thiếu và không thể implement an toàn.
- S4 public SQL có external gate `sales.can_access_sales_order`. Nếu Theme 05/Sales chưa cung cấp implementation source-owned, Dart lane vẫn test bằng fake nhưng BE database lane giữ `in_progress`; không thay bằng allow-all hoặc E-invoice cross-table query.
- Trước khi sửa symbol hiện hữu phải chạy GitNexus upstream impact và báo blast radius; nếu HIGH/CRITICAL thì dừng xin chỉ dẫn. Trước khi người dùng commit hoặc chốt toàn plan, chạy `detect_changes(scope: compare, base_ref: main)`.

---

## Frozen Slice 4 contracts

```dart
abstract interface class IElectronicInvoiceCommandGateway {
  Future<OfficialInvoiceViewDto> requestOfficialView({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required InvoiceDocumentType documentType,
    required String idempotencyKey,
  });

  Future<OfficialViewOperationContextDto?> loadOfficialViewContext({
    required String tenantId,
    required String operationId,
  });

  Future<InvoiceDocumentOperationContextDto?> loadDocumentContext({
    required String tenantId,
    required String operationId,
  });

  Future<void> recordOfficialViewResult(OfficialViewResultRecord record);
  Future<void> recordDocumentResult(InvoiceDocumentResultRecord record);
  Future<void> recordProviderObservation(ProviderObservationRecord record);
}

abstract interface class IElectronicInvoiceReadGateway {
  Future<ElectronicInvoiceDetailDto> getDetail({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<InvoiceDocumentsDto> getDocuments({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<ProviderObservationDto?> getLatestObservation({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}

abstract interface class IElectronicInvoiceProviderPort {
  Future<OfficialViewProviderOutcome> fetchOfficialView(
    ElectronicInvoiceProviderContextDto context,
  );
  Future<InvoiceDocumentProviderOutcome> downloadDocument(
    ElectronicInvoiceProviderContextDto context,
    InvoiceDocumentType documentType,
  );
  Future<ProviderObservationOutcome> observe(
    ElectronicInvoiceProviderContextDto context,
  );
}

abstract interface class IInvoiceDocumentStoragePort {
  Future<StoredInvoiceDocumentDto> store({
    required String tenantId,
    required String electronicInvoiceId,
    required InvoiceDocumentType documentType,
    required int documentVersion,
    required List<int> bytes,
  });
}

abstract interface class IProviderInteractionGateway {
  Future<ProviderInteractionRecord> start({
    required String tenantId,
    required String providerConnectionId,
    required ProviderInteractionDirection direction,
    required String operationType,
    required String targetType,
    required String targetId,
    required String correlationId,
    required String requestReference,
  });

  Future<ProviderInteractionRecord> finalize({
    required String tenantId,
    required String interactionReference,
    required int expectedVersion,
    required ProviderInteractionOutcome outcome,
    String? responseReference,
    String? providerReference,
    String? safeErrorCode,
  });
}
```

Identity và retry policy cố định:

| Resource | Logical identity | Internal command | Retry | Terminal |
|---|---|---|---:|---|
| Official view | `{electronicInvoiceId}:official_view:{generation}` | `einvoice.fetch_official_view` | tối đa 2 attempts trên cùng operation | `AVAILABLE`, definite `FAILED`, ambiguous `CHECK_REQUIRED` |
| PDF/XML | `{electronicInvoiceId}:{documentType}:{generation}` | `einvoice.download_invoice_document` | tối đa 3 attempts trên cùng operation | `AVAILABLE`, definite `FAILED`, ambiguous `CHECK_REQUIRED` |
| Observation | explicit trigger identity `{tenantId}:{invoiceId}:{triggerId}` | `einvoice.poll_provider_observation` | max 1 in-flight call/connection + generic worker backoff | interaction recorded; observation chỉ khi có provider fact |

Signed document URL được tạo mới ở mỗi read query sau permission check; do đó URL hết hạn không tạo document version mới. Gọi lại `RequestInvoiceDocumentCommand` trên document AVAILABLE tạo/reuse technical access operation trỏ tới cùng document row và tạo signed URL mới, không tải lại từ MISA. Official view là URL do provider trả nên hết TTL sẽ tạo generation mới ở request tiếp theo.

## File map

```text
modules/einvoice/domain/lib/src/electronic_invoice/
  services/invoice_document_content_policy.dart           Pure PDF/XML validation
  services/official_view_operation_policy.dart             Replay/refresh decision
  provider_connection/provider_capabilities_snapshot.dart  PDF/XML capability gate

modules/einvoice/application/lib/src/electronic_invoice/
  commands/request_official_invoice_view/                  Public request + validator + handler
  commands/request_invoice_document/                       Public request + validator + handler
  commands/fetch_official_invoice_view/                    Serializable worker command + handler
  commands/download_invoice_document/                      Serializable worker command + handler
  commands/poll_provider_observation/                      Serializable worker command + handler
  queries/get_electronic_invoice_detail/                   Detail read handler
  queries/get_invoice_documents/                           Document read handler + split DTO
  queries/get_latest_provider_observation/                 Latest observation read handler
  shared/                                                   Typed operation/provider/storage records
  ports/                                                    Command/read/provider/storage boundaries

modules/einvoice/integration_events/lib/src/
  provider_observation_attention_required_integration_event.dart
                                                             Safe mismatch/not-found handoff

modules/einvoice/infrastructure/lib/src/
  adapters/misa/                                            S4 MISA adapter/classifiers + host guard
  data_access/                                              S4 Supabase RPC gateways/read mappers
  provider_interactions/                                    Safe provider-call audit writer
  storage/                                                  Private bucket upload + SHA-256
  configuration/data_access/data_access_module.dart         DI
  configuration/processing/                                Generated registry + worker seeding

supabase/migrations/_drafts/
  001_einvoice_s1_schema_configuration.sql                  Freeze canonical ProviderInteractionRecord while draft
  005_einvoice_s2a_schema.sql                               Move preview operation state out of interaction audit
  006_einvoice_s2a_rpc.sql                                  Point preview RPCs at technical preview operations
  010_einvoice_s4a_official_view.sql
  011_einvoice_s4b_documents.sql
  012_einvoice_s4c_provider_observations.sql
```

---

### Task 0: Repair the frozen S4 contracts before feature implementation

**Files:**

- Modify: `docs/themes/TH-08-e-invoice/Theme-8-e-invoice.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/01-domain-model.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/02-module-map.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/03-architecture-and-flows.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md`
- Modify: `modules/einvoice/domain/lib/src/provider_connection/provider_capabilities_snapshot.dart`
- Create: `modules/einvoice/domain/test/provider_connection/provider_capabilities_snapshot_test.dart`
- Modify: `supabase/migrations/_drafts/001_einvoice_s1_schema_configuration.sql`
- Modify: `supabase/migrations/_drafts/005_einvoice_s2a_schema.sql`
- Modify: `supabase/migrations/_drafts/006_einvoice_s2a_rpc.sql`
- Create: `modules/einvoice/infrastructure/test/electronic_invoice/einvoice_s4_contract_repair_test.dart`
- Create: `modules/einvoice/infrastructure/test/electronic_invoice/provider_interaction_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/electronic_invoice/invoice_preview_operation_sql_contract_test.dart`

**Interfaces:**

- Consumes: canonical field conventions, US-01 SalesOrder scope rules, US-02 EC-02/EC-03, US-03 interaction/correlation/attention requirements.
- Produces: `ProviderCapabilitiesSnapshot.supportedDocumentTypes`, frozen unresolved-operation semantics, source-owned `sales.can_access_sales_order` dependency, complete `ProviderInteractionRecord` schema, explicit observation-trigger policy and exact Task 1-9 contracts.

- [ ] **Step 1: Write the failing contract tests**

```dart
test('capability snapshot distinguishes PDF and XML support', () {
  const snapshot = ProviderCapabilitiesSnapshot(
    supportsEmailDelivery: true,
    templateCount: 1,
    supportedDocumentTypes: {InvoiceDocumentType.pdf},
  );
  expect(snapshot.supports(InvoiceDocumentType.pdf), isTrue);
  expect(snapshot.supports(InvoiceDocumentType.xml), isFalse);
});

test('S4 contract freezes ambiguous and scope requirements', () {
  final apiContract = File(
    '../../../docs/themes/TH-08-e-invoice/harness/07-api-contracts.md',
  ).readAsStringSync();
  expect(apiContract, contains('CHECK_REQUIRED is an unresolved lock'));
  expect(apiContract, contains('sales.can_access_sales_order'));
  expect(apiContract, isNot(contains('seed_due_provider_observation_commands')));
  expect(apiContract, contains('triggerId'));
  expect(apiContract, isNot(contains('UTC-day')));
});

test('provider interaction contract is typed and payload-free', () {
  final sql = File(
    '../../../supabase/migrations/_drafts/'
    '001_einvoice_s1_schema_configuration.sql',
  ).readAsStringSync();
  expect(sql, contains('correlation_id uuid not null'));
  expect(sql, contains("direction in ('OUTBOUND','INBOUND_CALLBACK')"));
  expect(sql, contains('request_reference varchar(255) not null'));
  expect(sql, isNot(contains('request_summary')));
  expect(sql, isNot(contains('response_summary')));
});
```

Run:

```bash
cd modules/einvoice/domain && dart test test/provider_connection/provider_capabilities_snapshot_test.dart
cd modules/einvoice/infrastructure && dart test test/electronic_invoice/einvoice_s4_contract_repair_test.dart test/electronic_invoice/provider_interaction_sql_contract_test.dart test/electronic_invoice/invoice_preview_operation_sql_contract_test.dart
```

Expected: FAIL because the capability field and repaired frozen clauses do not exist.

- [ ] **Step 2: Freeze operation and capability semantics in canonical docs**

Add these exact rules to Theme/harness/API contracts:

```text
PENDING --provider success--> AVAILABLE
PENDING --definite rejection/no document--> FAILED
PENDING --auth/config/content uncertain--> CHECK_REQUIRED
PENDING --timeout/5xx/transport ambiguous--> retry same operation
ambiguous retry exhaustion --> CHECK_REQUIRED; keep logical resource lock
Request replay at CHECK_REQUIRED re-arms the same operation; no competing generation
```

Define `supported_document_types = ['PDF','XML']`; missing/unknown capability fails closed before operation creation. Define public access as actor + E-invoice permission + `sales.can_access_sales_order`; outside-scope response is `NOT_FOUND`.

- [ ] **Step 3: Freeze observation interaction and trigger semantics**

Document:

```text
Timeout/unavailable records interaction failure and creates no fabricated observation.
Each outbound provider-call attempt or inbound callback creates one ProviderInteractionRecord.
Provider fact creates append-only ProviderObservationRecord referencing the interaction.
NOT_FOUND/MISMATCH appends observation and outbox event einvoice.provider_observation_attention_required.
Observation collection is explicit policy/support trigger with caller-owned triggerId.
Replay of the same triggerId reuses one command; distinct authorized triggers on the same day remain distinct.
Rate protection is max one in-flight observation call per provider connection plus worker backoff/429 handling; it is not a daily uniqueness rule.
There is no tenant-wide scheduled scan.
ProviderObservationRecord correlation is resolved through provider_interaction_reference; no correlation_id column is added to invoice_provider_observations.
```

Record the SRS “Theme 11” versus repo `TH-10-alerts-and-risk` naming drift; E-invoice emits a neutral integration event and imports no alerts module.

- [ ] **Step 4: Extend the domain capability snapshot**

```dart
final Set<InvoiceDocumentType> supportedDocumentTypes;

bool supports(InvoiceDocumentType type) =>
    supportedDocumentTypes.contains(type);
```

Default deserialization for a missing field is the empty set, never `{pdf, xml}`. Update `copyWith`, equality props, fake fixtures and capability serialization tests.

- [ ] **Step 5: Freeze the full ProviderInteractionRecord contract in draft 001**

Draft 001 and draft 005 are both unpromoted. Replace the minimal table body in draft 001 rather than layering another conflicting `alter table`. In particular, preserve `correlation_id uuid`; do not introduce the previous `varchar(100)` proposal.

```sql
create table if not exists einvoice.provider_interaction_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  provider_connection_id uuid not null
    references einvoice.provider_connections(id),
  direction text not null
    check (direction in ('OUTBOUND','INBOUND_CALLBACK')),
  operation_type text not null,
  target_type text not null,
  target_id uuid not null,
  correlation_id uuid not null,
  request_reference varchar(255) not null,
  response_reference varchar(255) null,
  provider_reference varchar(255) null,
  status text not null default 'STARTED'
    check (status in ('STARTED','COMPLETED')),
  outcome text null check (outcome is null or outcome in (
    'SUCCEEDED','DEFINITE_FAILURE','TIMEOUT','UNAVAILABLE',
    'NOT_FOUND','MISMATCH','CHECK_REQUIRED'
  )),
  safe_error_code varchar(100) null,
  started_at timestamptz not null default now(),
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, correlation_id, operation_type),
  check (
    (status = 'STARTED' and outcome is null and completed_at is null)
    or
    (status = 'COMPLETED' and outcome is not null and completed_at is not null)
  )
);

alter table einvoice.provider_interaction_records enable row level security;
revoke all on einvoice.provider_interaction_records from anon, authenticated;
```

Freeze field semantics in Theme/harness:

```text
Cardinality: one row per outbound provider-call attempt or inbound callback.
Immutable after start: tenant, provider connection, direction, operation type,
target, correlation, request reference, started time.
Finalize once: response reference, provider reference, outcome, safe error code,
completed time, status and optimistic version.
request_reference = Vet45 command/message ID that caused the interaction.
response_reference = provider HTTP/request trace ID when safely available.
provider_reference = provider business object identity, never a credential/token.
```

Delete `request_summary` and `response_summary` from the canonical record; no request/response body, headers, viewer payload, credential or token is stored.

- [ ] **Step 6: Move S2 preview state out of ProviderInteractionRecord**

Draft 005 currently adds `sales_order_id`, `order_version`, `status`, `viewer_ref`, `expires_at` and preview payload behavior to the shared interaction table. Replace that extension with a dedicated technical resource table—not a business aggregate:

```sql
-- Title: einvoice S2a — buyer completion and preview operations
-- Kind: patch
-- Intent: buyer_invoice_completions plus technical invoice preview operation
-- Context: TH-08 EP-02/US-01; fake-seam — sales.* not yet available
-- Touches: einvoice.buyer_invoice_completions, einvoice.invoice_preview_operations
-- Safety: idempotent (create if not exists), RLS enabled, tenant_id scoped
-- Depends on: 001_einvoice_s1_schema_configuration.sql
```

```sql
create table if not exists einvoice.invoice_preview_operations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  provider_connection_id uuid not null
    references einvoice.provider_connections(id),
  sales_order_id uuid not null,
  correlation_id uuid not null,
  order_version varchar(100) not null,
  status text not null default 'PENDING'
    check (status in ('PENDING','READY','FAILED','SUPERSEDED')),
  viewer_ref text null,
  preview_payload jsonb null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, correlation_id)
);

alter table einvoice.invoice_preview_operations enable row level security;
revoke all on einvoice.invoice_preview_operations from anon, authenticated;
```

`request_invoice_preview` resolves and stores the active `provider_connection_id`, then includes it in the durable preview command payload. `preview_payload` is the existing normalized/allow-listed preview DTO consumed by the UI, never a raw MISA response. Update draft 006 RPC bodies without changing their external names or `-- Touches:` list: `request_invoice_preview`, `get_invoice_preview` and `store_preview_result` read/write `invoice_preview_operations`. Preserve 15-minute expiry, order-version supersession and service-role writeback. S2 preview worker will start/finalize a canonical interaction row around the actual `previewUnpublished` call in Task 7.

- [ ] **Step 7: Write schema and harness contract guards for the repaired shared record**

The tests must reject:

```text
correlation_id varchar/text
request_summary or response_summary on provider_interaction_records
sales_order_id, viewer_ref or preview_payload on provider_interaction_records
preview RPC reads/writes against provider_interaction_records
daily/UTC-date uniqueness for observation commands
```

The SQL tests require all canonical fields/checks, `invoice_preview_operations` and unchanged preview RPC names. `einvoice_s4_contract_repair_test.dart` reads the harness and requires same-trigger-only observation idempotency until draft 012's executable SQL guard is added in Task 6.

- [ ] **Step 8: Verify the gate**

```bash
dart format modules/einvoice/domain/lib/src/provider_connection modules/einvoice/domain/test/provider_connection
cd modules/einvoice/domain && dart analyze && dart test test/provider_connection/provider_capabilities_snapshot_test.dart
cd modules/einvoice/infrastructure && dart test test/electronic_invoice/einvoice_s4_contract_repair_test.dart test/electronic_invoice/provider_interaction_sql_contract_test.dart test/electronic_invoice/invoice_preview_operation_sql_contract_test.dart
bash scripts/ci/verify_harness.sh
```

Expected: PASS; no daily observation identity, no observation `correlation_id`, preview state is separate from interaction audit, canonical interaction fields are frozen, and ambiguous exhaustion is `CHECK_REQUIRED` on the same operation.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `docs(einvoice): repair slice 4 contracts`

---

### Task 1: Freeze S4 domain policies and repair contract DTO shape

**Files:**

- Create: `modules/einvoice/domain/lib/src/electronic_invoice/services/invoice_document_content_policy.dart`
- Create: `modules/einvoice/domain/lib/src/electronic_invoice/services/official_view_operation_policy.dart`
- Modify: `modules/einvoice/domain/lib/domain.dart`
- Create: `modules/einvoice/domain/test/electronic_invoice/invoice_document_content_policy_test.dart`
- Create: `modules/einvoice/domain/test/electronic_invoice/official_view_operation_policy_test.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/queries/get_invoice_documents/invoice_document_item_dto.dart`
- Modify: `modules/einvoice/application/lib/src/electronic_invoice/queries/get_invoice_documents/invoice_documents_dto.dart`
- Modify: `modules/einvoice/application/lib/application.dart`

**Interfaces:** Consumes frozen `InvoiceDocumentType`/`InvoiceDocumentStatus`; produces pure content/replay decisions and one-public-class-per-file DTOs for all later tasks.

- [ ] **Step 1: Run impact before changing current barrels/DTO**

```text
GitNexus impact upstream: InvoiceDocumentsDto, InvoiceDocumentItemDto, domain.dart/application.dart exports.
```

Expected: report direct consumers and generated metadata; stop if risk is HIGH/CRITICAL.

- [ ] **Step 2: Write failing domain tests**

```dart
test('accepts PDF signature and rejects empty or non-PDF bytes', () {
  expect(
    InvoiceDocumentContentPolicy.validate(
      type: InvoiceDocumentType.pdf,
      bytes: const [0x25, 0x50, 0x44, 0x46, 0x2D],
    ),
    isNull,
  );
  expect(
    InvoiceDocumentContentPolicy.validate(
      type: InvoiceDocumentType.pdf,
      bytes: const [1, 2, 3],
    ),
    'DOCUMENT_CONTENT_INVALID',
  );
});

test('refreshes expired available official view', () {
  expect(
    OfficialViewOperationPolicy.decide(
      status: InvoiceDocumentStatus.available,
      expiresAt: DateTime.utc(2026, 8, 31, 9),
      now: DateTime.utc(2026, 8, 31, 9, 0, 1),
    ),
    OfficialViewOperationDecision.createNextGeneration,
  );
});

test('re-arms the same operation after ambiguous outcome', () {
  expect(
    OfficialViewOperationPolicy.decide(
      status: InvoiceDocumentStatus.checkRequired,
      expiresAt: null,
      now: DateTime.utc(2026, 8, 31, 9),
    ),
    OfficialViewOperationDecision.rearmSameOperation,
  );
});
```

Run:

```bash
cd modules/einvoice/domain && dart test test/electronic_invoice
```

Expected: FAIL because policies do not exist.

- [ ] **Step 3: Implement minimal pure policies**

```dart
final class InvoiceDocumentContentPolicy {
  const InvoiceDocumentContentPolicy._();
  static const maxBytes = 20 * 1024 * 1024;

  static String? validate({
    required InvoiceDocumentType type,
    required List<int> bytes,
  }) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      return 'DOCUMENT_CONTENT_INVALID';
    }
    return switch (type) {
      InvoiceDocumentType.pdf =>
        bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-'
            ? null
            : 'DOCUMENT_CONTENT_INVALID',
      InvoiceDocumentType.xml => _looksLikeXml(bytes)
          ? null
          : 'DOCUMENT_CONTENT_INVALID',
    };
  }
}
```

`OfficialViewOperationPolicy.decide` trả `reuse` cho `pending` và `available` chưa hết hạn; trả `rearmSameOperation` cho `checkRequired`; chỉ trả `createNextGeneration` cho definite `failed` hoặc `available` đã hết hạn.

- [ ] **Step 4: Split `InvoiceDocumentItemDto`**

Chuyển nguyên class sang `invoice_document_item_dto.dart`, import class đó từ `invoice_documents_dto.dart`, export cả hai ở `application.dart`. Không đổi field/wire meaning.

- [ ] **Step 5: Verify**

```bash
dart format modules/einvoice/domain/lib modules/einvoice/domain/test modules/einvoice/application/lib/src/electronic_invoice
cd modules/einvoice/domain && dart analyze && dart test test/electronic_invoice
cd modules/einvoice/application && dart analyze
```

Expected: PASS, no analyzer warning, no second public DTO in `invoice_documents_dto.dart`.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `feat(einvoice): define slice 4 resource policies`

---

### Task 2: Add typed application ports, mappers and public CQRS handlers

**Files:**

- Create: `modules/einvoice/application/lib/src/ports/i_electronic_invoice_command_gateway.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_electronic_invoice_read_gateway.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_electronic_invoice_provider_port.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_invoice_document_storage_port.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_provider_interaction_gateway.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/electronic_invoice_provider_context_dto.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/official_view_operation_context_dto.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/invoice_document_operation_context_dto.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/official_view_provider_outcome.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/invoice_document_provider_outcome.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/provider_observation_outcome.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/stored_invoice_document_dto.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/official_view_result_record.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/invoice_document_result_record.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/provider_observation_record.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/provider_interaction_record.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/provider_interaction_direction.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/provider_interaction_status.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/shared/provider_interaction_outcome.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/request_official_invoice_view/request_official_invoice_view_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/request_official_invoice_view/request_official_invoice_view_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/request_invoice_document/request_invoice_document_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/request_invoice_document/request_invoice_document_command_handler.dart`
- Create: three query handler files beside the three existing S4 queries
- Modify: `modules/einvoice/application/lib/application.dart`
- Create: `modules/einvoice/application/test/electronic_invoice/s4_public_handlers_test.dart`
- Create: `modules/einvoice/application/test/electronic_invoice/s4_public_pipeline_test.dart`
- Modify: `modules/einvoice/application/lib/src/testing/fake_einvoice_module.dart`
- Modify: `modules/einvoice/application/test/fake_einvoice_scenarios_e03_test.dart`

**Interfaces:** Consumes existing public commands/queries and frozen ports; produces CQRS handlers with no Supabase/MISA dependency. Worker outcomes are sealed/typed; no `Map<String, Object?>` crosses provider boundary. `IProviderInteractionGateway` uses the frozen top-level signature, returns one typed record per provider-call attempt and supplies the stable interaction reference used by observation/document/official result records.

`ElectronicInvoiceProviderContextDto` contains only `providerConnectionId`, `electronicInvoiceId`, `providerInvoiceReference`, `invoiceSeries` and operation/document identifiers. Company tax code and credentials are loaded inside the worker adapter through existing service-role `read_provider_credentials`; they never enter internal-command payload or operation rows.

- [ ] **Step 1: Write failing handler and pipeline tests**

Cover these exact scenarios:

```text
SCN-E03-U01-FR06-01 request official view -> PENDING + stable operationId
SCN-E03-U02-FR03-01 request PDF -> PENDING + stable operationId
query detail/documents/latest observation delegates tenant+actor+salesOrderId
missing permission is rejected before gateway call
blank tenant/actor/salesOrder/idempotency key is validation failure
```

Representative assertion:

```dart
expect(gateway.officialViewRequests.single, (
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  salesOrderId: 'order-1',
));
expect(result.status, InvoiceDocumentStatus.pending);
```

Run:

```bash
cd modules/einvoice/application && dart test test/electronic_invoice/s4_public_handlers_test.dart test/electronic_invoice/s4_public_pipeline_test.dart
```

Expected: FAIL because ports/handlers/validators are absent.

- [ ] **Step 2: Implement public command handlers as thin orchestration**

```dart
@CommandHandlerFor(RequestOfficialInvoiceViewCommand)
final class RequestOfficialInvoiceViewCommandHandler
    implements ICommandHandler<RequestOfficialInvoiceViewCommand, OfficialInvoiceViewDto> {
  const RequestOfficialInvoiceViewCommandHandler(this._gateway);
  final IElectronicInvoiceCommandGateway _gateway;

  @override
  Future<OfficialInvoiceViewDto> handle(
    RequestOfficialInvoiceViewCommand command,
  ) => _gateway.requestOfficialView(
    tenantId: command.tenantId,
    actorId: command.actorId,
    salesOrderId: command.salesOrderId,
  );
}
```

Document handler forwards `documentType` and `idempotencyKey`; validators check identifiers with non-empty trimmed values and key length <=150.

- [ ] **Step 3: Implement read handlers**

```dart
@QueryHandlerFor(GetInvoiceDocumentsQuery)
final class GetInvoiceDocumentsQueryHandler
    implements IQueryHandler<GetInvoiceDocumentsQuery, InvoiceDocumentsDto> {
  const GetInvoiceDocumentsQueryHandler(this._gateway);
  final IElectronicInvoiceReadGateway _gateway;

  @override
  Future<InvoiceDocumentsDto> handle(GetInvoiceDocumentsQuery query) =>
      _gateway.getDocuments(
        tenantId: query.tenantId,
        actorId: query.actorId,
        salesOrderId: query.salesOrderId,
      );
}
```

- [ ] **Step 4: Normalize observation contract**

Thay `RecordProviderObservationCommand.observationPayload` bằng typed allow-list fields: `providerStateCode`, `safeDescription`, `providerReference`, `observedAt`, `deduplicationKey`, `detailsSnapshot`, `providerInteractionReference`. `detailsSnapshot` chỉ chứa state metadata đã allow-list, không chứa raw response. `ProviderObservationDto.correlationId` được read gateway derive từ referenced `ProviderInteractionRecord`; command/table observation không có cột `correlation_id` riêng.

Define the interaction types as exhaustive enums:

```dart
enum ProviderInteractionDirection { outbound, inboundCallback }
enum ProviderInteractionStatus { started, completed }
enum ProviderInteractionOutcome {
  succeeded,
  definiteFailure,
  timeout,
  unavailable,
  notFound,
  mismatch,
  checkRequired,
}
```

`ProviderInteractionRecord` contains every canonical Task 0 field. Its constructor requires `version >= 0`, non-empty references/type/target and UTC timestamps; a STARTED record has no outcome/completedAt, while COMPLETED requires both. Application tests cover every wire mapping and reject an unknown direction/status/outcome instead of defaulting.

Every provider outcome exposes optional safe `responseReference` and `providerReference` fields used only to finalize the interaction. These are identifiers/trace IDs, never response text or payload. Timeout/unavailable outcomes carry a stable `safeErrorCode` and no fabricated response/provider reference.

- [ ] **Step 5: Align the fake module with the async contract**

`download_unavailable` không được ném `DocumentUnavailableException` ngay tại request nữa. Fake request trả stable `operationId` + `status = failed`; query trả item FAILED. Sửa test cũ để bảo vệ semantics “request chỉ tạo/load operation, không gọi provider đồng bộ”. Giữ exception class cho presentation mapping của các flow cũ nếu còn consumer, không xóa khi chưa có impact evidence.

- [ ] **Step 6: Verify**

```bash
dart format modules/einvoice/application/lib modules/einvoice/application/test/electronic_invoice
cd modules/einvoice/application && dart analyze && dart test test/electronic_invoice
```

Expected: PASS; `rg "observationPayload|rawPayload" modules/einvoice/application/lib/src/electronic_invoice` returns no match.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `feat(einvoice): add slice 4 application boundaries`

---

### Task 3: Implement official-view draft SQL and Supabase gateways

**Files:**

- Create: `supabase/migrations/_drafts/010_einvoice_s4a_official_view.sql`
- Create: `modules/einvoice/infrastructure/lib/src/data_access/supabase_electronic_invoice_command_gateway.dart`
- Create: `modules/einvoice/infrastructure/lib/src/data_access/supabase_electronic_invoice_read_gateway.dart`
- Create: `modules/einvoice/infrastructure/lib/src/data_access/electronic_invoice_rpc_mapper.dart`
- Create: `modules/einvoice/infrastructure/test/electronic_invoice/einvoice_s4a_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/electronic_invoice/supabase_electronic_invoice_gateways_test.dart`

**Interfaces:** Consumes `electronic_invoices`, `internal_commands`, IAM permission helper and Task 2 ports; produces atomic official-view operation RPCs and detail read mapping.

- [ ] **Step 1: Write failing SQL contract tests**

Assert exact `-- Touches:` set and behavior tokens:

```sql
-- Title: einvoice S4a official invoice view operations
-- Kind: patch
-- Intent: einvoice_s4a_official_view
-- Context: TH-08 / EP-03 / US-01
-- Touches: _official_view_command_id, get_electronic_invoice_detail, load_official_view_operation_context, record_official_invoice_view_result, request_official_invoice_view
-- Safety: idempotent ; medium
-- Depends on: 007_einvoice_s2b_schema_and_rpc.sql, 009_einvoice_s3b_reconciliation.sql
```

```text
request_official_invoice_view
get_electronic_invoice_detail
_official_view_command_id
load_official_view_operation_context
record_official_invoice_view_result
```

Tests must require:

```sql
p_actor_id <> auth.uid()
iam.has_permission(p_tenant_id, 'einvoice.view')
current_setting('request.jwt.claim.role', true)
einvoice.fetch_official_view
sales.can_access_sales_order
on conflict
```

Run:

```bash
cd modules/einvoice/infrastructure && dart test test/electronic_invoice/einvoice_s4a_sql_contract_test.dart
```

Expected: FAIL because draft 010 is absent.

- [ ] **Step 2: Create official operation table and access-safe RPCs**

Core schema:

```sql
create table if not exists einvoice.official_invoice_view_operations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  electronic_invoice_id uuid not null,
  generation integer not null check (generation > 0),
  attempt_ordinal integer not null default 1 check (attempt_ordinal > 0),
  status text not null check (status in ('PENDING','AVAILABLE','FAILED','CHECK_REQUIRED')),
  provider_viewer_url text null,
  viewer_token text null,
  expires_at timestamptz null,
  failure_code text null,
  failure_message text null,
  provider_interaction_reference uuid null,
  requested_at timestamptz not null default now(),
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, electronic_invoice_id, generation),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id),
  foreign key (tenant_id, provider_interaction_reference)
    references einvoice.provider_interaction_records (tenant_id, id)
);
```

`request_official_invoice_view` locks the invoice row, rejects non-issued invoice, reuses `PENDING` or unexpired `AVAILABLE`, re-arms the same row at `CHECK_REQUIRED`, and increments generation only after definite `FAILED` or expired AVAILABLE. For a fresh generation it inserts the operation and internal command in the same transaction:

```sql
insert into einvoice.internal_commands (
  id, tenant_id, command_type, payload, source_event_id, enqueued_at
) values (
  einvoice._official_view_command_id(v_operation_id, v_attempt_ordinal),
  p_tenant_id,
  'einvoice.fetch_official_view',
  jsonb_build_object(
    'tenant_id', p_tenant_id,
    'operation_id', v_operation_id,
    'electronic_invoice_id', v_invoice_id,
    'correlation_id', v_operation_id
  ),
  v_operation_id,
  now()
) on conflict (id) do nothing;
```

The public request/read RPC access guard is exactly:

```sql
if auth.uid() is null
   or p_actor_id is null
   or p_actor_id <> auth.uid()
   or not iam.has_permission(p_tenant_id, 'einvoice.view') then
  raise exception 'NO_PERMISSION: einvoice.view required';
end if;

if not sales.can_access_sales_order(
  p_tenant_id,
  p_actor_id,
  p_sales_order_id
) then
  raise exception 'NOT_FOUND: sales order not found';
end if;
```

`_official_view_command_id(operationId, attemptOrdinal)` is deterministic UUIDv5. Request at `CHECK_REQUIRED` increments `attempt_ordinal`, returns the same operation id, changes it back to PENDING with optimistic `version`, and enqueues the next command id; it never inserts another generation. Load-context/result RPCs require service role. `record_official_invoice_view_result` compare-and-sets `version` on the named `PENDING` generation; duplicate terminal callbacks return existing state. AVAILABLE requires non-empty URL and sets `expires_at = least(provider expiry, now()+interval '5 minutes')`, falling back to `now()+interval '5 minutes'` when provider expiry is absent. Revoke all functions from `public, anon`; grant request/detail only to `authenticated`, and helper/context/result only to `service_role`.

- [ ] **Step 3: Write gateway tests, then map RPC rows**

Expected RPC params:

```dart
{
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_sales_order_id': salesOrderId,
}
```

Mapper must convert uppercase status with exhaustive switch and reject unknown values with `RpcException`; URLs/tokens are ignored unless mapped status is `available` and `expiresAt.isAfter(clock.now())`.

- [ ] **Step 4: Verify**

```bash
dart format modules/einvoice/infrastructure/lib/src/data_access modules/einvoice/infrastructure/test/electronic_invoice
cd modules/einvoice/infrastructure && dart analyze && dart test test/electronic_invoice/einvoice_s4a_sql_contract_test.dart test/electronic_invoice/supabase_electronic_invoice_gateways_test.dart
```

Expected: PASS. Draft is not applied to a database.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `feat(einvoice): draft official view operations`

---

### Task 4: Implement PDF/XML operation SQL and private document storage

**Files:**

- Create: `supabase/migrations/_drafts/011_einvoice_s4b_documents.sql`
- Create: `modules/einvoice/infrastructure/lib/src/storage/supabase_invoice_document_storage_port.dart`
- Create: `modules/einvoice/infrastructure/test/electronic_invoice/einvoice_s4b_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/storage/supabase_invoice_document_storage_port_test.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/data_access/supabase_electronic_invoice_command_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/data_access/supabase_electronic_invoice_read_gateway.dart`
- Modify: `modules/einvoice/infrastructure/pubspec.yaml`

**Interfaces:** Consumes Task 1 content policy and Task 2 storage/gateway ports; produces versioned document operation RPCs, deterministic private storage, checksum and fresh signed URLs.

- [ ] **Step 1: Write failing SQL/storage tests**

SQL `-- Touches:` must list exactly:

```sql
-- Title: einvoice S4b invoice document operations
-- Kind: patch
-- Intent: einvoice_s4b_documents
-- Context: TH-08 / EP-03 / US-02
-- Touches: _invoice_document_command_id, get_invoice_documents, load_invoice_document_operation_context, record_invoice_document_result, request_invoice_document
-- Safety: idempotent ; medium
-- Depends on: 007_einvoice_s2b_schema_and_rpc.sql, 009_einvoice_s3b_reconciliation.sql
```

```text
request_invoice_document
get_invoice_documents
_invoice_document_command_id
load_invoice_document_operation_context
record_invoice_document_result
```

Storage tests assert bucket `einvoice-documents`, upsert disabled, 20 MiB limit, SHA-256 checksum, MIME mapping, deterministic path and a 300-second signed URL generated only during read.

SQL contract tests additionally require `sales.can_access_sales_order`, `supported_document_types`, no insert when capability is absent, and same-operation re-arm from `CHECK_REQUIRED`.

Run:

```bash
cd modules/einvoice/infrastructure && dart test test/electronic_invoice/einvoice_s4b_sql_contract_test.dart test/storage/supabase_invoice_document_storage_port_test.dart
```

Expected: FAIL because draft/storage adapter are absent.

- [ ] **Step 2: Create document schema and atomic request RPC**

Separate technical request identity from the canonical document resource. First create the operation table that owns `operationId`, generation and idempotency:

```sql
create table if not exists einvoice.invoice_document_operations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  electronic_invoice_id uuid not null,
  document_type text not null check (document_type in ('PDF','XML')),
  generation integer not null check (generation > 0),
  attempt_ordinal integer not null default 1 check (attempt_ordinal > 0),
  status text not null check (status in ('PENDING','AVAILABLE','FAILED','CHECK_REQUIRED')),
  idempotency_key varchar(150) not null,
  intent_hash varchar(128) not null,
  invoice_document_id uuid null,
  access_expires_at timestamptz null,
  failure_code text null,
  failure_message text null,
  requested_at timestamptz null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, idempotency_key),
  unique (tenant_id, electronic_invoice_id, document_type, generation),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id)
);
```

Then create `invoice_documents` with the canonical fields from the harness only (plus normal `id`, `tenant_id`, timestamps):

```sql
create table if not exists einvoice.invoice_documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  electronic_invoice_id uuid not null,
  document_type text not null check (document_type in ('PDF','XML')),
  document_version integer not null check (document_version > 0),
  status text not null check (status in ('PENDING','AVAILABLE','FAILED','CHECK_REQUIRED')),
  provider_document_reference text null,
  storage_reference text null,
  content_type text null,
  file_name text null,
  file_size bigint null,
  checksum text null,
  requested_at timestamptz null,
  available_at timestamptz null,
  failure_code text null,
  failure_message text null,
  provider_interaction_reference uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, electronic_invoice_id, document_type, document_version),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id),
  foreign key (tenant_id, provider_interaction_reference)
    references einvoice.provider_interaction_records (tenant_id, id),
  check (status <> 'AVAILABLE' or (storage_reference is not null and checksum is not null))
);

alter table einvoice.invoice_document_operations
  drop constraint if exists invoice_document_operations_document_fk;
alter table einvoice.invoice_document_operations
  add constraint invoice_document_operations_document_fk
  foreign key (tenant_id, invoice_document_id)
  references einvoice.invoice_documents (tenant_id, id);
```

`request_invoice_document` first checks actor/permission, `sales.can_access_sales_order`, issued invoice identity and the connected provider's `capabilities_snapshot.supported_document_types`. Unsupported or unknown type raises `DOCUMENT_UNAVAILABLE` before any insert/enqueue. It then hashes intent `{electronicInvoiceId, documentType}`. Same idempotency key + same intent returns its existing operation; same key + different intent raises `IDEMPOTENCY_CONFLICT`. A current PENDING operation is reused. `CHECK_REQUIRED` increments `attempt_ordinal` and optimistic `version`, returns the same operation id, and enqueues `_invoice_document_command_id(operationId, attemptOrdinal)`. If an AVAILABLE document already exists, create/reuse an AVAILABLE access operation linked by `invoice_document_id` and do not enqueue MISA. Only definite FAILED permits a new generation. Otherwise create the next `invoice_documents` version with PENDING status, create a linked PENDING operation, and atomically insert its first internal command. `record_invoice_document_result` compare-and-sets expected operation/document versions; success fills immutable storage metadata and sets both AVAILABLE, definite provider rejection sets both FAILED, and ambiguous/auth/config/content outcomes set both CHECK_REQUIRED without changing `ElectronicInvoice`.

Revoke all document RPCs from `public, anon`; grant request/list only to `authenticated`, and load-context/result only to `service_role`. Revoke table access from `anon, authenticated`; document reads remain RPC + scoped Storage SELECT.

Insert private bucket metadata idempotently:

```sql
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'einvoice-documents',
  'einvoice-documents',
  false,
  20971520,
  array['application/pdf','application/xml','text/xml']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
```

Create exactly one authenticated read policy and no client write policy:

```sql
drop policy if exists einvoice_documents_select on storage.objects;
create policy einvoice_documents_select
on storage.objects for select to authenticated
using (
  bucket_id = 'einvoice-documents'
  and cardinality(storage.foldername(name)) >= 2
  and iam.has_permission(
    case
      when (storage.foldername(name))[1]
        ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      then ((storage.foldername(name))[1])::uuid
      else null::uuid
    end,
    'einvoice.download_document'
  )
);
```

The first path segment is the canonical `tenantId`; malformed/non-UUID paths must fail closed. Revoke authenticated insert/update/delete and test that no such policy exists.

- [ ] **Step 3: Implement deterministic storage adapter**

Add `crypto: ^3.0.6`. Storage path:

```dart
final checksum = sha256.convert(bytes).toString();
final extension = documentType == InvoiceDocumentType.pdf ? 'pdf' : 'xml';
final path = '$tenantId/$electronicInvoiceId/'
    '${documentType.name}/v$documentVersion/$checksum.$extension';
```

Validate bytes with `InvoiceDocumentContentPolicy` before upload. Upload exactly once; if the same deterministic object already exists, verify metadata/checksum and reuse. Return storage reference/checksum/contentType/fileName/fileSize; never return a signed URL from `store`.

- [ ] **Step 4: Generate signed URLs in read gateway only**

After `get_invoice_documents` passes permission and returns AVAILABLE document rows joined to their latest operation, call private bucket `createSignedUrl(storageReference, 300)`. The storage SELECT policy independently rechecks the tenant path and `einvoice.download_document`. A signing failure must map that item to `checkRequired` in the DTO response without mutating authoritative DB state; log only safe identifiers. The request gateway follows the same signing path when its AVAILABLE access operation references a document, thereby re-arming the 5-minute access lease without enqueueing another provider download.

- [ ] **Step 5: Verify**

```bash
melos bootstrap
dart format modules/einvoice/infrastructure/lib modules/einvoice/infrastructure/test
cd modules/einvoice/infrastructure && dart analyze && dart test test/electronic_invoice test/storage
```

Expected: PASS; bucket remains private, exactly one tenant/permission-scoped SELECT policy exists, no authenticated write policy exists, and there is no persisted `download_url` column.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `feat(einvoice): draft document retrieval and private storage`

---

### Task 5: Implement worker-only MISA resource adapter and classifiers

**Files:**

- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_electronic_invoice_provider_adapter.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_official_view_classifier.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_document_classifier.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_observation_classifier.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/worker_only_electronic_invoice_provider_port.dart`
- Create: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_electronic_invoice_provider_adapter_test.dart`
- Create: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_observation_classifier_test.dart`

**Interfaces:** Consumes `TenantMeInvoiceClientFactory`, `FakeMeInvoiceClient` and Task 2 provider port; produces safe typed outcomes with exactly three MISA operations.

- [ ] **Step 1: Write failing adapter tests**

Cover:

```text
previewPublished receives provider transaction id + company tax code
download receives transaction id + query derived from invoice series + exact PDF/XML type
empty provider document -> FAILED/DOCUMENT_UNAVAILABLE
malformed non-empty document bytes -> CHECK_REQUIRED/DOCUMENT_CONTENT_INVALID
provider auth rejection -> CHECK_REQUIRED
timeout/5xx/transport -> typed ProviderCallAmbiguousException; handler audits then retries the same operation and ends at CHECK_REQUIRED after attempt exhaustion
getStatus maps only allow-listed state fields
ERP worker-only adapter throws before an HTTP call
```

Run:

```bash
cd modules/einvoice/infrastructure && dart test test/adapters/misa/me_invoice_electronic_invoice_provider_adapter_test.dart test/adapters/misa/me_invoice_observation_classifier_test.dart
```

Expected: FAIL because adapter/classifiers are absent.

- [ ] **Step 2: Implement exact MISA calls**

```dart
final credentials = await _readCredentials(tenantId: context.tenantId);
final companyTaxCode = (credentials?['tax_code'] as String?)?.trim();
if (companyTaxCode == null || companyTaxCode.isEmpty) {
  return const OfficialViewProviderOutcome.checkRequired(
    'PROVIDER_TAX_CODE_MISSING',
  );
}
final result = await client.previewPublished(
  transactionIds: [context.providerInvoiceReference],
  companyTaxCode: companyTaxCode,
);

final result = await client.download(
  transactionIds: [context.providerInvoiceReference],
  query: MeInvoiceInvoiceQuery.fromInvSeries(context.invoiceSeries),
  downloadDataType: switch (documentType) {
    InvoiceDocumentType.pdf => MeInvoiceDownloadDataType.pdf,
    InvoiceDocumentType.xml => MeInvoiceDownloadDataType.xml,
  },
);

final result = await client.getStatus(
  ids: [context.providerInvoiceReference],
  inputType: MeInvoiceStatusInputType.transactionId,
  query: MeInvoiceInvoiceQuery.fromInvSeries(context.invoiceSeries),
);
```

Reuse credential loading/client factory behavior from `MeInvoiceProviderAdapter`; require non-empty credential `tax_code` before `previewPublished`, map its absence to `CHECK_REQUIRED`, and do not duplicate decrypted credentials into command payloads, context DTOs or logs.

When `vet45_misa` exposes a safe provider request/trace identifier, map it to `responseReference`; otherwise leave it null. Map the invoice transaction/business identity to `providerReference`. Never derive either reference from raw response text.

- [ ] **Step 3: Allow-list observation data**

Map only `publishStatus`, `eInvoiceStatus`, `referenceType`, `sendTaxStatus`, `invoiceCode`, `invNo`, `invSeries`, `publishedTime`, transaction id. Build stable `providerStateCode` from numeric fields and a Vietnamese-safe description from a fixed lookup; unknown values use `UNKNOWN_<number>`, never raw provider text/body.

Classifiers must distinguish these branches without string inspection in handlers:

```text
success/found                 -> provider fact
definite empty/no document    -> FAILED / DOCUMENT_UNAVAILABLE
not found                     -> NOT_FOUND provider fact
state/identity mismatch       -> MISMATCH provider fact
malformed content             -> CHECK_REQUIRED / DOCUMENT_CONTENT_INVALID
auth/config rejection         -> CHECK_REQUIRED
timeout/5xx/transport         -> ProviderCallAmbiguousException; throw/retry same operation
```

- [ ] **Step 4: Verify**

```bash
dart format modules/einvoice/infrastructure/lib/src/adapters/misa modules/einvoice/infrastructure/test/adapters/misa
cd modules/einvoice/infrastructure && dart analyze && dart test test/adapters/misa
```

Expected: PASS; Fake client counters prove exactly one provider call per handler attempt.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `feat(einvoice): adapt misa slice 4 resources`

---

### Task 6: Implement provider interaction audit, explicit observation trigger and reliable attention handoff

**Files:**

- Create: `supabase/migrations/_drafts/012_einvoice_s4c_provider_observations.sql`
- Modify: `modules/einvoice/infrastructure/lib/src/data_access/supabase_electronic_invoice_command_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/data_access/supabase_electronic_invoice_read_gateway.dart`
- Create: `modules/einvoice/infrastructure/lib/src/provider_interactions/supabase_provider_interaction_gateway.dart`
- Create: `modules/einvoice/infrastructure/test/provider_interactions/supabase_provider_interaction_gateway_test.dart`
- Create: `modules/einvoice/infrastructure/test/electronic_invoice/einvoice_s4c_sql_contract_test.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/record_provider_observation/record_provider_observation_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/record_provider_observation/record_provider_observation_command_validator.dart`
- Create: `modules/einvoice/application/test/electronic_invoice/record_provider_observation_command_handler_test.dart`
- Create: `modules/einvoice/integration_events/lib/src/provider_observation_attention_required_integration_event.dart`
- Modify: `modules/einvoice/integration_events/lib/integration_events.dart`
- Create: `modules/einvoice/integration_events/test/provider_observation_attention_required_integration_event_test.dart`

**Interfaces:** Consumes typed provider outcomes and Task 0 `ProviderInteractionRecord`; produces replay-safe interaction audit, append-only provider facts, an explicit per-invoice observation trigger, correlation through the interaction reference and a transactional mismatch/not-found outbox handoff. It never changes issuance lifecycle state and never scans all invoices.

- [ ] **Step 1: Write failing SQL, gateway and event tests**

Draft `-- Touches:` must list exactly these seven functions:

```sql
-- Title: einvoice S4c provider interactions and observations
-- Kind: patch
-- Intent: einvoice_s4c_provider_observations
-- Context: TH-08 / EP-03 / US-03
-- Touches: _provider_observation_command_id, get_latest_provider_observation, load_provider_observation_context, record_provider_interaction_result, record_provider_observation, request_provider_observation_refresh, start_provider_interaction
-- Safety: idempotent ; medium
-- Depends on: 001_einvoice_s1_schema_configuration.sql, 002_einvoice_s1_install_module_messaging.sql, 007_einvoice_s2b_schema_and_rpc.sql, 009_einvoice_s3b_reconciliation.sql
```

Tests must assert:

```text
no seed_due_provider_observation_commands function and no tenant-wide invoice scan
same tenant/invoice/triggerId returns one command; distinct triggerIds on the same day return distinct commands
no UTC date/day value participates in command identity or uniqueness
timeout/unavailable finalizes ProviderInteractionRecord but inserts no observation
observation table has provider_interaction_reference and no correlation_id column
get_latest_provider_observation derives correlation_id by joining ProviderInteractionRecord
NOT_FOUND/MISMATCH inserts observation and outbox event in the same RPC transaction
duplicate observation/event input returns the existing observation and one outbox row
no update to invoice_issuances or issuance lifecycle state
```

Run:

```bash
cd modules/einvoice/application && dart test test/electronic_invoice/record_provider_observation_command_handler_test.dart
cd modules/einvoice/integration_events && dart test test/provider_observation_attention_required_integration_event_test.dart
cd modules/einvoice/infrastructure && dart test test/electronic_invoice/einvoice_s4c_sql_contract_test.dart test/provider_interactions/supabase_provider_interaction_gateway_test.dart
```

Expected: FAIL because the draft, adapter and attention event do not exist.

- [ ] **Step 2: Create append-only observation schema without duplicate correlation state**

```sql
create table if not exists einvoice.invoice_provider_observations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  electronic_invoice_id uuid not null,
  provider_state_code text not null,
  provider_state_description text null,
  provider_reference text null,
  observed_at timestamptz not null,
  deduplication_key text not null,
  details_snapshot jsonb not null default '{}'::jsonb,
  provider_interaction_reference uuid not null,
  created_at timestamptz not null default now(),
  unique (tenant_id, deduplication_key),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id),
  foreign key (tenant_id, provider_interaction_reference)
    references einvoice.provider_interaction_records (tenant_id, id)
);
```

Keep this table append-only: no `updated_at`, no `version`, no `correlation_id`, and no raw payload. `details_snapshot` accepts only the allow-listed Task 5 state keys. `get_latest_provider_observation` performs actor, `einvoice.view` and `sales.can_access_sales_order` checks, then left-joins `provider_interaction_records` on tenant + stable interaction reference to return `correlation_id` in the DTO. Outside-scope orders return `NOT_FOUND`.

- [ ] **Step 3: Add trigger-scoped observation idempotency without a cadence rule**

`request_provider_observation_refresh` is service-role only and accepts an already resolved `tenantId`, `electronicInvoiceId`, caller-owned UUID `triggerId`, `triggerSource` (`POLICY` or `SUPPORT`) and `requestedBy` audit value. It verifies the invoice is issued and has a provider reference, then uses:

```sql
create or replace function einvoice._provider_observation_command_id(
  p_tenant_id uuid,
  p_electronic_invoice_id uuid,
  p_discriminator text
) returns uuid;

create or replace function einvoice.request_provider_observation_refresh(
  p_tenant_id uuid,
  p_electronic_invoice_id uuid,
  p_trigger_id uuid,
  p_trigger_source text,
  p_requested_by text
) returns table(command_id uuid, replayed boolean);
```

```text
dedupe key  = provider_observation:<tenantId>:<electronicInvoiceId>:<triggerId>
command id  = UUIDv5(namespace, dedupe key)
correlation = command id
```

It resolves the active `providerConnectionId` and inserts one `einvoice.poll_provider_observation` payload containing tenant, invoice, connection, trigger and correlation IDs with `on conflict (id) do nothing`. Replay of the same `triggerId` returns the same command; a distinct authorized trigger remains distinct even on the same date. No UTC date, minimum daily interval or implicit cadence participates in identity. There is no timer/seeder and no query over all issued invoices. The support/policy caller owns trigger authorization and target selection before invoking this internal RPC; future UI support tooling must expose a separate actor-scoped command rather than granting this service-role RPC to clients.

Protect MISA independently from idempotency: preserve the current single-worker processor's sequential claim execution, so at most one observation call is in flight in this deployment. HTTP 429, timeout and unavailable outcomes use existing queue backoff. Waiting/rate-limited commands remain queued and are not collapsed with another trigger. Multi-worker distributed rate limiting is a deployment-scale follow-up, not a daily domain invariant.

- [ ] **Step 4: Implement replay-safe interaction start/finalize RPCs**

Implement the frozen top-level `IProviderInteractionGateway` signature exactly. `start_provider_interaction` and `record_provider_interaction_result` require `service_role`; start validates the provider connection belongs to the same tenant. `correlationId` is deterministic UUIDv5 of `<internal-command-id>|provider-call|<worker-attempt-number>`, so every actual call has one audit row while replay before that call returns the same row.

Start inserts immutable direction/operation/target/request metadata and returns `status=STARTED, version=0`. Finalize compare-and-sets `expectedVersion`, changes `STARTED -> COMPLETED`, increments version and writes only typed references/outcome/safe error code. Duplicate finalize with identical terminal values returns the existing record; a changed outcome/reference raises `INTERACTION_RESULT_CONFLICT`. Unknown direction/outcome and raw summary/body parameters are not accepted by SQL or Dart.

Gateway tests assert these exact RPC parameters:

```dart
{
  'p_tenant_id': tenantId,
  'p_provider_connection_id': providerConnectionId,
  'p_direction': 'OUTBOUND',
  'p_operation_type': operationType,
  'p_target_type': targetType,
  'p_target_id': targetId,
  'p_correlation_id': correlationId,
  'p_request_reference': requestReference,
}

{
  'p_tenant_id': tenantId,
  'p_interaction_reference': interactionReference,
  'p_expected_version': expectedVersion,
  'p_outcome': 'TIMEOUT',
  'p_response_reference': null,
  'p_provider_reference': null,
  'p_safe_error_code': 'PROVIDER_TIMEOUT',
}
```

- [ ] **Step 5: Record provider facts and enqueue reliable attention events**

`record_provider_observation` requires `service_role` and a finalized interaction reference. It inserts with `on conflict (tenant_id, deduplication_key) do nothing`, then updates only `electronic_invoices.latest_provider_state_code` and `last_provider_observed_at` when the incoming observation is newer. It never modifies invoice number, provider identity, issuance attempts, snapshots or delivery state.

For `provider_state_code in ('NOT_FOUND','MISMATCH')`, the same RPC transaction inserts this deterministic outbox message:

```sql
insert into einvoice.outbox_messages (
  id, tenant_id, event_type, payload, occurred_at
) values (
  einvoice._provider_observation_command_id(
    p_tenant_id,
    p_electronic_invoice_id,
    'attention:' || p_deduplication_key
  ),
  p_tenant_id,
  'einvoice.provider_observation_attention_required',
  jsonb_build_object(
    'observation_id', v_observation_id,
    'electronic_invoice_id', p_electronic_invoice_id,
    'provider_state_code', p_provider_state_code,
    'provider_interaction_reference', p_provider_interaction_reference
  ),
  p_observed_at
) on conflict (id) do nothing;
```

The integration event mirrors only these safe fields. It is a neutral contract for the later alerts/support bounded context; E-invoice imports no Theme 10/11 module.

Revoke every Task 6 function from `public, anon, authenticated`; grant latest query to `authenticated`, and helper/start/finalize/request/context/record to `service_role`. Revoke direct table access from `anon, authenticated`.

- [ ] **Step 6: Implement handlers/gateways and verify**

The record command validator rejects blank interaction references, unknown state keys and non-allow-listed `detailsSnapshot` entries. The read mapper requires correlation from the joined interaction row; missing interaction is a contract error, not a nullable fake correlation.

```bash
dart format modules/einvoice/application/lib/src/electronic_invoice modules/einvoice/application/test/electronic_invoice modules/einvoice/integration_events modules/einvoice/infrastructure/lib/src/data_access modules/einvoice/infrastructure/lib/src/provider_interactions modules/einvoice/infrastructure/test/electronic_invoice modules/einvoice/infrastructure/test/provider_interactions
cd modules/einvoice/application && dart analyze && dart test test/electronic_invoice/record_provider_observation_command_handler_test.dart
cd modules/einvoice/integration_events && dart analyze && dart test
cd modules/einvoice/infrastructure && dart analyze && dart test test/electronic_invoice/einvoice_s4c_sql_contract_test.dart test/provider_interactions/supabase_provider_interaction_gateway_test.dart
```

Expected: PASS; timeout has an interaction record but no observation, and mismatch/not-found has exactly one observation plus one pending outbox event.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `feat(einvoice): audit provider observations and handoff attention`

---

### Task 7: Add three durable worker commands, same-operation retry and composition

**Files:**

- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/fetch_official_invoice_view/fetch_official_invoice_view_command.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/fetch_official_invoice_view/fetch_official_invoice_view_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/download_invoice_document/download_invoice_document_command.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/download_invoice_document/download_invoice_document_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/poll_provider_observation/poll_provider_observation_command.dart`
- Create: `modules/einvoice/application/lib/src/electronic_invoice/commands/poll_provider_observation/poll_provider_observation_command_handler.dart`
- Modify: `modules/einvoice/application/lib/src/issuance/commands/preview_invoice/preview_invoice_command.dart`
- Modify: `modules/einvoice/application/lib/src/issuance/commands/preview_invoice/preview_invoice_command_handler.dart`
- Modify: `modules/einvoice/application/lib/application.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/processing_module.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/official_view_command_dead_letter_handler.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/invoice_document_command_dead_letter_handler.dart`
- Generated: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/*.g.dart`
- Create: `modules/einvoice/application/test/electronic_invoice/s4_worker_handlers_test.dart`
- Modify: `modules/einvoice/application/test/issuance/preview_invoice_command_json_test.dart`
- Create: `modules/einvoice/application/test/issuance/preview_invoice_command_handler_test.dart`
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_s4_registration_test.dart`
- Modify: `modules/einvoice/infrastructure/test/configuration/einvoice_s2b_composition_test.dart`
- Modify: `modules/einvoice/infrastructure/test/preview_invoice_worker_test.dart`

**Interfaces:** Consumes typed provider/storage/interaction/gateway ports and operation contexts; produces serializable commands, one provider interaction per attempt, same-operation ambiguous retry and explicit observation processing. `ProcessInternalCommandsCommandHandler` claims already-enqueued commands only; S4 adds no observation seeder.

- [ ] **Step 1: Run impact for existing composition symbols**

Run upstream impact for `EinvoiceDataAccessModule.load`, `ProcessInternalCommandsCommandHandler.handle` and `EinvoiceProcessingModule.load`. Warn before edits if HIGH/CRITICAL. `IEinvoiceInternalCommandClient` does not change for S4 because observation collection is explicitly enqueued through Task 6.

- [ ] **Step 2: Write failing command serialization/handler tests**

Official command shape:

```dart
final class FetchOfficialInvoiceViewCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  FetchOfficialInvoiceViewCommand({
    String? id,
    required this.tenantId,
    required this.operationId,
    required this.electronicInvoiceId,
    required this.attemptOrdinal,
    required this.correlationId,
  }) : super(id);

  static const type = 'einvoice.fetch_official_view';
  @override
  String get commandType => type;
  @override
  final String tenantId;
  final String operationId;
  final String electronicInvoiceId;
  final int attemptOrdinal;
  final String correlationId;

  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId({
    'tenant_id': tenantId,
    'operation_id': operationId,
    'electronic_invoice_id': electronicInvoiceId,
    'attempt_ordinal': attemptOrdinal,
    'correlation_id': correlationId,
  });
}
```

Document command adds `documentType`, `operationGeneration` and `attemptOrdinal`; worker loads target `providerConnectionId`, `documentVersion` and expected DB versions from service-role context rather than trusting queue payload. Observation command contains `tenantId`, `providerConnectionId`, `electronicInvoiceId`, `triggerId` and `correlationId`. `PreviewInvoiceCommand` gains `providerConnectionId` from the repaired preview operation payload. Tests require `toJson/fromJson` round-trip with row id preserved, reject blank/invalid UUID `triggerId`, and prove two distinct trigger IDs on the same date remain distinct commands.

`ProcessInternalCommandsCommandHandler` copies the claimed row payload and injects reserved runtime key `_worker_attempt_number = row.retryCount + 1` before deserialization. Each S4 command and the existing `PreviewInvoiceCommand` read that key into a non-serialized `workerAttemptNumber` (default `1` only for direct unit deserialization); `toJson()` must never persist the reserved key. Handlers derive provider-call correlation as UUIDv5 of `<command.id>|provider-call|<workerAttemptNumber>`. Tests prove queue retry 1 and 2 create distinct interaction rows, while replay of the same claimed attempt reuses one row.

- [ ] **Step 3: Implement provider-call audit around every handler attempt**

Each handler executes this order:

```text
load current context and return on absent/already-terminal target
start ProviderInteractionRecord with provider connection, OUTBOUND direction,
operation/target, provider-call correlation and command.id request reference
make exactly one provider call
finalize interaction with safe typed outcome
record official/document result or provider observation using interactionReference
```

If the provider throws timeout/5xx/transport, finalize the interaction as `TIMEOUT` or `UNAVAILABLE`, then rethrow so queue retry applies. If interaction finalization itself fails, rethrow and do not persist a resource result; replay returns the same interaction from the unique correlation/operation key.

- [ ] **Step 4: Implement official/document terminal semantics**

Official success records AVAILABLE. Document success validates content, stores once, then records AVAILABLE with checksum/reference. Definite empty/no-document results record `FAILED/DOCUMENT_UNAVAILABLE`. Malformed content and auth/config errors record `CHECK_REQUIRED` immediately and do not retry/upload.

Timeout/5xx/transport never records FAILED. While attempts remain, the internal command is retried for the same operation. At max attempts, dedicated dead-letter handlers compare-and-set the still-PENDING resource to `CHECK_REQUIRED/PROVIDER_RESULT_UNDETERMINED`; operation id and generation remain unchanged. A user replay calls Task 3/4 request RPC, increments `attempt_ordinal`, resets that same row to PENDING and creates a new deterministic command id.

- [ ] **Step 5: Implement observation handler without fabricated facts**

On a found provider state, finalize interaction then dispatch the typed record command with dedupe key `provider_observation:<internal-command-id>`. On `NOT_FOUND` or `MISMATCH`, record the typed provider fact; Task 6 atomically emits the attention outbox event. On timeout/unavailable, finalize interaction and rethrow; retry exhaustion marks only the internal command failed. It does not call `recordProviderObservation` and does not update invoice latest-observation metadata.

Update the existing S2 `PreviewInvoiceCommandHandler` to use the same interaction gateway around `previewUnpublished`. Its target is `INVOICE_PREVIEW_OPERATION/<previewRequestId>`, request reference is `command.id`, and result continues to be stored by `store_preview_result` in `invoice_preview_operations`. Tests prove preview payload/viewer state never returns to `provider_interaction_records`.

- [ ] **Step 6: Enforce frozen attempt limits without changing S1-S3 policy**

Do not replace `retry_or_dead_letter_internal_command` from draft 007. Add an Infrastructure command policy:

```dart
const maxAttemptsByCommandType = <String, int>{
  FetchOfficialInvoiceViewCommand.type: 2,
  DownloadInvoiceDocumentCommand.type: 3,
};
```

`attemptNumber = row.retryCount + 1`. Below the limit, call existing `retryOrDeadLetter`. At the limit, call existing `fail`, then invoke the matching S4 dead-letter handler. Official/document dead-letter handlers write `CHECK_REQUIRED`, not `FAILED`; duplicate invocation and an already-terminal operation are no-ops. Observation and S1-S3 commands keep the existing generic retry/dead-letter behavior. The current `for` loop remains sequential, which is the S4 observation rate-concurrency guard for the single-worker deployment. Composition tests must prove that no method named `seedDueProviderObservationCommands` is added and the existing S3 reconciliation seeder behavior is unchanged.

- [ ] **Step 7: Register adapters, run codegen and verify**

Register `IProviderInteractionGateway`, provider/storage/command/read gateways and all three handlers in module-private GetIt. ERP receives `WorkerOnlyElectronicInvoiceProviderPort`; only messaging worker receives `MeInvoiceElectronicInvoiceProviderAdapter`.

```bash
melos run codegen
rg -n "einvoice.fetch_official_view|einvoice.download_invoice_document|einvoice.poll_provider_observation" modules/einvoice/infrastructure/lib/src/configuration/processing/generated
dart format modules/einvoice/application/lib modules/einvoice/infrastructure/lib modules/einvoice/application/test/electronic_invoice modules/einvoice/infrastructure/test/configuration
cd modules/einvoice/application && dart analyze && dart test test/electronic_invoice/s4_worker_handlers_test.dart
cd modules/einvoice/infrastructure && dart analyze && dart test test/configuration/einvoice_s4_registration_test.dart test/configuration/einvoice_s2b_composition_test.dart
```

Expected: three command types/deserializers/handlers are generated exactly once; provider calls are audited; ambiguous official/document exhaustion is CHECK_REQUIRED on the original operation; no S4 full-scan seeder exists.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `feat(einvoice): wire slice 4 worker commands`

---

### Task 8: Prove end-to-end BE/worker behavior with fakes

**Files:**

- Create: `modules/einvoice/infrastructure/test/einvoice_slice4_integration_test.dart`
- Create: `apps/messaging_worker/test/einvoice_worker_slice4_test.dart`
- Modify only if needed for deterministic fixtures: `packages/vet45_misa/lib/src/e_invoice/fake_me_invoice_client.dart`
- Modify only if fake changes: `packages/vet45_misa/test/e_invoice/fake_me_invoice_client_test.dart`

**Interfaces:** Consumes complete S4 CQRS/worker composition; proves request -> durable command -> interaction -> fake MISA -> storage/result/read/outbox behavior without network or applied draft.

- [ ] **Step 1: Write failing integration scenarios**

Cover these exact paths:

```text
official request/replay -> one operation; previewPublished once; AVAILABLE URL expires in 5m
official timeout twice -> same operation/generation becomes CHECK_REQUIRED; replay re-arms that operation
PDF request/replay -> one operation; download once; valid bytes stored once; signed URL + checksum
XML uses exact XML data type and content validation
unsupported PDF/XML capability -> DOCUMENT_UNAVAILABLE before operation, command, storage or provider call
same idempotency key with different intent -> IDEMPOTENCY_CONFLICT
SalesOrder out-of-scope -> NOT_FOUND and no invoice/document/provider data leak
definite empty document -> FAILED; later request may create next generation
document timeout three times -> same operation/document becomes CHECK_REQUIRED, never FAILED
malformed bytes -> CHECK_REQUIRED and no upload
same observation triggerId replayed twice -> one command
two distinct authorized triggerIds on the same date -> two commands and two independently auditable calls, executed sequentially with maxConcurrent=1
observation success -> one interaction + one safe append-only observation
observation timeout -> failed interaction only, no observation
observation NOT_FOUND/MISMATCH -> one observation + one reliable attention outbox event
permission denial returns no URL, viewer token or storage reference
ERP composition rejects MISA HTTP
```

Run:

```bash
cd modules/einvoice/infrastructure && dart test test/einvoice_slice4_integration_test.dart
cd apps/messaging_worker && dart test test/einvoice_worker_slice4_test.dart
```

Expected: FAIL until all fixtures/composition paths are connected.

- [ ] **Step 2: Build deterministic operation, interaction, outbox and storage fixtures**

The tests may fake RPC/clock/storage but must execute real command handlers, serializers, provider adapter/classifiers and worker processor. Inject `DateTime.utc(2026, 8, 31, 9)` and assert exact expiry `09:05:00Z`. Model optimistic `version`, `attemptOrdinal`, operation generation, unique interaction correlation and outbox id so duplicate callbacks prove compare-and-set/idempotency behavior.

- [ ] **Step 3: Extend `FakeMeInvoiceClient` only for missing deterministic scenarios**

Keep defaults backward compatible. Add queued outcomes for preview URL, PDF/XML bytes, status fact, timeout, not-found and mismatch. Never branch production adapter behavior on a test flag and never add raw provider payload to assertions/logging.

- [ ] **Step 4: Add static schema-contract assertions for the approved repairs**

Assert `invoice_documents.version bigint not null default 0`, nullable `requested_at`, absence of observation `correlation_id`, presence of interaction join, `sales.can_access_sales_order`, capability check before insert, and absence of a daily/full-scan observation function. Require trigger-scoped command identity and prove no UTC date expression participates in dedupe. Also assert the complete interaction field/check set, UUID correlation, payload-free audit rows, and preview RPC isolation through `invoice_preview_operations`. The contract test must fail if SQL contains an allow-all fallback or direct E-invoice read of Sales-owned tables.

- [ ] **Step 5: Verify packages and worker**

```bash
dart format packages/vet45_misa modules/einvoice/infrastructure/test apps/messaging_worker/test
cd packages/vet45_misa && dart analyze && dart test
cd modules/einvoice/infrastructure && dart analyze && dart test test/einvoice_slice4_integration_test.dart
cd apps/messaging_worker && dart analyze && dart test test/einvoice_worker_slice4_test.dart
```

Expected: PASS with zero external HTTP call and all seven approved review repairs covered by executable tests.

**Task gate complete.** Không tự commit; tiếp tục trên branch hiện tại. Gợi ý message nếu user commit: `test(einvoice): cover slice 4 worker flows`

---

### Task 9: Update harness truth and run final verification gates

**Files:**

- Modify: `docs/themes/TH-08-e-invoice/harness/01-domain-model.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/02-module-map.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/03-architecture-and-flows.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md`
- Modify: `docs/themes/TH-08-e-invoice/README.md`

**Interfaces:** Consumes verified implementation evidence; produces honest S4 lane status and frozen access/operation/interaction/job/storage contracts. FE/E2E remain unchanged unless independently proven.

- [ ] **Step 1: Record exact S4 contracts and evidence**

Document public/internal RPCs, three command types, operation identity, `attemptOrdinal`, official=2/document=3 retry semantics, `CHECK_REQUIRED` unresolved lock, capability preflight, source-owned SalesOrder scope gate, 5-minute URL TTL, private bucket policy, the full provider-interaction field/lifecycle/cardinality contract, trigger-scoped observation idempotency, sequential single-worker rate protection, allow-list and attention event. Correct `download_unavailable` to async definite FAILED and distinguish it from ambiguous timeout -> CHECK_REQUIRED.

Roadmap status rules are evidence-based:

```text
Worker = done only after focused + full worker tests pass.
BE Dart = done only after application/infrastructure tests pass.
BE DB = in_progress while sales.can_access_sales_order is absent or drafts are not promoted/applied.
FE = todo.
E2E = todo/blocked until DB dependency, promoted migration and UI flow exist.
```

The current repo has no `sales.can_access_sales_order` definition, so do not mark the aggregate S4 BE lane `done` during this plan unless the source-owned Sales implementation lands and its integration test passes. Never replace this blocker with allow-all or cross-module table access.

- [ ] **Step 2: Run SQL policy and harness guards**

```bash
melos run migrate:verify-policy -- --strict
bash scripts/ci/verify_harness.sh
```

Expected: strict policy PASS for draft headers/Touches. Harness PASS, or pre-existing unrelated failures are captured verbatim while S4-specific guards stay green.

- [ ] **Step 3: Run module/full verification**

```bash
melos bootstrap
melos run codegen
melos run analyze
melos run test
cd apps/messaging_worker && dart test
git diff --check
```

Expected: all commands PASS. Focused tests alone cannot close a lane.

- [ ] **Step 4: Check generated files, obsolete policy, placeholders and secrets**

```bash
rg -n "TODO|FIXME|throw UnimplementedError|rawPayload|access_token|authorization" modules/einvoice/application/lib/src/electronic_invoice modules/einvoice/infrastructure/lib/src supabase/migrations/_drafts/010_einvoice_s4a_official_view.sql supabase/migrations/_drafts/011_einvoice_s4b_documents.sql supabase/migrations/_drafts/012_einvoice_s4c_provider_observations.sql
rg -n "seed_due_provider_observation|seedDueProviderObservation|daily observation scan|UTC-day|YYYY-MM-DD.*observation" modules/einvoice/application/lib modules/einvoice/infrastructure/lib apps/messaging_worker/lib supabase/migrations/_drafts
rg -n "request_summary|response_summary|viewer_ref.*provider_interaction_records|correlation_id varchar" supabase/migrations/_drafts modules/einvoice/application/lib modules/einvoice/infrastructure/lib
git diff -- modules/einvoice/infrastructure/lib/src/configuration/processing/generated
```

Expected: no implementation placeholder, secret/raw payload, daily observation identity/scanner or preview payload on interaction audit; generated diff contains only expected registrations/metadata.

- [ ] **Step 5: Run GitNexus change audit**

```text
GitNexus detect_changes(scope: compare, base_ref: main)
```

Expected: affected flows are limited to e-invoice S4 resource reads, document retrieval, provider interaction/observation, attention outbox and messaging worker processing. Investigate unexpected IAM/Sales/Partner/Delivery impacts.

**Plan complete.** Không tự commit; thay đổi nằm trên branch hiện tại. Gợi ý message nếu user commit: `docs(einvoice): record slice 4 be worker evidence`

---

## Final reviewer checklist

- [ ] Public request RPC + internal command insert are one transaction for official view and documents.
- [ ] Actor, E-invoice permission and `sales.can_access_sales_order` are checked before resolving scoped resources; outside scope returns `NOT_FOUND`.
- [ ] Unsupported/unknown PDF/XML capability fails before operation, document or command creation.
- [ ] Replay never creates a competing active operation; CHECK_REQUIRED re-arms the same operation.
- [ ] Definite provider rejection may become FAILED; timeout/5xx/transport exhaustion becomes CHECK_REQUIRED with safe code `PROVIDER_RESULT_UNDETERMINED`.
- [ ] Official view does not create/use `InvoiceDocument` rows.
- [ ] `invoice_documents.version` is canonical and `requested_at` is nullable.
- [ ] PDF/XML AVAILABLE requires private storage reference + SHA-256 checksum.
- [ ] Signed URLs/viewer tokens are permission-checked and no longer than 5 minutes; Storage has scoped SELECT only and no authenticated writes.
- [ ] Every provider attempt has one canonical, versioned `ProviderInteractionRecord`; immutable start fields and once-only finalize fields match the frozen contract.
- [ ] `ProviderInteractionRecord.correlation_id` is UUID, request/response/provider references have distinct semantics, and no summary/body/viewer payload is persisted there.
- [ ] S2 preview state lives in `invoice_preview_operations`; preview RPC names/15-minute expiry remain backward compatible.
- [ ] Observation is append-only, has no duplicate `correlation_id`, derives correlation through `provider_interaction_reference`, and does not alter issuance lifecycle.
- [ ] Observation collection is explicit and deduplicated only by caller-owned triggerId; distinct triggers on the same day remain distinct and there is no tenant-wide scan.
- [ ] Observation timeout writes interaction failure only; NOT_FOUND/MISMATCH writes one observation and one transactional attention outbox event.
- [ ] Only messaging worker can call MISA; ERP host guard is tested.
- [ ] No live provider/network dependency in CI.
- [ ] Draft 010/011/012 have exact `Touches`, no timestamp migration and no promotion.
- [ ] Generated code came from codegen, not hand edits.
- [ ] Harness status reflects the unresolved Sales helper/DB promotion gate; FE/E2E are not prematurely marked done.
