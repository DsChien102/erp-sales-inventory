import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('wgt_e02_u07_fr01_01: loads audit logs via SearchTenantAuditLogsQuery without FakeAuditLogsData',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationAuditLogsPage(
          iamModule:
              FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử quản trị'), findsOneWidget);
    expect(find.textContaining('hoạt động'), findsWidgets);
    expect(find.text('Tải thêm'), findsOneWidget);
  });

  testWidgets('actor unavailable detail shows generic actor message',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-001',
          iamModule: FakeIamModule(
            scenario: FakeIamScenario.tenantAuditActorUnavailable,
          ),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Không còn thông tin người thực hiện'),
      findsWidgets,
    );
  });

  testWidgets('redacted detail does not render raw before/after values',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-REDACTED',
          iamModule:
              FakeIamModule(scenario: FakeIamScenario.tenantAuditDetailOk),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('[Đã che theo chính sách]'), findsWidgets);
    expect(find.textContaining('display_name: Old'), findsNothing);
    expect(find.textContaining('display_name: New'), findsNothing);
  });

  testWidgets('cross-tenant detail shows generic not found', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-999',
          iamModule: FakeIamModule(
            scenario: FakeIamScenario.tenantAuditCrossTenant,
          ),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy hoạt động'), findsOneWidget);
  });
}
