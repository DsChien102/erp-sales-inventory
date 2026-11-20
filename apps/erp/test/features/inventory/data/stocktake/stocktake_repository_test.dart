import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingInventoryRpc extends Fake implements InventoryRpc {
  final List<({String kind, String fn, String? scope, String? key, Map<String, dynamic> params})>
      calls = [];
  Map<String, dynamic> nextResponse = const {};

  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async {
    calls.add((kind: 'query', fn: fn, scope: null, key: null, params: params));
    return nextResponse;
  }

  @override
  Future<Map<String, dynamic>> mutate({
    required String scope,
    required String idempotencyKey,
    required String fn,
    required Map<String, dynamic> params,
  }) async {
    calls.add((kind: 'mutate', fn: fn, scope: scope, key: idempotencyKey, params: params));
    return nextResponse;
  }
}

void main() {
  late _RecordingInventoryRpc rpc;
  late StocktakeRepository repository;

  setUp(() {
    rpc = _RecordingInventoryRpc();
    repository = StocktakeRepository(rpc: rpc);
  });

  group('StocktakeModels', () {
    test('session_from_json_blind keeps absent blind and owner money fields null', () {
      final blindSession = StocktakeSession.fromJson({
        'id': 's1',
        'code': 'KK-261112-01',
        'scope_kind': 'ALL',
        'scope_label': 'Toàn kho',
        'counter_name': 'Nguyễn Văn An',
        'reason': 'Kiểm kê định kỳ',
        'status': 'COUNTING',
        'opened_at': '2026-11-12T10:00:00Z',
        'lines': [
          {
            'line_id': 'l1',
            'product_id': 'p1',
            'product_name': 'Oxytetracycline',
            'product_code': 'OXY-01',
            'is_expired': false,
            'uom': 'chai',
            'is_unexpected': false,
            'draft_qty': 10,
            'needs_recount': false,
          },
        ],
      });

      expect(blindSession.adjustmentValueVnd, isNull);
      expect(blindSession.lines, hasLength(1));
      final line = blindSession.lines.first;
      expect(line.draftQty, 10);
      expect(line.bookQty, isNull);
      expect(line.variance, isNull);
      expect(line.firstQty, isNull);
      expect(line.recountQty, isNull);
      expect(line.adjustQty, isNull);
      expect(line.adjustValueVnd, isNull);

      final ownerCompleted = StocktakeSession.fromJson({
        'id': 's2',
        'code': 'KK-261112-02',
        'scope_kind': 'PRODUCT',
        'scope_label': 'Tylosin',
        'counter_name': 'Chủ cửa hàng',
        'reason': 'Kiểm kê định kỳ',
        'status': 'COMPLETED',
        'result_kind': 'ADJUSTED',
        'opened_at': '2026-11-12T10:00:00Z',
        'completed_at': '2026-11-12T11:00:00Z',
        'completed_by_name': 'Chủ cửa hàng',
        'adjustment_value_vnd': -110000,
        'stock_changes': [
          {
            'product_id': 'p2',
            'product_name': 'Tylosin',
            'base_uom': 'lọ',
            'before': 14,
            'after': 3,
          },
        ],
        'lines': [
          {
            'line_id': 'l2',
            'product_id': 'p2',
            'product_name': 'Tylosin',
            'product_code': 'TYL-01',
            'lot_id': 'lot1',
            'lot_code': 'TY2408',
            'is_expired': true,
            'uom': 'lọ',
            'is_unexpected': false,
            'needs_recount': true,
            'loss_reason': 'EXPIRED',
            'first_qty': 0,
            'recount_qty': 0,
            'book_qty': 11,
            'variance': -11,
            'adjust_qty': -11,
            'adjust_value_vnd': -110000,
          },
        ],
      });

      expect(ownerCompleted.adjustmentValueVnd, -110000);
      expect(ownerCompleted.resultKind, StocktakeResultKind.adjusted);
      expect(ownerCompleted.stockChanges.single.after, 3);
      expect(ownerCompleted.lines.single.lossReason, StocktakeLossReason.expired);
      expect(ownerCompleted.lines.single.adjustValueVnd, -110000);
    });

    test('open_conflict_json parses conflict object and leaves sessionId null', () {
      final result = OpenStocktakeResult.fromJson({
        'conflict': {
          'session_id': 's',
          'code': 'KK-261111-01',
          'scope_label': 'Toàn kho',
        },
      });

      expect(result.sessionId, isNull);
      expect(result.code, isNull);
      expect(result.conflict, isNotNull);
      expect(result.conflict!.sessionId, 's');
      expect(result.conflict!.code, 'KK-261111-01');
      expect(result.conflict!.scopeLabel, 'Toàn kho');
    });
  });

  group('StocktakeRepository', () {
    test('repository_calls_one_rpc maps each method to exact RPC and idempotency scope', () async {
      rpc.nextResponse = {'items': const []};
      await repository.list();

      rpc.nextResponse = {
        'all_count': 0,
        'products': const [],
        'lots': const [],
        'members': const [],
        'me': 'u1',
      };
      await repository.formOptions();

      rpc.nextResponse = {'session_id': 's1', 'code': 'KK-261112-01'};
      await repository.open(
        idempotencyKey: 'k-open',
        kind: StocktakeScopeKind.all,
        counterUserId: 'u1',
        reason: 'Kiểm kê định kỳ',
      );

      rpc.nextResponse = {
        'id': 's1',
        'code': 'KK-261112-01',
        'scope_kind': 'ALL',
        'scope_label': 'Toàn kho',
        'counter_name': 'An',
        'reason': 'Kiểm kê định kỳ',
        'status': 'COUNTING',
        'opened_at': '2026-11-12T10:00:00Z',
        'lines': const [],
      };
      await repository.get('s1');

      rpc.nextResponse = const {};
      await repository.saveDraft(sessionId: 's1', lineId: 'l1', quantity: 5);

      rpc.nextResponse = {'products': const []};
      await repository.unexpectedOptions('s1');

      rpc.nextResponse = {
        'line_id': 'l2',
        'product_id': 'p2',
        'product_name': 'Găng tay',
        'product_code': 'GLV-01',
        'is_expired': false,
        'uom': 'hộp',
        'is_unexpected': true,
        'needs_recount': false,
      };
      await repository.addUnexpected(
        sessionId: 's1',
        productId: 'p2',
        lotCode: 'TY2601',
        expiryDate: DateTime(2027, 2, 10),
        expiryPrecision: 'DAY',
      );

      rpc.nextResponse = {'status': 'RECOUNT', 'result_kind': null};
      await repository.submitFirst(
        idempotencyKey: 'k-first',
        sessionId: 's1',
        counts: const [StocktakeCountInput(lineId: 'l1', quantity: 5)],
      );

      rpc.nextResponse = {'status': 'COMPLETED', 'result_kind': 'ADJUSTED'};
      await repository.submitRecount(
        idempotencyKey: 'k-recount',
        sessionId: 's1',
        counts: const [
          StocktakeCountInput(
            lineId: 'l1',
            quantity: 5,
            lossReason: StocktakeLossReason.damaged,
          ),
        ],
      );

      rpc.nextResponse = {'status': 'CANCELLED'};
      final cancelStatus = await repository.cancel(
        idempotencyKey: 'k-cancel',
        sessionId: 's1',
        reason: 'Đóng ca',
      );
      expect(cancelStatus, StocktakeStatus.cancelled);

      expect(rpc.calls.map((c) => (c.kind, c.fn, c.scope, c.key)).toList(), [
        ('query', 'list_stocktake_sessions', null, null),
        ('query', 'get_stocktake_form_options', null, null),
        ('mutate', 'open_stocktake', 'stocktake.open', 'k-open'),
        ('query', 'get_stocktake_session', null, null),
        ('query', 'save_stocktake_draft', null, null),
        ('query', 'get_stocktake_unexpected_options', null, null),
        ('query', 'add_stocktake_unexpected_line', null, null),
        ('mutate', 'submit_stocktake_first_count', 'stocktake.first', 'k-first'),
        ('mutate', 'submit_stocktake_recount', 'stocktake.recount', 'k-recount'),
        ('mutate', 'cancel_stocktake', 'stocktake.cancel', 'k-cancel'),
      ]);

      final addParams = rpc.calls[6].params['p_payload'] as Map<String, dynamic>;
      expect(addParams['expiry_date'], '2027-02-10');
    });
  });

  group('InventoryErrorCode stocktake messages', () {
    test('error_messages match section 2.4 spec', () {
      String msg(String code) => inventoryErrorMessage(
            AppException(code, serverMessage: code),
            fallback: 'fallback',
          );

      expect(
        msg(InventoryErrorCode.stocktakeScopeEmpty),
        'Kho chưa có hàng trong phạm vi này để kiểm kê.',
      );
      expect(
        msg(InventoryErrorCode.stocktakeLineExists),
        'Mặt hàng này đã có trong phiên.',
      );
      expect(
        msg(InventoryErrorCode.cancelReasonRequired),
        'Nhập lý do hủy phiên',
      );
      expect(msg(InventoryErrorCode.stocktakeStateChanged), isNot('fallback'));
      expect(msg(InventoryErrorCode.stocktakeCountMissing), isNot('fallback'));
    });
  });
}
