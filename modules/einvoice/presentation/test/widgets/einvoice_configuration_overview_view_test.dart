import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  Future<void> pumpOverview(
    WidgetTester tester, {
    required FakeEInvoiceScenario scenario,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: BlocProvider(
          create: (_) => EInvoiceConfigurationOverviewCubit(
            einvoiceModule: FakeEInvoiceModule(scenario: scenario),
            executionContext: FakeExecutionContext(),
          )..load(),
          child: const Scaffold(
            body: EInvoiceConfigurationOverviewView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'wgt_e01_u04_fr09_01: D01 shows not-ready banner and incomplete nav copy',
    (tester) async {
      await pumpOverview(
        tester,
        scenario: FakeEInvoiceScenario.configReadinessBlocked,
      );

      expect(find.byKey(const Key('wgt_e01_u04_fr09_01')), findsOneWidget);
      expect(find.text('Cần hoàn tất'), findsOneWidget);
      expect(find.text('Chưa sẵn sàng phát hành'), findsOneWidget);
      expect(
        find.text(
          'Còn 2 điều kiện cần hoàn tất trước khi có thể phát hành hóa đơn điện tử.',
        ),
        findsOneWidget,
      );
      expect(find.text('Xem và hoàn tất'), findsOneWidget);
      expect(find.byType(VButton), findsNothing);
      expect(find.byType(VBanner), findsNothing);
      expect(find.text('Kết nối MISA'), findsOneWidget);
      expect(find.text('Chưa kết nối MISA meInvoice'), findsOneWidget);
      expect(find.text('Cấu hình phát hành'), findsOneWidget);
      expect(find.text('Chưa chọn mẫu hóa đơn mặc định'), findsOneWidget);
      expect(find.text('Tự động hóa'), findsOneWidget);
      expect(
        find.text('Phát hành hóa đơn và gửi email tự động.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'wgt_e01_u04_fr09_02: D02 shows ready banner and configured nav copy',
    (tester) async {
      await pumpOverview(
        tester,
        scenario: FakeEInvoiceScenario.configReadinessReady,
      );

      expect(find.byKey(const Key('wgt_e01_u04_fr09_02')), findsOneWidget);
      expect(find.text('Cần hoàn tất'), findsNothing);
      expect(find.text('Xem và hoàn tất'), findsNothing);
      expect(find.text('Sẵn sàng phát hành'), findsOneWidget);
      expect(
        find.text(
          'Đã đủ điều kiện phát hành hóa đơn điện tử từ đơn hàng Hoàn tất.',
        ),
        findsOneWidget,
      );
      expect(find.text('MISA meInvoice · Đã kết nối'), findsOneWidget);
      expect(
        find.text('C22TAA · Có mã của cơ quan thuế'),
        findsOneWidget,
      );
      expect(
        find.text('Phát hành thủ công · Gửi email thủ công'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'wgt_e01_s01_01: overview maps permission denied to S01',
    (tester) async {
      await pumpOverview(
        tester,
        scenario: FakeEInvoiceScenario.connectPermissionDenied,
      );

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
      expect(find.text('Không có quyền truy cập'), findsOneWidget);
      expect(find.text('Chưa sẵn sàng phát hành'), findsNothing);
    },
  );

  testWidgets(
    'wgt_e01_s02_01: overview maps load failure to S02',
    (tester) async {
      await pumpOverview(
        tester,
        scenario: FakeEInvoiceScenario.configurationLoadFailure,
      );

      expect(find.byKey(const Key('wgt_e01_s02_01')), findsOneWidget);
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );
}
