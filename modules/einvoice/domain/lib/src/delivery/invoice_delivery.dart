import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'delivery_attempt.dart';
import 'enums/delivery_actor_type.dart';
import 'enums/delivery_attempt_status.dart';
import 'enums/delivery_kind.dart';
import 'enums/delivery_status.dart';
import 'enums/delivery_trigger_type.dart';
import 'events/invoice_delivery_failed_domain_event.dart';
import 'events/invoice_delivery_started_domain_event.dart';
import 'events/invoice_delivery_succeeded_domain_event.dart';
import 'events/invoice_delivery_undetermined_domain_event.dart';
import 'rules/delivery_can_start_rule.dart';
import 'rules/delivery_result_can_be_applied_rule.dart';
import 'value_objects/delivery_recipient_snapshot.dart';
import 'value_objects/provider_delivery_result.dart';

/// Business send/resend intent for one electronic invoice.
final class InvoiceDelivery extends Entity<String> implements IAggregateRoot {
  InvoiceDelivery._({
    required super.id,
    required TenantId tenantId,
    required String electronicInvoiceId,
    required int deliveryNumber,
    required DeliveryKind kind,
    required DeliveryTriggerType triggerType,
    required DeliveryActorType actorType,
    String? actorId,
    required DeliveryRecipientSnapshot recipient,
    required DeliveryStatus status,
    required DateTime startedAt,
    DateTime? completedAt,
    ProviderDeliveryResult? providerResult,
    required List<DeliveryAttempt> attempts,
    required int version,
  }) : _tenantId = tenantId,
       _electronicInvoiceId = electronicInvoiceId,
       _deliveryNumber = deliveryNumber,
       _kind = kind,
       _triggerType = triggerType,
       _actorType = actorType,
       _actorId = actorId,
       _recipient = recipient,
       _status = status,
       _startedAt = startedAt,
       _completedAt = completedAt,
       _providerResult = providerResult,
       _attempts = attempts,
       _version = version;

  static const int maxAttempts = 3;

  factory InvoiceDelivery.start({
    required String id,
    required TenantId tenantId,
    required String electronicInvoiceId,
    required int deliveryNumber,
    required DeliveryKind kind,
    required DeliveryTriggerType triggerType,
    required DeliveryActorType actorType,
    String? actorId,
    required DeliveryRecipientSnapshot recipient,
    required String firstAttemptId,
    required String providerConnectionId,
    required DateTime startedAt,
    required bool hasPriorDeliveryHistory,
    required bool hasPriorInitialDelivery,
    required bool invoiceHasActiveLock,
  }) {
    final delivery = InvoiceDelivery._(
      id: id,
      tenantId: tenantId,
      electronicInvoiceId: electronicInvoiceId,
      deliveryNumber: deliveryNumber,
      kind: kind,
      triggerType: triggerType,
      actorType: actorType,
      actorId: actorId,
      recipient: recipient,
      status: DeliveryStatus.processing,
      startedAt: startedAt,
      attempts: [],
      version: 1,
    );
    delivery.checkRule(
      DeliveryCanStartRule(
        kind: kind,
        hasPriorDeliveryHistory: hasPriorDeliveryHistory,
        hasPriorInitialDelivery: hasPriorInitialDelivery,
        invoiceHasActiveLock: invoiceHasActiveLock,
      ),
    );
    delivery._attempts.add(
      DeliveryAttempt.queued(
        id: firstAttemptId,
        attemptNumber: 1,
        providerConnectionId: providerConnectionId,
        queuedAt: startedAt,
      ),
    );
    delivery.addDomainEvent(
      InvoiceDeliveryStartedDomainEvent(
        deliveryId: id,
        electronicInvoiceId: electronicInvoiceId,
      ),
    );
    return delivery;
  }

  factory InvoiceDelivery.reconstitute({
    required String id,
    required TenantId tenantId,
    required String electronicInvoiceId,
    required int deliveryNumber,
    required DeliveryKind kind,
    required DeliveryTriggerType triggerType,
    required DeliveryActorType actorType,
    String? actorId,
    required DeliveryRecipientSnapshot recipient,
    required DeliveryStatus status,
    required DateTime startedAt,
    DateTime? completedAt,
    ProviderDeliveryResult? providerResult,
    required List<DeliveryAttempt> attempts,
    required int version,
  }) {
    return InvoiceDelivery._(
      id: id,
      tenantId: tenantId,
      electronicInvoiceId: electronicInvoiceId,
      deliveryNumber: deliveryNumber,
      kind: kind,
      triggerType: triggerType,
      actorType: actorType,
      actorId: actorId,
      recipient: recipient,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      providerResult: providerResult,
      attempts: List<DeliveryAttempt>.of(attempts),
      version: version,
    );
  }

  final TenantId _tenantId;
  final String _electronicInvoiceId;
  final int _deliveryNumber;
  final DeliveryKind _kind;
  final DeliveryTriggerType _triggerType;
  final DeliveryActorType _actorType;
  final String? _actorId;
  final DeliveryRecipientSnapshot _recipient;
  DeliveryStatus _status;
  final DateTime _startedAt;
  DateTime? _completedAt;
  ProviderDeliveryResult? _providerResult;
  final List<DeliveryAttempt> _attempts;
  int _version;

