import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/core/inventory_command_result.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_router_harness.dart';

class _FlowStocktakeRepository extends Fake implements StocktakeRepository {
  final Map<String, StocktakeSession> _sessions = {};
  final Map<String, Map<String, num>> _bookBySession = {};
  int _seq = 1;

  void seedSession(
    StocktakeSession session, {
    Map<String, num> bookQuantities = const {},
  }) {
    _sessions[session.id] = session;
    if (bookQuantities.isNotEmpty) {
      _bookBySession[session.id] = Map<String, num>.from(bookQuantities);
    }
  }

  @override
  Future<List<StocktakeListRow>> list() async {
    return _sessions.values
        .map((s) {
          final countedCount = s.status == StocktakeStatus.counting
              ? s.lines.where((l) => l.draftQty != null).length
              : s.lines.length;
          final varianceCount = s.lines.where((l) => l.needsRecount).length;
          return StocktakeListRow(
            id: s.id,
            code: s.code,
            scopeLabel: s.scopeLabel,
            counterName: s.counterName,
            status: s.status,
            openedAt: s.openedAt,
            lineCount: s.lines.length,
            countedCount: countedCount,
            varianceCount: varianceCount,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<StocktakeFormOptions> formOptions() async => const StocktakeFormOptions(
    allCount: 2,
    products: [
      StocktakeProductOption(
        id: 'p-oxy',
        name: 'Oxytetracycline LA',
        code: 'SP-000147',
        uom: 'chai',
        lineCount: 1,
      ),
      StocktakeProductOption(
        id: 'p-ty',
        name: 'Tylosin 20%',
        code: 'SP-000122',
        uom: 'lọ',
        lineCount: 1,
      ),
    ],
    lots: [],
    members: [
      StocktakeMember(userId: 'u1', name: 'Nguyễn Văn An'),
    ],
    me: 'u1',
  );

  @override
  Future<OpenStocktakeResult> open({
    required String idempotencyKey,
    required StocktakeScopeKind kind,
    String? productId,
    String? lotId,
    required String counterUserId,
    required String reason,
  }) async {
    final id = 'st-${_seq++}';
    final code = 'KK-261112-0${_seq - 1}';
    const lines = [
      StocktakeLine(
        lineId: 'line-oxy',
        productId: 'p-oxy',
        productName: 'Oxytetracycline LA',
        productCode: 'SP-000147',
        isExpired: false,
        uom: 'chai',
        isUnexpected: false,
        needsRecount: false,
      ),
      StocktakeLine(
        lineId: 'line-ty',
        productId: 'p-ty',
        productName: 'Tylosin 20%',
        productCode: 'SP-000122',
        isExpired: false,
        uom: 'lọ',
        isUnexpected: false,
        needsRecount: false,
      ),
    ];
    _bookBySession[id] = {'line-oxy': 12, 'line-ty': 5};
    _sessions[id] = StocktakeSession(
      id: id,
      code: code,
      scopeKind: kind,
      scopeLabel: 'Toàn kho',
      counterName: 'Nguyễn Văn An',
      reason: reason,
      status: StocktakeStatus.counting,
      openedAt: DateTime(2026, 11, 12, 18, 30),
      lines: lines,
    );
    return OpenStocktakeResult(sessionId: id, code: code);
  }

  @override
  Future<StocktakeSession> get(String sessionId) async => _sessions[sessionId]!;

  @override
  Future<void> saveDraft({
    required String sessionId,
    required String lineId,
    num? quantity,
  }) async {
    final current = _sessions[sessionId];
    if (current == null) return;
    final updatedLines = current.lines
        .map(
          (l) => l.lineId == lineId
              ? StocktakeLine(
                  lineId: l.lineId,
                  productId: l.productId,
                  productName: l.productName,
                  productCode: l.productCode,
                  lotId: l.lotId,
                  lotCode: l.lotCode,
                  expiryDate: l.expiryDate,
                  isExpired: l.isExpired,
                  uom: l.uom,
                  isUnexpected: l.isUnexpected,
                  draftQty: quantity,
                  needsRecount: l.needsRecount,
                  lossReason: l.lossReason,
                  firstQty: l.firstQty,
                  recountQty: l.recountQty,
                  bookQty: l.bookQty,
                  variance: l.variance,
                  adjustQty: l.adjustQty,
                  adjustValueVnd: l.adjustValueVnd,
                )
              : l,
        )
        .toList(growable: false);
    _sessions[sessionId] = StocktakeSession(
      id: current.id,
      code: current.code,
      scopeKind: current.scopeKind,
      scopeLabel: current.scopeLabel,
      counterName: current.counterName,
      reason: current.reason,
      status: current.status,
      resultKind: current.resultKind,
      openedAt: current.openedAt,
      lines: updatedLines,
    );
  }

  @override
  Future<StocktakeSubmitResult> submitFirst({
    required String idempotencyKey,
    required String sessionId,
    required List<StocktakeCountInput> counts,
  }) async {
    final current = _sessions[sessionId]!;
    final books = _bookBySession[sessionId]!;
    final countById = {for (final c in counts) c.lineId: c.quantity};
    final updatedLines = current.lines.map((l) {
      final firstQty = countById[l.lineId]!;
      final book = books[l.lineId]!;
      final variance = firstQty - book;
      return StocktakeLine(
        lineId: l.lineId,
        productId: l.productId,
        productName: l.productName,
        productCode: l.productCode,
        lotId: l.lotId,
        lotCode: l.lotCode,
        expiryDate: l.expiryDate,
        isExpired: l.isExpired,
        uom: l.uom,
        isUnexpected: l.isUnexpected,
        needsRecount: variance != 0,
        firstQty: firstQty,
        bookQty: book,
        variance: variance,
      );
    }).toList(growable: false);

    final hasVariance = updatedLines.any((l) => l.needsRecount);
    final nextStatus =
        hasVariance ? StocktakeStatus.recount : StocktakeStatus.completed;
    _sessions[sessionId] = StocktakeSession(
      id: current.id,
      code: current.code,
      scopeKind: current.scopeKind,
      scopeLabel: current.scopeLabel,
      counterName: current.counterName,
      reason: current.reason,
      status: nextStatus,
      resultKind: hasVariance ? null : StocktakeResultKind.matched,
      openedAt: current.openedAt,
      firstSubmittedAt: DateTime(2026, 11, 12, 19, 0),
      completedAt: hasVariance ? null : DateTime(2026, 11, 12, 19, 0),
      lines: updatedLines,
    );
    return StocktakeSubmitResult(
      status: nextStatus,
      resultKind: hasVariance ? null : StocktakeResultKind.matched,
    );
  }

  @override
  Future<StocktakeSubmitResult> submitRecount({
    required String idempotencyKey,
    required String sessionId,
    required List<StocktakeCountInput> counts,
  }) async {
    final current = _sessions[sessionId]!;
    final countById = {for (final c in counts) c.lineId: c};
    final stockChanges = <InventoryStockChange>[];
    final updatedLines = current.lines.map((l) {
      final input = countById[l.lineId];
      if (input == null) {
        return l;
      }
      final book = l.bookQty!;
      final delta = input.quantity - book;
      if (delta != 0) {
        stockChanges.add(
          InventoryStockChange(
            productId: l.productId,
            productName: l.productName,
            baseUom: l.uom,
            before: book,
            after: input.quantity,
          ),
        );
      }
      return StocktakeLine(
        lineId: l.lineId,
        productId: l.productId,
        productName: l.productName,
        productCode: l.productCode,
        lotId: l.lotId,
        lotCode: l.lotCode,
        expiryDate: l.expiryDate,
        isExpired: l.isExpired,
        uom: l.uom,
        isUnexpected: l.isUnexpected,
        needsRecount: l.needsRecount,
        lossReason: delta < 0
            ? (input.lossReason ?? StocktakeLossReason.loss)
            : null,
        firstQty: l.firstQty,
        recountQty: input.quantity,
        bookQty: book,
        variance: delta,
        adjustQty: delta,
      );
    }).toList(growable: false);

    final adjusted = stockChanges.isNotEmpty;
    final resultKind = adjusted
        ? StocktakeResultKind.adjusted
        : StocktakeResultKind.matched;
    _sessions[sessionId] = StocktakeSession(
      id: current.id,
      code: current.code,
      scopeKind: current.scopeKind,
      scopeLabel: current.scopeLabel,
      counterName: current.counterName,
      reason: current.reason,
      status: StocktakeStatus.completed,
      resultKind: resultKind,
      openedAt: current.openedAt,
      firstSubmittedAt: current.firstSubmittedAt,
      completedAt: DateTime(2026, 11, 12, 20, 10),
      completedByName: 'Chủ cửa hàng',
      adjustmentValueVnd: adjusted ? -110000 : null,
      stockChanges: stockChanges,
      lines: updatedLines,
    );
    return StocktakeSubmitResult(
      status: StocktakeStatus.completed,
      resultKind: resultKind,
    );
  }
}

void main() {
  late _FlowStocktakeRepository repo;

  setUp(() async {
    await setUpInventoryRouterTest();
    repo = _FlowStocktakeRepository();
    if (getIt.isRegistered<StocktakeRepository>()) {
      getIt.unregister<StocktakeRepository>();
    }
    getIt.registerSingleton<StocktakeRepository>(repo);
  });

  tearDown(tearDownInventoryRouterTest);

  testWidgets(
    'stocktake_flow_test traverses Hub -> 042 -> 043 -> 044 -> 045 -> 047 -> 042',
    (tester) async {
      await pumpInventoryApp(tester, location: '/warehouse');

      await tester.tap(find.text('Kiểm kê'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có phiên kiểm kê'), findsOneWidget);

      await tester.tap(find.widgetWithText(VButton, 'Tạo phiên kiểm kê'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Mở phiên kiểm kê'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Mở phiên'));
      await tester.pumpAndSettle();

      // 044 Đếm mù: 2 dòng (Oxy lệch 10 vs 12, Tylosin khớp 5 vs 5)
      expect(find.text('Đếm mù'), findsOneWidget);
      final cells = find.descendant(
        of: find.byType(K7EditCell),
        matching: find.byType(TextField),
      );
      await tester.enterText(cells.at(0), '10');
      await tester.pump();
      await tester.enterText(cells.at(1), '5');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả đếm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả'));
      await tester.pumpAndSettle();

      // 045 Chênh lệch và đếm lại
      expect(find.text('Chênh lệch và đếm lại'), findsOneWidget);
      await tester.tap(find.widgetWithText(VButton, 'Vẫn 10 chai'));
      await tester.pump();

      await tester.tap(find.widgetWithText(VButton, 'Ghi nhận điều chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Ghi nhận'));
      await tester.pumpAndSettle();

      // 047 Kết quả kiểm kê
      expect(find.text('Đã hoàn tất kiểm kê'), findsOneWidget);
      final backToListBtn = find.widgetWithText(VButton, 'Về kiểm kê');
      await tester.ensureVisible(backToListBtn);
      await tester.tap(backToListBtn);
      await tester.pumpAndSettle();

      // 042 có phiên 'Đã xong'
      expect(find.text('Kiểm kê kho'), findsOneWidget);
      expect(find.text('KK-261112-01'), findsOneWidget);
      expect(find.text('Đã xong'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'deep_link_wrong_step redirects /count to /recount when session status is RECOUNT',
    (tester) async {
      repo.seedSession(
        StocktakeSession(
          id: 's1',
          code: 'KK-261112-99',
          scopeKind: StocktakeScopeKind.all,
          scopeLabel: 'Toàn kho',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.recount,
          openedAt: DateTime(2026, 11, 12, 18, 30),
          lines: const [
            StocktakeLine(
              lineId: 'l1',
              productId: 'p1',
              productName: 'Oxytetracycline LA',
              productCode: 'SP-000147',
              isExpired: false,
              uom: 'chai',
              isUnexpected: false,
              needsRecount: true,
              bookQty: 12,
              firstQty: 10,
              variance: -2,
            ),
          ],
        ),
      );

      await pumpInventoryApp(tester, location: '/warehouse/stocktakes/s1/count');

      expect(find.text('Chênh lệch và đếm lại'), findsOneWidget);
      expect(find.text('Thiếu 2 chai'), findsOneWidget);
    },
  );
}

