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

  testWidgets(
    'toggling switches and tapping save dispatches UpdateAutomationPolicyCommand with expected payload and version',
    (tester) async {
      final executedCommands = <ICommand<dynamic>>[];
      final fake = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.automationPolicyOk);
      final module = _RecordingAutomationPolicyModule(fake, executedCommands);
      final execContext = FakeExecutionContext(tenantId: 'tenant-ap-1', userId: 'user-ap-2');

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => AutomationPolicyCubit(
              einvoiceModule: module,
              executionContext: execContext,
            )..load(),
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

      expect(executedCommands, hasLength(1));
      final command = executedCommands.first as UpdateAutomationPolicyCommand;
      expect(command.tenantId, 'tenant-ap-1');
      expect(command.actorId, 'user-ap-2');
      expect(command.autoIssueEnabled, isFalse);
      expect(command.autoSendEnabled, isFalse);
      expect(command.expectedPolicyVersion, 1);
    },
  );

  testWidgets(
    'displays permission denied state when loading policy without manageConfiguration permission',
    (tester) async {
      final module = _PermissionDeniedAutomationModule();
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => AutomationPolicyCubit(
              einvoiceModule: module,
              executionContext: FakeExecutionContext(),
            )..load(),
            child: const Scaffold(body: AutomationPolicyView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
    },
  );
}

final class _PermissionDeniedAutomationModule implements IEInvoiceModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
  }
}

final class _RecordingAutomationPolicyModule implements IEInvoiceModule {
  _RecordingAutomationPolicyModule(this.delegate, this.executedCommands);

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
