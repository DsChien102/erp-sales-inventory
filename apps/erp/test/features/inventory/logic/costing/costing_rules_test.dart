import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:flutter_test/flutter_test.dart';

CostRunView _sampleRun({int productCount = 12}) => CostRunView(
      runId: 'r1',
      code: 'GV-2608-01',
      kind: CostRunKind.periodClose,
      periodMonth: DateTime(2026, 8, 1),
      status: CostRunStatus.readyForReview,
      method: CostMethod.periodic,
      fromSequence: 0,
      cutOffSequence: 10,
      cutOffAt: DateTime(2026, 8, 31, 23, 59),
      createdAt: DateTime(2026, 9, 1, 8, 0),
      publishedAt: null,
      blockers: const [],
      productCount: productCount,
      changedCount: 0,
      totals: const CostTotals(
        closingValue: 0,
        cogsValue: 0,
        cogsAdjust: 0,
        valueAdjust: 0,
        balanceOk: true,
      ),
      alt: const CostAlt(
        method: CostMethod.moving,
        closingValue: 0,
        cogsValue: 0,
      ),
      lines: const [],
    );

CostRunRow _sampleRow(CostRunStatus status, {DateTime? publishedAt}) =>
    CostRunRow(
      runId: 'r1',
      code: 'GV-2608-01',
      kind: CostRunKind.periodClose,
      periodMonth: DateTime(2026, 8, 1),
      status: status,
      productCount: 12,
      blockerCount: 2,
      valueAdjustVnd: 20000,
      publishedAt: publishedAt,
      createdAt: DateTime(2026, 9, 1, 8, 0),
    );

CostRunLineView _sampleLine(String id, int lineAdjust) => CostRunLineView(
      productId: id,
      name: 'SP $id',
      code: id,
      uom: 'hộp',
      openingQty: 0,
      openingValue: 0,
      inboundQty: 10,
      inboundValue: 100000,
      rebateValue: 0,
      saleQty: 0,
      saleValueRecorded: 0,
      lossQty: 0,
      lossValueRecorded: 0,
      closingQty: 10,
      movingAvgEnd: 10000,
      cogsTrueUp: 0,
      lossTrueUp: 0,
      roundingAdjust: 0,
      closingValueAfter: 100000,
      lineAdjust: lineAdjust,
      balanceDiff: 0,
    );

