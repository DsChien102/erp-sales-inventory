# E-Invoice S2b Backend Design

**Date:** 2026-08-27  
**Theme:** TH-08 — E-Invoice  
**Slice:** S2b BE — Manual issuance plus immediate-result subset of US-04
**Status:** Approved in chat; review corrections incorporated

## 1. Purpose

S2b builds the reusable invoice issuance engine behind manual issuance. A user-confirmed `IssueInvoiceCommand` must re-check authoritative state, atomically create immutable issuance state, commit that state before any MISA call, publish through the messaging worker, and land the immediate provider result without creating duplicate attempts or duplicate electronic invoices.

This engine is deliberately trigger-agnostic after the initial authorization step. S3a will reuse the same issuance-start boundary for automatic issuance, while S3b will extend the result boundary with reconciliation polling and explicit recovery workflows.

## 2. Canonical Inputs

The design implements and reconciles these sources:

- `docs/themes/TH-08-e-invoice/Epic-02-issue-from-sales-order/US-02.md`
- `docs/themes/TH-08-e-invoice/harness/01-domain-model.md`
- `docs/themes/TH-08-e-invoice/harness/03-architecture-and-flows.md`
- `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md` §S2b and the immediate-result subset of §S3b
- `docs/superpowers/plans/2026-08-27-einvoice-s2a-be.md`
- `docs/architecture/07-integration-and-messaging.md`
- [MISA meInvoice outbound Open API](https://www.misa.vn/154989/tai-lieu-open-api-tich-hop-hoa-don-dien-tu-misa-meinvoice-dau-ra/) for `RefID` duplicate detection and status lookup semantics. Confirmed from the doc: `RefID` ("Mã tham chiếu của hóa đơn") is a **GUID** (example `88d18970-380a-4138-bbce-e25049ca9e3c`), must be globally unique, is the duplicate-detection key ("check trùng theo key này"), and is a status-lookup input (`inputType=2`); on a duplicate the response returns the already-issued invoice. No explicit max length is published, so S2b pins `RefID` to a canonical UUID.

When labels differ, the contract shell already present in code is canonical for implementation naming: `IssueInvoiceCommand`, not the prose-only `StartManualInvoiceIssuance` name.

## 3. Scope

### 3.1 Included

- Manual issuance through `IssueInvoiceCommand`.
- Authoritative readiness re-evaluation at confirmation time.
- Controlled buyer completion for the current SalesOrder version when completion remains `OPEN`.
- Atomic creation or lookup of the ORIGINAL `InvoiceIssuance`.
- Atomic creation of one active `IssuanceAttempt` using the canonical §4.4.3 field set, including immutable `AttemptSnapshot`, `intent_hash`, canonical model version/hash, and durable `einvoice.publish_invoice` internal command containing the canonical payload.
- Worker-only MISA `publish` call outside database transactions.
- Immediate provider outcome normalization into success, definite failure, or undetermined.
- Immediate result landing:
  - success creates one `ElectronicInvoice` and immutable `InvoiceSnapshot`;
  - definite failure marks the attempt `FAILED`;
  - undetermined atomically marks the attempt `RECONCILING` and creates or continues its pending `ReconciliationCase` with `next_check_at` set — that pending case IS the durable S3b handoff (no internal command is enqueued) — without inventing failure.
- Durable local-finalization seam that cannot intentionally publish again after provider success evidence has been persisted.
- `GetOrderInvoiceProjectionQuery` for processing, issued, and failed display states.
- Atomic outbox events for processing, failed, and registered outcomes.
- Fake/in-memory tests, Supabase RPC contract tests, worker tests, DI/codegen, and draft SQL.

### 3.2 Excluded

- S2 FE confirmation sheet and polling UI.
- Automatic trigger consumption and `StartAutoIssuanceCommand` (S3a).
- `sales.order.completed` integration event ownership or Sales module changes (S3a).
- Execution of poll processing, provider callback ingestion, repeated polling, mismatch review, and case resolution (S3b). S2b owns only atomic pending-case creation/continuation (with `next_check_at`) required by an undetermined direct result; that pending case is the durable handoff and S2b enqueues no `einvoice.poll_issuance_status` internal command.
- Operator-facing local-finalization recovery command and reconciliation resolution (S3b).
- Business retry that creates a new attempt after definite failure (S3c).
- Adjusted/replacement invoices, cancellation, delivery, document download, and provider observation.
- Timestamped migrations or promotion of draft SQL.

### 3.3 S2b/S3b boundary

`US-02 FR-08` requires the publish result to be handed to result application. Result normalization, `ElectronicInvoice` registration, `InvoiceSnapshot`, and unknown-result reconciliation are responsibilities from `US-04`. Therefore this plan is explicitly traceable as **US-02 plus the immediate-result subset of US-04** rather than claiming that all result handling belongs to US-02:

- normalize the direct `publish` response;
- atomically apply success, definite failure, or undetermined;
- for undetermined, create or continue the single pending `ReconciliationCase` (with `next_check_at`) in the same transaction — the pending case is the durable S3b handoff; no internal command is enqueued;
- persist success evidence before any later local recovery work;
- expose the resulting projection.

S3b remains owner of poll-command execution, callbacks, mismatch review, case resolution, and explicit recovery commands. Because the unknown-result handoff is a pending `ReconciliationCase` (data), not an enqueued internal command, S2b can deploy ahead of S3b safely: pending cases stay inert and unread until the S3b poll consumer scans them (`next_check_at <= now()`). There is no unregistered-command "poison row" hazard and no queue-hold policy is required.

### 3.4 Upstream dependency boundary

Theme 05 does not yet expose the authoritative completed-SalesOrder snapshot contract, and the production Theme 03 buyer-completion adapter is not implemented. Existing S2a RPC defaults and fake gateways are test seams; they are not valid issuance inputs.

S2b therefore defines the exact SQL-owned source-snapshot contract consumed by `einvoice.issue_invoice`, implements the issuance engine against fakes/contract tests, and fails closed in production when the authoritative source contract is unavailable:

- no attempt is created;
- no publish command is enqueued;
- the command returns top-level `ISSUANCE_NOT_READY` with `details.blockers[]` containing `SOURCE_SNAPSHOT_UNAVAILABLE` and/or `BUYER_SOURCE_UNAVAILABLE`;
- no placeholder buyer, order-completed flag, totals, tax lines, or version is accepted for issuance.

These values are issuance blocker reasons, not new top-level exception codes and not members of `EInvoiceBlockedCodes`. When Theme 05 and Theme 03 land, their owned RPC/view contracts satisfy the SQL dependency without introducing a Dart `IIssuanceSourceSnapshotPort` or changing provider processing.

## 4. Architectural Decisions

### AD-01 — RPC is the authoritative mutation boundary

Application handlers orchestrate; they do not reproduce concurrency, uniqueness, or state-transition rules in unused mirror aggregates. Critical state changes and outbox/internal-command writes happen in Supabase RPC transactions.

`einvoice.issue_invoice` owns the start transaction. Result RPCs own terminal or reconciling transitions. No Dart-side PostgREST writes are allowed.

The SQL RPCs and constraints are the production enforcement-of-record because the mutation path is `handler -> gateway -> RPC`; conceptual aggregate rules document the model but are not described as runtime enforcement unless application code actually invokes them. The RPC may consume only an explicitly owned cross-context contract such as a Sales-owned snapshot RPC/view. It must not read private Sales or Partner tables directly.

### AD-02 — Commit the attempt before calling MISA

The start transaction must commit all of the following before the worker can call MISA:

- locked buyer completion when completion was required;
- ORIGINAL issuance identity;
- active attempt identity and sequence;
- immutable `AttemptSnapshot`;
- canonical `intent_hash`, model version and SHA-256 payload hash on the attempt;
- the canonical invoice payload inside the durable internal command, not duplicated on `IssuanceAttempt`;
- canonical attempt `idempotency_key`, which maps to MISA `RefID` as provider correlation/lookup identity — it must be a **canonical UUID** (validated at the command boundary) because it is transported unchanged as the GUID `RefID`;
- processing outbox event;
- `einvoice.publish_invoice` internal command.

If any item cannot be committed, no publish job exists and MISA is not called.

### AD-03 — The publish command is durable and attempt-scoped

`PublishInvoiceCommand` is a serializable internal command with:

```text
commandType: einvoice.publish_invoice
tenantId: String
attemptId: String
canonicalInvoice: Map<String, Object?>
payloadHash: String
idempotencyKey: String
```

The command payload is produced by `einvoice.issue_invoice` from the same immutable snapshot stored for the attempt. The publish handler must verify the stored attempt identity/hash through the result gateway and must never rebuild payload from current SalesOrder, Partner, profile, or connection data.

### AD-03a — Hashes are calculated and compared only as PostgreSQL `jsonb`

`einvoice.issue_invoice` constructs the provider-neutral payload as `jsonb` and stores `canonical_payload_hash = encode(digest(convert_to(canonical_jsonb::text, 'UTF8'), 'sha256'), 'hex')`. The worker transports that value as JSON data only; it never hashes `jsonEncode`, map iteration, or raw request bytes. `einvoice.prepare_issuance_publish` receives the payload as `jsonb`, recomputes `encode(digest(convert_to(p_canonical_payload::jsonb::text, 'UTF8'), 'sha256'), 'hex')` inside PostgreSQL, and compares it to the stored hash.

This makes object-key ordering and whitespace irrelevant while retaining JSON types and array order. Contract tests must submit semantically equal maps with different object-key order and assert the DB-side hash matches; a changed scalar value or array order must fail `STATE_CHANGED`.

### AD-04 — Provider outcomes are a closed application contract

`IMeInvoiceProviderPort.publish` returns a discriminated `MeInvoicePublishOutcome`, not a raw provider map:

```text
MeInvoicePublishSuccess
  providerReference
  invoiceNumber
  invoiceSeries
  issuedAt
  safeProviderEvidence

MeInvoicePublishDefiniteFailure
  providerCode
  providerMessage
  safeProviderEvidence

MeInvoicePublishUndetermined
  reasonCode
  safeProviderEvidence
```

Credentials, tokens, request headers, and unrestricted raw response bodies never enter attempt snapshots, audit payloads, commands, logs, or outbox events.

The same port exposes synchronous `validateCanonical(canonicalInvoice)`. `PublishInvoiceCommandHandler` calls this pure preflight before `prepare_issuance_publish` crosses the durable dispatch barrier. Invalid canonical data is an internal command-integrity failure: during bounded retries it does not call MISA and does not use the provider-rejection failure path.

Because `validateCanonical` is deterministic, retries cannot recover a genuinely corrupt payload. To prevent an attempt from being stranded in `PREPARING` after the command dead-letters, S2b defines a terminal dead-letter landing with its own mutation contract — the dedicated RPC `einvoice.record_issuance_command_integrity_failure(p_tenant_id, p_attempt_id, p_reason_code)`. On retry exhaustion the processing dead-letter handler calls it; it marks the attempt `FAILED` with `failure_code = 'COMMAND_INTEGRITY'`, leaves all `provider_*` fields null, and enqueues a system-origin failed event. This is explicitly a system fault — no MISA call occurred and no provider evidence exists — and it is a **separate RPC from `record_issuance_failure`**, so provider rejection and command-integrity failure are never conflated in reporting or projection.

### AD-05 — Unknown is not failure

Timeout, connection loss after request dispatch, an ambiguous provider response, a response that cannot be safely correlated, or a replay that finds dispatch already started must produce `RECONCILING`. The same transaction creates or continues the single pending `ReconciliationCase` with `next_check_at` set; that pending case is the durable handoff (S2b enqueues no `einvoice.poll_issuance_status` internal command). These cases must not produce `FAILED`, must not expose a manual retry action, and must keep the issuance operation locked against competition.

Only an explicit provider rejection known to have produced no invoice side effect may produce `FAILED`.

**Frozen decision — `DuplicateInvoiceRefID` is always `undetermined` in S2b.** Even when the duplicate response carries a correlatable invoice identity for the same `RefID`, S2b lands `undetermined` (never `success`, never `definiteFailure`). Trusting a duplicate response to auto-upgrade to `success` is deliberately deferred to S3b's status-lookup by the same `RefID`. This is a conscious safety-over-optimism tradeoff, not an oversight.

### AD-06 — Immediate success and local finalization are separated conceptually

`einvoice.record_issuance_success` uses one outer transaction with an inner `BEGIN ... EXCEPTION ... END` PL/pgSQL subtransaction. The outer scope validates and persists allow-listed correlated provider success evidence. The inner scope creates the `ElectronicInvoice`, immutable `InvoiceSnapshot`, and registered outbox event idempotently.

If the inner finalization block fails, only that block is rolled back; the caught exception must not escape. The outer scope retains success evidence, sets `SUCCEEDED + UNRESOLVED`, enqueues processing, and commits. Once success evidence is durably stored, recovery executes local finalization only; it does not call `publish` again. The explicit recovery command remains S3b, but S2b makes this branch contract-tested and idempotent.

There is an unavoidable process-crash window between dispatch and durable result landing. MISA `RefID` is the persisted attempt `idempotency_key`, used for provider correlation and duplicate detection, not proof that repeated publish is idempotent. Once `prepare_issuance_publish` crosses the durable dispatch barrier, any replay returns `reconcileOnly`; it must never call publish again. S3b resolves the ambiguity by status lookup with the same `RefID`.

**Semantics of `submitted_at` (frozen).** `prepare_issuance_publish` sets `submitted_at` once *at barrier crossing*, i.e. **before** the MISA HTTP call. It records intent-to-submit / that the one-way barrier was crossed — deliberately set-before-send so a crash between barrier and HTTP is conservatively reconciled rather than lost. `submitted_at` is **not** proof that the provider received or acknowledged the request; provider acknowledgement is captured separately by `provider_confirmed_at` on a correlated success. Readers and projections must not treat `submitted_at` as provider receipt.

### AD-07 — Technical replay and business retry are different

- Technical replay keeps the same internal command, attempt, snapshot, payload hash, and `idempotency_key`, but retaining identity does not authorize a repeated provider call.
- `PREPARING` may cross the dispatch barrier exactly once and return `callProvider`; `WAITING_RESULT` returns `reconcileOnly`; terminal or already-reconciling state returns `skip`.
- Business retry creates a new attempt and is excluded until S3c.
- A reconciling attempt is never eligible for business retry.
- A repeated `IssueInvoiceCommand` returns the existing attempt only for the same `idempotency_key` and equal `intent_hash`; the same key with changed intent is `IDEMPOTENCY_CONFLICT`.

**Frozen decision — VET45 deliberately diverges from MISA's client-retry guidance for publish.** MISA's Open API recommends client retry for some transient/ambiguous publish errors. VET45 does **not** auto-republish after the dispatch barrier: post-barrier ambiguity is resolved by `RefID` status-lookup in S3b, never by a second `publish`. Only technical faults strictly *before* the barrier retry the same internal command. This is a conscious safety divergence to prevent duplicate invoices, and it is frozen here so it is not "corrected" back toward MISA's retry advice later.

### AD-08 — Projection is a read gateway

`GetOrderInvoiceProjectionQuery` reads a dedicated RPC/view contract and returns a presentation-safe DTO. It does not load aggregates or infer state in the query handler.

Display mapping:

| Authoritative state | Projection state | Actions |
| --- | --- | --- |
| no issuance | notIssued | issue |
| PREPARING, SUBMITTED, WAITING_RESULT, RECONCILING, or finalization pending | processing | none |
| SUCCEEDED + ElectronicInvoice exists | issued | view |
| definite FAILED | failed | issue |

The `issue` action after definite failure is only a projection contract in S2b; creating a new attempt is implemented in S3c.

## 5. Domain Model

### 5.1 Bounded context responsibility

The E-Invoice context owns issuance lifecycle, attempts, snapshots, provider-result classification, and the registered electronic invoice. It does not own SalesOrder commercial state, Partner master data, legal-profile master data, or MISA credentials.

Cross-context information is copied into immutable snapshots with lineage. The domain never imports Sales, Partner, or IAM domain entities.

### 5.2 Aggregates and embedded values

#### Conceptual `InvoiceIssuance` aggregate root

- Identity: `issuanceId`.
- External identity: tenant + SalesOrder + `IssuanceType.original`.
- Owns the sequence of `IssuanceAttempt` children.
- Defines the at-most-one-active-attempt invariant; `issue_invoice` and database constraints enforce it on the production mutation path.
- References at most one original `ElectronicInvoice`.
- Does not mutate SalesOrder.

#### `IssuanceAttempt` child entity

- Identity and monotonically increasing sequence within an issuance.
- Status: `preparing`, `submitted`, `waitingResult`, `reconciling`, `succeeded`, `failed`.
- Owns exactly one immutable `AttemptSnapshot`.
- Persists the canonical §4.4.3 fields: resolved connection/profile, `idempotency_key`, `intent_hash`, snapshot schema/version, canonical model/hash, normalized provider-result/failure fields, `internal_finalization_state`, and lifecycle timestamps. It does not persist the runtime canonical payload, a second provider-correlation key, generic evidence JSON, or a duplicate dispatch timestamp.
- In S2b, `provider_interaction_reference` remains **null**: S2b writes no `provider_interaction_records` rows. Those audit records (the shared-technical `provider_interaction_records` table) and the population of `provider_interaction_reference`/`latest_provider_interaction_reference` are owned by S3b provider-observation. S2b persists only the safe `provider_result_*`/`failure_*` fields directly on the attempt.

#### `AttemptSnapshot` immutable value

Contains the seller snapshot, effective buyer snapshot, SalesOrder commercial/tax lines, effective issuance configuration, warning acknowledgements, source references, SalesOrder version, buyer partner lineage, and buyer-completion lineage. It is never changed by technical replay.

#### `ElectronicInvoice` aggregate root

- Created only after correlated provider success.
- Unique per ORIGINAL issuance.
- Stores provider reference, invoice identity, and immutable `InvoiceSnapshot` derived from the successful `AttemptSnapshot` plus safe provider result fields.
- Does not re-resolve seller, buyer, SalesOrder, or Theme 03 data during finalization.

#### `ReconciliationCase` process entity

- References exactly one `IssuanceAttempt`; it does not own the attempt's authoritative result.
- Has at most one pending case per tenant + target + purpose.
- S2b generates `correlation_id = einvoice:reconcile:{caseId}` only when opening a new case and reuses the stored value for a pending-case continuation.
- S2b creates or continues the pending case with `next_check_at` atomically with the `RECONCILING` transition; the pending case is itself the durable polling handoff (no internal command). S3b's poll consumer discovers it by scanning `next_check_at`.
- S3b owns polling history, callback evidence, resolution, mismatch review, and terminal `resolved`/`unresolved` policy.

### 5.3 Invariants

| Rule | Enforcement |
| --- | --- |
| One ORIGINAL issuance per tenant + SalesOrder | `issue_invoice` guard plus database unique constraint |
| One active attempt per issuance | `issue_invoice` guard plus partial unique constraint |
| One ElectronicInvoice per ORIGINAL issuance | `record_issuance_success` plus database unique constraint |
| AttemptSnapshot exists before publish | Start RPC transaction and internal-command foreign identity |
| AttemptSnapshot/model version/payload hash are immutable | No update RPC; command payload is recomputed and hash-checked by `prepare_issuance_publish` |
| Buyer completion must be LOCKED before an attempt when completion is required | Start RPC under row lock |
| Same idempotency key + same business intent returns the existing attempt | Unique idempotency identity plus equal `intent_hash` RPC replay branch |
| Same idempotency key + different business intent is rejected | `IDEMPOTENCY_CONFLICT` before upstream source read |
| Stale SalesOrder source version cannot start | opaque `source_version` authoritative equality comparison; no numeric semantics |
| Timeout/ambiguous result cannot become FAILED | Closed result classification and transition rule |
| Success/failure applies only to matching tenant, attempt, idempotency identity, and payload hash | Result RPC guards |
| Provider success cannot create two ElectronicInvoices | Idempotent finalization plus unique constraint |
| An undetermined attempt has one active reconciliation process | unknown-result RPC upsert plus pending-case unique constraint |
| Dispatch barrier is crossed once | `prepare_issuance_publish` action contract; replay never republishes |

**Frozen decision — version representation diverges by command, intentionally.** `IssueInvoiceCommand` uses an **opaque `String sourceVersion`** compared by exact text equality (authoritative issuance-time token). Its sibling commands `CompleteBuyerInvoiceDataCommand`, `RequestInvoicePreviewCommand`, and `RetryIssuanceCommand` keep `int expectedOrderVersion` (Sales optimistic-concurrency, used pre-issuance). The two do not clash at runtime: buyer completion inside `issue_invoice` resolves through the SQL-owned source-snapshot contract, not the numeric field. This divergence is deliberate and frozen — do not "unify" the sibling commands onto a string, and do not add numeric semantics to `sourceVersion`.

### 5.4 Domain events

Domain events remain in-module facts and are not published directly. The critical production path writes integration outbox messages server-side in the same RPC transaction.

- `IssuanceAttemptStarted`
- `IssuanceResultUndetermined`
- `IssuanceFailed`
- `IssuanceSucceeded`
- `ElectronicInvoiceRegistered`

## 6. Application Layer

### 6.1 User command

`IssueInvoiceCommand` remains the public manual-start contract:

```dart
IssueInvoiceCommand({
  String? id,
  required String tenantId,
  required String actorId,
  required String salesOrderId,
  required String sourceVersion,
  required String idempotencyKey,
  bool? acknowledgeWarnings,
})
```

Its handler:

1. relies on the command pipeline for tenant and `EInvoicePermissions.issue` checks;
2. asks `IIssuanceCommandGateway.issueInvoice(...)` to execute the authoritative transaction;
3. maps the gateway result to `IssueInvoiceResultDto` whose `status` is the attempt's `IssuanceAttemptStatus` enum — `preparing` on a fresh start, or the existing attempt status on replay (never the projection string `PROCESSING`);
4. does not call MISA and does not enqueue in Dart.

Input-shape validation lives in `IssueInvoiceCommandValidator`; conceptual business invariants are documented in the domain model and enforced on the production path by RPCs/constraints. The validator additionally rejects an `idempotencyKey` that is not a canonical UUID, since it becomes the MISA GUID `RefID` unchanged.

### 6.2 Internal publish command

`PublishInvoiceCommand implements ISerializableInternalCommand` is dispatched only by the E-Invoice internal-command worker. Its handler:

1. calls `IMeInvoiceProviderPort.validateCanonical(...)` before the durable dispatch barrier;
2. validates the command payload/hash and obtains `PublishPreparationAction` from `IIssuanceResultGateway.preparePublish(...)`;
3. for `callProvider`, invokes `IMeInvoiceProviderPort.publish(...)` exactly once outside a database transaction;
4. for `reconcileOnly`, calls `recordUndetermined` with `DISPATCH_STATE_UNCERTAIN` without calling MISA;
5. for `skip`, returns without a provider call;
6. maps a direct closed provider outcome to `recordSuccess`, `recordDefiniteFailure`, or `recordUndetermined`.

Provider failures are data when classified; they are not thrown as generic worker errors. Only technical inability to start or durably record a result is thrown to processing infrastructure.

### 6.3 Immediate result contract

The existing raw-map `RecordIssuanceResultCommand` shell is not used as the worker/provider boundary in its current form. **S2b keeps this command DORMANT**: the immediate-result path routes classification privately in `PublishInvoiceCommandHandler` and calls typed `IIssuanceResultGateway` methods directly, and never dispatches `RecordIssuanceResultCommand`. The command (and its generated access metadata) is left untouched — it is entangled with uncommitted S2a work, so deleting it now is out of scope. S3b will retype it (raw `Map<String, Object?> providerResult` → typed evidence envelope) when it becomes the poll/callback result entry point.

The selected implementation must satisfy both rules:

- provider-specific response parsing stays in the MISA adapter;
- RPC parameters are explicit safe fields, never an unrestricted provider response map.

### 6.4 Projection query

`GetOrderInvoiceProjectionQueryHandler` depends only on `IOrderInvoiceProjectionReadGateway`. The gateway returns `OrderInvoiceProjectionDto` and enforces tenant scope in its RPC.

### 6.5 Ports

```text
IIssuanceCommandGateway
  issueInvoice(IssueInvoiceRequest) -> IssueInvoiceStartDto

IIssuanceResultGateway
  preparePublish(PublishAttemptEnvelope) -> PublishPreparationAction
  recordSuccess(IssuanceSuccessEvidence) -> RecordIssuanceResultDto
  recordDefiniteFailure(IssuanceFailureEvidence) -> RecordIssuanceResultDto
  recordUndetermined(IssuanceUndeterminedEvidence) -> RecordIssuanceResultDto

IOrderInvoiceProjectionReadGateway
  getBySalesOrder(tenantId, actorId, salesOrderId) -> OrderInvoiceProjectionDto

IMeInvoiceProviderPort   (EXTEND the existing port — keep S1/S2a methods)
  authenticateAndListTemplates(...)   // existing, used by capability sync
  previewUnpublished(...)             // existing, used by preview
  validateCanonical(canonicalInvoice) -> void          // added by S2b
  publish(tenantId, canonicalInvoice, idempotencyKey)  // added by S2b
    -> MeInvoicePublishOutcome
```

`validateCanonical`/`publish` are **added** to `IMeInvoiceProviderPort`; the existing `authenticateAndListTemplates` and `previewUnpublished` must remain (S1/S2a depend on them). Do not replace the interface.

One DTO occupies one file and is colocated with its single use case unless shared by two or more issuance use cases.

The source anti-corruption boundary is the SQL-owned `einvoice.load_issuance_source_snapshot` contract called only inside `einvoice.issue_invoice`, after same-idempotency replay is checked. This preserves the atomic authoritative re-check and prevents current upstream unavailability from breaking replay of an already-created attempt. Theme 03 lookup remains behind an owned SQL contract and is used only for permitted missing fields while current-version completion is `OPEN`.

## 7. Infrastructure Layer

### 7.1 Supabase schema draft

S2b adds one cohesive draft SQL file under `supabase/migrations/_drafts/`; no timestamped migration is created.

Tables:

- `einvoice.invoice_issuances`
- `einvoice.issuance_attempts`
- `einvoice.electronic_invoices`
- `einvoice.invoice_reconciliation_cases`, using the canonical §4.4.6 polymorphic process schema; S2b uses its `ISSUANCE_ATTEMPT`/`DETERMINE_RESULT` specialization for the unknown-result handoff

Snapshots remain JSONB embedded in their owning row, matching the canonical relational model. They are not separate tables.

Every new S2b table (`invoice_issuances`, `issuance_attempts`, `electronic_invoices`, `invoice_reconciliation_cases`) carries the repo-standard common audit columns `created_at`/`updated_at` (`timestamptz not null default now()`), consistent with the S2a schema (`005_einvoice_s2a_schema.sql`). These convention columns are not the forbidden parallel business aliases.

Required constraints include the canonical §4.4.3/§4.4.6 fields and names, tenant-aware foreign keys, ORIGINAL issuance uniqueness, one-active-attempt partial uniqueness, attempt idempotency uniqueness, one-original-electronic-invoice uniqueness, one active case per target/purpose, non-empty hashes/correlation identities, and state-consistent terminal fields. S2b must not create parallel replacements such as `provider_correlation_key`, `safe_provider_evidence`, `dispatch_started_at`, `internal_finalization_status`, or a case-specific `attempt_id`/`purpose` table shape.

RLS denies direct client mutation. Service-role mutation occurs only through scoped RPCs with explicit tenant checks. Read projection is exposed through a security-definer RPC or approved view/RPC pattern matching current E-Invoice infrastructure.

### 7.2 RPCs

S2b owns these draft RPC contracts:

| RPC | Transaction responsibility |
| --- | --- |
| `einvoice.issue_invoice` | Compute `intent_hash`; same key/equal hash replay, same key/different hash `IDEMPOTENCY_CONFLICT`; then re-check readiness/version, lock completion, create attempt/snapshot, enqueue publish command and processing event |
| `einvoice.prepare_issuance_publish` | Recompute DB-side `jsonb` canonical payload hash, verify attempt/idempotency, set canonical `submitted_at` once, and return `callProvider`, `reconcileOnly`, or `skip` |
| `einvoice.record_issuance_success` | Persist safe provider success in outer scope; finalize one ElectronicInvoice/InvoiceSnapshot in a caught inner subtransaction; preserve evidence as `UNRESOLVED` if finalization fails |
| `einvoice.record_issuance_failure` | Apply only definite provider failure, preserve SalesOrder, enqueue failed event |
| `einvoice.record_issuance_command_integrity_failure` | System-origin terminal for exhausted canonical-integrity dead-letter: set attempt `FAILED` with `failure_code = 'COMMAND_INTEGRITY'`, null all `provider_*` fields, enqueue a system-origin failed event; no MISA call, no provider evidence; separate from the provider `record_issuance_failure` path |
| `einvoice.record_issuance_undetermined` | Move to RECONCILING, upsert canonical pending ReconciliationCase (`ISSUANCE_ATTEMPT` + `DETERMINE_RESULT`) with `next_check_at` (the durable handoff — no internal command), and enqueue the processing event atomically |
| `einvoice.get_order_invoice_projection` | Return the tenant-scoped display projection and actions |

S2b uses the three explicit provider-result RPCs above (success / definite failure / undetermined), plus the separate system-origin `record_issuance_command_integrity_failure` terminal, which is not a provider result. The implementation updates `07-api-contracts.md` before code so the consolidated draft name `einvoice.record_issuance_result` is replaced for the immediate-result path. This makes definite-failure versus undetermined impossible to confuse at the call site. S3b consumes the pending reconciliation cases (scanning `next_check_at`) and may orchestrate the same typed result RPCs from `RecordIssuanceResultCommand`; it does not reintroduce a raw provider map.

### 7.3 Gateways and adapters

Infrastructure implementations live under focused issuance/electronic-invoice folders, not new root-level global buckets:

```text
modules/einvoice/infrastructure/lib/src/domain/issuance/
  supabase_issuance_command_gateway.dart
  supabase_issuance_result_gateway.dart
  supabase_order_invoice_projection_read_gateway.dart

modules/einvoice/infrastructure/lib/src/adapters/misa/
  me_invoice_provider_adapter.dart
```

`EinvoiceDataAccessModule` registers the gateways. `EinvoiceMediationModule` registers handlers through generated CQRS registration. The module-private GetIt container remains the composition boundary.

### 7.4 Messaging and outbox

`einvoice.issue_invoice` inserts `PublishInvoiceCommand` into `einvoice.internal_commands` in the same transaction as the attempt. The worker claims and deserializes it through the generated internal-command registry.

Outbox mappings must include:

- `einvoice.issuance.processing`
- `einvoice.issuance.failed`
- `einvoice.electronic_invoice.registered`

Every outbox event is written atomically with the state it describes. `EinvoiceOutboxModule` must map the existing integration event classes so `ProcessOutboxCommandHandler` can publish them.

### 7.5 Processing failure policy

`einvoice.publish_invoice` is never repeated after the durable dispatch barrier. A replay that sees `WAITING_RESULT` records/continues `RECONCILING` and completes the publish command without calling MISA. An explicit definite rejection records `FAILED` and completes the command.

Technical failures before `prepare_issuance_publish` crosses the barrier may retry the same internal command with bounded backoff. A crash after the barrier but before the HTTP call is conservatively reconciled; safety is preferred over an automatic duplicate publish. Failures after correlated success evidence has been durably recorded may retry local finalization only. The internal-command failure contract distinguishes retryable pre-barrier, reconciliation-only post-barrier, terminal business outcome, and finalization-only recovery. A deterministic canonical-integrity fault (`validateCanonical` rejects before the barrier) is a fifth class: it retries with bounded backoff and, on exhaustion, the dead-letter handler calls `einvoice.record_issuance_command_integrity_failure` to land a system-origin terminal `FAILED` (`failure_code = 'COMMAND_INTEGRITY'`), so the attempt never stays stranded in `PREPARING`.

## 8. End-to-End Data Flow

### 8.1 Start manual issuance

```text
UI/host
  -> IEinvoiceModule.executeCommandAsync(IssueInvoiceCommand)
  -> scoped command pipeline: tenant + permission + validator
  -> IssueInvoiceCommandHandler
  -> IIssuanceCommandGateway
  -> einvoice.issue_invoice transaction
       authoritative SalesOrder/version/config/buyer checks
       lock BuyerInvoiceCompletion when required
       create/replay ORIGINAL InvoiceIssuance
       create IssuanceAttempt + immutable AttemptSnapshot
       create canonical payload for the durable command
       persist canonical attempt fields: intent hash, model version, payload hash, idempotency identity
       enqueue einvoice.publish_invoice containing that payload
       enqueue einvoice.issuance.processing outbox event
  <- issuanceId + attemptId + attempt status (IssuanceAttemptStatus: preparing on fresh start / existing status on replay)
```

### 8.2 Publish and land result

```text
messaging worker
  -> ProcessInternalCommandsCommand
  -> generated serializer
  -> PublishInvoiceCommandHandler
  -> prepare_issuance_publish RPC -> callProvider | reconcileOnly | skip
  -> callProvider: IMeInvoiceProviderPort.publish once (outside DB transaction)
       success          -> record_issuance_success RPC
       definite failure -> record_issuance_failure RPC
       undetermined     -> record_issuance_undetermined RPC
  -> reconcileOnly: record_issuance_undetermined without provider call
       atomically upsert pending ReconciliationCase (next_check_at) = durable handoff; no internal command
  -> skip: no provider/result mutation
  -> complete internal command
  -> ProcessOutboxCommand publishes committed integration event
```

### 8.3 Projection

```text
GetOrderInvoiceProjectionQuery
  -> IOrderInvoiceProjectionReadGateway
  -> einvoice.get_order_invoice_projection
  -> OrderInvoiceProjectionDto
```

## 9. Error Semantics

Pre-provider errors are stable business errors returned from `IssueInvoiceCommand`:

- `NOT_FOUND`
- `ORDER_NOT_COMPLETED`
- `CONFIG_NOT_READY`
- `ISSUANCE_NOT_READY`
- `BUYER_DATA_INCOMPLETE`, including `BUYER_TAX_CODE_REQUIRED`
- `ALREADY_ISSUED`
- `OPERATION_IN_PROGRESS`
- `IDEMPOTENCY_CONFLICT`
- `STATE_CHANGED`
- pipeline-owned `NO_PERMISSION`

Provider outcomes after dispatch:

- success: `SUCCEEDED`, invoice registered;
- definite rejection: `FAILED`, safe provider code/message stored;
- timeout/ambiguous/correlation uncertainty: `RECONCILING`;
- local persistence failure after durable success evidence: finalization pending/unresolved, still projected as processing, never as provider failure.

No result path changes SalesOrder status or commercial data.

## 10. Security and Audit

- Provider calls occur only in `apps/messaging_worker` using service-role infrastructure.
- Credentials are read through the existing worker-only credential RPC and never serialized into commands.
- All RPCs require tenant identity and validate row tenant ownership.
- User commands carry actor identity for audit; worker commands use attempt/idempotency identities. A `ReconciliationCase` creates its own canonical `correlation_id` when unknown result processing begins.
- Logs contain IDs, status, safe codes, and hashes, not credentials or full invoice payloads.
- AttemptSnapshot and InvoiceSnapshot retain source/version/buyer-completion lineage required by NFR-08.
- Provider evidence is allow-listed before persistence.

## 11. Test Strategy

### 11.1 Domain model and policy coverage

- Existing runtime-used pure domain services/enums retain their focused tests.
- S2b does not add mirror aggregate tests for objects that the handler never loads or saves.
- ORIGINAL uniqueness, active-attempt rules, status transitions, immutable snapshot/hash, one-invoice finalization, and reconciliation-case uniqueness are executable SQL contract/integration assertions in §11.3.

### 11.2 Application tests

- Validator rejects empty IDs, blank opaque source version, and empty idempotency key.
- Permission and tenant decorators are enforced by `PipelineTestHarness`.
- Issue handler calls only the command gateway and maps replay correctly.
- Publish handler verifies envelope before provider call.
- Success, definite failure, and undetermined each call exactly one typed result method.
- Undetermined and `reconcileOnly` do not throw a generic worker failure, do not call failure landing, and do not re-publish.
- Provider success replay does not create or request a new attempt.
- Projection handler delegates to its read gateway.

### 11.3 Infrastructure and contract tests

- RPC names and parameter keys match draft SQL.
- Start RPC atomically writes attempt/snapshot/hash/internal command/outbox.
- Repeated idempotency key returns the same attempt only when `intent_hash` matches.
- Concurrent start is protected by database constraints and row locks.
- Same idempotency key/equal intent hash replays; same key/different intent hash returns `IDEMPOTENCY_CONFLICT` without upstream reads or enqueueing publish.
- Stale opaque source version, not-ready config, incomplete buyer, active operation, and already-issued branches return stable codes without enqueueing publish.
- Result RPCs reject wrong tenant, attempt, idempotency identity, payload hash, and invalid status.
- DB-side `jsonb` hash accepts reordered object keys but rejects changed scalar/array content; no Dart-side byte hash participates.
- Success landing is idempotent and creates one ElectronicInvoice.
- Unknown landing atomically produces RECONCILING and one pending ReconciliationCase with `next_check_at` (the durable handoff), enqueues no `einvoice.poll_issuance_status` internal command, and exposes no publish retry action.
- Success finalization failure preserves evidence, returns `SUCCEEDED + UNRESOLVED`, enqueues processing, and does not throw from the RPC.
- Projection maps all processing states, issued, and failed.
- RLS/direct-write guards remain intact.

### 11.4 Provider and worker tests

- MISA adapter maps success, explicit rejection, auth failure, timeout, and malformed/ambiguous response into the closed outcome contract.
- Attempt `idempotency_key` is passed unchanged as MISA `RefID`; tests do not call it an idempotency guarantee.
- Same-series publish scheduling is single-flight/sequential as required by the MISA integration contract.
- Worker command serialization round-trips without row `id` in payload.
- Generated registry recognizes `einvoice.publish_invoice`.
- One failing E-Invoice job does not stop the worker tick for other tenants/modules.
- Outbox mapper recognizes processing, failed, and registered event types.

## 12. File Responsibility Map

The implementation plan will decompose work around these responsibilities:

```text
modules/einvoice/domain/lib/src/issuance/
  existing enums/services               shared language and pure policies already used at runtime

No new Dart InvoiceIssuance/ElectronicInvoice mirror aggregates are added in S2b.
The RPC/constraint path is production enforcement-of-record; the harness remains
the conceptual aggregate specification until a repository-backed runtime path exists.

modules/einvoice/application/lib/src/issuance/commands/issue_invoice/
  issue_invoice_command_handler.dart
  issue_invoice_command_validator.dart

modules/einvoice/application/lib/src/issuance/commands/publish_invoice/
  publish_invoice_command.dart
  publish_invoice_command_handler.dart

modules/einvoice/application/lib/src/issuance/queries/get_order_invoice_projection/
  get_order_invoice_projection_query_handler.dart

modules/einvoice/application/lib/src/issuance/shared/
  typed start/result/evidence DTOs used by multiple issuance use cases

modules/einvoice/application/lib/src/ports/
  i_issuance_command_gateway.dart
  i_issuance_result_gateway.dart
  i_order_invoice_projection_read_gateway.dart
  i_me_invoice_provider_port.dart

modules/einvoice/infrastructure/lib/src/domain/issuance/
  Supabase gateway implementations

modules/einvoice/infrastructure/lib/src/adapters/misa/
  provider outcome mapping

modules/einvoice/infrastructure/lib/src/configuration/
  DI, generated CQRS/internal-command registry, outbox event map

supabase/migrations/_drafts/
  S2b schema + RPC draft, including the canonical §4.4.6 reconciliation case
  (ISSUANCE_ATTEMPT/DETERMINE_RESULT specialization) and its next_check_at handoff, only

test trees under domain/application/infrastructure, packages/vet45_misa,
and apps/messaging_worker
```

## 13. Implementation Sequencing

1. Align US-02/US-04 traceability, opaque source version, blocker reasons, result RPCs, and the S2b/S3b deployment boundary.
2. Draft schema, constraints, RPCs, RLS, the canonical §4.4.6 reconciliation case (ISSUANCE_ATTEMPT/DETERMINE_RESULT) with its next_check_at handoff, and nested-success semantics.
3. Implement Issue command contract/handler and Supabase start gateway without a Dart source-snapshot port.
4. Implement typed provider publish port and MISA adapter using `RefID` as correlation/lookup identity.
5. Implement serializable publish command, three-action dispatch barrier, immediate-result gateways, and worker behavior.
6. Implement projection query/read gateway.
7. Wire DI, outbox types, code generation, worker binding, and same-series scheduling.
8. Run focused tests, SQL text/contract verification, package analysis, codegen, worker verification, and harness verification.

## 14. Acceptance Mapping

| Requirement | Design mechanism |
| --- | --- |
| AC-01 authorized manual issuance | command pipeline + issue RPC |
| AC-02 snapshot before provider | atomic attempt snapshot/hash + canonical payload in durable command |
| AC-03 seller/buyer snapshot precedence | authoritative snapshot builder + locked completion |
| AC-04 duplicate confirmation | command idempotency uniqueness + replay branch; provider RefID is not treated as retry authorization |
| AC-05 changed config/order blocks | authoritative re-check + opaque source-version equality |
| AC-06 timeout is not failure | undetermined outcome -> RECONCILING |
| AC-07 SalesOrder unchanged | E-Invoice-only mutation RPCs |
| AC-08 incomplete buyer blocks before attempt | controlled completion inside start transaction |
| AC-09 locked completion is stable | no Theme 03 re-resolution after LOCKED |

## 15. Review Checklist

- [x] Lifecycle and bounded-context ownership are explicit.
- [x] Manual and future automatic triggers converge on one issuance engine.
- [x] Domain, application, infrastructure, and worker responsibilities are separated.
- [x] AttemptSnapshot commits before provider dispatch.
- [x] Provider call occurs outside database transactions.
- [x] Duplicate prevention exists at command/RPC/database levels without relying on a provider exactly-once guarantee.
- [x] Timeout/ambiguous result maps to RECONCILING, not FAILED.
- [x] RECONCILING atomically owns a pending ReconciliationCase whose `next_check_at` is the durable polling handoff; no internal command is enqueued.
- [x] Post-dispatch replay never calls publish again; RefID is correlation/lookup identity only.
- [x] Success finalization is idempotent and preserves snapshot lineage.
- [x] Nested success finalization failure preserves evidence as SUCCEEDED + UNRESOLVED and does not escape the RPC.
- [x] Scope is traceable as US-02 plus immediate-result subset of US-04; S3b owns poll execution/resolution/recovery.
- [x] SQL remains draft-only.
- [x] No cross-module entity imports or direct SalesOrder mutation are introduced.
- [x] Missing Theme 05/Theme 03 authoritative contracts fail closed; S2a placeholders cannot issue.
- [x] Source version is opaque text across the S2b command/gateway/RPC boundary.
- [x] Source/buyer unavailable values are ISSUANCE_NOT_READY blocker reasons, not top-level error codes.
- [x] Runtime canonical payload is stored only in the durable command; the attempt stores its model version and hash.
- [x] `issuance_attempts` and `invoice_reconciliation_cases` use the exact canonical §4.4.3/§4.4.6 field sets; S2b adds no parallel schema aliases.
- [x] Same idempotency key with changed business intent is rejected through persisted `intent_hash`.
- [x] Canonical hash creation and verification occur only inside PostgreSQL `jsonb`, with object-order and changed-content tests.
- [x] Invalid canonical command data is a pre-dispatch processing fault, never a definite provider failure.
- [x] No unused Dart aggregate is claimed as production mutation authority.
- [x] No unrestricted provider payload or credential is persisted.
- [x] Tests cover invariants, orchestration, SQL contracts, provider mapping, worker serialization, and DI.
- [x] Unknown-result handoff is a pending ReconciliationCase (`next_check_at`), not an internal command; S2b deploys ahead of S3b with no poison-row hazard.
- [x] `IssueInvoiceResultDto.status` is the `IssuanceAttemptStatus` enum (`preparing`/replayed), never the projection string `PROCESSING`.
- [x] Deterministic canonical-integrity dead-letter lands a system-origin terminal via `record_issuance_command_integrity_failure` (`failure_code='COMMAND_INTEGRITY'`), separate from provider failure; no attempt stays stranded in `PREPARING`.
- [x] All new tables carry `created_at`/`updated_at` per repo convention.
- [x] `DuplicateInvoiceRefID` always classifies `undetermined` in S2b (frozen); duplicate→success is S3b's status-lookup.
- [x] VET45 post-barrier no-republish is a frozen conscious divergence from MISA retry guidance.
- [x] `submitted_at` = barrier-crossing (intent-to-submit, set before HTTP), not provider receipt; provider ack is `provider_confirmed_at`.
- [x] Version representation diverges intentionally: opaque `String sourceVersion` for `IssueInvoiceCommand`, `int expectedOrderVersion` for sibling commands (frozen).
- [x] `IMeInvoiceProviderPort` is extended (validateCanonical/publish added); existing S1/S2a methods retained.
- [x] `RecordIssuanceResultCommand` stays dormant in S2b; retyped by S3b.
- [x] `provider_interaction_reference` is null in S2b; `provider_interaction_records` are owned by S3b.
- [x] `idempotencyKey` is validated as a canonical UUID at the command boundary because it is the MISA GUID `RefID` (per MISA meInvoice doc); no explicit max length published, so pinned to UUID.
