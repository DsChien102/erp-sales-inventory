import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'enums/delivery_attempt_status.dart';
import 'value_objects/provider_delivery_result.dart';

/// Technical process record owned by [InvoiceDelivery].
final class DeliveryAttempt extends Entity<String> {
  DeliveryAttempt._({
    required super.id,
    required int attemptNumber,
    required DeliveryAttemptStatus status,
    required String providerConnectionId,
    required DateTime queuedAt,
    DateTime? submittedAt,
    DateTime? completedAt,
    String? providerInteractionReference,
    String? providerRequestReference,
    ProviderDeliveryResult? result,
    int version = 1,
  }) : _attemptNumber = attemptNumber,
       _status = status,
       _providerConnectionId = providerConnectionId,
       _queuedAt = queuedAt,
       _submittedAt = submittedAt,
       _completedAt = completedAt,
       _providerInteractionReference = providerInteractionReference,
       _providerRequestReference = providerRequestReference,
       _result = result,
       _version = version;

  factory DeliveryAttempt.queued({
    required String id,
    required int attemptNumber,
    required String providerConnectionId,
    required DateTime queuedAt,
  }) {
    return DeliveryAttempt._(
      id: id,
      attemptNumber: attemptNumber,
      status: DeliveryAttemptStatus.queued,
      providerConnectionId: providerConnectionId,
      queuedAt: queuedAt,
    );
  }

  factory DeliveryAttempt.reconstitute({
    required String id,
    required int attemptNumber,
    required DeliveryAttemptStatus status,
    required String providerConnectionId,
    required DateTime queuedAt,
    DateTime? submittedAt,
    DateTime? completedAt,
    String? providerInteractionReference,
    String? providerRequestReference,
    ProviderDeliveryResult? result,
    int version = 1,
  }) {
    return DeliveryAttempt._(
      id: id,
      attemptNumber: attemptNumber,
      status: status,
      providerConnectionId: providerConnectionId,
      queuedAt: queuedAt,
      submittedAt: submittedAt,
      completedAt: completedAt,
      providerInteractionReference: providerInteractionReference,
      providerRequestReference: providerRequestReference,
      result: result,
      version: version,
    );
  }

  final int _attemptNumber;
  DeliveryAttemptStatus _status;
  final String _providerConnectionId;
  final DateTime _queuedAt;
  DateTime? _submittedAt;
  DateTime? _completedAt;
  String? _providerInteractionReference;
  String? _providerRequestReference;
  ProviderDeliveryResult? _result;
  int _version;

  int get attemptNumber => _attemptNumber;
  DeliveryAttemptStatus get status => _status;
  String get providerConnectionId => _providerConnectionId;
  DateTime get queuedAt => _queuedAt;
  DateTime? get submittedAt => _submittedAt;
  DateTime? get completedAt => _completedAt;
  String? get providerInteractionReference => _providerInteractionReference;
  String? get providerRequestReference => _providerRequestReference;
  ProviderDeliveryResult? get result => _result;
  int get version => _version;

  bool get isActive =>
      _status == DeliveryAttemptStatus.queued || _status == DeliveryAttemptStatus.submitted;

  void markSubmitted({
    required String providerInteractionReference,
    required String providerRequestReference,
    required DateTime submittedAt,
  }) {
    if (_status != DeliveryAttemptStatus.queued) {
      throw BusinessRuleValidationException(
        _AttemptTransitionRule(
          from: _status,
          to: DeliveryAttemptStatus.submitted,
        ),
      );
    }
    _providerInteractionReference = providerInteractionReference;
    _providerRequestReference = providerRequestReference;
    _submittedAt = submittedAt;
    _status = DeliveryAttemptStatus.submitted;
    _version += 1;
  }

  void completeWith({
    required DeliveryAttemptStatus status,
    required ProviderDeliveryResult result,
    required DateTime completedAt,
  }) {
    assert(
      status == DeliveryAttemptStatus.succeeded ||
          status == DeliveryAttemptStatus.failed ||
          status == DeliveryAttemptStatus.unknown,
    );
    _result = result;
    _completedAt = completedAt;
    _status = status;
    _version += 1;
  }
}

final class _AttemptTransitionRule implements IBusinessRule {
  const _AttemptTransitionRule({required this.from, required this.to});

  final DeliveryAttemptStatus from;
  final DeliveryAttemptStatus to;

  @override
  bool isBroken() => true;

  @override
  String get message => 'Delivery attempt transition from $from to $to is not allowed';
}
