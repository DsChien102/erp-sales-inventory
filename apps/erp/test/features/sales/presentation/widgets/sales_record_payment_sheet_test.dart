
import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:erp/features/sales/logic/sales_record_payment_cubit.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:erp/features/sales/presentation/widgets/sales_record_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../../support/fake_sales_payment_repository.dart';

final class _TestExecutionContext implements IExecutionContext {
  const _TestExecutionContext();
  @override
  String get correlationId => 'corr-1';
  @override
  Future<String> requireTenantId() async => 'tenant-1';
  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _TestActiveStoreContext implements ISalesActiveStoreContext {
  const _TestActiveStoreContext();
  @override
  String? get activeStoreId => 'store-1';
  @override
  Future<String> requireActiveStoreId() async => 'store-1';
}

Widget _harness({
  required Widget child,
}) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  late FakeSalesPaymentRepository repo;
  late _TestExecutionContext executionContext;
  late _TestActiveStoreContext activeStoreContext;

  setUp(() {
    repo = FakeSalesPaymentRepository();
    repo.recordResult = const SalesRecordPaymentResult(
      transactionId: 'tx-1',
      outstandingMinor: 0,
      paymentStatus: 'paid',
      version: 2,
    );
    executionContext = const _TestExecutionContext();
    activeStoreContext = const _TestActiveStoreContext();
  });

  SalesRecordPaymentCubit createCubit({
    int outstandingMinor = 600000,
    String salesOrderId = 'order-1',
  }) {
    return SalesRecordPaymentCubit(
      repository: repo,
      executionContext: executionContext,
      activeStoreContext: activeStoreContext,
      salesOrderId: salesOrderId,
      outstandingMinor: outstandingMinor,
    );
  }

  group('showSalesRecordPaymentSheet', () {
    testWidgets('shows_outstanding_and_due_date', (tester) async {
      final cubit = createCubit(outstandingMinor: 600000);

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                dueDateFormatted: '15/10/2026',
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Thu tiền'), findsWidgets);
      expect(find.text('Đơn DH202610060003'), findsOneWidget);
      expect(find.text('Còn phải thu'), findsOneWidget);
      expect(find.text('600.000đ'), findsWidgets);
      expect(find.text('Hẹn thanh toán'), findsOneWidget);
      expect(find.text('15/10/2026'), findsOneWidget);
      expect(find.byKey(const Key('inp_sg11_amount')), findsOneWidget);
      expect(find.byKey(const Key('seg_sg11_method')), findsOneWidget);
    });

    testWidgets('reference_only_for_transfer', (tester) async {
      final cubit = createCubit(outstandingMinor: 600000);

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Initially cash -> no reference input
      expect(find.byKey(const Key('inp_sg11_reference')), findsNothing);

      // Tap transfer -> reference input appears
      await tester.tap(find.text('Chuyển khoản'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inp_sg11_reference')), findsOneWidget);

      // Tap cash -> reference input disappears
      await tester.tap(find.text('Tiền mặt'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inp_sg11_reference')), findsNothing);
    });

    testWidgets('confirm_disabled_while_submitting', (tester) async {
      final completer = Completer<SalesRecordPaymentResult>();
      repo.recordCompleter = completer;
      final cubit = createCubit(outstandingMinor: 600000);

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final confirmBtnFinder = find.byKey(const Key('btn_sg11_confirm'));
      expect(confirmBtnFinder, findsOneWidget);

      await tester.tap(confirmBtnFinder);
      await tester.pump();

      final confirmBtn = tester.widget<VButton>(confirmBtnFinder);
      expect(confirmBtn.isLoading, isTrue);
      expect(confirmBtn.onPressed, isNull);

      completer.complete(
        const SalesRecordPaymentResult(
          transactionId: 'tx-done',
          outstandingMinor: 0,
          paymentStatus: 'paid',
          version: 3,
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('retry_label_after_network_error', (tester) async {
      final cubit = createCubit(outstandingMinor: 600000);
      repo.recordErrors.add(const AppException('NETWORK_ERROR'));

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Initially editing -> label is "Xác nhận thu tiền"
      expect(find.text('Xác nhận thu tiền'), findsOneWidget);

      // Tap confirm -> triggers network error
      await tester.tap(find.byKey(const Key('btn_sg11_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.byKey(const Key('txt_sg11_error')), findsOneWidget);
      expect(
        find.text('Không thể ghi nhận thanh toán. Vui lòng thử lại.'),
        findsOneWidget,
      );
    });

    testWidgets('retry_label_cleared_after_edit', (tester) async {
      repo.recordErrors.add(const AppException('NETWORK_ERROR'));
      final cubit = createCubit();

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap confirm -> triggers network error -> button becomes "Thử lại"
      await tester.tap(find.byKey(const Key('btn_sg11_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);

      // Edit amount field -> button reverts to "Xác nhận thu tiền"
      await tester.enterText(find.byKey(const Key('inp_sg11_amount')), '500.000');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận thu tiền'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('narrow_is_bottom_sheet_wide_is_dialog', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Narrow screen: 390x844
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      final cubit1 = createCubit();
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit1,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsNothing);

      // Close sheet
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();

      // Wide screen: 1440x900
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;

      final cubit2 = createCubit();
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit2,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsOneWidget);
    });

    testWidgets('enter_submits_once', (tester) async {
      final cubit = createCubit(outstandingMinor: 600000);

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Focus amount field and press Enter
      await tester.tap(find.byKey(const Key('inp_sg11_amount')));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repo.recordCalls.length, 1);
      expect(repo.recordCalls.first.amountMinor, 600000);
    });

    testWidgets('escape_closes', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cubit = createCubit();

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSalesRecordPaymentSheet(
                context,
                salesOrderId: 'order-1',
                orderNumber: 'DH202610060003',
                outstandingMinor: 600000,
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsNothing);
    });
  });
}
