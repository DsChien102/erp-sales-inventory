import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/logic/receivable_list_cubit.dart';
import 'package:erp/features/receivable/presentation/pages/customer_receivable_page.dart';
import 'package:erp/features/receivable/presentation/receivable_area_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/fake_receivable_repository.dart';
import '../support/receivable_fixtures.dart' as fx;
import 'receivable_test_harness.dart';

const _paidOff = CustomerReceivableDetail(
  customer: fx.tuanCustomer,
  outstandingMinor: 0,
  openOrderCount: 0,
  overdueOrderCount: 0,
  maxOverdueDays: 0,
  openOrders: [],
);

void main() {
  setUpAll(loadInterFont);

  late FakeReceivableRepository repo;

  setUp(() => repo = FakeReceivableRepository());

  Widget page() => CustomerReceivableDetailPage(
    customerId: fx.tuanId,
    repository: repo,
    today: fx.today,
    canCollect: true,
  );

  Future<void> openSheet(WidgetTester tester, {Size size = phone}) async {
    await pumpReceivable(tester, page(), size: size);
    await tester.tap(find.widgetWithText(VButton, 'Thu tiền'));
    await tester.pumpAndSettle();
  }

  VButton button(WidgetTester tester, String label) =>
      tester.widget<VButton>(find.widgetWithText(VButton, label));

  Future<void> tickAllAndType(WidgetTester tester, String amount) async {
    await tester.tap(find.text('Tất cả đơn · trả hết'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(VTextField).first, amount);
    await tester.pumpAndSettle();
  }

  for (final size in [phone, web]) {
    group('${size.width.toInt()}', () {
      testWidgets('mở: chưa tick đơn nào, nút xác nhận khoá', (tester) async {
        await openSheet(tester, size: size);
        expect(find.text('Anh Tuấn · Còn nợ 18.000.000 ₫'), findsOneWidget);
        expect(find.text('Tất cả đơn · trả hết'), findsOneWidget);
        expect(find.text('Chọn ít nhất một đơn để thu.'), findsOneWidget);
        expect(button(tester, 'Xác nhận thu').onPressed, isNull);
      });

      testWidgets('tick tất cả rồi sửa 10.000.000 → chia cũ trước', (tester) async {
        await openSheet(tester, size: size);
        await tickAllAndType(tester, '10000000');
        expect(find.text('Trừ 4.000.000 → hết nợ'), findsOneWidget);
        expect(find.text('Trừ 6.000.000 → còn 2.000.000'), findsOneWidget);
        expect(find.text('Chưa nhận'), findsOneWidget);
        expect(find.text('Khách còn nợ sau khi thu'), findsOneWidget);
        expect(find.text('8.000.000 ₫'), findsOneWidget);
      });

      testWidgets('Chuyển khoản hiện ô mã giao dịch', (tester) async {
        await openSheet(tester, size: size);
        await tester.tap(find.text('Chuyển khoản'));
        await tester.pumpAndSettle();
        expect(find.text('Mã giao dịch (Không bắt buộc)'), findsOneWidget);
      });

      testWidgets('xác nhận → gửi request, đóng sheet, toast, tải lại CN-02', (tester) async {
        repo.enqueueCustomer(fx.tuanDetail); // load lần đầu
        await openSheet(tester, size: size);
        await tickAllAndType(tester, '10000000');
        await tester.tap(find.widgetWithText(VButton, 'Xác nhận thu'));
        await tester.pumpAndSettle();
        expect(find.text('Xác nhận thu tiền?'), findsOneWidget);
        expect(find.text('Thu 10.000.000 ₫ Tiền mặt từ Anh Tuấn · tất cả đơn'), findsOneWidget);
        expect(find.text('SẼ TRỪ VÀO'), findsOneWidget);
        await tester.tap(find.widgetWithText(VButton, 'Xác nhận'));
        await tester.pumpAndSettle();
        final r = repo.collectionCalls.single;
        expect(r.amountMinor, 10000000);
        expect(r.orderIds, ['so-001', 'so-002', 'so-003']);
        expect(find.text('Xác nhận thu tiền?'), findsNothing);
        expect(find.text('Đã thu 10.000.000 ₫ từ Anh Tuấn'), findsOneWidget);
        expect(repo.customerCalls, hasLength(2));
      });

      testWidgets('RECEIVABLE_CHANGED → hộp thoại, Tải lại đóng sheet và tải lại', (tester) async {
        repo.enqueueRecord(const AppException('RECEIVABLE_CHANGED'));
        await openSheet(tester, size: size);
        await tickAllAndType(tester, '10000000');
        await tester.tap(find.widgetWithText(VButton, 'Xác nhận thu'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VButton, 'Xác nhận'));
        await tester.pumpAndSettle();
        expect(
          find.text('Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(VButton, 'Tải lại'));
        await tester.pumpAndSettle();
        expect(find.text('Xác nhận thu'), findsNothing);
        expect(repo.customerCalls, hasLength(2));
      });

      testWidgets('lỗi khác → dòng đỏ trong sheet + Thử lại giữ khoá', (tester) async {
        repo.enqueueRecord(const AppException(AppErrorCode.network));
        await openSheet(tester, size: size);
        await tickAllAndType(tester, '10000000');
        await tester.tap(find.widgetWithText(VButton, 'Xác nhận thu'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VButton, 'Xác nhận'));
        await tester.pumpAndSettle();
        expect(find.text('Không ghi nhận được. Thử lại?'), findsOneWidget);
        await tester.tap(find.widgetWithText(VButton, 'Thử lại'));
        await tester.pumpAndSettle();
        expect(repo.collectionCalls.map((c) => c.idempotencyKey).toSet(), hasLength(1));
        expect(repo.collectionCalls, hasLength(2));
      });

      testWidgets('đã tick rồi đóng → hỏi bỏ; Ở lại giữ, Bỏ đóng', (tester) async {
        await openSheet(tester, size: size);
        await tester.tap(find.text('Tất cả đơn · trả hết'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Đóng'));
        await tester.pumpAndSettle();
        expect(find.text('Bỏ khoản thu đang nhập?'), findsOneWidget);
        await tester.tap(find.widgetWithText(VButton, 'Ở lại'));
        await tester.pumpAndSettle();
        expect(find.text('Xác nhận thu'), findsOneWidget);
        await tester.tap(find.byTooltip('Đóng'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VButton, 'Bỏ'));
        await tester.pumpAndSettle();
        expect(find.text('Xác nhận thu'), findsNothing);
      });

      testWidgets('chưa nhập gì → đóng ngay', (tester) async {
        await openSheet(tester, size: size);
        await tester.tap(find.byTooltip('Đóng'));
        await tester.pumpAndSettle();
        expect(find.text('Bỏ khoản thu đang nhập?'), findsNothing);
        expect(find.text('Xác nhận thu'), findsNothing);
      });
    });
  }

  testWidgets('pay all then paid-off: CN-02 hết nợ, cột trái không còn khách', (tester) async {
    final listCubit = ReceivableListCubit(repository: repo);
    addTearDown(listCubit.close);
    await listCubit.load();
    repo
      ..enqueueCustomer(fx.tuanDetail)
      ..enqueueCustomer(_paidOff)
      ..enqueueList(
        CustomerReceivablePage(
          summary: const ReceivableSummary(
            totalOutstandingMinor: 8500000,
            customerCount: 2,
            overdueCustomerCount: 0,
            overdueAmountMinor: 0,
            maxOverdueDays: 0,
          ),
          items: [fx.rowsBefore[1], fx.rowsBefore[2]],
          nextCursor: null,
        ),
      )
      ..enqueueRecord(const CustomerCollectionResult(collectionId: 'c', outstandingAfterMinor: 0));
    await pumpReceivable(
      tester,
      ReceivableAreaShell(cubit: listCubit, selectedId: fx.tuanId, child: page()),
      size: web,
    );
    expect(find.text('Anh Tuấn'), findsWidgets);
    await tester.tap(find.widgetWithText(VButton, 'Thu tiền'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả đơn · trả hết'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Xác nhận thu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Xác nhận'));
    await tester.pumpAndSettle();
    expect(repo.collectionCalls.single.amountMinor, 18000000);
    expect(find.text('Không còn nợ'), findsOneWidget);
    expect(find.text('Không còn đơn nào nợ'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Thu tiền'), findsNothing);
    // Cột trái: Anh Tuấn chỉ còn trong tiêu đề CN-02, không còn dòng khách.
    expect(find.text('0901 234 567 · 3 đơn'), findsNothing);
    expect(find.text('Trại Hưng Phát'), findsOneWidget);
  });
}
