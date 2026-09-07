import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  Future<void> pumpIssuance(
    WidgetTester tester, {
    required FakeEInvoiceScenario scenario,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: BlocProvider(
          create: (_) => DefaultIssuanceConfigurationCubit(
            einvoiceModule: FakeEInvoiceModule(scenario: scenario),
            executionContext: FakeExecutionContext(),
          )..load(),
          child: const Scaffold(body: DefaultIssuanceConfigurationView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'wgt_e01_u02_fr04_01: D05 shows template select and info without signing field',
    (tester) async {
      await pumpIssuance(
        tester,
        scenario: FakeEInvoiceScenario.listTemplatesOk,
      );

      expect(find.byKey(const Key('wgt_e01_u02_fr04_01')), findsOneWidget);
      expect(
        find.text(
          'Chọn mẫu hóa đơn và hình thức ký số mặc định khi phát hành hóa đơn điện tử.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mẫu hóa đơn', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Đồng bộ gần nhất: 10:38, 05/08/2026'), findsOneWidget);
      expect(find.text('Thông tin mẫu'), findsOneWidget);
      expect(find.text('Ký hiệu'), findsOneWidget);
      expect(find.text('C22TAA'), findsWidgets);
      expect(find.text('Cấp mã'), findsOneWidget);
      expect(find.text('Có mã của cơ quan thuế'), findsOneWidget);
      expect(find.text('Loại hóa đơn'), findsOneWidget);
      expect(find.text('Hóa đơn GTGT'), findsOneWidget);
      expect(find.text('Hình thức ký số'), findsNothing);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);
    },
  );

  testWidgets(
    'D05 missing profile hides template info card until a template is selected',
    (tester) async {
      await pumpIssuance(
        tester,
        scenario: FakeEInvoiceScenario.configReadinessBlocked,
      );

      expect(
        find.textContaining('Mẫu hóa đơn', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Ký hiệu'), findsNothing);
    },
  );
}
