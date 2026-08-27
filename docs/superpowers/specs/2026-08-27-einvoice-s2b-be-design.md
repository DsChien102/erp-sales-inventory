# E-Invoice S2b Backend Design

**Date:** 2026-08-27  
**Theme:** TH-08 — E-Invoice  
**Slice:** S2b BE — Manual invoice issuance  
**Status:** Approved in chat; awaiting written-spec review

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

When labels differ, the contract shell already present in code is canonical for implementation naming: `IssueInvoiceCommand`, not the prose-only `StartManualInvoiceIssuance` name.

## 3. Scope

### 3.1 Included

- Manual issuance through `IssueInvoiceCommand`.
- Authoritative readiness re-evaluation at confirmation time.
- Controlled buyer completion for the current SalesOrder version when completion remains `OPEN`.
- Atomic creation or lookup of the ORIGINAL `InvoiceIssuance`.
- Atomic creation of one active `IssuanceAttempt`, its immutable `AttemptSnapshot`, canonical payload, payload hash, stable provider idempotency identity, and durable `einvoice.publish_invoice` internal command.
- Worker-only MISA `publish` call outside database transactions.
- Immediate provider outcome normalization into success, definite failure, or undetermined.
- Immediate result landing:
  - success creates one `ElectronicInvoice` and immutable `InvoiceSnapshot`;
  - definite failure marks the attempt `FAILED`;
  - undetermined marks the attempt `RECONCILING` without inventing failure.
- Durable local-finalization seam that cannot intentionally publish again after provider success evidence has been persisted.
- `GetOrderInvoiceProjectionQuery` for processing, issued, and failed display states.
- Atomic outbox events for processing, failed, and registered outcomes.
- Fake/in-memory tests, Supabase RPC contract tests, worker tests, DI/codegen, and draft SQL.

### 3.2 Excluded

- S2 FE confirmation sheet and polling UI.
- Automatic trigger consumption and `StartAutoIssuanceCommand` (S3a).
- `sales.order.completed` integration event ownership or Sales module changes (S3a).
- Reconciliation case creation, `einvoice.poll_issuance_status`, provider callback ingestion, and repeated polling (S3b).
- Operator-facing local-finalization recovery command and reconciliation resolution (S3b).
- Business retry that creates a new attempt after definite failure (S3c).
- Adjusted/replacement invoices, cancellation, delivery, document download, and provider observation.
- Timestamped migrations or promotion of draft SQL.

### 3.3 S2b/S3b boundary

`US-02 FR-08` requires the publish result to be handed to result application. Therefore S2b implements the smallest immediate-result landing path needed for an end-to-end manual issuance:

- normalize the direct `publish` response;
- atomically apply success, definite failure, or undetermined;
- persist success evidence before any later local recovery work;
- expose the resulting projection.

S3b remains owner of reconciliation cases, status polling, callbacks, mismatch review, and explicit recovery commands. The implementation plan must first align `07-api-contracts.md` so this boundary is no longer implicit.

### 3.4 Upstream dependency boundary

Theme 05 does not yet expose the authoritative completed-SalesOrder snapshot contract, and the production Theme 03 buyer-completion adapter is not implemented. Existing S2a RPC defaults and fake gateways are test seams; they are not valid issuance inputs.

S2b therefore defines the exact source-snapshot port and draft RPC dependency, implements the issuance engine against fakes/contract tests, and fails closed in production when the authoritative source contract is unavailable:

- no attempt is created;
- no publish command is enqueued;
- readiness returns `ISSUANCE_NOT_READY` with blocker `SOURCE_SNAPSHOT_UNAVAILABLE` or `BUYER_SOURCE_UNAVAILABLE`;
- no placeholder buyer, order-completed flag, totals, tax lines, or version is accepted for issuance.

When Theme 05 and Theme 03 land, their adapters satisfy these ports without changing issuance aggregate behavior, command contracts, or provider processing.

## 4. Architectural Decisions

### AD-01 — RPC is the authoritative mutation boundary

Application handlers orchestrate; they do not reproduce concurrency, uniqueness, or state-transition rules in Dart. Critical state changes and outbox/internal-command writes happen in Supabase RPC transactions.

