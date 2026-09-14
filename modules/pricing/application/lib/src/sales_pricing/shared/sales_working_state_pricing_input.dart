import 'sales_pricing_line_input.dart';

final class SalesWorkingStatePricingInput {
  const SalesWorkingStatePricingInput({
    required this.tenantId,
    required this.storeId,
    required this.currencyCode,
    required this.contextVersion,
    required this.effectiveAt,
    required this.lines,
    this.customerId,
  });

  final String tenantId;
  final String storeId;
  final String? customerId;
  final String currencyCode;
  final int contextVersion;
  final DateTime effectiveAt;
  final List<SalesPricingLineInput> lines;
}
