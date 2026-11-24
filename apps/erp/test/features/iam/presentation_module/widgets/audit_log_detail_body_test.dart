import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/iam/presentation/audit_logs/widgets/audit_log_detail_body.dart';
import 'package:erp/features/iam/presentation/audit_logs/mappers/tenant_audit_ui_mapper.dart';
import '../../support/fake_iam_backend.dart';

void main() {
  testWidgets('AuditLogDetailBody has back button with tooltip Quay lại and invokes callback', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backPressed = false;
    final backend = FakeIamBackend(scenario: FakeIamScenario.tenantAuditDetailOk);
    final repo = FakeAuditLogRepository(backend);
    final detail = await repo.getDetail('AUD-T-001');
    final log = TenantAuditUiMapper.fromDetail(detail);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: AuditLogDetailBody(
          log: log,
          onBackPressed: () => backPressed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final backButton = find.byTooltip('Quay lại');
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(backPressed, isTrue);
  });
}
