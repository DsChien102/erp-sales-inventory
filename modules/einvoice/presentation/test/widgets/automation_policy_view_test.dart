import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets(
    'wgt_e01_u03_fr02_01: D06 shows auto-issue and auto-send switches',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => AutomationPolicyCubit(
              einvoiceModule: FakeEInvoiceModule(
                scenario: FakeEInvoiceScenario.automationPolicyOk,
              ),
              executionContext: FakeExecutionContext(),
            )..load(),
            child: const Scaffold(body: AutomationPolicyView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u03_fr02_01')), findsOneWidget);
      expect(find.text('Quy tắc tự động'), findsOneWidget);
      expect(find.text('Tự động phát hành'), findsOneWidget);
      expect(
        find.text(
          'Khi bật, hệ thống phát hành hóa đơn điện tử khi đơn hàng Hoàn tất và đủ điều kiện.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tự động gửi email'), findsOneWidget);
      expect(
        find.text(
          'Khi bật, hệ thống gửi hóa đơn điện tử đến email khách hàng sau khi phát hành thành công (chỉ áp dụng với khách hàng có email hợp lệ trong hồ sơ khách hàng).',
        ),
        findsOneWidget,
      );
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);
      expect(find.byType(VSwitch), findsNWidgets(2));
    },
  );
}