void main() {
  test('signedMoney formats positive, negative with U+2212, and zero', () {
    expect(signedMoney(50400), '+50.400 đ');
    expect(signedMoney(-25000), '\u221225.000 đ');
    expect(signedMoney(0), '0 đ');
  });

  test('runTitle formats periodClose and midPeriod', () {
    expect(
      runTitle(CostRunKind.periodClose, DateTime(2026, 8, 1)),
      'Chốt kỳ 08/2026',
    );
    expect(
      runTitle(CostRunKind.midPeriod, DateTime(2026, 11, 1)),
      'Cập nhật giá vốn 11/2026',
    );
  });

  test('runSubtitle includes product count when > 0 and omits when 0', () {
    expect(
      runSubtitle(_sampleRun(productCount: 12)),
      '12 sản phẩm · Thời điểm chốt 31/08/2026 · 23:59',
    );
    expect(
      runSubtitle(_sampleRun(productCount: 0)),
      'Thời điểm chốt 31/08/2026 · 23:59',
    );
  });

  test('runStatus covers all 4 visible statuses', () {
    final ready = runStatus(_sampleRow(CostRunStatus.readyForReview));
    expect(ready.label, 'Sẵn sàng công bố');
    expect(ready.tone, CostStatusTone.success);
    expect(ready.subtitle, '12 sản phẩm · đã tính, chờ công bố');

    final pub = runStatus(
      _sampleRow(CostRunStatus.published, publishedAt: DateTime(2026, 9, 2)),
    );
    expect(pub.label, 'Đã công bố');
    expect(pub.tone, CostStatusTone.success);
    expect(pub.subtitle, 'Công bố 02/09/2026');

    final stale = runStatus(_sampleRow(CostRunStatus.stale));
    expect(stale.label, 'Cần tính lại');
    expect(stale.tone, CostStatusTone.warning);
    expect(stale.subtitle, '12 sản phẩm · dữ liệu đã đổi');

    final blocked = runStatus(_sampleRow(CostRunStatus.blocked));
    expect(blocked.label, 'Cần xử lý');
    expect(blocked.tone, CostStatusTone.warning);
    expect(blocked.subtitle, '2 việc cần xử lý');
  });

  test('blockerView covers all 6 blocker codes', () {
    final prev = blockerView(
      CostBlocker(
        code: 'PREVIOUS_PERIOD_OPEN',
        periodMonth: DateTime(2026, 10, 1),
      ),
    );
    expect(prev.title, 'Kỳ 10/2026 chưa chốt');
    expect(prev.actionLabel, 'Chốt kỳ 10/2026');
    expect(prev.action, CostBlockerAction.closePeriod);

    final notEnded = blockerView(
      CostBlocker(
        code: 'PERIOD_NOT_ENDED',
        periodMonth: DateTime(2026, 11, 1),
      ),
    );
    expect(notEnded.title, 'Tháng 11/2026 chưa kết thúc');
    expect(notEnded.actionLabel, 'Cập nhật giữa kỳ');
    expect(notEnded.action, CostBlockerAction.midPeriod);

    final stocktake = blockerView(const CostBlocker(code: 'STOCKTAKE_OPEN'));
    expect(stocktake.title, 'Có phiên kiểm kê chưa ghi nhận');
    expect(stocktake.actionLabel, 'Mở kiểm kê');
    expect(stocktake.action, CostBlockerAction.stocktakes);

    final pending = blockerView(const CostBlocker(code: 'RUN_PENDING_REVIEW'));
    expect(pending.title, 'Đã có lần tính chờ công bố');
    expect(pending.actionLabel, 'Mở lần tính');
    expect(pending.action, CostBlockerAction.openPendingRun);

    final mismatch = blockerView(
      const CostBlocker(code: 'LEDGER_MISMATCH', productCount: 3),
    );
    expect(
      mismatch.title,
      'Sổ số lượng và sổ giá trị không khớp (3 sản phẩm)',
    );
    expect(mismatch.detail, 'Liên hệ hỗ trợ; không tự sửa.');
    expect(mismatch.actionLabel, isNull);
    expect(mismatch.action, CostBlockerAction.none);

    final nothing = blockerView(const CostBlocker(code: 'NOTHING_TO_COST'));
    expect(nothing.title, 'Không có biến động mới từ lần công bố trước');
    expect(nothing.action, CostBlockerAction.none);
  });

  test('topChanged filters out zero lineAdjust and limits to n', () {
    final lines = [
      _sampleLine('1', -20000),
      _sampleLine('2', 0),
      _sampleLine('3', 5000),
      _sampleLine('4', -1000),
    ];
    final top = topChanged(lines, 2);
    expect(top.map((e) => e.productId).toList(), ['1', '3']);
  });

  test('inventoryErrorMessage maps 3 costing error codes', () {
    expect(
      inventoryErrorMessage(
        const AppException(InventoryErrorCode.costRunStale),
        fallback: 'err',
      ),
      'Dữ liệu đầu vào đã thay đổi. Hãy tạo lần tính kế tiếp.',
    );
    expect(
      inventoryErrorMessage(
        const AppException(InventoryErrorCode.costRunNotReady),
        fallback: 'err',
      ),
      'Lần tính không còn ở trạng thái chờ công bố.',
    );
    expect(
      inventoryErrorMessage(
        const AppException(InventoryErrorCode.costPolicyLocked),
        fallback: 'err',
      ),
      'Đã công bố giá vốn nên không đổi được phương pháp.',
    );
  });
}
