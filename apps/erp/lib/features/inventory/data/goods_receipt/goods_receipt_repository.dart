import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';

class GoodsReceiptRepository {
  const GoodsReceiptRepository({required InventoryRpc rpc}) : _rpc = rpc;

  final InventoryRpc _rpc;

  Future<ReceiptFormOptions> formOptions() async {
    final res = await _rpc.query('get_goods_receipt_form_options');
    return ReceiptFormOptions.fromJson(res);
  }

  Future<RecordReceiptResult> record({
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    final res = await _rpc.mutate(
      scope: 'goods_receipt.record',
      fn: 'record_goods_receipt',
      idempotencyKey: idempotencyKey,
      params: {'p_payload': payload},
    );
    return RecordReceiptResult.fromJson(res);
  }

  Future<List<ReceiptListRow>> list({
    String? supplierId,
    int limit = 100,
  }) async {
    final res = await _rpc.query(
      'list_goods_receipts',
      {
        'p_supplier_id': ?supplierId,
        'p_limit': limit,
      },
    );
    final list = (res['receipts'] as List?) ?? const [];
    return list
        .map((e) => ReceiptListRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ReceiptDetail> get(String receiptId) async {
    final res = await _rpc.query(
      'get_goods_receipt',
      {'p_receipt_id': receiptId},
    );
    return ReceiptDetail.fromJson(res);
  }
}
