import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/automation_policy_cubit.dart';
import 'package:erp/features/einvoice/presentation/widgets/automation_policy_view.dart';

import '../../support/fake_einvoice_configuration_repository.dart';

class _RecordingAutomationPolicyRepository extends FakeEInvoiceConfigurationRepository {
  _RecordingAutomationPolicyRepository()
      : super(scenario: FakeEInvoiceConfigurationScenario.automationPolicyOk);

  bool? lastAutoIssue;
  bool? lastAutoSend;
  int? lastExpectedVersion;

  @override
  Future<AutomationPolicyDto> updateAutomationPolicy({
    required int expectedPolicyVersion,
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
  }) async {
    lastExpectedVersion = expectedPolicyVersion;
    lastAutoIssue = autoIssueEnabled;
    lastAutoSend = autoSendEnabled;
    return super.updateAutomationPolicy(
      expectedPolicyVersion: expectedPolicyVersion,
      autoIssueEnabled: autoIssueEnabled,
      autoSendEnabled: autoSendEnabled,
    );
  }
}

void main() {
  testWidgets(
    'wgt_e01_u03_fr02_01: D06 shows auto-issue and auto-send switches',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => AutomationPolicyCubit(
              repository: FakeEInvoiceConfigurationRepository(
                scenario: FakeEInvoiceConfigurationScenario.automationPolicyOk,
              ),
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

  testWidgets(
    'toggling switches and tapping save dispatches UpdateAutomationPolicyCommand with expected payload and version',
    (tester) async {
      final repo = _RecordingAutomationPolicyRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => AutomationPolicyCubit(repository: repo)..load(),
            child: const Scaffold(body: AutomationPolicyView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially enabled in automationPolicyOk
      // Toggle both switches
      await tester.tap(find.byType(VSwitch).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(VSwitch).last);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.byKey(const Key('automation_policy_save')));
      await tester.pumpAndSettle();

      expect(
        repo.calls.where((c) => c == 'updateAutomationPolicy'),
        hasLength(1),
      );
      expect(repo.lastAutoIssue, isFalse);
      expect(repo.lastAutoSend, isFalse);
      expect(repo.lastExpectedVersion, 1);
    },
  );

  testWidgets(
    'displays permission denied state when loading policy without manageConfiguration permission',
    (tester) async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.connectPermissionDenied,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => AutomationPolicyCubit(repository: repo)..load(),
            child: const Scaffold(body: AutomationPolicyView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
    },
  );
}
