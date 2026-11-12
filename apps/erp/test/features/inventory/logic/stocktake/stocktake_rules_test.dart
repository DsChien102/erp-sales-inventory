import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('stocktake_rules', () {
    test('parse_count parses valid numbers and rejects invalid/negative', () {
      expect(parseStocktakeCount('8'), 8);
      expect(parseStocktakeCount('2,5'), 2.5);
      expect(parseStocktakeCount(' 0 '), 0);
      expect(parseStocktakeCount(''), isNull);
      expect(parseStocktakeCount('   '), isNull);
      expect(parseStocktakeCount('-1'), isNull);
      expect(parseStocktakeCount('abc'), isNull);
      expect(parseStocktakeCount('NaN'), isNull);
      expect(parseStocktakeCount('Infinity'), isNull);
    });

    test('blockers return Vietnamese blocker text when missing > 0', () {
      expect(firstCountBlocker(3), 'Còn 3 mặt hàng chưa đếm');
      expect(firstCountBlocker(0), isNull);
      expect(recountBlocker(2), 'Còn 2 mặt hàng chưa đếm lại');
      expect(recountBlocker(0), isNull);
    });

    test('variance_label formats Thiếu / Thừa with stock quantity', () {
      expect(varianceLabel(-2, 'chai'), 'Thiếu 2 chai');
      expect(varianceLabel(1, 'lọ'), 'Thừa 1 lọ');
      expect(varianceLabel(-1.5, 'hộp'), 'Thiếu 1,5 hộp');
    });

    test('default_loss_reason chooses expired when line isExpired else loss', () {
      const normalLine = StocktakeLine(
        lineId: 'l1',
        productId: 'p1',
        productName: 'Oxytetracycline',
        productCode: 'OXY-01',
        isExpired: false,
        uom: 'chai',
        isUnexpected: false,
        needsRecount: true,
      );
      const expiredLine = StocktakeLine(
        lineId: 'l2',
        productId: 'p2',
        productName: 'Tylosin',
        productCode: 'TYL-01',
        lotId: 'lot1',
        lotCode: 'TY2408',
        isExpired: true,
        uom: 'lọ',
        isUnexpected: false,
        needsRecount: true,
      );

      expect(defaultLossReason(normalLine), StocktakeLossReason.loss);
      expect(defaultLossReason(expiredLine), StocktakeLossReason.expired);
    });

    test('list_subtitle and stocktakeStatusBadge match SCR-042 contract', () {
      final countingRow = StocktakeListRow(
        id: 's1',
        code: 'KK-261112-01',
        scopeLabel: 'Toàn kho',
        counterName: 'An',
        status: StocktakeStatus.counting,
        openedAt: DateTime(2026, 11, 12, 18, 30),
        lineCount: 9,
        countedCount: 4,
        varianceCount: 0,
      );
      final recountRow = StocktakeListRow(
        id: 's2',
        code: 'KK-261112-02',
        scopeLabel: 'Toàn kho',
        counterName: 'An',
        status: StocktakeStatus.recount,
        openedAt: DateTime(2026, 11, 12, 19, 0),
        lineCount: 9,
        countedCount: 9,
        varianceCount: 2,
      );

      expect(stocktakeListSubtitle(countingRow), 'Toàn kho · An · Đã đếm 4/9');
      expect(stocktakeListSubtitle(recountRow), 'Toàn kho · An · 2 mặt hàng lệch');
      expect(stocktakeStatusBadge(StocktakeStatus.counting), ('Đang đếm', VComponentTone.info));
      expect(stocktakeStatusBadge(StocktakeStatus.recount), ('Đếm lại', VComponentTone.warning));
      expect(stocktakeStatusBadge(StocktakeStatus.completed), ('Đã xong', VComponentTone.success));
      expect(stocktakeStatusBadge(StocktakeStatus.cancelled), ('Đã hủy', VComponentTone.neutral));
    });

    test('route_for covers all 3 status branches', () {
      expect(stocktakeRouteFor('s1', StocktakeStatus.counting), '/warehouse/stocktakes/s1/count');
      expect(stocktakeRouteFor('s1', StocktakeStatus.recount), '/warehouse/stocktakes/s1/recount');
      expect(stocktakeRouteFor('s1', StocktakeStatus.completed), '/warehouse/stocktakes/s1/result');
      expect(stocktakeRouteFor('s1', StocktakeStatus.cancelled), '/warehouse/stocktakes/s1/result');
    });

    test('stocktakeLineSub uses NBSP inside segments', () {
      const noLot = StocktakeLine(
        lineId: 'l1',
        productId: 'p1',
        productName: 'Oxy',
        productCode: 'OXY-01',
        isExpired: false,
        uom: 'chai',
        isUnexpected: false,
        needsRecount: false,
      );
      expect(
        stocktakeLineSub(noLot),
        'OXY-01 · Không\u00a0theo\u00a0lô · Bán\u00a0được',
      );
    });
  });
}

