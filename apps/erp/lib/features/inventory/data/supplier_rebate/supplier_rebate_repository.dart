import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';

class SupplierRebateRepository {
  final InventoryRpc _rpc;

  SupplierRebateRepository({required InventoryRpc rpc}) : _rpc = rpc;

  Future<RebatePreview> preview({
    required String programId,
    int? amountVnd,
  }) async {
    final res = await _rpc.query(
      'preview_supplier_rebate',
      {
        'p_program_id': programId,
        'p_amount_vnd': amountVnd,
      },
    );
    return RebatePreview.fromJson(res);
  }

  Future<RebateRecordResult> record({
    required String idempotencyKey,
    required String programId,
    required String documentNo,
    required DateTime documentDate,
    required int amountVnd,
    String? overrideReason,
  }) async {
    final payload = <String, dynamic>{
      'document_no': documentNo.trim(),
      'document_date': _formatDateIso(documentDate),
      'amount_vnd': amountVnd,
      if (overrideReason != null) 'override_reason': overrideReason.trim(),
    };

    final res = await _rpc.mutate(
      scope: 'supplier_rebate.record',
      fn: 'record_supplier_rebate',
      idempotencyKey: idempotencyKey,
      params: {
        'p_program_id': programId,
        'p_payload': payload,
      },
    );
    return RebateRecordResult.fromJson(res);
  }

  Future<ProjectedCost> projectedCost({
    required String programId,
    required String productId,
    num? extraQty,
    num? unitPrice,
  }) async {
    final res = await _rpc.query(
      'get_projected_cost',
      {
        'p_program_id': programId,
        'p_product_id': productId,
        'p_extra_qty': extraQty,
        'p_unit_price': unitPrice,
      },
    );
    return ProjectedCost.fromJson(res);
  }

  Future<SupplierCompare> compareSuppliers(String productId) async {
    final res = await _rpc.query(
      'compare_suppliers',
      {'p_product_id': productId},
    );
    return SupplierCompare.fromJson(res);
  }

  static String _formatDateIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

