import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
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

  testWidgets(
    'selecting template and tapping save dispatches SetDefaultIssuanceConfigurationCommand with expected payload and version',
    (tester) async {
      final executedCommands = <ICommand<dynamic>>[];
      final fake = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.listTemplatesOk);
      final module = _RecordingDefaultIssuanceModule(fake, executedCommands);
      final execContext = FakeExecutionContext(tenantId: 't-test-1', userId: 'a-test-2');

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => DefaultIssuanceConfigurationCubit(
              einvoiceModule: module,
              executionContext: execContext,
            )..load(),
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

      expect(executedCommands, hasLength(1));
      final command = executedCommands.first as SetDefaultIssuanceConfigurationCommand;
      expect(command.tenantId, 't-test-1');
      expect(command.actorId, 'a-test-2');
      expect(command.templateId, 'tpl-2');
      expect(command.signingConfigId, 'sign-hsm');
      expect(command.expectedProfileVersion, 1);
    },
  );

  testWidgets(
    'selecting an MTT template derives the no-sign configuration',
    (tester) async {
      final executedCommands = <ICommand<dynamic>>[];
      final fake = FakeEInvoiceModule(
        scenario: FakeEInvoiceScenario.listTemplatesOk,
      );
      final module = _RecordingDefaultIssuanceModule(fake, executedCommands);
      final execContext = FakeExecutionContext(
        tenantId: 't-test-1',
        userId: 'a-test-2',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => DefaultIssuanceConfigurationCubit(
              einvoiceModule: module,
              executionContext: execContext,
            )..load(),
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

      expect(executedCommands, hasLength(1));
      final command = executedCommands.first as SetDefaultIssuanceConfigurationCommand;
      expect(command.templateId, 'tpl-mtt');
      expect(command.signingConfigId, 'sign-nosign');
    },
  );

  testWidgets(
    'displays permission denied state when loading templates without manageConfiguration permission',
    (tester) async {
      await pumpIssuance(
        tester,
        scenario: FakeEInvoiceScenario.listTemplatesPermissionDenied,
      );

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
    },
  );
}

final class _RecordingDefaultIssuanceModule implements IEInvoiceModule {
  _RecordingDefaultIssuanceModule(this.delegate, this.executedCommands);

  final IEInvoiceModule delegate;
  final List<ICommand<dynamic>> executedCommands;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    executedCommands.add(command);
    return delegate.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return delegate.executeQueryAsync(query);
  }
}
