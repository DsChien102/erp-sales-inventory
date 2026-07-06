import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_rpc_mapper.dart';

final class SupabaseCatalogUnitGateway implements ICatalogUnitGateway {
  SupabaseCatalogUnitGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<TenantMeasurementUnitDto>> listTenantUnits({
    required String tenantId,
    String? keyword,
    required int limit,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'list_tenant_measurement_units',
        params: ProductRpcMapper.listTenantUnitsParams(
          tenantId: tenantId,
          keyword: keyword,
          limit: limit,
        ),
      );

      return rows
          .map(
            (row) => TenantMeasurementUnitDto(
              id: row['id'] as String,
              name: row['name'] as String,
              isActive: row['is_active'] as bool? ?? true,
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<bool> isDuplicateUnitName({
    required String tenantId,
    required String name,
  }) async {
    try {
      return await _rpcClient.callScalar<bool>(
            'check_duplicate_measurement_unit_name',
            params: ProductRpcMapper.checkDuplicateUnitNameParams(
              tenantId: tenantId,
              name: name,
            ),
          ) ??
          false;
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<SetProductBaseUnitResult> setProductBaseUnit({
    required SetProductBaseUnitCommand command,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'set_product_base_unit',
        params: ProductRpcMapper.setProductBaseUnitParams(command),
      );

      if (row.isEmpty) {
        throw ApplicationException('Set base unit did not return a result.');
      }

      return SetProductBaseUnitResult(
        productId: row['product_id'] as String,
        baseUnitName: row['base_unit_name'] as String,
        readinessSummary: _readinessSummaryFromRow(row),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  ReadinessSummaryDto _readinessSummaryFromRow(Map<String, dynamic> row) {
    final blockersValue = row['readiness_blockers'];
    final blockers = blockersValue is List
        ? blockersValue
              .map((value) => Map<String, dynamic>.from(value as Map))
              .map(
                (blocker) => ReadinessBlockerDto(
                  code: blocker['code'] as String,
                  message: blocker['message'] as String? ?? '',
                  group: blocker['group'] as String?,
                ),
              )
              .toList(growable: false)
        : const <ReadinessBlockerDto>[];

    return ReadinessSummaryDto(
      status: ProductRpcMapper.readinessStatusFromRpc(
        row['readiness_status'] as String?,
      ),
      blockers: blockers,
    );
  }
}
