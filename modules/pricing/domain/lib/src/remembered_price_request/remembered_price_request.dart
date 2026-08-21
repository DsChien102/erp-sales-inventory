import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'events/remembered_price_saved_domain_event.dart';
import 'remembered_price_request_status.dart';
import 'remembered_price_result_type.dart';
import 'rules/remembered_price_outcome_must_be_consistent_rule.dart';
import 'rules/remembered_price_request_must_be_complete_rule.dart';
import 'rules/remembered_price_request_must_be_open_rule.dart';

final class RememberedPriceRequest extends Entity<String>
    implements IAggregateRoot {
  RememberedPriceRequest._({
    required super.id,
    required this.tenantId,
    required this.actorId,
    required this.sourceOrderId,
    required this.sourceOrderLineId,
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.soldPrice,
    required this.soldAt,
    required this.idempotencyKey,
    required RememberedPriceRequestStatus status,
  }) : _status = status;

  factory RememberedPriceRequest.receive({
    required String id,
    required String tenantId,
    required String actorId,
    required String sourceOrderId,
    required String sourceOrderLineId,
    required String? customerId,
    required String productId,
    required String productUnitId,
    required Money soldPrice,
    required DateTime soldAt,
    required String idempotencyKey,
  }) {
    RememberedPriceRequestMustBeCompleteRule(
      tenantId: tenantId,
      actorId: actorId,
      sourceOrderId: sourceOrderId,
      sourceOrderLineId: sourceOrderLineId,
      productId: productId,
      productUnitId: productUnitId,
      idempotencyKey: idempotencyKey,
    ).ensureValid();
    return RememberedPriceRequest._(
      id: id,
      tenantId: tenantId.trim(),
      actorId: actorId.trim(),
      sourceOrderId: sourceOrderId.trim(),
      sourceOrderLineId: sourceOrderLineId.trim(),
      customerId: _normalizeCustomerId(customerId),
      productId: productId.trim(),
      productUnitId: productUnitId.trim(),
      soldPrice: soldPrice,
      soldAt: soldAt.toUtc(),
      idempotencyKey: idempotencyKey.trim(),
      status: RememberedPriceRequestStatus.received,
    );
  }

  final String tenantId;
  final String actorId;
  final String sourceOrderId;
  final String sourceOrderLineId;
  final String? customerId;
  final String productId;
  final String productUnitId;
  final Money soldPrice;
  final DateTime soldAt;
  final String idempotencyKey;
  RememberedPriceRequestStatus _status;
  RememberedPriceRequestStatus get status => _status;

  void recordOutcome({
    required RememberedPriceResultType resultType,
    required String? ruleId,
    required int? ruleVersion,
    required String? reasonCode,
  }) {
    RememberedPriceRequestMustBeOpenRule(_status).ensureValid();
    RememberedPriceOutcomeMustBeConsistentRule(
      resultType: resultType,
      ruleId: ruleId,
      ruleVersion: ruleVersion,
      reasonCode: reasonCode,
    ).ensureValid();
    _status = switch (resultType) {
      RememberedPriceResultType.created ||
      RememberedPriceResultType.updated =>
        RememberedPriceRequestStatus.processed,
      RememberedPriceResultType.skipped =>
        RememberedPriceRequestStatus.skipped,
      RememberedPriceResultType.blocked =>
        RememberedPriceRequestStatus.blocked,
    };
    if (resultType == RememberedPriceResultType.created ||
        resultType == RememberedPriceResultType.updated) {
      addDomainEvent(
        RememberedPriceSavedDomainEvent(
          requestId: id,
          ruleId: ruleId!,
          ruleVersion: ruleVersion!,
          resultType: resultType,
        ),
      );
    }
  }

  static String? _normalizeCustomerId(String? customerId) {
    final normalized = customerId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
