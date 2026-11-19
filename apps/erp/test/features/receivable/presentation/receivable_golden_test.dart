import 'dart:async';

import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/logic/receivable_list_cubit.dart';
import 'package:erp/features/receivable/presentation/pages/customer_receivable_page.dart';
import 'package:erp/features/receivable/presentation/pages/receivable_list_page.dart';
import 'package:erp/features/receivable/presentation/receivable_area_shell.dart';
import 'package:erp/features/receivable/presentation/widgets/receivable_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../inventory/support/inventory_test_surface.dart';
import '../support/fake_receivable_repository.dart';
import '../support/receivable_fixtures.dart' as fx;
import 'receivable_test_harness.dart';

String _goldenPath(String name) =>
    '${repoRoot()}/docs/refactor/plans/T6/img/T6-2b/$name.png';

CustomerReceivableRow _row(
  String id,
  String name,
  String? phone,
  int total,
  int orders, {
  int overdueOrders = 0,
  int overdueAmount = 0,
  int maxOverdue = 0,
  String? next,
  bool active = true,
}) => CustomerReceivableRow(
  customerId: id,
  displayName: name,
  phone: phone,
  isActive: active,
  outstandingMinor: total,
  openOrderCount: orders,
  overdueOrderCount: overdueOrders,
  overdueAmountMinor: overdueAmount,
  maxOverdueDays: maxOverdue,
  nextDueDate: next == null ? null : DateTime.parse(next),
);

ReceivableSummary _sum(int total, int n, int overN, int overAmt, int maxDays) => ReceivableSummary(
  totalOutstandingMinor: total,
  customerCount: n,
  overdueCustomerCount: overN,
  overdueAmountMinor: overAmt,
  maxOverdueDays: maxDays,
);

/// 8 khách (`richCustomers` của prototype), thứ tự mức khẩn của server.
final _many = CustomerReceivablePage(
  summary: _sum(53250000, 8, 4, 21450000, 21),
  nextCursor: null,
  items: [
    _row('c-binh', 'Anh Bình', '0905 118 227', 850000, 1,
        overdueOrders: 1, overdueAmount: 850000, maxOverdue: 21, next: '2026-10-28'),
    fx.rowsBefore[0],
    _row('c-khoa', 'Phòng khám thú y Đồng Xuân – Chi nhánh 2', '0283 555 0142', 7400000, 2,
        overdueOrders: 1, overdueAmount: 5400000, maxOverdue: 6, next: '2026-12-02'),
    _row('c-mai', 'Chị Mai', '0908 765 432', 3200000, 1,
        overdueOrders: 1, overdueAmount: 3200000, maxOverdue: 3, next: '2026-11-15'),
    fx.rowsBefore[1],
    fx.rowsBefore[2],
    _row('c-chau', 'Cửa hàng Minh Châu', '0912 004 880', 14200000, 1, next: '2026-11-28'),
    _row('c-nam', 'Anh Nam', '0977 222 111', 1100000, 1),
  ],
);

final _long = CustomerReceivablePage(
  summary: _sum(1262567890, 5, 1, 12000000, 8),
  nextCursor: null,
  items: [
    fx.rowsBefore[0],
    fx.rowsBefore[1],
    fx.rowsBefore[2],
    _row('c-long', 'Công ty TNHH Thuốc Thú Y và Vật Tư Chăn Nuôi Đồng Bằng Sông Cửu Long', null,
        1234567890, 1, next: '2026-11-30'),
    _row('c-hoa', 'Cô Hoa', '0933 111 222', 1500000, 1, next: '2026-11-30', active: false),
  ],
);

final _noOverdue = CustomerReceivablePage(
  summary: _sum(8500000, 2, 0, 0, 0),
  nextCursor: null,
  items: [fx.rowsBefore[1], fx.rowsBefore[2]],
);

final _overdueOnly = CustomerReceivablePage(
  summary: fx.summaryBefore,
  nextCursor: null,
  items: [fx.rowsBefore[0]],
);

const _emptySummary = ReceivableSummary(
  totalOutstandingMinor: 0,
  customerCount: 0,
  overdueCustomerCount: 0,
  overdueAmountMinor: 0,
  maxOverdueDays: 0,
);

