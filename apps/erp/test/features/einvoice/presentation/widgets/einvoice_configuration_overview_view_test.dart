import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/einvoice_configuration_overview_cubit.dart';
import 'package:erp/features/einvoice/presentation/widgets/einvoice_configuration_overview_view.dart';
import 'package:erp/features/einvoice/presentation/widgets/settings_navigation_item.dart';

import '../../support/fake_einvoice_configuration_repository.dart';

class _DisconnectedOverviewRepository extends FakeEInvoiceConfigurationRepository {
  _DisconnectedOverviewRepository()
      : super(scenario: FakeEInvoiceConfigurationScenario.connectionScreenDisconnected);

  var templateQueryCount = 0;

  @override
  Future<List<ProviderTemplateDto>> listTemplates({bool? invoiceWithCode, int? year}) {
    templateQueryCount += 1;
    throw StateError('template query must not run before provider is connected');
  }
}

SettingsNavigationItem _issuanceCard(WidgetTester tester) {
  return tester.widget<SettingsNavigationItem>(
    find.ancestor(
      of: find.text('Cấu hình phát hành'),
      matching: find.byType(SettingsNavigationItem),
    ),
  );
}

void main() {
  Future<void> pumpOverview(
    WidgetTester tester, {
    required FakeEInvoiceConfigurationScenario scenario,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: BlocProvider(
          create: (_) => EInvoiceConfigurationOverviewCubit(
            repository: FakeEInvoiceConfigurationRepository(scenario: scenario),
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
        scenario: FakeEInvoiceConfigurationScenario.configReadinessBlocked,
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

  testWidgets('disconnected overview does not query provider templates', (tester) async {
    final repo = _DisconnectedOverviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: BlocProvider(
          create: (_) => EInvoiceConfigurationOverviewCubit(
            repository: repo,
          )..load(),
          child: const Scaffold(body: EInvoiceConfigurationOverviewView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa kết nối MISA meInvoice'), findsOneWidget);
    expect(repo.templateQueryCount, 0);
    expect(_issuanceCard(tester).enabled, isFalse);
  });

  testWidgets('disconnected issuance card ignores tap', (tester) async {
    var opened = false;
    final repo = _DisconnectedOverviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: BlocProvider(
          create: (_) => EInvoiceConfigurationOverviewCubit(
            repository: repo,
          )..load(),
          child: Scaffold(
            body: EInvoiceConfigurationOverviewView(
              onIssuanceTap: () => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cấu hình phát hành'));
    await tester.pumpAndSettle();

    expect(opened, isFalse);
  });

  testWidgets(
    'wgt_e01_u04_fr09_02: D02 shows ready banner and configured nav copy',
    (tester) async {
      await pumpOverview(
        tester,
        scenario: FakeEInvoiceConfigurationScenario.configReadinessReady,
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
      expect(_issuanceCard(tester).enabled, isTrue);
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
        scenario: FakeEInvoiceConfigurationScenario.connectPermissionDenied,
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
        scenario: FakeEInvoiceConfigurationScenario.configurationLoadFailure,
      );

      expect(find.byKey(const Key('wgt_e01_s02_01')), findsOneWidget);
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );
}
