import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import '../logic/catalog_rules.dart';
import 'catalog_errors.dart';
import 'models/measurement_unit.dart';
import 'models/product_inputs.dart';

final class MeasurementUnitRepository {
  MeasurementUnitRepository({
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

  /// 1. List tenant measurement units (EPIC-04/US-01).
  Future<List<TenantMeasurementUnitDto>> listTenantUnits({
    String? keyword,
    int limit = 50,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'list_tenant_measurement_units',
        params: {
          'p_tenant_id': tid,
          'p_keyword': keyword,
          'p_limit': limit,
        },
      );
      return rows.map(TenantMeasurementUnitDto.fromJson).toList(growable: false);
    });
  }

  /// 2. List measurement units for a product (EPIC-04/US-01/US-02).
  Future<ProductUnitsDto> listProductUnits(
    String productId, {
    bool includeInactive = false,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      final rows = await _rpc.rows(
        'catalog',
        'list_product_units',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_include_inactive': includeInactive,
        },
      );
      final baseUnitName = rows
          .where((row) => row['is_base_unit'] == true)
          .map((row) => row['name'] as String)
          .firstOrNull ?? '';
      return ProductUnitsDto(
        productId: productId,
        baseUnitName: baseUnitName,
        units: rows.map(ProductUnitDto.fromJson).toList(growable: false),
      );
    });
  }

  /// 3. Set base unit for product (EPIC-04/US-01).
  Future<void> setBaseUnit(
    String productId,
    BaseUnitSelection selection,
  ) async {
    checkBaseUnitSelection(selection);
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'set_product_base_unit',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_tenant_unit_id': switch (selection) {
            ExistingTenantUnit(:final unitId) => unitId,
            NewTenantUnit() => null,
          },
          'p_new_unit_name': switch (selection) {
            ExistingTenantUnit() => null,
            NewTenantUnit(:final name) => name,
          },
        },
      );
      if (result == null || (result is Map && result.isEmpty)) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Set base unit did not return a result.',
        );
      }
    });
  }

  /// 4. Add conversion unit for product (EPIC-04/US-02).
  Future<void> addConversionUnit({
    required String productId,
    required String unitName,
    required double conversionRateToBase,
  }) async {
    checkConversionUnit(
      unitName: unitName,
      conversionRateToBase: conversionRateToBase,
    );
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'add_product_conversion_unit',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_unit_name': unitName,
          'p_conversion_rate_to_base': conversionRateToBase,
        },
      );
    });
  }

  /// 5. Deactivate conversion unit (EPIC-04/US-02).
  Future<void> deactivateConversionUnit({
    required String productId,
    required String productUnitId,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'deactivate_product_conversion_unit',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_product_unit_id': productUnitId,
        },
      );
    });
  }

  /// 6. Reactivate conversion unit (EPIC-04/US-02).
  Future<void> reactivateConversionUnit({
    required String productId,
    required String productUnitId,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'reactivate_product_conversion_unit',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_product_unit_id': productUnitId,
        },
      );
    });
  }

  /// 7. Delete conversion unit (EPIC-04/US-02).
  Future<void> deleteConversionUnit({
    required String productId,
    required String productUnitId,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.rows(
        'catalog',
        'delete_product_conversion_unit',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_product_unit_id': productUnitId,
        },
      );
    });
  }
}

