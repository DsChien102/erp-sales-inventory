# TH-08 Slice 5 BE and Worker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to execute this plan task-by-task. Execute on the **current branch and current working tree**. Do not create a worktree, checkout another branch, stash user changes, or commit unless the user explicitly requests it. Use `superpowers:test-driven-development` for every behavior change and `superpowers:verification-before-completion` before claiming completion.

**Goal:** Complete the TH-08 Slice 5 BE + Worker lane for automatic initial email delivery after invoice registration, manual initial send/resend, immutable delivery history, and safe delivery-result handling without duplicating a provider call after an ambiguous outcome.

**Architecture:** Delivery is a separate process from legal issuance. Public manual/read RPCs enforce actor identity, `einvoice.send`, and source-owned SalesOrder data scope. A registered-invoice integration event enters the E-invoice inbox and starts one deterministic automatic initial delivery using current Partner email with the immutable `BuyerInvoiceSnapshot` as fallback. Each business delivery owns immutable recipient evidence and one or more technical attempts. A worker persists the dispatch barrier and canonical provider interaction before calling MISA; any potentially-dispatched ambiguous outcome becomes `UNKNOWN`, atomically opens a `PENDING` capability-aware reconciliation case, and locks blind resend. Providers with a reliable observation contract follow the five-check schedule; current MISA has no email-delivery observation API, so the first reconciliation worker step records `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, moves the case to `UNRESOLVED`, and emits support attention without calling `getStatus` or `sendEmail` again.

**Tech Stack:** Dart >=3.11.1 <4.0.0, Vet45 CQRS/codegen, Supabase/Postgres draft SQL, `packages/vet45_misa`, `apps/messaging_worker`, package:test, UUIDv5 deterministic identities.

**Spec:** `docs/themes/TH-08-e-invoice/Theme-8-e-invoice.md` EP-04 US-01/US-02/US-03; `docs/themes/TH-08-e-invoice/harness/01-domain-model.md`; `02-module-map.md`; `03-architecture-and-flows.md`; `04-slice-roadmap.md`; `05-traceability.md`; and `07-api-contracts.md` S5a/S5b/S5c.

## Global Constraints

- Scope is S5 BE + Worker only. Do not implement the ERP send sheet/history UI, S6 adjustment/replacement, or inbound provider callbacks. Implement only the capability-aware delivery reconciliation contract in this plan; do not add an unscoped recurring/full-table poll.
- Preserve the working S1-S4 implementation and all unrelated uncommitted user changes. Make the smallest task-local diff.
- Before modifying an existing function, class, or method, run GitNexus upstream impact for that symbol and report the blast radius. Stop for user direction on HIGH or CRITICAL risk. Before final handoff run GitNexus `detect_changes(scope: compare, base_ref: main)`.
- Create SQL only under `supabase/migrations/_drafts/`. Do not create or edit timestamp migrations, promote drafts, run `supabase db reset`, or claim the database contract is deployed.
- Every draft `create or replace function` must appear exactly in the file's `-- Touches:` header. Do not copy unchanged RPC bodies into a patch.
- ERP and public command handlers never call MISA HTTP. Only `apps/messaging_worker` receives the real delivery provider adapter; ERP keeps a worker-only guard.
- CI and tests use `FakeMeInvoiceClient`; never contact live MISA.
- Application imports Domain/shared packages but never Infrastructure/Supabase. Domain imports no Supabase, Flutter, GetIt, application, infrastructure, or another module.
- E-invoice does not query Partner or Sales tables. It may call source-owned public functions `partner.get_einvoice_recipient_snapshot(...)` and `sales.can_access_sales_order(...)`.
- Public RPCs verify `auth.uid()`, `p_actor_id = auth.uid()`, `iam.has_permission(..., 'einvoice.send')`, and `sales.can_access_sales_order(...)`. Out-of-scope resources return `NOT_FOUND`, not `FORBIDDEN`.
- Worker-only RPCs require JWT role `service_role`, derive all identity from persisted context, and do not accept a spoofable actor id.
- Recipient email/name are immutable snapshots on a delivery. Retry attempts never re-resolve or overwrite the recipient.
- `DeliveryKind` is server-derived. Remove it from the manual command input and reject any attempt to choose initial/resend from the client.
- At most one initial business delivery exists per invoice. Auto/manual races converge on the same initial-send invariant; subsequent intentional sends are `RESEND`.
- A delivery in `PROCESSING` or `UNKNOWN` locks another business delivery for that invoice. `UNKNOWN` means the delivery result is not yet established; its reconciliation case starts as `PENDING`, not `UNRESOLVED`, and the delivery is never treated as a retryable failure.
- Never infer email-delivery success from MISA invoice publication status. `getStatus` is not a delivery-status API and must not be called from delivery reconciliation.
- A reliable `sendEmail` acknowledgement means `SUCCEEDED`; a reliable provider rejection means `FAILED`; a transport timeout, 5xx, malformed response, or replay after a persisted dispatch barrier without a terminal result means `UNKNOWN`.
- Do not store access tokens, credentials, HTTP headers, signatures, raw provider response, raw exception text, or unrestricted recipient payloads. Persist only allow-listed outcome/error codes and canonical references.
- A prior successful delivery keeps the invoice's main display state `SENT` even if a later resend fails or becomes unknown; expose the later problem as secondary attention.
- Delivery state must not mutate legal issuance status, registration facts, invoice number, lookup code, or official-document state.
- Do not hand-edit generated `.g.dart` files. Run codegen and review generated changes.
- Task gates verify work but do not commit. Each task provides a suggested commit message for a later user-authorized commit.

---

## Frozen Slice 5 contracts

### Business identities and state

```dart
enum DeliveryStatus { processing, succeeded, failed, unknown }
enum DeliveryAttemptStatus { queued, submitted, succeeded, failed, unknown }
enum DeliveryKind { initial, resend }
enum DeliveryDisplayState { notSent, sending, sent, failed }
enum DeliveryTriggerType { automatic, manual }
enum DeliveryActorType { system, user }

enum DeliveryRecipientSource {
  currentPartnerProfile,
  buyerInvoiceSnapshot,
  lastSuccessfulPartnerDelivery,
  lastInvoiceDelivery,
  userInput,
}
```

The stable automatic initial-send key is UUIDv5:

```text
namespace = 9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275
name      = <tenantId>|<electronicInvoiceId>|auto_initial
```

`triggerId` remains the registered integration event id for traceability. Duplicate event ids and duplicate registered events still converge on the stable business idempotency key above.

Recipient resolution is fixed:

| Entry point | Priority | Result when all candidates are absent |
|---|---|---|
| Automatic initial | current Partner invoice email → immutable `BuyerInvoiceSnapshot` email captured in invoice lineage | Skip with a safe reason; no delivery/attempt/provider call |
| Manual initial suggestion | current Partner invoice email → latest successful delivery for the same stable Partner in the tenant | Blank suggestion |
| Manual resend suggestion | latest delivery recipient for the same electronic invoice | Blank suggestion |
| Manual confirmed send | validated user input | Persist source `USER_INPUT` |

Do not use tenant-wide or cross-customer history. Without a stable `buyerPartnerId`, automatic fallback is only `invoice_snapshot.attemptSnapshot.buyer_lineage.buyerInvoiceSnapshot.email`, and manual initial history fallback is disabled. `attemptSnapshot.buyer` is `EffectiveBuyerInvoiceData`; it is not an acceptable substitute for the canonical base `BuyerInvoiceSnapshot`.

The S2/S3 snapshot contract is repaired before S5 reads it:

```json
{
  "buyer": { "...": "EffectiveBuyerInvoiceData" },
  "buyer_lineage": {
    "buyerPartnerId": "uuid-or-null",
    "buyerInvoiceCompletionId": "uuid-or-null",
    "buyerInvoiceSnapshotSourceVersion": "source-version",
    "buyerInvoiceSnapshot": { "...": "unaltered Theme-05 base snapshot" }
  }
}
```

Automatic start eligibility is evaluated atomically at operation acceptance time, not at event-publication time:

| Check | Authoritative source | Failure behavior |
|---|---|---|
| ElectronicInvoice exists and is registered | E-invoice authoritative row | `NOT_FOUND`; no delivery |
| Auto-send is still enabled | `einvoice.automation_policies.auto_send_enabled` | skip `POLICY_OFF`; no delivery |
| Active provider connection supports email | `provider_connections.capabilities_snapshot.supports_email_delivery` | `DELIVERY_NOT_SUPPORTED`; no delivery |
| Resolved recipient is valid | current Partner snapshot, then immutable `BuyerInvoiceSnapshot` lineage | skip `INVALID_OR_MISSING_EMAIL`; no delivery |

Manual start must repeat the registered-invoice and provider-capability checks before insertion. Policy-off does not block manual send.

### Domain model

```text
InvoiceDelivery (aggregate root)
├── delivery identity, invoice identity, delivery number/kind/trigger
├── immutable DeliveryRecipientSnapshot
├── status, provider result/failure, actor, timestamps, version
└── DeliveryAttempt[] (technical process records)

