import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';

class SupplierProgramRepository {
  final InventoryRpc _rpc;

  SupplierProgramRepository({required InventoryRpc rpc}) : _rpc = rpc;

  Future<List<ProgramRow>> list() async {
    final res = await _rpc.query('list_supplier_programs');
    final raw = (res['programs'] as List?) ?? const [];
    return raw
        .map((e) => ProgramRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ProgramDetail> get(String id) async {
    final res = await _rpc.query(
      'get_supplier_program',
      {'p_program_id': id},
    );
    return ProgramDetail.fromJson(res);
  }

  Future<ProgramFormOptions> formOptions() async {
    final res = await _rpc.query('get_supplier_program_form_options');
    return ProgramFormOptions.fromJson(res);
  }

  Future<({String id, int revision})> create({
    required String idempotencyKey,
    required ProgramPayload payload,
  }) async {
    final res = await _rpc.mutate(
      scope: 'supplier_program.create',
      fn: 'create_supplier_program',
      idempotencyKey: idempotencyKey,
      params: {
        'p_payload': payload.toJson(),
      },
    );
    return (
      id: res['program_id'] as String,
      revision: (res['revision'] as num?)?.toInt() ?? 1,
    );
  }

  Future<({String id, int revision})> update({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
    required ProgramPayload payload,
  }) async {
    final res = await _rpc.mutate(
      scope: 'supplier_program.update',
      fn: 'update_supplier_program',
      idempotencyKey: idempotencyKey,
      params: {
        'p_program_id': id,
        'p_expected_revision': expectedRevision,
        'p_payload': payload.toJson(),
      },
    );
    return (
      id: (res['program_id'] as String?) ?? id,
      revision: (res['revision'] as num?)?.toInt() ?? expectedRevision + 1,
    );
  }

  Future<int> end({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
  }) async {
    final res = await _rpc.mutate(
      scope: 'supplier_program.end',
      fn: 'end_supplier_program',
      idempotencyKey: idempotencyKey,
      params: {
        'p_program_id': id,
        'p_expected_revision': expectedRevision,
      },
    );
    return (res['revision'] as num?)?.toInt() ?? expectedRevision + 1;
  }

  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async {
    final res = await _rpc.query(
      'get_receipt_program_hints',
      {
        'p_supplier_id': supplierId,
        'p_lines': [
          for (final l in lines)
            {
              'product_id': l.productId,
              'paid_qty': l.paidQty,
              'unit_price': l.unitPrice,
            },
        ],
      },
    );
    final rawLines = (res['lines'] as List?) ?? const [];
    return [
      for (final item in rawLines)
        if (item is Map && item['hint'] is Map)
          ProgramHint.fromJson(Map<String, dynamic>.from(item['hint'] as Map))
        else
          null,
    ];
  }
}

