import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sales_manual_price_evaluation_dto.dart';

@RequiresPermission(PricingPermissions.adjustSalesPrice)
@RequiresTenant()
final class EvaluateSalesManualPriceQuery
    extends QueryBase<SalesManualPriceEvaluationDto>
    implements IQuery<SalesManualPriceEvaluationDto>, ITenantScopedCommand {
  EvaluateSalesManualPriceQuery({
    String? id,
    this.tenantId = '',
    required this.storeId,
    this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.quantityMicros,
    required String currencyCode,
    required this.contextVersion,
    this.manualUnitPriceMinor,
    this.manualDiscountMinor,
    this.manualDiscountBasisPoints,
    required this.acknowledgeBelowFloor,
  }) : currencyCode = currencyCode.trim().toUpperCase(),
       super(id);

  @override
  final String tenantId;
  final String storeId;
  final String? customerId;
  final String productId;
  final String productUnitId;
  final int quantityMicros;
  final String currencyCode;
  final int contextVersion;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
  final bool acknowledgeBelowFloor;

  int get manualIntentCount => [
    manualUnitPriceMinor,
    manualDiscountMinor,
    manualDiscountBasisPoints,
  ].where((value) => value != null).length;

  EvaluateSalesManualPriceQuery withExecutionContext({
    required String tenantId,
  }) => EvaluateSalesManualPriceQuery(
    id: id,
    tenantId: tenantId,
    storeId: storeId,
    customerId: customerId,
    productId: productId,
    productUnitId: productUnitId,
    quantityMicros: quantityMicros,
    currencyCode: currencyCode,
    contextVersion: contextVersion,
    manualUnitPriceMinor: manualUnitPriceMinor,
    manualDiscountMinor: manualDiscountMinor,
    manualDiscountBasisPoints: manualDiscountBasisPoints,
    acknowledgeBelowFloor: acknowledgeBelowFloor,
  );
}