Future<void> capture(
  WidgetTester tester, {
  required Size size,
  required Widget page,
  required String name,
}) async {
  useInventoryTestSurface(size);
  final key = GlobalKey();
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => page)]);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => RepaintBoundary(key: key, child: child!),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
  await expectLater(find.byKey(key), matchesGoldenFile(_goldenPath(name)));
}

Widget _cn01Page(ReceivableListCubit cubit, Size size) {
  if (size.width < 840) return ReceivableListPage(cubit: cubit, today: fx.today);
  return ReceivableAreaShell(
    cubit: cubit,
    child: const ReceivablePickPlaceholder(),
  );
}

void main() {
  setUpAll(loadInterFont);

  group('CN-01', () {
    Future<void> run(
      WidgetTester tester,
      String state,
      Size size,
      Future<void> Function(FakeReceivableRepository repo, ReceivableListCubit cubit) arrange,
    ) async {
      final repo = FakeReceivableRepository();
      final cubit = ReceivableListCubit(repository: repo);
      addTearDown(cubit.close);
      await tester.runAsync(() => arrange(repo, cubit));
      await capture(
        tester,
        size: size,
        page: _cn01Page(cubit, size),
        name: 'flutter-CN-01-$state-${size.width.toInt()}',
      );
    }

    final cases = <String, Future<void> Function(FakeReceivableRepository, ReceivableListCubit)>{
      'all': (r, c) => c.load(),
      'many': (r, c) {
        r.enqueueList(_many);
        return c.load();
      },
      'no-overdue': (r, c) {
        r.enqueueList(_noOverdue);
        return c.load();
      },
      'overdue': (r, c) async {
        await c.load();
        r.enqueueList(_overdueOnly);
        c.toggleOverdue();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      'search-empty': (r, c) async {
        await c.load();
        r.enqueueList(CustomerReceivablePage(summary: fx.summaryBefore, items: const [], nextCursor: null));
        c.setQuery('xyz');
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      'empty': (r, c) {
        r.enqueueList(const CustomerReceivablePage(summary: _emptySummary, items: [], nextCursor: null));
        return c.load();
      },
      'error': (r, c) {
        r.enqueueList(Exception('x'));
        return c.load();
      },
      'loading': (r, c) async {
        r.enqueueList(Completer<CustomerReceivablePage>());
        unawaited(c.load());
      },
      'loading-more': (r, c) async {
        r.enqueueList(CustomerReceivablePage(summary: _many.summary, items: _many.items, nextCursor: 'c'));
        await c.load();
        r.enqueueList(Completer<CustomerReceivablePage>());
        unawaited(c.loadMore());
      },
      'long': (r, c) {
        r.enqueueList(_long);
        return c.load();
      },
    };

    for (final entry in cases.entries) {
      for (final size in [phone, web]) {
        testWidgets('${entry.key} ${size.width.toInt()}', (tester) async {
          await run(tester, entry.key, size, entry.value);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('CN-02', () {
    OpenReceivableOrder order(String code, String done, int payable, int owed, String due, int days) =>
        OpenReceivableOrder(
          salesOrderId: 'so-$code',
          orderCode: code,
          completedAt: DateTime.parse(done),
          payableMinor: payable,
          outstandingMinor: owed,
          dueDate: DateTime.parse(due),
          overdueDays: days,
          settlementVersion: 1,
        );
    CustomerReceivableDetail detail(
      ReceivableCustomer c,
      List<OpenReceivableOrder> orders,
    ) => CustomerReceivableDetail(
      customer: c,
      outstandingMinor: orders.fold(0, (s, o) => s + o.outstandingMinor),
      openOrderCount: orders.length,
      overdueOrderCount: orders.where((o) => o.overdueDays > 0).length,
      maxOverdueDays: orders.fold(0, (m, o) => o.overdueDays > m ? o.overdueDays : m),
      openOrders: orders,
    );
    ReceivableHistoryItem collect(DateTime at, int amount, List<(String, int)> alloc) => ReceivableHistoryItem(
      kind: ReceivableHistoryKind.customerCollection,
      occurredAt: at,
      amountMinor: amount,
      paymentMethodCode: 'cash',
      actorDisplayName: 'Nguyễn An',
      allocations: [for (final a in alloc) HistoryAllocation(orderCode: a.$1, amountMinor: a.$2)],
    );
    final c2 = collect(DateTime(2026, 11, 6, 14, 20), 2000000, [('DH-002', 2000000)]);
    final c10 = collect(DateTime(2026, 11, 18, 9, 30), 10000000, [('DH-001', 4000000), ('DH-002', 6000000)]);
    final c18 = collect(
      DateTime(2026, 11, 18, 9, 30),
      18000000,
      [('DH-001', 4000000), ('DH-002', 8000000), ('DH-003', 6000000)],
    );
    final o500 = ReceivableHistoryItem(
      kind: ReceivableHistoryKind.offset,
      occurredAt: DateTime(2026, 11, 18, 10, 15),
      amountMinor: 500000,
      actorDisplayName: 'Nguyễn An',
      sourceOrderCode: 'DH-001',
      targetOrderCode: 'DH-002',
      returnExchangeReference: '#DT-0001',
    );
    final dh1 = order('DH-001', '2026-11-01T09:00:00', 4000000, 4000000, '2026-11-10', 8);
    final dh3 = order('DH-003', '2026-11-12T09:00:00', 6000000, 6000000, '2026-11-30', 0);
    ReceivableHistoryPage page(List<ReceivableHistoryItem> i) => ReceivableHistoryPage(items: i, nextCursor: null);
    const hoa = ReceivableCustomer(
      customerId: 'c-hoa',
      displayName: 'Cô Hoa',
      phone: '0933 111 222',
      isActive: false,
    );
    const lan = ReceivableCustomer(
      customerId: fx.lanId,
      displayName: 'Chị Lan',
      phone: '0912 345 678',
      isActive: true,
    );

    final cases = <String, (CustomerReceivableDetail, Object, String)>{
      'full': (fx.tuanDetail, page([c2]), fx.tuanId),
      'after-offset': (
        detail(fx.tuanCustomer, [order('DH-002', '2026-11-05T09:00:00', 10000000, 1500000, '2026-11-15', 3), dh3]),
        page([o500, c10, c2]),
        fx.tuanId,
      ),
      'block-error': (fx.tuanDetail, Exception('x'), fx.tuanId),
      'paid-off': (detail(fx.tuanCustomer, const []), page([c18, c2]), fx.tuanId),
      'inactive': (
        detail(hoa, [order('DH-030', '2026-11-12T09:00:00', 2000000, 1500000, '2026-11-30', 0)]),
        page([
          ReceivableHistoryItem(
            kind: ReceivableHistoryKind.orderCollection,
            occurredAt: DateTime(2026, 11, 12, 9, 10),
            amountMinor: 500000,
            orderCode: 'DH-030',
          ),
          ReceivableHistoryItem(
            kind: ReceivableHistoryKind.refund,
            occurredAt: DateTime(2026, 11, 3, 16),
            amountMinor: 200000,
            orderCode: 'DH-029',
          ),
        ]),
        'c-hoa',
      ),
      'no-history': (
        detail(lan, [order('DH-020', '2026-11-10T09:00:00', 6000000, 6000000, '2026-11-25', 0)]),
        page(const []),
        fx.lanId,
      ),
    };

    for (final entry in cases.entries) {
      for (final size in [phone, web]) {
        testWidgets('${entry.key} ${size.width.toInt()}', (tester) async {
          final (detailData, historyData, id) = entry.value;
          final repo = FakeReceivableRepository()
            ..enqueueCustomer(detailData)
            ..enqueueHistory(historyData);
          final cubit = ReceivableListCubit(repository: repo);
          addTearDown(cubit.close);
          await tester.runAsync(cubit.load);
          final detailPage = CustomerReceivableDetailPage(
            key: ValueKey(id),
            customerId: id,
            repository: repo,
            today: fx.today,
            canCollect: true,
          );
          await capture(
            tester,
            size: size,
            page: size.width < 840
                ? detailPage
                : ReceivableAreaShell(cubit: cubit, selectedId: id, child: detailPage),
            name: 'flutter-CN-02-${entry.key}-${size.width.toInt()}',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