`einvoice.issue_invoice` owns the start transaction. Result RPCs own terminal or reconciling transitions. No Dart-side PostgREST writes are allowed.

The RPC may consume only an explicitly owned cross-context contract such as a Sales-owned snapshot RPC/view. It must not read private Sales or Partner tables directly.

### AD-02 — Commit the attempt before calling MISA

The start transaction must commit all of the following before the worker can call MISA:

- locked buyer completion when completion was required;
- ORIGINAL issuance identity;
- active attempt identity and sequence;
- immutable `AttemptSnapshot`;
- canonical invoice payload and SHA-256 payload hash;
- provider correlation/idempotency identity;
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
providerIdempotencyKey: String
correlationId: String
```

The command payload is produced by `einvoice.issue_invoice` from the same immutable snapshot stored for the attempt. The publish handler must verify the stored attempt identity/hash through the result gateway and must never rebuild payload from current SalesOrder, Partner, profile, or connection data.

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

### AD-05 — Unknown is not failure

Timeout, connection loss after request dispatch, an ambiguous provider response, or a response that cannot be safely correlated must produce `RECONCILING`. These cases must not produce `FAILED`, must not expose a manual retry action, and must keep the issuance operation locked against competition.

Only an explicit provider rejection known to have produced no invoice side effect may produce `FAILED`.

### AD-06 — Immediate success and local finalization are separated conceptually

The system first durably records correlated provider success evidence against the attempt. It then creates the `ElectronicInvoice`, immutable `InvoiceSnapshot`, and registered outbox event in an idempotent local finalization transaction.

Once success evidence is durably stored, recovery executes local finalization only; it does not call `publish` again. The explicit operator/reconciliation recovery use case remains S3b, but S2b must make the storage and RPC idempotent so S3b can safely invoke it.

There is an unavoidable process-crash window between receiving provider success and persisting it. S2b controls duplicate side effects in that window with the stable provider idempotency identity embedded in the canonical MISA request. S3b later adds status polling rather than treating that window as a definite failure.

### AD-07 — Technical replay and business retry are different

- Technical replay keeps the same internal command, attempt, snapshot, payload hash, correlation ID, and provider idempotency identity.
- Business retry creates a new attempt and is excluded until S3c.
- A reconciling attempt is never eligible for business retry.
- A repeated `IssueInvoiceCommand` with the same business identity returns the existing attempt.

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

#### `InvoiceIssuance` aggregate root

- Identity: `issuanceId`.
- External identity: tenant + SalesOrder + `IssuanceType.original`.
- Owns the sequence of `IssuanceAttempt` children.
- Enforces at most one active attempt.
- References at most one original `ElectronicInvoice`.
- Does not mutate SalesOrder.

#### `IssuanceAttempt` child entity

- Identity and monotonically increasing sequence within an issuance.
- Status: `preparing`, `submitted`, `waitingResult`, `reconciling`, `succeeded`, `failed`.
- Owns exactly one immutable `AttemptSnapshot`.
- Stores canonical payload, payload hash, provider idempotency identity, correlation ID, safe result evidence, and local-finalization status.

#### `AttemptSnapshot` immutable value

Contains the seller snapshot, effective buyer snapshot, SalesOrder commercial/tax lines, effective issuance configuration, warning acknowledgements, source references, SalesOrder version, buyer partner lineage, and buyer-completion lineage. It is never changed by technical replay.

#### `ElectronicInvoice` aggregate root

- Created only after correlated provider success.
- Unique per ORIGINAL issuance.
- Stores provider reference, invoice identity, and immutable `InvoiceSnapshot` derived from the successful `AttemptSnapshot` plus safe provider result fields.
- Does not re-resolve seller, buyer, SalesOrder, or Theme 03 data during finalization.

### 5.3 Invariants

| Rule | Enforcement |
| --- | --- |
| One ORIGINAL issuance per tenant + SalesOrder | Domain rule plus database unique constraint |
| One active attempt per issuance | Aggregate rule plus partial unique constraint |
| One ElectronicInvoice per ORIGINAL issuance | Domain rule plus database unique constraint |
| AttemptSnapshot exists before publish | Start RPC transaction and internal-command foreign identity |
| AttemptSnapshot and canonical payload are immutable | No update RPC; hash checked on result landing |
| Buyer completion must be LOCKED before an attempt when completion is required | Start RPC under row lock |
| Same command/business identity returns the existing attempt | Unique idempotency identity plus RPC replay branch |
| Stale SalesOrder version cannot start | `expected_order_version` authoritative comparison |
| Timeout/ambiguous result cannot become FAILED | Closed result classification and transition rule |
| Success/failure applies only to matching tenant, attempt, correlation, idempotency, and payload hash | Result RPC guards |
| Provider success cannot create two ElectronicInvoices | Idempotent finalization plus unique constraint |

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
  required int expectedOrderVersion,
  required String idempotencyKey,
  bool? acknowledgeWarnings,
})
```