DeliveryAttempt
├── attempt number and status
├── provider connection and interaction/request references
└── queued/submitted/completed timestamps and safe result/failure
```

Required domain artifacts:

- Aggregate: `InvoiceDelivery`.
- Entity/process record: `DeliveryAttempt`.
- Value objects: `DeliveryRecipientEmail`, `DeliveryRecipientSnapshot`, `ProviderDeliveryResult`.
- Rules: `DeliveryRecipientEmailMustBeValidRule`, `DeliveryCanStartRule`, `DeliveryResultCanBeAppliedRule`.
- Policies: `DeliveryRecipientResolutionPolicy`, `DeliveryDisplayStatePolicy`.
- Domain events: `InvoiceDeliveryStartedDomainEvent`, `InvoiceDeliverySucceededDomainEvent`, `InvoiceDeliveryFailedDomainEvent`, `InvoiceDeliveryUndeterminedDomainEvent`.
- Aggregate commands: start initial/resend, mark attempt submitted, apply success/definite failure/retryable rejection/unknown.
- Aggregate queries: current lock state, latest attempt, main display state, secondary attention.

State invariants:

- Delivery transitions: `PROCESSING -> SUCCEEDED | FAILED | UNKNOWN`; `UNKNOWN -> SUCCEEDED | FAILED` is allowed only when later authenticated/authoritative evidence for the same attempt is recorded. `SUCCEEDED` never reverses, and a late failure cannot overwrite it.
- Attempt transitions: `QUEUED -> SUBMITTED -> SUCCEEDED | FAILED | UNKNOWN`; a pre-dispatch exhausted attempt may transition `QUEUED -> FAILED`; `UNKNOWN` may be resolved only by later authoritative evidence for the same attempt.
- One active technical attempt (`QUEUED` or `SUBMITTED`) per delivery.
- Duplicate/reordered results are idempotent and can never reverse success.
- A retryable, known no-send rejection completes the current attempt as failed and may add exactly one next queued attempt within the same business delivery, capped at three attempts.

### Application boundaries

```dart
abstract interface class IDeliveryCommandGateway {
  Future<AutoDeliveryStartResult> startAuto(AutoDeliveryStartRequest request);
  Future<ManualDeliveryStartResult> startManual(ManualDeliveryStartRequest request);

  Future<DeliveryAttemptContextDto?> loadAttemptContext({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
  });

  Future<PrepareDeliveryProviderCallResult> prepareProviderCall({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
    required int expectedDeliveryVersion,
    required int expectedAttemptVersion,
    required String requestReference,
  });

  Future<RecordDeliveryResultDto> recordResult(
    DeliveryResultRecord record,
  );

  Future<void> recordCommandDeadLetter({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
    required String safeFailureCode,
  });
}

