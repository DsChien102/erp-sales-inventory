import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_cubit.dart';
import 'package:erp/features/einvoice/presentation/widgets/default_issuance_configuration_view.dart';

import '../../support/fake_einvoice_configuration_repository.dart';

class _RecordingDefaultIssuanceRepository extends FakeEInvoiceConfigurationRepository {
  _RecordingDefaultIssuanceRepository()
      : super(scenario: FakeEInvoiceConfigurationScenario.listTemplatesOk);

  String? lastTemplateId;
  String? lastSigningConfigId;
  int? lastExpectedProfileVersion;

  @override
  Future<IssuanceProfileDto> setDefaultConfiguration({
    required String templateId,
    required String signingConfigId,
    int? expectedProfileVersion,
  }) async {
    lastTemplateId = templateId;
    lastSigningConfigId = signingConfigId;
    lastExpectedProfileVersion = expectedProfileVersion;
    return super.setDefaultConfiguration(
      templateId: templateId,
      signingConfigId: signingConfigId,
      expectedProfileVersion: expectedProfileVersion,
    );
  }
}

void main() {
  Future<void> pumpIssuance(
    WidgetTester tester, {
    required FakeEInvoiceConfigurationScenario scenario,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: BlocProvider(
          create: (_) => DefaultIssuanceConfigurationCubit(
            repository: FakeEInvoiceConfigurationRepository(scenario: scenario),
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
        scenario: FakeEInvoiceConfigurationScenario.listTemplatesOk,
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
        scenario: FakeEInvoiceConfigurationScenario.configReadinessBlocked,
      );

      expect(
        find.textContaining('Mẫu hóa đơn', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Ký hiệu'), findsNothing);
    },
  );

  testWidgets(
    'selecting template and tapping save dispatches SetDefaultIssuanceConfigurationCommand with expected payload and version',
    (tester) async {
      final repo = _RecordingDefaultIssuanceRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => DefaultIssuanceConfigurationCubit(repository: repo)..load(),
            child: const Scaffold(body: DefaultIssuanceConfigurationView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open select dropdown and choose second template
      await tester.tap(find.byKey(const Key('wgt_e01_u02_fr04_01')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('C26TAA').last);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.byKey(const Key('default_issuance_save')));
      await tester.pumpAndSettle();

      expect(repo.lastTemplateId, 'tpl-2');
      expect(repo.lastSigningConfigId, 'sign-hsm');
      expect(repo.lastExpectedProfileVersion, 1);
    },
  );

  testWidgets(
    'selecting an MTT template derives the no-sign configuration',
    (tester) async {
      final repo = _RecordingDefaultIssuanceRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => DefaultIssuanceConfigurationCubit(repository: repo)..load(),
            child: const Scaffold(body: DefaultIssuanceConfigurationView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wgt_e01_u02_fr04_01')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2C25MYY').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('default_issuance_save')));
      await tester.pumpAndSettle();

      expect(repo.lastTemplateId, 'tpl-mtt');
      expect(repo.lastSigningConfigId, 'sign-nosign');
    },
  );

  testWidgets(
    'displays permission denied state when loading templates without manageConfiguration permission',
    (tester) async {
      await pumpIssuance(
        tester,
        scenario: FakeEInvoiceConfigurationScenario.listTemplatesPermissionDenied,
      );

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
    },
  );
}