Its handler:

1. relies on the command pipeline for tenant and `EInvoicePermissions.issue` checks;
2. asks `IIssuanceCommandGateway.issueInvoice(...)` to execute the authoritative transaction;
3. maps the gateway result to `IssueInvoiceResultDto` with `status = submitted` or the replayed active status;
4. does not call MISA and does not enqueue in Dart.

Input-shape validation lives in `IssueInvoiceCommandValidator`; business invariants stay in domain/RPC.

### 6.2 Internal publish command

`PublishInvoiceCommand implements ISerializableInternalCommand` is dispatched only by the E-Invoice internal-command worker. Its handler:

1. validates the attempt envelope/hash through `IIssuanceResultGateway.preparePublish(...)`;
2. invokes `IMeInvoiceProviderPort.publish(...)` outside a database transaction;
3. maps the closed provider outcome to `IIssuanceResultGateway.recordSuccess`, `recordDefiniteFailure`, or `recordUndetermined`;
4. treats already-applied result RPC responses as success so internal-command replay is idempotent.

Provider failures are data when classified; they are not thrown as generic worker errors. Only technical inability to start or durably record a result is thrown to processing infrastructure.

### 6.3 Immediate result contract

The existing raw-map `RecordIssuanceResultCommand` shell is not used as the worker/provider boundary in its current form. The implementation must replace the raw `Map<String, Object?> providerResult` with a typed, serializable result envelope or keep result classification private to `PublishInvoiceCommandHandler` and expose typed gateway methods.

The selected implementation must satisfy both rules:

- provider-specific response parsing stays in the MISA adapter;
- RPC parameters are explicit safe fields, never an unrestricted provider response map.

### 6.4 Projection query

`GetOrderInvoiceProjectionQueryHandler` depends only on `IOrderInvoiceProjectionReadGateway`. The gateway returns `OrderInvoiceProjectionDto` and enforces tenant scope in its RPC.

### 6.5 Ports

```text
IIssuanceCommandGateway
  issueInvoice(IssueInvoiceRequest) -> IssueInvoiceStartDto

IIssuanceSourceSnapshotPort
  loadAuthoritativeSnapshot(tenantId, actorId, salesOrderId)
    -> IssuanceSourceSnapshotDto

IIssuanceResultGateway
  preparePublish(PublishAttemptEnvelope) -> PublishPreparationDto
  recordSuccess(IssuanceSuccessEvidence) -> RecordIssuanceResultDto
  recordDefiniteFailure(IssuanceFailureEvidence) -> RecordIssuanceResultDto
  recordUndetermined(IssuanceUndeterminedEvidence) -> RecordIssuanceResultDto

IOrderInvoiceProjectionReadGateway
  getBySalesOrder(tenantId, actorId, salesOrderId) -> OrderInvoiceProjectionDto

IMeInvoiceProviderPort
  publish(tenantId, canonicalInvoice, providerIdempotencyKey, correlationId)
    -> MeInvoicePublishOutcome
```

One DTO occupies one file and is colocated with its single use case unless shared by two or more issuance use cases.

`IIssuanceSourceSnapshotPort` is the anti-corruption boundary for Theme 05 commercial data and current-version buyer snapshot lineage. Its production adapter remains fail-closed until Theme 05 publishes the corresponding owned contract. Theme 03 lookup remains behind the existing buyer-data gateway and is called only for permitted missing fields while the current-version completion is `OPEN`.

## 7. Infrastructure Layer

