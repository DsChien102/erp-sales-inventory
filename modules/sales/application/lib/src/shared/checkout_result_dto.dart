import 'sales_contract_enums.dart';

final class CheckoutResultDto {
  const CheckoutResultDto({
    required this.idempotencyKey,
    required this.salesOrderId,
    required this.salesOrderVersion,
    required this.status,
  });

  final String idempotencyKey;
  final String salesOrderId;
  final int salesOrderVersion;
  final CheckoutResultStatus status;
}
