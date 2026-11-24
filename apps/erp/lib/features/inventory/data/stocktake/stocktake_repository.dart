import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';

String _formatIsoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Repository cho nghiệp vụ kiểm kê (SCR-042..046); mỗi method gọi đúng 1 RPC.
class StocktakeRepository {
  StocktakeRepository({required InventoryRpc rpc}) : _rpc = rpc;

  final InventoryRpc _rpc;

  Future<List<StocktakeListRow>> list() async {
    final json = await _rpc.query('list_stocktake_sessions');
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => StocktakeListRow.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<StocktakeFormOptions> formOptions() async {
    final json = await _rpc.query('get_stocktake_form_options');
    return StocktakeFormOptions.fromJson(json);
  }

  Future<OpenStocktakeResult> open({
    required String idempotencyKey,
    required StocktakeScopeKind kind,
    String? productId,
    String? lotId,
    required String counterUserId,
    required String reason,
  }) async {
    final json = await _rpc.mutate(
      scope: 'stocktake.open',
      idempotencyKey: idempotencyKey,
      fn: 'open_stocktake',
      params: {
        'p_payload': {
          'scope_kind': kind.wire,
          'product_id': ?productId,
          'lot_id': ?lotId,
          'counter_user_id': counterUserId,
          'reason': reason,
        },
      },
    );
    return OpenStocktakeResult.fromJson(json);
  }

  Future<StocktakeSession> get(String sessionId) async {
    final json = await _rpc.query('get_stocktake_session', {
      'p_session_id': sessionId,
    });
    return StocktakeSession.fromJson(json);
  }

  Future<void> saveDraft({
    required String sessionId,
    required String lineId,
    num? quantity,
  }) async {
    await _rpc.query('save_stocktake_draft', {
      'p_session_id': sessionId,
      'p_line_id': lineId,
      'p_quantity': quantity,
    });
  }

  Future<StocktakeUnexpectedOptions> unexpectedOptions(String sessionId) async {
    final json = await _rpc.query('get_stocktake_unexpected_options', {
      'p_session_id': sessionId,
    });
    return StocktakeUnexpectedOptions.fromJson(json);
  }

  Future<StocktakeLine> addUnexpected({
    required String sessionId,
    required String productId,
    String? lotId,
    String? lotCode,
    DateTime? expiryDate,
    String? expiryPrecision,
  }) async {
    final json = await _rpc.query('add_stocktake_unexpected_line', {
      'p_session_id': sessionId,
      'p_payload': {
        'product_id': productId,
        'lot_id': ?lotId,
        'lot_code': ?lotCode,
        if (expiryDate != null) 'expiry_date': _formatIsoDate(expiryDate),
        'expiry_precision': ?expiryPrecision,
      },
    });
    return StocktakeLine.fromJson(json);
  }

  Future<StocktakeSubmitResult> submitFirst({
    required String idempotencyKey,
    required String sessionId,
    required List<StocktakeCountInput> counts,
  }) async {
    final json = await _rpc.mutate(
      scope: 'stocktake.first',
      idempotencyKey: idempotencyKey,
      fn: 'submit_stocktake_first_count',
      params: {
        'p_session_id': sessionId,
        'p_counts': counts.map((c) => c.toJson()).toList(growable: false),
      },
    );
    return StocktakeSubmitResult.fromJson(json);
  }

  Future<StocktakeSubmitResult> submitRecount({
    required String idempotencyKey,
    required String sessionId,
    required List<StocktakeCountInput> counts,
  }) async {
    final json = await _rpc.mutate(
      scope: 'stocktake.recount',
      idempotencyKey: idempotencyKey,
      fn: 'submit_stocktake_recount',
      params: {
        'p_session_id': sessionId,
        'p_counts': counts.map((c) => c.toJson()).toList(growable: false),
      },
    );
    return StocktakeSubmitResult.fromJson(json);
  }

  Future<StocktakeStatus> cancel({
    required String idempotencyKey,
    required String sessionId,
    required String reason,
  }) async {
    final json = await _rpc.mutate(
      scope: 'stocktake.cancel',
      idempotencyKey: idempotencyKey,
      fn: 'cancel_stocktake',
      params: {
        'p_session_id': sessionId,
        'p_reason': reason,
      },
    );
    return StocktakeStatus.fromWire(json['status'] as String);
  }
}