abstract interface class IDeliveryReadGateway {
  Future<SendInvoiceSheetContextDto> getSendSheetContext({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<InvoiceDeliveryHistoryDto> getHistory({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}

abstract interface class IInvoiceDeliveryProviderPort {
  Future<DeliveryProviderOutcome> sendEmail(
    DeliveryProviderContextDto context,
  );
}

abstract interface class IDeliveryReconciliationGateway {
  Future<DeliveryReconciliationContextDto?> loadContext({
    required String tenantId,
    required String reconciliationCaseId,
    required int checkSequence,
  });

  Future<DeliveryReconciliationResultDto> recordCheck(
    DeliveryReconciliationCheckRecord record,
  );
}

abstract interface class IInvoiceDeliveryObservationProviderPort {
  Future<DeliveryObservationOutcome> observe(
    DeliveryObservationContextDto context,
  );
}
```

The context/result records are explicit and provider-neutral:

```dart
final class DeliveryProviderContextDto {
  final String tenantId;
  final String providerConnectionId;
  final String providerTransactionId;
  final String invoiceSeries;
  final String recipientEmail;
  final String? recipientName;
}

enum DeliveryResultKind {
  success,
  definiteFailure,
  retryableFailure,
  undetermined,
}

final class DeliveryResultEvidence {
  final DeliveryResultKind kind;
  final String? providerReference;
  final String? safeCode;
}

final class DeliveryResultRecord {
  final String tenantId;
  final String deliveryId;
  final String attemptId;
  final int expectedDeliveryVersion;
  final int expectedAttemptVersion;
  final String interactionReference;
  final DeliveryResultEvidence evidence;
}

enum DeliveryObservationKind {
  succeeded,
  definiteFailure,
  undetermined,
  unsupported,
}

final class DeliveryReconciliationContextDto {
  final String tenantId;
  final String reconciliationCaseId;
  final String deliveryId;
  final String attemptId;
  final String providerConnectionId;
  final bool supportsDeliveryResultObservation;
  final int checkSequence;
  final int caseVersion;
}

final class DeliveryObservationContextDto {
  final String tenantId;
  final String reconciliationCaseId;
  final String deliveryId;
  final String attemptId;
  final String providerConnectionId;
  final String? providerDeliveryReference;
}

sealed class DeliveryObservationOutcome {
  const DeliveryObservationOutcome();
}

final class DeliveryObservedSucceeded extends DeliveryObservationOutcome {
  const DeliveryObservedSucceeded({this.providerReference});
  final String? providerReference;
}

final class DeliveryObservedDefiniteFailure extends DeliveryObservationOutcome {
  const DeliveryObservedDefiniteFailure(this.safeCode);
  final String safeCode;
}

final class DeliveryObservationUndetermined extends DeliveryObservationOutcome {
  const DeliveryObservationUndetermined(this.safeCode);
  final String safeCode;
}

final class DeliveryObservationUnsupported extends DeliveryObservationOutcome {
  const DeliveryObservationUnsupported();
}

final class DeliveryReconciliationCheckRecord {
  final String tenantId;
  final String reconciliationCaseId;
  final int expectedCaseVersion;
  final int checkSequence;
  final String? interactionReference;
  final DeliveryObservationKind kind;
  final String? providerReference;
  final String? safeCode;
}

final class DeliveryReconciliationResultDto {
  final ReconciliationCaseStatus caseStatus;
  final DeliveryStatus deliveryStatus;
  final DateTime? nextCheckAt;
  final bool hasSecondaryAttention;
}
```

Provider outcomes are typed and exhaustive:

```dart
sealed class DeliveryProviderOutcome {
  const DeliveryProviderOutcome();
}

final class DeliveryProviderSucceeded extends DeliveryProviderOutcome {
  const DeliveryProviderSucceeded({this.providerReference});
  final String? providerReference;
}

final class DeliveryProviderDefiniteFailure extends DeliveryProviderOutcome {
  const DeliveryProviderDefiniteFailure(this.safeErrorCode);
  final String safeErrorCode;
}

final class DeliveryProviderRetryableFailure extends DeliveryProviderOutcome {
  const DeliveryProviderRetryableFailure(this.safeErrorCode);
  final String safeErrorCode;
}

final class DeliveryProviderUndetermined extends DeliveryProviderOutcome {
  const DeliveryProviderUndetermined(this.safeErrorCode);
  final String safeErrorCode;
}
```

`SendInvoiceEmailCommand` is serializable as `einvoice.send_invoice_email` and contains only `tenantId`, `deliveryId`, and `attemptId`. The worker loads all provider and recipient context from the database. The internal command identity should equal the attempt id unless an existing registry convention requires a deterministic UUID derived from it.

`ReconcileInvoiceDeliveryCommand` is serializable as `einvoice.reconcile_invoice_delivery` and contains only `tenantId`, `reconciliationCaseId`, and `checkSequence`. Its deterministic UUIDv5 identity uses `<caseId>|<checkSequence>`. It never sends email. For current MISA, `supportsDeliveryResultObservation == false`, so the command records one unsupported check and transitions the case to `UNRESOLVED` without creating a provider interaction. A future provider with an explicit delivery-observation contract may call `IInvoiceDeliveryObservationProviderPort.observe`; each such outbound observation has its own canonical `ProviderInteractionRecord`.

`prepareProviderCall` returns one of:

- `callProvider`: caller persisted the `SUBMITTED` barrier and may perform exactly one HTTP call.
- `skip`: attempt/delivery is already terminal or superseded; acknowledge without HTTP.
- `recordUnknown`: a replay found `SUBMITTED` without a terminal result; record `UNKNOWN` without HTTP.

Public DTOs are fixed:

```dart
enum AutoDeliveryDisposition { started, skipped }

enum AutoDeliverySkipReason {
  policyOff,
  invalidOrMissingEmail,
  initialDeliveryAlreadyClaimed,
}

final class AutoDeliveryResultDto {
  final AutoDeliveryDisposition disposition;
  final String? deliveryId;
  final AutoDeliverySkipReason? skipReason;
}

final class SendInvoiceSheetContextDto {
  final SendInvoiceSheetMode mode;
  final String? suggestedEmail;
  final DeliveryRecipientSource? suggestedEmailSource;
  final List<InvoiceDeliveryItemDto> history;
  final bool operationLocked;
  final DeliveryDisplayState displayState;
}

final class InvoiceDeliveryItemDto {
  final String deliveryId;
  final int deliveryNo;
  final DeliveryKind kind;
  final DeliveryTriggerType triggerType;
  final String recipientEmail;
  final DeliveryStatus status;
  final DeliveryActorType initiatedByActorType;
  final String? initiatedByActorId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? failureCode;
}

final class InvoiceDeliveryHistoryDto {
  final List<InvoiceDeliveryItemDto> deliveries;
  final DeliveryDisplayState displayState;
  final bool hasSecondaryAttention;
}

final class RecordDeliveryResultDto {
  final DeliveryStatus deliveryStatus;
  final DeliveryDisplayState displayState;
  final bool hasSecondaryAttention;
}
```

For automatic start, a replay that already owns the same auto identity returns the existing started delivery idempotently; a manual initial delivery that won the race returns `initialDeliveryAlreadyClaimed`. Missing capability raises `DELIVERY_NOT_SUPPORTED` and creates no rows. Policy-off and invalid/missing recipient are explicit safe skips.

`SendElectronicInvoiceCommand` accepts tenant, actor, SalesOrder, recipient email, and idempotency key. It does not accept `deliveryKind`. `RecordDeliveryResultCommand` accepts delivery/attempt expected versions, typed `DeliveryResultEvidence`, and `interactionReference`; it does not accept `Map<String, Object?>` or raw provider data.

### Provider and worker semantics

Each actual outbound call has exactly one `ProviderInteractionRecord` targeted at `DELIVERY_ATTEMPT`. Use a deterministic correlation/request reference per internal-command worker attempt, call `start` before HTTP, and finalize the same record once with an allow-listed terminal outcome.

Reuse the full S4 `IProviderInteractionGateway`/`ProviderInteractionRecord` contract unchanged: immutable request identity plus optimistic one-time finalization. Delivery rows store only canonical `provider_interaction_reference`/`provider_request_reference`; do not add a second canonical `correlation_id` to delivery entities or raw provider evidence columns.

| Condition | HTTP may have dispatched? | Provider outcome | Delivery result |
|---|---:|---|---|
| MISA reliable success acknowledgement | Yes | succeeded | `SUCCEEDED` |
| Reliable auth/credential/validation/business rejection | No or reliably rejected | definite failure | `FAILED` |
| HTTP 429 before provider acceptance | Reliably no | retryable failure | next technical attempt, max 3 |
| Timeout, connection loss after write, HTTP 5xx, malformed success body | Possibly | undetermined | `UNKNOWN` + `PENDING` reconciliation |
| Dead-letter while attempt is still `QUEUED` | No | definite worker failure | `FAILED` |
| Dead-letter/replay after `SUBMITTED` | Possibly | undetermined | `UNKNOWN` + `PENDING` reconciliation |

Do not enqueue another email-send call after `UNKNOWN`. Recording `UNKNOWN` atomically creates or reuses one `PENDING` `VERIFY_DELIVERY` case with `attempt_count = 0`, `next_check_at = now() + interval '30 seconds'`, and the deterministic first `einvoice.reconcile_invoice_delivery` command. The reconciliation worker is capability-aware:

- If `supports_delivery_result_observation = true`, execute one typed observation for the current check sequence. Terminal evidence resolves the existing delivery/attempt/case. Undetermined evidence schedules the next sequence using `[30s, 2m, 10m, 30m, 2h]`; the fifth undetermined check changes the case to `UNRESOLVED` and emits attention.
- If `supports_delivery_result_observation = false`, do not perform outbound HTTP. The first scheduled check records safe code `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, changes the case to `UNRESOLVED`, clears `next_check_at`, and emits attention.
- Current MISA always exposes `supports_delivery_result_observation = false`. Neither `/invoice/status` nor another invoice/document API may be treated as email-delivery evidence.
- Later authenticated terminal evidence for the same attempt may change `PENDING` or `UNRESOLVED` to `RESOLVED` without creating another delivery or sending email again.

### Database contracts

`einvoice.invoice_deliveries` includes convention fields plus:

```text
id, tenant_id, electronic_invoice_id, delivery_no,
delivery_intent, trigger_type, channel,
recipient_snapshot_schema_version, recipient_snapshot,
idempotency_key, intent_hash,
status, provider_delivery_reference,
provider_result_code, provider_result_message,
failure_code, failure_message,
initiated_by_actor_type, initiated_by_actor_id,
started_at, completed_at, created_at, updated_at, version
```

`einvoice.delivery_attempts` includes:

```text
id, tenant_id, invoice_delivery_id, attempt_no, status,
provider_connection_id,
provider_interaction_reference, provider_request_reference,
provider_result_code, provider_result_message,
failure_code, failure_message,
queued_at, submitted_at, completed_at, created_at, updated_at, version
```

`provider_result_message` and `failure_message` are canonical nullable fields, but values must be Vet45-authored, allow-listed safe text derived from normalized codes. Never copy MISA descriptions, HTTP bodies, exception messages, recipient addresses, or credentials into either field.

Reuse the canonical S2/S3 `einvoice.invoice_reconciliation_cases` table; S5 must not create a second delivery-specific case table. A delivery case uses `target_type = 'DELIVERY_ATTEMPT'`, `target_id = delivery_attempts.id`, and `reconciliation_purpose = 'VERIFY_DELIVERY'`. Its lifecycle is exactly `PENDING -> RESOLVED | UNRESOLVED`, with the existing late-evidence amendment `UNRESOLVED -> RESOLVED`; case identity, scheduling, claim, attempt count, safe error, timestamps, and version remain the canonical fields already owned by that table.

Required constraints:

- Unique `(tenant_id, electronic_invoice_id, delivery_no)`.
- Partial unique one `INITIAL_SEND` per `(tenant_id, electronic_invoice_id)`.
- Partial unique one active business delivery in `PROCESSING` or `UNKNOWN` per invoice.
- Unique `(tenant_id, idempotency_key)`; replay with a different intent hash returns `IDEMPOTENCY_CONFLICT`.
- Unique `(tenant_id, invoice_delivery_id, attempt_no)`.
- Partial unique one active attempt in `QUEUED` or `SUBMITTED` per delivery.
- Delivery, immutable recipient snapshot, first attempt, and internal command are inserted atomically.

Draft RPC surface:

```text
partner.get_einvoice_recipient_snapshot(uuid, uuid)

einvoice.start_auto_delivery(uuid, uuid, uuid, uuid)
einvoice.send_electronic_invoice(uuid, uuid, uuid, text, uuid)
einvoice.get_send_invoice_sheet_context(uuid, uuid, uuid)
einvoice.get_invoice_delivery_history(uuid, uuid, uuid)
einvoice.load_delivery_attempt_context(uuid, uuid, uuid)

einvoice.prepare_delivery_provider_call(uuid, uuid, uuid, bigint, bigint, text)
einvoice.record_delivery_result(uuid, uuid, uuid, bigint, bigint, text, text, text, text)
einvoice.record_delivery_command_dead_letter(uuid, uuid, uuid, text)
einvoice.load_delivery_reconciliation_context(uuid, uuid, integer)
einvoice.record_delivery_reconciliation_check(uuid, uuid, bigint, integer, text, text, text, text)
einvoice.get_order_invoice_projection(uuid, uuid, uuid)
```

Final argument names and types must match the Dart gateway constants exactly. If implementation requires expected-version arguments, add them explicitly to both contract and gateway in the same task; do not hide optimistic concurrency in an untyped payload.

`get_order_invoice_projection` changes its returned row type in S5. PostgreSQL cannot change OUT columns with `create or replace function`; the S5 result draft must explicitly `drop function if exists einvoice.get_order_invoice_projection(uuid, uuid, uuid)` immediately before recreating it.

### Integration events

- Consume `einvoice.electronic_invoice.registered` through the E-invoice inbox and dispatch `StartAutoDeliveryCommand`.
- Extend `einvoice.delivery.result_recorded` safe payload with `salesOrderId`, `deliveryId`, `deliveryStatus`, `deliveryDisplayState`, `deliveryVersion`, and `hasSecondaryAttention`.
- Add `einvoice.delivery.attention_required` only when capability-aware reconciliation reaches `UNRESOLVED`; payload contains tenant/invoice/SalesOrder/delivery/attempt/case ids and safe error code only.
- Initial `UNKNOWN`, `PENDING` case creation, first deterministic reconciliation command, and result event are atomic. `UNRESOLVED` transition and attention event are atomic. Event replay is deduplicated by the existing inbox/outbox mechanisms.

---

## File map

```text
docs/themes/TH-08-e-invoice/
  Theme-8-e-invoice.md
  harness/01-domain-model.md
  harness/02-module-map.md
  harness/03-architecture-and-flows.md
  harness/04-slice-roadmap.md
  harness/05-traceability.md
  harness/07-api-contracts.md

modules/einvoice/domain/lib/src/provider_connection/
  provider_capabilities_snapshot.dart                     Delivery-observation capability (MISA=false)

modules/einvoice/domain/lib/src/delivery/
  invoice_delivery.dart
  delivery_attempt.dart
  value_objects/delivery_recipient_email.dart
  value_objects/delivery_recipient_snapshot.dart
  value_objects/provider_delivery_result.dart
  rules/delivery_recipient_email_must_be_valid_rule.dart
  rules/delivery_can_start_rule.dart
  rules/delivery_result_can_be_applied_rule.dart
  services/delivery_recipient_resolution_policy.dart
  services/delivery_display_state_policy.dart
  events/invoice_delivery_*_domain_event.dart
  enums/delivery_trigger_type.dart
  enums/delivery_actor_type.dart
  enums/delivery_recipient_source.dart

modules/einvoice/application/lib/src/delivery/
  commands/start_auto_delivery/*
  commands/send_electronic_invoice/*
  commands/send_invoice_email/*
  commands/record_delivery_result/*
  commands/reconcile_invoice_delivery/*
  queries/get_send_invoice_sheet_context/*
  queries/get_invoice_delivery_history/*
  shared/delivery_*_dto.dart
  shared/auto_delivery_idempotency_key.dart
  integration_events/electronic_invoice_registered_integration_event_handler.dart

modules/einvoice/application/lib/src/ports/
  i_delivery_command_gateway.dart
  i_delivery_read_gateway.dart
  i_invoice_delivery_provider_port.dart
  i_delivery_reconciliation_gateway.dart
  i_invoice_delivery_observation_provider_port.dart

modules/einvoice/integration_events/lib/src/
  delivery_result_recorded_integration_event.dart
  delivery_attention_required_integration_event.dart
  electronic_invoice_registered_integration_event.dart

modules/einvoice/infrastructure/lib/src/
  adapters/misa/me_invoice_delivery_provider_adapter.dart
  adapters/misa/me_invoice_delivery_classifier.dart
  adapters/misa/me_invoice_delivery_observation_provider_adapter.dart
  domain/delivery/supabase_delivery_command_gateway.dart
  domain/delivery/supabase_delivery_read_gateway.dart
  domain/delivery/supabase_delivery_reconciliation_gateway.dart
  domain/delivery/delivery_rpc_mapper.dart
  configuration/data_access/data_access_module.dart
  configuration/processing/processing_module.dart
  configuration/processing/internal_commands/delivery_command_dead_letter_handler.dart
  configuration/processing/internal_commands/delivery_reconciliation_command_dead_letter_handler.dart
  configuration/processing/outbox/process_outbox_command_handler.dart
  configuration/einvoice_startup.dart

packages/vet45_misa/lib/src/
  e_invoice/i_me_invoice_client.dart
  e_invoice/me_invoice_client.dart
  e_invoice/fake_me_invoice_client.dart
  e_invoice/models/me_invoice_result.dart

apps/messaging_worker/lib/
  messaging_module_binding.dart
  messaging_worker_bootstrap.dart

supabase/migrations/_drafts/
  007_einvoice_s2b_schema_and_rpc.sql                     Preserve base BuyerInvoiceSnapshot lineage
  008_einvoice_s3a_s3c_start_and_retry.sql                Preserve base BuyerInvoiceSnapshot lineage
  partner_einvoice_recipient_snapshot.sql
  013_einvoice_s5_delivery_schema_and_start.sql
  014_einvoice_s5_delivery_results.sql
  015_einvoice_s5_delivery_reconciliation.sql
```

Generated registrars/barrels discovered by codegen may change, but agents must not edit generated files directly. Reuse the repository's current export style rather than creating duplicate barrel conventions.

---

### Task 0: Freeze S5 semantics and repair contract scaffolds

**Files:**

- Modify: `docs/themes/TH-08-e-invoice/Theme-8-e-invoice.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/01-domain-model.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/02-module-map.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/03-architecture-and-flows.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md`
- Modify: `modules/einvoice/application/lib/src/delivery/commands/send_electronic_invoice/send_electronic_invoice_command.dart`
- Modify: `modules/einvoice/application/lib/src/delivery/commands/record_delivery_result/record_delivery_result_command.dart`
- Modify: `modules/einvoice/application/lib/src/delivery/commands/record_delivery_result/record_delivery_result_result.dart`
- Modify: `modules/einvoice/application/lib/src/delivery/queries/get_send_invoice_sheet_context/send_invoice_sheet_context_dto.dart`
- Modify: `modules/einvoice/application/lib/src/delivery/queries/get_invoice_delivery_history/invoice_delivery_item_dto.dart`
- Modify: `modules/einvoice/application/lib/src/delivery/queries/get_invoice_delivery_history/invoice_delivery_history_dto.dart`
- Modify: `supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql`
- Modify: `supabase/migrations/_drafts/008_einvoice_s3a_s3c_start_and_retry.sql`
- Modify: `modules/einvoice/infrastructure/test/domain/issuance/einvoice_s2b_repair_sql_contract_test.dart`
- Modify: `modules/einvoice/infrastructure/test/domain/issuance/einvoice_s3a_s3c_sql_contract_test.dart`
- Create: `modules/einvoice/application/test/delivery/s5_contract_test.dart`

**Interfaces:** Consumes EP-04 and current S5a/S5b/S5c scaffold. Produces the frozen enums, typed commands/results, explicit `BuyerInvoiceSnapshot` lineage, capability-aware reconciliation amendment, and traceability test ids used by Tasks 1-10.

- [ ] Run GitNexus impact for every existing DTO/command class listed above; record affected consumers before editing.
- [ ] Add failing compile/shape tests proving manual input has no `deliveryKind`, provider evidence is typed, and public DTOs expose the frozen fields.
- [ ] Run `dart test test/delivery/s5_contract_test.dart` from `modules/einvoice/application`; expect failure from the old scaffold shapes.
- [ ] Add failing S2/S3 SQL contract assertions requiring `attempt_snapshot.buyer_lineage.buyerInvoiceSnapshot` to preserve the unmodified Theme-05 base snapshot separately from effective `attempt_snapshot.buyer` and to retain `buyerPartnerId`, completion id, and source version lineage.
- [ ] Update the Theme, EP-04 US-03, and harness documents with the exact contracts in this plan: `BuyerInvoiceSnapshot` fallback, one initial delivery, `UNKNOWN` lock, capability-aware reconciliation, MISA observation unsupported amendment, bounded technical retry, display-state precedence, event payloads, and source-owned Partner RPC.
- [ ] Repair both manual/S2 and automatic/S3 attempt-snapshot builders so `buyer_lineage.buyerInvoiceSnapshot` is copied from the source-owned `p_buyer_snapshot` before any completion merge; do not derive it from effective buyer data or current Partner profile.
- [ ] Add `DeliveryTriggerType`, `DeliveryActorType`, and `DeliveryRecipientSource`; repair the existing command/result/read DTOs without adding infrastructure concerns.
- [ ] Run codegen if annotations require it, then rerun the contract test and application analyzer; expect pass.
- [ ] Gate: run `rg -n "deliveryKind|Map<String, Object\?> providerResult|invoiceSnapshot\.buyer\.email|once per.*day|daily" modules/einvoice/application/lib/src/delivery docs/themes/TH-08-e-invoice supabase/migrations/_drafts`; only deliberate historical/problem descriptions may remain.

Suggested commit: `docs(einvoice): freeze slice 5 delivery contracts`

### Task 1: Correct the MISA email-success result type

**Files:**

- Modify: `packages/vet45_misa/lib/src/e_invoice/i_me_invoice_client.dart`
- Modify: `packages/vet45_misa/lib/src/e_invoice/me_invoice_client.dart`
- Modify: `packages/vet45_misa/lib/src/e_invoice/fake_me_invoice_client.dart`
- Modify: `packages/vet45_misa/test/e_invoice/me_invoice_client_test.dart`
- Modify: `packages/vet45_misa/test/e_invoice/fake_me_invoice_client_test.dart`

**Interfaces:** `sendEmail` changes from `Future<MeInvoiceResult<void>>` to `Future<MeInvoiceResult<bool>>`; success returns `MeInvoiceResult.ok(true)`. `MeInvoiceResult.isSuccess` itself remains unchanged to avoid altering all provider operations.

- [ ] Run GitNexus impact for `IMeInvoiceClient.sendEmail`, the concrete implementation, and the fake override. Report all adapters/tests that compile against them.
- [ ] Add a failing test proving a successful fake and decoded HTTP response have `isSuccess == true` and `data == true`.
- [ ] Run the focused `vet45_misa` test; expect the current `ok(null)` result to fail.
- [ ] Change only the email-send return type and successful values; preserve existing safe error mapping.
- [ ] Run `dart format`, focused tests, and `dart analyze` for `packages/vet45_misa`; expect pass.
- [ ] Gate: verify no `MeInvoiceResult<void>` remains for `sendEmail` and no unrelated provider endpoint changed.

Suggested commit: `fix(misa): represent successful email dispatch explicitly`

### Task 2: Implement the delivery domain model and pure policies

**Files:**

- Create: `modules/einvoice/domain/lib/src/delivery/invoice_delivery.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/delivery_attempt.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/value_objects/delivery_recipient_email.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/value_objects/delivery_recipient_snapshot.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/value_objects/provider_delivery_result.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/rules/delivery_recipient_email_must_be_valid_rule.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/rules/delivery_can_start_rule.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/rules/delivery_result_can_be_applied_rule.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/services/delivery_recipient_resolution_policy.dart`
- Create: `modules/einvoice/domain/lib/src/delivery/services/delivery_display_state_policy.dart`
- Create: four domain-event files under `modules/einvoice/domain/lib/src/delivery/events/`
- Create: three enum files under `modules/einvoice/domain/lib/src/delivery/enums/`
- Modify: `modules/einvoice/domain/lib/domain.dart`
- Create: `modules/einvoice/domain/test/delivery/delivery_recipient_email_test.dart`
- Create: `modules/einvoice/domain/test/delivery/invoice_delivery_test.dart`
- Create: `modules/einvoice/domain/test/delivery/delivery_recipient_resolution_policy_test.dart`
- Create: `modules/einvoice/domain/test/delivery/delivery_display_state_policy_test.dart`

**Interfaces:** Pure Dart only. Consume current delivery enums and shared domain primitives. Produce validated aggregate behavior, recipient selection, display-state projection, safe events, and no persistence/provider logic.

- [ ] Write failing tests for valid/invalid/trimmed email; immutable recipient; initial-vs-resend rule; active lock; legal transitions; idempotent duplicate result; no reversal from success; and max-three-attempt behavior.
- [ ] Write failing recipient-policy tests for all table rows in the frozen priority matrix, including stable Partner mismatch and no cross-customer fallback.
- [ ] Write failing display-policy tests: no history → `NOT_SENT`; active/unknown without success → `SENDING`; latest failure without success → `FAILED`; any success → `SENT`; failed/unknown resend after success → `SENT` plus secondary attention.
- [ ] Run `dart test test/delivery`; expect compile failures because artifacts do not exist.
- [ ] Implement the value objects and business rules first, then the policy services, then the aggregate/entity/events. Use existing domain exception and `IBusinessRule` conventions.
- [ ] Keep provider error classification out of Domain; Domain receives only `ProviderDeliveryResult` categories and safe codes.
- [ ] Run `dart format`, `dart analyze`, and all domain tests; expect pass.
- [ ] Gate: use `rg` to confirm this subtree has no `supabase`, `flutter`, `get_it`, `application`, `infrastructure`, `partner`, or `sales` imports.

Suggested commit: `feat(einvoice): model invoice delivery lifecycle`

### Task 3: Build application ports, handlers, internal command, and auto-event handler

**Files:**

- Create: `modules/einvoice/application/lib/src/ports/i_delivery_command_gateway.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_delivery_read_gateway.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_invoice_delivery_provider_port.dart`
- Create: typed request/context/outcome/record DTOs under `modules/einvoice/application/lib/src/delivery/shared/`
- Create: `modules/einvoice/application/lib/src/delivery/shared/auto_delivery_idempotency_key.dart`
- Modify: existing StartAutoDelivery, SendElectronicInvoice, RecordDeliveryResult command/result files
- Create: handlers and validators beside those three commands
- Create: `modules/einvoice/application/lib/src/delivery/commands/send_invoice_email/send_invoice_email_command.dart`
- Create: `modules/einvoice/application/lib/src/delivery/commands/send_invoice_email/send_invoice_email_command_handler.dart`
- Create: handlers for the two existing delivery queries
- Create: `modules/einvoice/application/lib/src/delivery/integration_events/electronic_invoice_registered_integration_event_handler.dart`
- Modify: `modules/einvoice/application/lib/application.dart`
- Modify: `modules/einvoice/integration_events/lib/src/electronic_invoice_registered_integration_event.dart`
- Modify: `modules/einvoice/integration_events/lib/src/delivery_result_recorded_integration_event.dart`
- Create: `modules/einvoice/integration_events/lib/src/delivery_attention_required_integration_event.dart`
- Modify: `modules/einvoice/integration_events/lib/integration_events.dart`
- Create: `modules/einvoice/integration_events/test/delivery_integration_events_test.dart`
- Create: `modules/einvoice/application/test/delivery/start_auto_delivery_command_handler_test.dart`
- Create: `modules/einvoice/application/test/delivery/send_electronic_invoice_command_handler_test.dart`
- Create: `modules/einvoice/application/test/delivery/send_invoice_email_command_handler_test.dart`
- Create: `modules/einvoice/application/test/delivery/record_delivery_result_command_handler_test.dart`
- Create: `modules/einvoice/application/test/delivery/delivery_query_handlers_test.dart`
- Create: `modules/einvoice/application/test/delivery/electronic_invoice_registered_integration_event_handler_test.dart`
- Modify: `modules/einvoice/application/test/fake_einvoice_scenarios_e04_test.dart`

**Interfaces:** Produce the three gateway ports, typed provider outcome boundary, serializable `einvoice.send_invoice_email`, public CQRS handlers, and registered-event-to-auto-command orchestration. `ElectronicInvoiceRegisteredIntegrationEvent.fromPayload` must parse its own outbox payload safely.

- [ ] Add fakes for the new ports following `modules/einvoice/application/lib/src/testing/fakes/` conventions.
- [ ] Write failing handler tests for validation, argument forwarding, idempotency key preservation, and query delegation.
- [ ] Write failing worker-handler tests for `callProvider`, `skip`, and `recordUnknown`; assert provider is never called for the latter two.
- [ ] Write failing provider-outcome tests for success, definite failure, retryable failure, and undetermined evidence passed to `RecordDeliveryResultCommand` with the interaction reference.
- [ ] Write a failing event-handler test proving duplicate registered events derive the same UUIDv5 auto idempotency key and dispatch `StartAutoDeliveryCommand` with event id as trigger id.
- [ ] Write failing integration-event round-trip tests for registered, result-recorded, and attention-required payloads; reject malformed enum/timestamp/required-id data and ignore no safe fields.
- [ ] Run focused application tests; expect compile/registration failures.
- [ ] Implement `AutoDeliveryIdempotencyKey` with the frozen namespace and seed `<tenantId>|<electronicInvoiceId>|auto_initial`, following the existing `AutoIssuanceIdempotencyKey` UUIDv5 convention.
- [ ] Extend the safe result event and add the attention event with `toPayload`/`fromPayload` symmetry; do not include recipient email, provider body, headers, or raw exception text.
- [ ] Implement commands/validators/handlers and typed DTOs. Keep handlers orchestration-only: no SQL, MISA mapping, or raw response inspection.
- [ ] In `SendInvoiceEmailCommandHandler`, persist/start the provider interaction only for `callProvider`, finalize it once after classification, and route every typed outcome through `RecordDeliveryResultCommand`.
- [ ] Ensure an exception after the persisted dispatch barrier maps to undetermined evidence; do not throw it into a generic retry that calls MISA again.
- [ ] Run codegen; review generated registrar/serialization diffs rather than editing them.
- [ ] Run all application tests and analyzer; expect pass.
- [ ] Gate: verify `SendInvoiceEmailCommand` round-trips through the current internal-command mapper and contains no recipient/provider credential fields.

Suggested commit: `feat(einvoice): add slice 5 delivery use cases`

### Task 4: Add the source-owned Partner recipient snapshot contract

**Files:**

- Create: `supabase/migrations/_drafts/partner_einvoice_recipient_snapshot.sql`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/partner_recipient_snapshot_sql_contract_test.dart`
- Modify: Partner harness/API contract only if its source-owned contract catalog requires registration

**Interfaces:**

```sql
partner.get_einvoice_recipient_snapshot(
  p_tenant_id uuid,
  p_partner_id uuid
) returns table (
  partner_id uuid,
  invoice_email text,
  recipient_name text,
  source_version bigint,
  is_active boolean
)
```

The function is source-owned, `security definer`, uses a pinned `search_path`, validates tenant membership/source records according to Partner conventions, and is executable only by `service_role` and the function owner path required for the E-invoice definer RPC. Do not grant direct authenticated-client execution.

- [ ] Write a failing SQL contract test for signature, return fields, `security definer`, pinned `search_path`, tenant/active filters, grants/revokes, and absence of E-invoice-owned Partner table reads.
- [ ] Run the focused infrastructure test; expect failure because the draft does not exist.
- [ ] Implement the smallest source-owned function using the canonical Partner model actually present in the repository; do not invent a second Partner email store.
- [ ] Add exact `Kind`, `Intent`, and `Touches` draft headers. `Touches` lists only this function.
- [ ] Rerun the SQL contract test and strict harness verification; expect pass.
- [ ] Gate: `rg` all E-invoice SQL/Dart for direct Partner table references; only the public function call is allowed.

Suggested commit: `feat(partner): expose e-invoice recipient snapshot contract`

### Task 5: Add delivery schema, atomic start/read RPCs, and SQL contract tests

**Files:**

- Create: `supabase/migrations/_drafts/013_einvoice_s5_delivery_schema_and_start.sql`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/einvoice_s5_schema_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/einvoice_s5_start_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/einvoice_s5_read_sql_contract_test.dart`

**Interfaces:** Create `invoice_deliveries`, `delivery_attempts`, required constraints/RLS/indexes, recipient snapshot helpers, deterministic intent hash/display helper if necessary, and the start/read/load RPCs listed in the frozen database contract.

- [ ] Write failing schema tests for every canonical column and exact canonical name: `recipient_snapshot`, `invoice_delivery_id`, `provider_interaction_reference`, `provider_request_reference`, both `provider_result_message`/`failure_message` fields, `version bigint`, nullable completion/result fields, enum/check constraints, unique/partial indexes, tenant RLS, and immutable recipient semantics.
- [ ] Write failing public-RPC tests for `auth.uid`, actor equality, `einvoice.send`, `sales.can_access_sales_order`, outside-scope `NOT_FOUND`, idempotency replay, and same-key/different-intent `IDEMPOTENCY_CONFLICT`.
- [ ] Write failing start tests for atomic delivery + recipient + first attempt + internal command insertion, one initial send, auto/manual race convergence, active/unknown lock, server-derived kind, and stable auto identity.
- [ ] Write failing eligibility tests proving automatic start re-reads `auto_send_enabled`, requires `capabilities_snapshot.supports_email_delivery`, and creates no rows when policy/capability is invalid; manual start ignores auto policy but still requires email capability.
- [ ] Write failing recipient tests for Partner current email, `BuyerInvoiceSnapshot` fallback at `invoice_snapshot.attemptSnapshot.buyer_lineage.buyerInvoiceSnapshot.email`, stable Partner lineage at `buyer_lineage.buyerPartnerId`, and skip/no-leak cases. Add a negative assertion that `attemptSnapshot.buyer.email` is never used for this fallback.
- [ ] Write failing read tests for manual suggestion priorities, full recipient only with send permission, immutable chronological history, and no cross-partner lookup.
- [ ] Run the three focused tests; expect missing-draft failures.
- [ ] Implement schema and helpers first; then `start_auto_delivery`, `send_electronic_invoice`, both reads, and `load_delivery_attempt_context`.
- [ ] Make public manual/read RPCs fail closed on missing source-owned Sales/Partner dependencies; do not add allow-all fallbacks.
- [ ] Make automatic no-recipient return an explicit safe skipped result without creating a delivery, attempt, command, or provider interaction.
- [ ] Ensure the first internal command uses `einvoice.send_invoice_email`, payload ids only, and a deterministic identity tied to the attempt.
- [ ] Persist only safe Vet45-authored values in canonical message fields; SQL must never copy provider description, raw response, exception text, or recipient email into `provider_result_message`/`failure_message`.
- [ ] Add exact `Touches` entries for every created/replaced function.
- [ ] Rerun focused SQL contract tests and `bash scripts/ci/verify_harness.sh`; expect pass.
- [ ] Gate: scan the draft for direct `sales.*`/`partner.*` table references, unscoped `auth.uid`, raw email history across Partners, and timestamp migration filenames.

Suggested commit: `feat(einvoice): add delivery schema and start contracts`

### Task 6: Implement delivery result state machine, projection, and Supabase gateways

**Files:**

- Create: `supabase/migrations/_drafts/014_einvoice_s5_delivery_results.sql`
- Create: `modules/einvoice/infrastructure/lib/src/domain/delivery/supabase_delivery_command_gateway.dart`
- Create: `modules/einvoice/infrastructure/lib/src/domain/delivery/supabase_delivery_read_gateway.dart`
- Create: `modules/einvoice/infrastructure/lib/src/domain/delivery/delivery_rpc_mapper.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/domain/issuance/issuance_rpc_mapper.dart`
- Modify: `modules/einvoice/application/lib/src/shared/order_invoice_projection_dto.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/einvoice_s5_result_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/einvoice_s5_projection_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/supabase_delivery_command_gateway_test.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/supabase_delivery_read_gateway_test.dart`
- Modify: `modules/einvoice/infrastructure/test/domain/issuance/supabase_order_invoice_projection_read_gateway_test.dart`
- Modify: `modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_gateways_test.dart`

**Interfaces:** Implement prepare/result/dead-letter state transitions, reliable outbox events, projection fields, and typed RPC mapping. No provider HTTP logic belongs here.

- [ ] Run GitNexus impact for the existing projection function/mapper/DTO before editing; report downstream readers.
- [ ] Write failing result SQL tests for row locks, tenant/delivery/attempt relation, expected version, all four outcomes, retry cap, next-attempt command insertion, duplicate/reordered idempotency, and no success reversal.
- [ ] Write failing unknown tests requiring one `PENDING` reconciliation case with purpose `VERIFY_DELIVERY`, `attempt_count = 0`, first `next_check_at = now()+30s`, one deterministic `einvoice.reconcile_invoice_delivery` command, result event, no attention event yet, and an active business lock.
- [ ] Write failing dead-letter tests: exhausted `QUEUED` → `WORKER_EXHAUSTED_BEFORE_DISPATCH`/failed; `SUBMITTED` → `UNKNOWN` plus one `PENDING` reconciliation case/first command and no immediate attention.
- [ ] Write failing projection tests for main display-state precedence and secondary attention after a prior success.
- [ ] Write failing SQL-shape test requiring `drop function if exists einvoice.get_order_invoice_projection(uuid, uuid, uuid)` before recreating the changed OUT row type.
- [ ] Write failing gateway/mapper tests for exact RPC names/params, nullable fields, enum casing, timestamps, optimistic version, typed evidence, and safe error mapping.
- [ ] Run focused infrastructure tests; expect missing implementations.
- [ ] Implement `prepare_delivery_provider_call` as an atomic barrier that returns `CALL_PROVIDER`, `SKIP`, or `RECORD_UNKNOWN`.
- [ ] Implement `record_delivery_result` and `record_delivery_command_dead_letter` with row locks, immutable terminal transitions, max-three-attempt rule, atomic `PENDING` reconciliation handoff for unknown outcomes, and no legal issuance mutation. Initial unknown must not write `UNRESOLVED` or emit attention.
- [ ] Drop and recreate only `get_order_invoice_projection` to add `delivery_display_state` and `has_secondary_attention`; list it in `Touches` and do not copy unrelated RPCs.
- [ ] Implement typed gateways/mappers and update the existing projection mapper.
- [ ] Rerun focused tests, infrastructure analyzer, `git diff --check`, and strict migration policy verification applicable to drafts; expect pass.
- [ ] Gate: prove the result RPC has no route from `UNKNOWN` back to queued/processing, emits exactly one deterministic capability-aware reconciliation command, and never enqueues `send_invoice_email` for an unknown attempt.

Suggested commit: `feat(einvoice): persist delivery outcomes and projection`

### Task 7: Implement capability-aware delivery reconciliation

**Files:**

- Modify: `modules/einvoice/domain/lib/src/provider_connection/provider_capabilities_snapshot.dart`
- Modify: `modules/einvoice/domain/test/provider_connection/provider_capabilities_snapshot_test.dart`
- Modify: `modules/einvoice/application/lib/src/configuration/commands/record_connection_verified/record_connection_verified_command.dart`
- Modify: `modules/einvoice/application/lib/src/configuration/commands/sync_provider_capabilities/sync_provider_capabilities_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_delivery_reconciliation_gateway.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_invoice_delivery_observation_provider_port.dart`
- Create: typed reconciliation DTOs/outcomes under `modules/einvoice/application/lib/src/delivery/shared/`
- Create: `modules/einvoice/application/lib/src/delivery/commands/reconcile_invoice_delivery/reconcile_invoice_delivery_command.dart`
- Create: `modules/einvoice/application/lib/src/delivery/commands/reconcile_invoice_delivery/reconcile_invoice_delivery_command_handler.dart`
- Modify: `modules/einvoice/application/lib/application.dart`
- Create: `modules/einvoice/application/test/delivery/reconcile_invoice_delivery_command_handler_test.dart`
- Create: `supabase/migrations/_drafts/015_einvoice_s5_delivery_reconciliation.sql`
- Create: `modules/einvoice/infrastructure/lib/src/domain/delivery/supabase_delivery_reconciliation_gateway.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_delivery_observation_provider_adapter.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/einvoice_s5_reconciliation_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/domain/delivery/supabase_delivery_reconciliation_gateway_test.dart`
- Create: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_delivery_observation_provider_adapter_test.dart`

**Interfaces:** Add `ProviderCapabilitiesSnapshot.supportsDeliveryResultObservation`; current MISA capability sync sets it to `false`. Produce serializable `ReconcileInvoiceDeliveryCommand` (`einvoice.reconcile_invoice_delivery`), `IDeliveryReconciliationGateway`, `IInvoiceDeliveryObservationProviderPort`, typed observation outcomes, deterministic five-check scheduling for capable providers, and the one-check unsupported path for MISA.

- [ ] Run GitNexus impact for `ProviderCapabilitiesSnapshot`, capability serialization/sync, and generated internal-command registration; report the blast radius before editing existing symbols.
- [ ] Write failing domain/application tests proving the capability defaults/fails closed to false, round-trips through connection verification payload, and current MISA sync never advertises delivery-result observation.
- [ ] Write failing handler tests for: missing/stale case → no-op; unsupported capability → zero provider calls/interactions plus `unsupported` record; supported capability → exactly one observation interaction; terminal observation → resolution record; undetermined observation → same-case continuation.
- [ ] Run focused domain/application tests; expect compile failures for missing capability/ports/command.
- [ ] Implement the capability field, typed ports/DTOs, and command handler. The unsupported branch must not resolve an MISA client and must not call `getStatus`, `download`, `previewPublished`, or `sendEmail`.
- [ ] Write failing SQL tests requiring deterministic `_delivery_reconciliation_command_id(caseId, checkSequence)`, service-role-only load/record RPCs, row/version locks, exact target/purpose validation, and schedules `1=30s`, `2=2m`, `3=10m`, `4=30m`, `5=2h`.
- [ ] Write failing transition tests: supported terminal evidence → case `RESOLVED` and same delivery/attempt terminal; supported undetermined checks 1-4 → `PENDING` plus exactly one next command; check 5 undetermined → `UNRESOLVED` plus attention; unsupported check 1 → `UNRESOLVED` with `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, no provider interaction, no next command, and attention.
- [ ] Write failing late-evidence tests proving authenticated terminal evidence may resolve the same delivery/attempt and change its case from `PENDING` or `UNRESOLVED` to `RESOLVED` without creating a delivery or email-send command; duplicate/late failure cannot reverse success.
- [ ] Implement draft 015 and the Supabase gateway. `record_delivery_reconciliation_check` must write safe canonical messages only, clear `next_check_at` on terminal/unsupported/exhausted paths, and atomically write the attention outbox only on `UNRESOLVED`.
- [ ] Implement `MeInvoiceDeliveryObservationProviderAdapter` as an explicit unsupported adapter returning `DeliveryObservationUnsupported` without HTTP. Do not adapt MISA invoice `getStatus` into delivery evidence.
- [ ] Run codegen; then run focused domain/application/infrastructure tests and analyzers; expect pass.
- [ ] Gate: search all delivery reconciliation code for `getStatus`, `sendEmail`, direct raw provider payload, and duplicate initial attention. Expect no provider call on the MISA unsupported path and exactly one attention event at `UNRESOLVED`.

Suggested commit: `feat(einvoice): add capability-aware delivery reconciliation`

### Task 8: Implement the MISA delivery adapter and safe classifier

**Files:**

- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_delivery_provider_adapter.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_delivery_classifier.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/adapters/misa/tenant_me_invoice_client_factory.dart` only if delivery context needs an existing factory method exposed
- Create: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_delivery_classifier_test.dart`
- Create: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_delivery_provider_adapter_test.dart`

**Interfaces:** Adapt `IInvoiceDeliveryProviderPort` to `IMeInvoiceClient.sendEmail`; map canonical invoice context to MISA receiver fields and derive invoice-code flags via `MeInvoiceInvoiceQuery.fromInvSeries`. Return only typed allow-listed outcomes.

- [ ] Write failing classifier tests for reliable success, authentication/credential/validation/business rejection, 429 no-send retryable rejection, timeout/connection/5xx/malformed ambiguous result, and unknown provider codes defaulting to undetermined.
- [ ] Write failing adapter tests for tenant client selection, provider transaction id, receiver email/name, invoice-series-derived flags, and absence of raw response leakage.
- [ ] Run focused adapter tests; expect missing implementation.
- [ ] Implement classifier as a closed allowlist. Unknown codes and unexpected response shapes are undetermined, never definite failure.
- [ ] Implement the send adapter using `TenantMeInvoiceClientFactory`; do not call `getStatus` or mix delivery observation/reconciliation into the send adapter.
- [ ] Preserve worker-only host behavior and avoid logging recipient addresses or provider payloads.
- [ ] Run focused tests and infrastructure analyzer; expect pass.
- [ ] Gate: search for `getStatus` in all delivery send/observation code and for raw MISA message/body fields in persisted DTOs; expect none.

Suggested commit: `feat(einvoice): adapt MISA email delivery safely`

### Task 9: Wire inbox, internal commands, dead-letter handling, DI, and worker composition

**Files:**

- Modify: `modules/einvoice/infrastructure/lib/src/configuration/einvoice_startup.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/processing_module.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/outbox/process_outbox_command_handler.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/einvoice_internal_command_attempt_policy.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/delivery_command_dead_letter_handler.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/delivery_reconciliation_command_dead_letter_handler.dart`
- Generated by codegen and review only: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/einvoice_cqrs_registrar.g.dart`
- Generated by codegen and review only: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart`
- Generated by codegen and review only: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/einvoice_integration_event_registry.g.dart`
- Modify: `apps/messaging_worker/lib/messaging_module_binding.dart`
- Modify: `apps/messaging_worker/lib/messaging_worker_bootstrap.dart` only if the existing binding is not sufficient
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_s5_registration_test.dart`
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_s5_event_subscription_test.dart`
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_s5_worker_composition_test.dart`
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_s5_dead_letter_test.dart`
- Create: `modules/einvoice/infrastructure/test/configuration/einvoice_s5_reconciliation_registration_test.dart`

**Interfaces:** Register public handlers in normal module composition; register real `IInvoiceDeliveryProviderPort` only when worker MISA HTTP is enabled; register the explicit unsupported MISA `IInvoiceDeliveryObservationProviderPort`; deserialize/publish own registered event; subscribe it through the E-invoice inbox; register both `einvoice.send_invoice_email` and `einvoice.reconcile_invoice_delivery` with separate dead-letter handlers.

- [ ] Run GitNexus impact for `EinvoiceStartup`, processing registration, outbox deserialization, attempt policy, and worker composition before modifying them.
- [ ] Write failing registration tests proving all command/query/event handlers and gateways resolve exactly once.
- [ ] Write a failing event-flow test: S3 registered outbox payload → event bus subscription → E-invoice inbox dedupe → registered handler → StartAutoDelivery command.
- [ ] Write a failing worker-composition test proving ERP resolves a worker-only guard while messaging worker resolves the real MISA adapter.
- [ ] Write failing attempt-policy/dead-letter tests for max-three delivery attempts and queued-vs-submitted classification.
- [ ] Write failing reconciliation registration/dead-letter tests: unsupported MISA observation port resolves only in worker composition; exhausted reconciliation command changes a still-pending case to `UNRESOLVED` with safe code `DELIVERY_RECONCILIATION_WORKER_EXHAUSTED`, emits one attention event, and never sends email.
- [ ] Run focused configuration tests; expect missing registrations.
- [ ] Add `ElectronicInvoiceRegisteredIntegrationEvent.fromPayload` to the outbox/event mapper and register generated E-invoice integration-event subscriptions from startup.
- [ ] Register delivery/reconciliation gateways, handlers, both internal command types, both dead-letter handlers, the send adapter, and the explicit unsupported observation adapter through existing module conventions.
- [ ] Ensure generic internal-command retries cannot call MISA again after a submitted barrier; replay must flow to `recordUnknown`.
- [ ] Run codegen and inspect generated command/handler/subscription registries.
- [ ] Run `melos run env:sync` and `melos run env:doctor` before worker integration verification; if credentials/local services are unavailable, record the exact external gate while still running fake-only tests.
- [ ] Run focused configuration tests, `cd apps/messaging_worker && dart test`, and analyzers; expect pass.
- [ ] Gate: assert one registered event produces at most one active initial delivery and one provider call in the integration fake.

Suggested commit: `feat(einvoice): wire slice 5 delivery worker flow`

### Task 10: Add traceable S5 integration and scenario coverage

**Files:**

- Create: `modules/einvoice/infrastructure/test/support/slice5_delivery_integration_harness.dart`
- Create: `modules/einvoice/infrastructure/test/einvoice_slice5_integration_test.dart`
- Modify: `modules/einvoice/application/test/fake_einvoice_scenarios_e04_test.dart`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`

**Interfaces:** End-to-end in-process coverage uses fake RPC/state, real command/query handlers, inbox/outbox/internal-command processing, provider-interaction fake, and `FakeMeInvoiceClient`. No network or production database.

- [ ] Add `scn_e04_u01_fr01_01`: registration with Partner invoice email creates one automatic initial delivery and sends once.
- [ ] Add `e2e_e04_u01_sc01_01`: registered outbox replay/inbox replay converges on the same deterministic initial delivery and provider call.
- [ ] Add `scn_e04_u02_fr08_01`: manual initial send validates a changed email, persists `USER_INPUT`, and server derives `INITIAL`.
- [ ] Add `e2e_e04_u02_sc01_01`: successful initial delivery enables manual resend; resend uses new immutable recipient and server derives `RESEND`.
- [ ] Add `scn_e04_u03_fr04_01`: reliable result updates attempt/delivery/history/display and emits the safe result event.
- [ ] Add `e2e_e04_u03_sc01_01`: timeout after dispatch becomes `UNKNOWN` with one `PENDING` case and no immediate attention; replay performs zero additional email calls; the first MISA reconciliation command records unsupported, changes the case to `UNRESOLVED`, and emits exactly one attention event.
- [ ] Add race coverage for automatic and manual initial requests; assert one initial delivery and no duplicate internal command.
- [ ] Add recipient-priority coverage for current Partner, explicit `BuyerInvoiceSnapshot` lineage fallback, same-Partner successful-history suggestion, inactive/missing Partner, retail/no Partner, effective-buyer-vs-base-snapshot divergence, and tenant isolation.
- [ ] Add automatic eligibility coverage for policy turned off before processing, provider email capability missing, invalid/missing recipient, and provider capability removed before manual confirmation; assert no delivery/attempt/command is created.
- [ ] Add retry coverage for two 429s then success, max-three exhaustion, queued dead-letter, and submitted dead-letter.
- [ ] Add capability-aware reconciliation coverage with a capable fake: terminal check resolves the existing attempt; four undetermined checks remain `PENDING` and schedule one next command each; the fifth becomes `UNRESOLVED`; late terminal evidence resolves `PENDING`/`UNRESOLVED` without creating a delivery or email call.
- [ ] Add prior-success coverage: a failed/unknown resend leaves main display `SENT` and sets secondary attention.
- [ ] Run the new integration/scenario files; expect initial failures, implement only missing harness seams, then rerun to green.
- [ ] Run all E-invoice application/domain/infrastructure tests; expect pass.
- [ ] Update traceability rows with exact executable test ids and lane status; do not mark FE or production migration complete.

Suggested commit: `test(einvoice): cover slice 5 delivery scenarios`

### Task 11: Reconcile harness truth and run final verification

**Files:**

- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md` only for implementation-discovered exact signature corrections
- Modify: `docs/harness/PROGRESS.md` only if this repository tracks TH-08 lane completion there

**Interfaces:** Final documentation reports BE/Worker implementation truth while keeping FE/E2E-with-real-DB/migration promotion separate.

- [ ] Run `dart format` on changed Dart files and `git diff --check`.
- [ ] Run `melos bootstrap`.
- [ ] Run `melos run env:sync` and `melos run env:doctor`; record an unavailable environment honestly and do not bypass fail-closed checks.
- [ ] Run `melos run codegen`; confirm there are no manually maintained generated files.
- [ ] Run `melos run analyze`.
- [ ] Run `melos run test`.
- [ ] Run `cd apps/messaging_worker && dart test`.
- [ ] Run `bash scripts/ci/verify_harness.sh`.
- [ ] Run `melos run migrate:verify-policy -- --strict` without promoting drafts or resetting the database.
- [ ] Run GitNexus `detect_changes(scope: compare, base_ref: main)` and verify affected flows are limited to S5 delivery plus the intentional Partner/MISA/event/projection seams.
- [ ] Search changed code/docs for placeholder language, raw provider payload persistence, direct Partner/Sales table access, client-supplied delivery kind, MISA `getStatus` used as delivery evidence, unscoped reconciliation scans, and timestamp migration files.
- [ ] Mark S5 Contract and BE/Worker rows according to evidence. Keep FE and any real-environment E2E row open until separately implemented and verified.
- [ ] Record any unavailable local Supabase/env verification as an explicit external gate; do not substitute an assumed pass.

Suggested commit: `docs(einvoice): record slice 5 backend completion`

---

## Reviewer checklist

- [ ] Automatic initial delivery is triggered by the registered integration event through inbox dedupe, not by a UI call or daily scan.
- [ ] Auto idempotency is stable per tenant/invoice and auto/manual races cannot create two initial deliveries.
- [ ] Partner data is accessed only through `partner.get_einvoice_recipient_snapshot`; Sales scope only through `sales.can_access_sales_order`.
- [ ] Recipient selection matches the frozen priority matrix and cannot leak another customer's address.
- [ ] Automatic fallback reads the immutable base `BuyerInvoiceSnapshot` from invoice lineage, never `EffectiveBuyerInvoiceData` or a current SalesOrder refresh.
- [ ] Manual input cannot select `DeliveryKind`; the server derives initial/resend.
- [ ] Delivery recipient and intent evidence are immutable; technical retries remain under one business delivery.
- [ ] Provider dispatch has a persisted pre-call barrier and one interaction record per actual HTTP attempt.
- [ ] Timeout/5xx/malformed/replay-after-submitted becomes `UNKNOWN`, atomically creates one `PENDING` case/first reconciliation command, performs no duplicate email call, and locks another business send.
- [ ] Current MISA's first reconciliation check performs no HTTP, records `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, changes the case to `UNRESOLVED`, and emits exactly one attention event.
- [ ] A provider with explicit observation capability follows `[30s, 2m, 10m, 30m, 2h]`; only terminal evidence resolves early, and the fifth undetermined check becomes `UNRESOLVED`.
- [ ] No implementation treats invoice `getStatus` as an email-delivery observation.
- [ ] Result replay cannot reverse success; retryable no-send failures are capped at three technical attempts.
- [ ] A failed/unknown resend after success keeps the main display state `SENT` and exposes secondary attention.
- [ ] Delivery result and attention events contain safe canonical fields only and are written atomically with state.
- [ ] Both delivery tables use exact canonical names and include safe nullable `provider_result_message`/`failure_message` without raw provider text.
- [ ] `get_order_invoice_projection` is dropped before recreation because its OUT row type changes.
- [ ] Every public RPC checks actor, permission, and SalesOrder scope; worker RPCs require `service_role`.
- [ ] SQL remains in `_drafts`, `Touches` is exact, and no production migration was created or promoted.
- [ ] All six required EP-04 scenario/e2e trace ids are executable and green.
- [ ] Domain/Application/Infrastructure dependency directions remain valid and ERP cannot resolve the real MISA HTTP adapter.