### 7.1 Supabase schema draft

S2b adds one cohesive draft SQL file under `supabase/migrations/_drafts/`; no timestamped migration is created.

Tables:

- `einvoice.invoice_issuances`
- `einvoice.issuance_attempts`
- `einvoice.electronic_invoices`

Snapshots remain JSONB embedded in their owning row, matching the canonical relational model. They are not separate tables.

Required constraints include tenant-aware foreign keys, ORIGINAL issuance uniqueness, one-active-attempt partial uniqueness, attempt idempotency uniqueness, one-original-electronic-invoice uniqueness, non-empty hashes/correlation identities, and state-consistent terminal fields.

RLS denies direct client mutation. Service-role mutation occurs only through scoped RPCs with explicit tenant checks. Read projection is exposed through a security-definer RPC or approved view/RPC pattern matching current E-Invoice infrastructure.

### 7.2 RPCs

S2b owns these draft RPC contracts:

| RPC | Transaction responsibility |
| --- | --- |
| `einvoice.issue_invoice` | Re-check readiness/version, lock completion, create/replay issuance + attempt + snapshot, enqueue publish command, enqueue processing event |
| `einvoice.prepare_issuance_publish` | Verify attempt/hash/correlation and transition PREPARING/SUBMITTED to publishable state idempotently |
| `einvoice.record_issuance_success` | Persist safe provider success, finalize one ElectronicInvoice/InvoiceSnapshot idempotently, enqueue registered event |
| `einvoice.record_issuance_failure` | Apply only definite failure, preserve SalesOrder, enqueue failed event |
| `einvoice.record_issuance_undetermined` | Move to RECONCILING, retain operation lock, enqueue processing/unknown event |
| `einvoice.get_order_invoice_projection` | Return the tenant-scoped display projection and actions |

S2b uses the three explicit result RPCs above. The implementation updates `07-api-contracts.md` before code so the consolidated draft name `einvoice.record_issuance_result` is replaced for the immediate-result path. This makes definite-failure versus undetermined impossible to confuse at the call site. S3b may orchestrate these RPCs from its typed `RecordIssuanceResultCommand`; it does not reintroduce a raw provider map.

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

`einvoice.publish_invoice` is not blindly retried after an undetermined network outcome; it records `RECONCILING` and completes the internal command. An explicit definite rejection records `FAILED` and completes the command.

Technical failures before provider dispatch may retry the same internal command with bounded backoff. Technical failures after correlated success evidence has been durably recorded may retry local finalization only. The E-Invoice internal-command failure contract must therefore distinguish retryable pre-dispatch, terminal business outcome, and finalization-only recovery instead of immediately setting `failed_at` for every thrown error.

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
       create canonical payload + hash + stable identities
       enqueue einvoice.publish_invoice
       enqueue einvoice.issuance.processing outbox event
  <- PROCESSING with issuanceId + attemptId
```

### 8.2 Publish and land result

```text
messaging worker
  -> ProcessInternalCommandsCommand
  -> generated serializer
  -> PublishInvoiceCommandHandler
  -> prepare_issuance_publish RPC
  -> IMeInvoiceProviderPort.publish (outside DB transaction)
       success          -> record_issuance_success RPC
       definite failure -> record_issuance_failure RPC
       undetermined     -> record_issuance_undetermined RPC
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
- User commands carry actor identity for audit; worker commands use attempt/correlation identities.
- Logs contain IDs, status, safe codes, and hashes, not credentials or full invoice payloads.
- AttemptSnapshot and InvoiceSnapshot retain source/version/buyer-completion lineage required by NFR-08.
- Provider evidence is allow-listed before persistence.

## 11. Test Strategy

### 11.1 Domain tests

- ORIGINAL uniqueness and one-active-attempt rule.
- Valid and invalid attempt status transitions.
- Immutable snapshot/payload identity across technical replay.
- Definite failure versus reconciling classification.
- Successful result creates invoice state once.
- Finalization derives InvoiceSnapshot from the successful AttemptSnapshot.

### 11.2 Application tests

