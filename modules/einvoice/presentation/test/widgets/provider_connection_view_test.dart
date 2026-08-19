import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  Future<void> pumpConnection(
    WidgetTester tester, {
    required FakeEInvoiceScenario scenario,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: BlocProvider(
          create: (_) => ProviderConnectionCubit(
            einvoiceModule: FakeEInvoiceModule(scenario: scenario),
            executionContext: FakeExecutionContext(),
          )..load(),
          child: const Scaffold(body: ProviderConnectionView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'wgt_e01_u01_fr03_01: D04-A shows read-only seller info and credential form',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectionScreenDisconnected,
      );

      expect(find.byKey(const Key('wgt_e01_u01_fr03_01')), findsOneWidget);
      expect(find.text('Thông tin kết nối'), findsOneWidget);
      expect(find.text('Nhà cung cấp'), findsOneWidget);
      expect(find.text('MISA meInvoice'), findsOneWidget);
      expect(find.text('Mã số thuế đơn vị phát hành'), findsOneWidget);
      expect(find.text('0101234567'), findsOneWidget);
      expect(
        find.text('Mã số thuế được lấy từ Hồ sơ pháp lý của Tổ chức.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tài khoản MISA', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mật khẩu MISA', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(
          'Mật khẩu được bảo mật và không hiển thị lại sau khi kết nối.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Thông tin xác thực được lưu mã hóa. Mật khẩu không được hiển thị lại sau khi lưu.',
        ),
        findsNothing,
      );
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Kết nối'), findsOneWidget);
      expect(find.text('App ID'), findsNothing);
    },
  );

  testWidgets(
    'wgt_e01_u01_fr02_01: D04-B shows connected info and Thao tác',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.configReadinessReady,
      );

      expect(find.byKey(const Key('wgt_e01_u01_fr02_01')), findsOneWidget);
      expect(find.text('Đã kết nối'), findsOneWidget);
      expect(find.text('MISA meInvoice'), findsOneWidget);
      expect(find.text('ketoan@anphu.vn'), findsOneWidget);
      expect(find.text('0101234567'), findsOneWidget);
      expect(find.text('Kiểm tra gần nhất: 10:40, 05/08/2026'), findsOneWidget);
      expect(find.text('Thao tác'), findsOneWidget);
    },
  );

  testWidgets(
    'D04-A submit without credentials shows required errors',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectionScreenDisconnected,
      );

      await tester.tap(find.byKey(const Key('provider_connection_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tài khoản MISA'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu MISA'), findsOneWidget);
    },
  );

  testWidgets(
    'connectPermissionDenied shows S01 on connection surface',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectPermissionDenied,
      );

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
      expect(find.text('Không có quyền truy cập'), findsOneWidget);
    },
  );
}
