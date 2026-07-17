import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class RememberedPriceRequestMustBeCompleteRule implements IBusinessRule {
  const RememberedPriceRequestMustBeCompleteRule({
    required this.tenantId,
    required this.actorId,
    required this.sourceOrderId,
    required this.sourceOrderLineId,
    required this.productId,
    required this.productUnitId,
    required this.idempotencyKey,
  });

  final String tenantId;
  final String actorId;
  final String sourceOrderId;
  final String sourceOrderLineId;
  final String productId;
  final String productUnitId;
  final String idempotencyKey;

  @override
  bool isBroken() =>
      tenantId.trim().isEmpty ||
      actorId.trim().isEmpty ||
      sourceOrderId.trim().isEmpty ||
      sourceOrderLineId.trim().isEmpty ||
      productId.trim().isEmpty ||
      productUnitId.trim().isEmpty ||
      idempotencyKey.trim().isEmpty;

  @override
  String get message =>
      'Remembered price request requires tenant, actor, source, product, '
      'unit, and idempotency key.';
}
