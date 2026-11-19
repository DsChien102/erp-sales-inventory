import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/presentation/pages/customer_receivable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_receivable_repository.dart';
import '../support/receivable_fixtures.dart' as fx;
import 'receivable_test_harness.dart';

CustomerReceivableDetail _detail({
  required List<OpenReceivableOrder> orders,
  ReceivableCustomer customer = fx.tuanCustomer,
  int? overdue,
}) => CustomerReceivableDetail(
  customer: customer,
  outstandingMinor: orders.fold(0, (s, o) => s + o.outstandingMinor),
  openOrderCount: orders.length,
  overdueOrderCount: overdue ?? orders.where((o) => o.overdueDays > 0).length,
  maxOverdueDays: orders.fold(0, (m, o) => o.overdueDays > m ? o.overdueDays : m),
  openOrders: orders,
);

void main() {
  setUpAll(loadInterFont);

  late FakeReceivableRepository repo;

  setUp(() => repo = FakeReceivableRepository());

  Future<RouteLog> open(WidgetTester tester, {bool canCollect = true}) async {
    final log = RouteLog();
    await pumpReceivable(
      tester,
      CustomerReceivableDetailPage(
        customerId: fx.tuanId,
        repository: repo,
        today: fx.today,
        canCollect: canCollect,
      ),
      log: log,
    );
    return log;
  }

  testWidgets('full: đầu trang, đơn, lịch sử, nút Thu tiền', (tester) async {
    await open(tester);
    for (final t in [
      'Anh Tuấn',
      '0901 234 567',
      'Còn nợ',
      '18.000.000 ₫',
      '3 đơn ·',
      '2 quá hạn',
      'DH-001 · 01/11',
      'Còn nợ 4.000.000 ₫',
      'Tổng 4.000.000 ₫',
      'Quá hạn 8 ngày',
      'Thu 2.000.000 · Tiền mặt',
      '06/11 14:20 · Nguyễn An',
      'Vào: DH-002 2.000.000',
      'Thu tiền',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  testWidgets('after-offset: dòng cấn trừ, đơn DH-001 hết khỏi khối đơn', (tester) async {
    repo
      ..enqueueCustomer(
        _detail(orders: [
          OpenReceivableOrder(
            salesOrderId: 'so-002',
            orderCode: 'DH-002',
            completedAt: DateTime(2026, 11, 5),
            payableMinor: 10000000,
            outstandingMinor: 1500000,
            dueDate: DateTime(2026, 11, 15),
            overdueDays: 3,
            settlementVersion: 2,
          ),
          fx.tuanOrders[2],
        ]),
      )
      ..enqueueHistory(
        ReceivableHistoryPage(
          nextCursor: null,
          items: [
            ReceivableHistoryItem(
              kind: ReceivableHistoryKind.offset,
              occurredAt: DateTime(2026, 11, 18, 9, 5),
              amountMinor: 500000,
              actorDisplayName: 'Nguyễn An',
              sourceOrderCode: 'DH-001',
              targetOrderCode: 'DH-002',
              returnExchangeReference: '#DT-0001',
            ),
          ],
        ),
      );
    await open(tester);
    expect(
      find.text('Cấn trừ 500.000 · từ trả hàng đơn DH-001 (phiếu #DT-0001) sang đơn DH-002'),
      findsOneWidget,
    );
    expect(find.textContaining('DH-001 ·'), findsNothing);
    expect(find.text('7.500.000 ₫'), findsOneWidget);
  });

  testWidgets('paid-off: không còn nợ, ẩn nút Thu tiền', (tester) async {
    repo.enqueueCustomer(_detail(orders: const []));
    await open(tester);
    expect(find.text('Không còn nợ'), findsOneWidget);
    expect(find.text('Không còn đơn nào nợ'), findsOneWidget);
    expect(find.text('Thu tiền'), findsNothing);
  });

  testWidgets('block-error: chỉ khối lịch sử lỗi, Thử lại gọi history lần 2', (tester) async {
    repo.enqueueHistory(const AppException(AppErrorCode.network));
    await open(tester);
    expect(find.text('DH-002 · 05/11'), findsOneWidget);
    expect(find.text('Không tải được'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.historyCalls, hasLength(2));
    expect(find.text('Không tải được'), findsNothing);
  });

  testWidgets('chi tiết lỗi: cả trang lỗi + Thử lại', (tester) async {
    repo.enqueueCustomer(const AppException(AppErrorCode.network));
    await open(tester);
    expect(find.text('Không tải được công nợ'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Anh Tuấn'), findsOneWidget);
  });

  testWidgets('no-history', (tester) async {
    repo.enqueueHistory(const ReceivableHistoryPage(items: [], nextCursor: null));
    await open(tester);
    expect(find.text('Chưa có lần thu nào'), findsOneWidget);
  });

  testWidgets('inactive', (tester) async {
    repo.enqueueCustomer(
      _detail(
        orders: [fx.tuanOrders[2]],
        customer: const ReceivableCustomer(
          customerId: fx.tuanId,
          displayName: 'Cô Hoa',
          phone: null,
          isActive: false,
        ),
      ),
    );
    await open(tester);
    expect(find.text('Ngừng hoạt động'), findsOneWidget);
  });

  testWidgets('chạm dòng DH-002 → /sales/orders/so-002', (tester) async {
    final log = await open(tester);
    await tester.tap(find.text('DH-002 · 05/11'));
    await tester.pumpAndSettle();
    expect(log.locations, contains('/sales/orders/so-002'));
  });

  testWidgets('thiếu quyền receivable.collect → không có nút Thu tiền', (tester) async {
    await open(tester, canCollect: false);
    expect(find.text('Thu tiền'), findsNothing);
  });

  testWidgets('Xem thêm khi còn cursor', (tester) async {
    repo.enqueueHistory(ReceivableHistoryPage(items: fx.tuanHistoryBefore, nextCursor: 'h1'));
    await open(tester);
    expect(find.text('Xem thêm'), findsOneWidget);
    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();
    expect(repo.historyCalls.last.cursor, 'h1');
  });
}
