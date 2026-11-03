import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import '../logic/catalog_rules.dart';
import 'catalog_errors.dart';
import 'models/catalog_enums.dart';
import 'models/price_band.dart';
import 'models/store_price_rule.dart';

final class ProductPriceRepository {
  ProductPriceRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  })  : _rpc = rpc,
        _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AppException catch (e) {
      throw catalogException(e);
    }
  }

  /// 1. Set manual base price for product (EPIC-06/US-01, SP-11).
  Future<void> setManualBasePrice({
    required String productId,
    required double basePrice,
    String currency = 'VND',
  }) async {
    checkManualBasePrice(basePrice);
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'set_manual_base_price',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_mode': 'manual',
          'p_base_price_after_vat': basePrice,
          'p_currency': currency,
        },
      );
    });
  }

  /// 2. List price bands across all units for product (EPIC-06/US-02, SP-12).
  Future<ProductUnitPriceBandsDto> listUnitPriceBands(String productId) async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'list_product_unit_price_bands',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Product unit price bands did not return a result.',
        );
      }
      return ProductUnitPriceBandsDto.fromRows(rows);
    });
  }

  /// 3. Get price band snapshot for Pricing / POS (TH-02 9.1).
  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot(
    List<ProductPriceBandSnapshotRequest> items,
  ) async {
    checkPriceBandSnapshotRequest(items);
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'get_product_price_band_snapshot',
        params: {
          'p_tenant_id': tid,
          'p_items': items
              .map(
                (item) => <String, dynamic>{
                  'product_id': item.productId,
                  'product_unit_id': item.productUnitId,
                },
              )
              .toList(growable: false),
        },
      );
      final capturedAt = DateTime.now().toUtc();
      final map = _asMap(result);
      return ProductPriceBandSnapshotDto.fromJson(map, capturedAt: capturedAt);
    });
  }

  /// 4. Set price band for a specific product unit (SP-13).
  Future<void> setUnitPriceBand({
    required String productId,
    String? productUnitId,
    PriceBandSourceType sourceType = PriceBandSourceType.manual,
    int? listBeforeVat,
    int? listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    double? listMarkupRatio,
    double? floorMarkupRatio,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
  }) async {
    checkUnitPriceBand(
      sourceType: sourceType,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      floorBeforeVat: floorBeforeVat,
      floorAfterVat: floorAfterVat,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
    );

    // Q7: customConfig is calculated by server; clear prices
    // (phòng hờ nếu gọi trực tiếp bỏ qua checkUnitPriceBand).
    int? effectiveListBeforeVat = listBeforeVat;
    int? effectiveListAfterVat = listAfterVat;
    int? effectiveFloorBeforeVat = floorBeforeVat;
    int? effectiveFloorAfterVat = floorAfterVat;
    if (sourceType == PriceBandSourceType.customConfig) {
      effectiveListBeforeVat = null;
      effectiveListAfterVat = null;
      effectiveFloorBeforeVat = null;
      effectiveFloorAfterVat = null;
    }

    final tid = await _tenantId();
    return _guard(() async {
      final params = <String, dynamic>{
        'p_tenant_id': tid,
        'p_product_id': productId,
        'p_product_unit_id': productUnitId,
        'p_list_price_before_vat': effectiveListBeforeVat,
        'p_list_price_after_vat': effectiveListAfterVat,
        'p_source_type': switch (sourceType) {
          PriceBandSourceType.ruleBased => 'ruleBased',
          PriceBandSourceType.customConfig => 'customConfig',
          PriceBandSourceType.manual => 'manual',
        },
        'p_store_price_rule_id': null,
        'p_list_markup_ratio': listMarkupRatio,
        'p_floor_markup_ratio': floorMarkupRatio,
      };
      if (effectiveFloorBeforeVat != null) {
        params['p_floor_price_before_vat'] = effectiveFloorBeforeVat;
      }
      if (effectiveFloorAfterVat != null) {
        params['p_floor_price_after_vat'] = effectiveFloorAfterVat;
      }
      if (effectiveFrom != null) {
        params['p_effective_from'] = effectiveFrom.toUtc().toIso8601String();
      }
      if (effectiveTo != null) {
        params['p_effective_to'] = effectiveTo.toUtc().toIso8601String();
      }
      if (status != null) {
        params['p_status'] = status.toWire();
      }

      await _rpc.rows(
        'catalog',
        'set_product_unit_price_band',
        params: params,
      );
    });
  }

  /// 5. Suggest price based on store price rule (SP-18).
  Future<ProductUnitPriceSuggestionDto> suggestUnitPrice({
    required String productId,
    String? productUnitId,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'suggest_product_unit_price',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_product_unit_id': productUnitId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Suggest product unit price did not return a result.',
        );
      }
      return ProductUnitPriceSuggestionDto.fromRow(rows.first);
    });
  }

  /// 6. Apply store price rule to a unit (SP-18).
  Future<void> applyStorePriceRule({
    required String productId,
    String? productUnitId,
    String? storePriceRuleId,
    int? basePriceVersion,
    bool confirmOverwrite = false,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'apply_store_price_rule',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_product_unit_id': productUnitId,
          'p_store_price_rule_id': storePriceRuleId,
          'p_confirm_overwrite': confirmOverwrite,
          'p_base_price_version': basePriceVersion,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Apply store price rule did not return a result.',
        );
      }
    });
  }

  /// 7. Get store price rule (SP-18…20).
  Future<StorePriceRuleDto?> getStorePriceRule() async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'get_store_price_rule',
        params: {
          'p_tenant_id': tid,
        },
      );
      if (rows.isEmpty) {
        return null;
      }
      return StorePriceRuleDto.fromRow(rows.first);
    });
  }

  /// 8. Set store price rule (SP-18…20).
  Future<StorePriceRuleDto> setStorePriceRule({
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) async {
    checkStorePriceRule(
      name: name,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
    );
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'set_store_price_rule',
        params: {
          'p_tenant_id': tid,
          'p_name': name,
          'p_list_markup_ratio': listMarkupRatio,
          'p_floor_markup_ratio': floorMarkupRatio,
          'p_status': status == StorePriceRuleStatus.active ? 'active' : 'inactive',
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Set store price rule did not return a result.',
        );
      }
      final rule = StorePriceRuleDto.fromRow(rows.first);
      if (rule == null) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Set store price rule returned invalid data.',
        );
      }
      return rule;
    });
  }

  /// 9. Get store price rule change history (SP-20).
  Future<StorePriceRuleChangeHistoryResultDto> getStorePriceRuleHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'get_store_price_rule_change_history',
        params: {
          'p_tenant_id': tid,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      final map = _asMap(result);
      return StorePriceRuleChangeHistoryResultDto.fromJson(map);
    });
  }
}

Map<String, dynamic> _asMap(Object? result) {
  if (result == null) return const <String, dynamic>{};
  if (result is Map<String, dynamic>) return result;
  if (result is Map) return Map<String, dynamic>.from(result);
  return const <String, dynamic>{};
}


