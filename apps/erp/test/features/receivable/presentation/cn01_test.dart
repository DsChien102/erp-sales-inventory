import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/more/presentation/more_entries.dart';
import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/logic/receivable_list_cubit.dart';
import 'package:erp/features/receivable/presentation/pages/receivable_list_page.dart';
import 'package:erp/features/receivable/presentation/receivable_area_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_receivable_repository.dart';
import '../support/receivable_fixtures.dart' as fx;
import 'receivable_test_harness.dart';

CustomerReceivablePage _page({
  ReceivableSummary? summary,
  List<CustomerReceivableRow>? items,
}) => CustomerReceivablePage(
  summary: summary ?? fx.summaryBefore,
  items: items ?? fx.rowsBefore,
  nextCursor: null,
);

void main() {
  setUpAll(loadInterFont);

  late FakeReceivableRepository repo;
  late ReceivableListCubit cubit;

  setUp(() {
    repo = FakeReceivableRepository();
    cubit = ReceivableListCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester, {Size size = phone}) async {
    await cubit.load();
    await pumpReceivable(
      tester,
      ReceivableListPage(cubit: cubit, today: fx.today),
      size: size,
    );
  }

  testWidgets('all: hero, tổng, dòng khách', (tester) async {
    await open(tester);
    for (final t in [
      'Quá hạn',
      '12.000.000 ₫',
      '1 khách · lâu nhất 8 ngày',
      'Tổng còn phải thu',
      '26.500.000 ₫',
      '3 khách',
      'Anh Tuấn',
      '0901 234 567 · 3 đơn',
      'Quá hạn 8 ngày',
      'Đến hạn hôm nay',
      'Hẹn 25/11',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text('0987 654 321 · 2 đơn'), findsOneWidget);
  });

  testWidgets('chạm hero → lọc quá hạn, hiện "Xem tất cả" + số tiền quá hạn + đếm', (tester) async {
    repo.enqueueList(_page()); // load
    await open(tester);
    repo.enqueueList(_page(items: [fx.rowsBefore[0]]));
    await tester.tap(find.textContaining('lâu nhất'));
    await tester.pumpAndSettle();
    expect(cubit.state.filter, ReceivableFilter.overdue);
    expect(find.text('Xem tất cả'), findsOneWidget);
    expect(find.text('· 12.000.000 ₫'), findsOneWidget);
    expect(find.text('Đang hiển thị 1 / 3 khách'), findsOneWidget);
  });

  testWidgets('no-overdue: hero xanh không bấm được', (tester) async {
    repo.enqueueList(
      _page(
        summary: const ReceivableSummary(
          totalOutstandingMinor: 8500000,
          customerCount: 2,
          overdueCustomerCount: 0,
          overdueAmountMinor: 0,
          maxOverdueDays: 0,
        ),
        items: [fx.rowsBefore[1], fx.rowsBefore[2]],
      ),
    );
    await open(tester);
    expect(find.text('Không có khoản nào quá hạn'), findsOneWidget);
    expect(find.text('Tất cả khách đang nợ còn trong hạn hẹn.'), findsOneWidget);
    await tester.tap(find.text('Không có khoản nào quá hạn'));
    await tester.pumpAndSettle();
    expect(cubit.state.filter, ReceivableFilter.all);
    expect(repo.listCalls, hasLength(1));
  });

  testWidgets('search-empty: bấm Xoá tìm kiếm gọi clearQuery', (tester) async {
    repo.enqueueList(_page(items: const []));
    await open(tester);
    cubit.setQuery('xyz');
    await tester.pump();
    expect(find.text('Không tìm thấy khách phù hợp.'), findsOneWidget);
    await tester.tap(find.text('Xoá tìm kiếm').last);
    await tester.pumpAndSettle();
    expect(cubit.state.query, '');
  });

  testWidgets('empty', (tester) async {
    repo.enqueueList(
      _page(
        summary: const ReceivableSummary(
          totalOutstandingMinor: 0,
          customerCount: 0,
          overdueCustomerCount: 0,
          overdueAmountMinor: 0,
          maxOverdueDays: 0,
        ),
        items: const [],
      ),
    );
    await open(tester);
    expect(find.text('Không có khách nào đang nợ'), findsOneWidget);
    expect(find.text('Đơn bán nợ sẽ hiện ở đây.'), findsOneWidget);
  });

  testWidgets('error: Thử lại gọi lại list', (tester) async {
    repo.enqueueList(const AppException(AppErrorCode.network));
    await open(tester);
    expect(find.text('Không tải được công nợ'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.listCalls, hasLength(2));
    expect(find.text('Anh Tuấn'), findsOneWidget);
  });

  testWidgets('khách ngừng hoạt động có nhãn', (tester) async {
    final inactive = CustomerReceivableRow(
      customerId: 'c-hoa',
      displayName: 'Cô Hoa',
      phone: null,
      isActive: false,
      outstandingMinor: 1000000,
      openOrderCount: 1,
      overdueOrderCount: 0,
      overdueAmountMinor: 0,
      maxOverdueDays: 0,
      nextDueDate: null,
    );
    repo.enqueueList(_page(items: [inactive]));
    await open(tester);
    expect(find.text('Ngừng hoạt động'), findsOneWidget);
    expect(find.text('Không có hẹn'), findsOneWidget);
  });

  testWidgets('long 390: tên dài + số lớn không tràn', (tester) async {
    final longRow = CustomerReceivableRow(
      customerId: 'c-long',
      displayName: 'Công ty TNHH Thương mại và Dịch vụ Nông nghiệp Công nghệ cao Miền Tây',
      phone: null,
      isActive: true,
      outstandingMinor: 1234567890,
      openOrderCount: 12,
      overdueOrderCount: 3,
      overdueAmountMinor: 900000000,
      maxOverdueDays: 125,
      nextDueDate: null,
    );
    repo.enqueueList(_page(items: [longRow]));
    await open(tester);
    expect(find.text('1.234.567.890 ₫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1280: tách đôi, chưa chọn → gợi ý, không nút lùi', (tester) async {
    await cubit.load();
    await pumpReceivable(
      tester,
      ReceivableAreaShell(
        cubit: cubit,
        child: const Scaffold(body: Center(child: Text('Chọn một khách để xem công nợ'))),
      ),
      size: web,
    );
    expect(find.text('Chọn một khách để xem công nợ'), findsOneWidget);
    expect(find.text('Công nợ phải thu'), findsOneWidget);
    expect(find.byTooltip('Quay lại'), findsNothing);
  });

  test('menu Thêm: receivables ngay sau customers', () {
    final ids = [for (final e in kMoreEntries) e.id];
    expect(ids[ids.indexOf('customers') + 1], 'receivables');
    expect(kMoreEntries.firstWhere((e) => e.id == 'receivables').route, '/more/receivables');
  });
}