  TenantId get tenantId => _tenantId;
  String get electronicInvoiceId => _electronicInvoiceId;
  int get deliveryNumber => _deliveryNumber;
  DeliveryKind get kind => _kind;
  DeliveryTriggerType get triggerType => _triggerType;
  DeliveryActorType get actorType => _actorType;
  String? get actorId => _actorId;
  DeliveryRecipientSnapshot get recipient => _recipient;
  DeliveryStatus get status => _status;
  DateTime get startedAt => _startedAt;
  DateTime? get completedAt => _completedAt;
  ProviderDeliveryResult? get providerResult => _providerResult;
  List<DeliveryAttempt> get attempts => List.unmodifiable(_attempts);
  int get version => _version;

  DeliveryAttempt? get latestAttempt => _attempts.isEmpty ? null : _attempts.last;

  bool get hasActiveLock => _status == DeliveryStatus.processing;

  void markAttemptSubmitted({
    required String attemptId,
    required String providerInteractionReference,
    required String providerRequestReference,
    required DateTime submittedAt,
  }) {
    final attempt = _requireAttempt(attemptId);
    attempt.markSubmitted(
      providerInteractionReference: providerInteractionReference,
      providerRequestReference: providerRequestReference,
      submittedAt: submittedAt,
    );
    _version += 1;
  }

  void applyProviderResult({
    required String attemptId,
    required ProviderDeliveryResult result,
    required DateTime completedAt,
    String? nextAttemptId,
  }) {
    final attempt = _requireAttempt(attemptId);

    if (_status == DeliveryStatus.succeeded) {
      return;
    }
    if (attempt.status == DeliveryAttemptStatus.succeeded ||
        attempt.status == DeliveryAttemptStatus.failed) {
      return;
    }

    checkRule(
      DeliveryResultCanBeAppliedRule(
        deliveryStatus: _status,
        attemptStatus: attempt.status,
        result: result,
        isTargetAttempt: true,
      ),
    );

    switch (result.category) {
      case ProviderDeliveryResultCategory.success:
        attempt.completeWith(
          status: DeliveryAttemptStatus.succeeded,
          result: result,
          completedAt: completedAt,
        );
        _providerResult = result;
        _completedAt = completedAt;
        _status = DeliveryStatus.succeeded;
        _version += 1;
        addDomainEvent(
          InvoiceDeliverySucceededDomainEvent(
            deliveryId: id,
            electronicInvoiceId: _electronicInvoiceId,
          ),
        );
      case ProviderDeliveryResultCategory.definiteFailure:
        attempt.completeWith(
          status: DeliveryAttemptStatus.failed,
          result: result,
          completedAt: completedAt,
        );
        _providerResult = result;
        _completedAt = completedAt;
        _status = DeliveryStatus.failed;
        _version += 1;
        addDomainEvent(
          InvoiceDeliveryFailedDomainEvent(
            deliveryId: id,
            electronicInvoiceId: _electronicInvoiceId,
          ),
        );
      case ProviderDeliveryResultCategory.retryableFailure:
        attempt.completeWith(
          status: DeliveryAttemptStatus.failed,
          result: result,
          completedAt: completedAt,
        );
        if (_attempts.length < maxAttempts) {
          if (nextAttemptId == null || nextAttemptId.isEmpty) {
            throw ArgumentError.value(
              nextAttemptId,
              'nextAttemptId',
              'required when queuing a retry attempt',
            );
          }
          _attempts.add(
            DeliveryAttempt.queued(
              id: nextAttemptId,
              attemptNumber: _attempts.length + 1,
              providerConnectionId: attempt.providerConnectionId,
              queuedAt: completedAt,
            ),
          );
          _status = DeliveryStatus.processing;
          _providerResult = result;
          _completedAt = null;
          _version += 1;
        } else {
          _providerResult = result;
          _completedAt = completedAt;
          _status = DeliveryStatus.failed;
          _version += 1;
          addDomainEvent(
            InvoiceDeliveryFailedDomainEvent(
              deliveryId: id,
              electronicInvoiceId: _electronicInvoiceId,
            ),
          );
        }
      case ProviderDeliveryResultCategory.undetermined:
        attempt.completeWith(
          status: DeliveryAttemptStatus.unknown,
          result: result,
          completedAt: completedAt,
        );
        _providerResult = result;
        _completedAt = completedAt;
        _status = DeliveryStatus.unknown;
        _version += 1;
        addDomainEvent(
          InvoiceDeliveryUndeterminedDomainEvent(
            deliveryId: id,
            electronicInvoiceId: _electronicInvoiceId,
          ),
        );
    }
  }

  DeliveryAttempt _requireAttempt(String attemptId) {
    for (final attempt in _attempts) {
      if (attempt.id == attemptId) {
        return attempt;
      }
    }
    throw ArgumentError.value(attemptId, 'attemptId', 'unknown attempt');
  }
}
