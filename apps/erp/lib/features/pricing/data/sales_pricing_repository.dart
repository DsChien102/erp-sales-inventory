import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/mappers/sales_pricing_json.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/logic/pricing_rules.dart';

class SalesPricingRepository {
  SalesPricingRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  }) : _rpc = rpc,
       _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  Future<SalesWorkingStatePricingPreviewDto> preview({
    required String storeId,
    String? customerId,
    required String currencyCode,
    required int contextVersion,
    required DateTime effectiveAt,
    required List<SalesPricingLineInput> lines,
  }) => _guard(() async {
    checkSalesPreview(
      storeId: storeId,
      customerId: customerId,
      currencyCode: currencyCode,
      effectiveAt: effectiveAt,
      contextVersion: contextVersion,
      lines: lines,
    );
    final normalizedCurrencyCode = currencyCode.trim().toUpperCase();
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'preview_sales_working_state_pricing',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_store_id': storeId,
        'p_customer_id': customerId,
        'p_currency_code': normalizedCurrencyCode,
        'p_context_version': contextVersion,
        'p_effective_at': effectiveAt.toUtc().toIso8601String(),
        'p_lines': lines.map(_lineParams).toList(growable: false),
      },
    );
    return SalesPricingJson.preview(
      raw,
      expectedContextVersion: contextVersion,
      expectedCurrencyCode: normalizedCurrencyCode,
      expectedLocalLineIds: [for (final line in lines) line.localLineId],
    );
  });

  Future<SalesManualPriceEvaluationDto> evaluateManualPrice({
    required String storeId,
    String? customerId,
    required String productId,
    required String productUnitId,
    required int quantityMicros,
    required String currencyCode,
    required int contextVersion,
    int? manualUnitPriceMinor,
    int? manualDiscountMinor,
    int? manualDiscountBasisPoints,
    required bool acknowledgeBelowFloor,
  }) => _guard(() async {
    checkSalesManualPrice(
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
    );
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'evaluate_sales_manual_price',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_store_id': storeId,
        'p_customer_id': customerId,
        'p_product_id': productId,
        'p_product_unit_id': productUnitId,
        'p_quantity_micros': quantityMicros,
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_context_version': contextVersion,
        'p_manual_unit_price_minor': manualUnitPriceMinor,
        'p_manual_discount_minor': manualDiscountMinor,
        'p_manual_discount_basis_points': manualDiscountBasisPoints,
        'p_acknowledge_below_floor': acknowledgeBelowFloor,
      },
    );
    return SalesPricingJson.manualEvaluation(raw);
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (error) {
      throw pricingException(error);
    }
  }

  static Map<String, dynamic> _lineParams(SalesPricingLineInput line) =>
      <String, dynamic>{
        'local_line_id': line.localLineId,
        'product_id': line.productId,
        'product_unit_id': line.productUnitId,
        'quantity_micros': line.quantityMicros,
        'manual_unit_price_minor': line.manualUnitPriceMinor,
        'manual_discount_minor': line.manualDiscountMinor,
        'manual_discount_basis_points': line.manualDiscountBasisPoints,
      };
}