- Validator rejects empty IDs, non-positive version, and empty idempotency key.
- Permission and tenant decorators are enforced by `PipelineTestHarness`.
- Issue handler calls only the command gateway and maps replay correctly.
- Publish handler verifies envelope before provider call.
- Success, definite failure, and undetermined each call exactly one typed result method.
- Undetermined does not throw a generic worker failure and does not call failure landing.
- Provider success replay does not create or request a new attempt.
- Projection handler delegates to its read gateway.

### 11.3 Infrastructure and contract tests

- RPC names and parameter keys match draft SQL.
- Start RPC atomically writes attempt/snapshot/hash/internal command/outbox.
- Repeated idempotency key returns the same attempt.
- Concurrent start is protected by database constraints and row locks.
- Stale order version, not-ready config, incomplete buyer, active operation, and already-issued branches return stable codes without enqueueing publish.
- Result RPCs reject wrong tenant, attempt, correlation, payload hash, and invalid status.
- Success landing is idempotent and creates one ElectronicInvoice.
- Unknown landing produces RECONCILING and no retry action.
- Projection maps all processing states, issued, and failed.
- RLS/direct-write guards remain intact.

### 11.4 Provider and worker tests

- MISA adapter maps success, explicit rejection, auth failure, timeout, and malformed/ambiguous response into the closed outcome contract.
- Stable provider idempotency identity is passed unchanged.
- Worker command serialization round-trips without row `id` in payload.
- Generated registry recognizes `einvoice.publish_invoice`.
- One failing E-Invoice job does not stop the worker tick for other tenants/modules.
- Outbox mapper recognizes processing, failed, and registered event types.

## 12. File Responsibility Map

The implementation plan will decompose work around these responsibilities:

```text
modules/einvoice/domain/lib/src/issuance/
  invoice_issuance.dart                 aggregate lifecycle
  issuance_attempt.dart                 attempt state and immutable identity
  attempt_snapshot.dart                 immutable issuance input
  rules/*.dart                          one invariant per file
  events/*.dart                         one domain event per file

modules/einvoice/domain/lib/src/electronic_invoice/
  electronic_invoice.dart               registered invoice lifecycle
  invoice_snapshot.dart                 immutable successful snapshot
  rules/*.dart

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
  i_issuance_source_snapshot_port.dart
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
  S2b schema + RPC draft only

test trees under domain/application/infrastructure, packages/vet45_misa,
and apps/messaging_worker
```

## 13. Implementation Sequencing

1. Align the S2b/S3b API-contract boundary and lock exact typed interfaces.
2. Add the fail-closed Theme 05/Theme 03 source-snapshot contracts and tests.
3. Implement and test issuance/electronic-invoice domain behavior.
4. Draft schema, constraints, RPCs, RLS, and outbox/internal-command transaction contracts.
5. Implement Issue command validator/handler and Supabase start gateway.
6. Implement typed provider publish port and MISA adapter mapping.
7. Implement serializable publish command, immediate-result gateways, and worker behavior.
8. Implement projection query/read gateway.
9. Wire DI, outbox types, code generation, and worker module binding.
10. Run focused tests, package analysis, codegen, full module/worker verification, and harness verification.

## 14. Acceptance Mapping

| Requirement | Design mechanism |
| --- | --- |
| AC-01 authorized manual issuance | command pipeline + issue RPC |
| AC-02 snapshot before provider | atomic start transaction + durable command |
| AC-03 seller/buyer snapshot precedence | authoritative snapshot builder + locked completion |
| AC-04 duplicate confirmation | idempotency uniqueness + replay branch |
| AC-05 changed config/order blocks | authoritative re-check + expected version |
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
- [x] Duplicate prevention exists at command, aggregate, and database levels.
- [x] Timeout/ambiguous result maps to RECONCILING, not FAILED.
- [x] Success finalization is idempotent and preserves snapshot lineage.
- [x] S2b immediate-result scope is separated from S3b reconciliation workflows.
- [x] SQL remains draft-only.
- [x] No cross-module entity imports or direct SalesOrder mutation are introduced.
- [x] Missing Theme 05/Theme 03 authoritative contracts fail closed; S2a placeholders cannot issue.
- [x] No unrestricted provider payload or credential is persisted.
- [x] Tests cover business rules, orchestration, SQL contracts, provider mapping, worker serialization, and DI.
