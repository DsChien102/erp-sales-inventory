import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/presentation/testing/recording_iam_module.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('loads audit logs and renders total count in subtitle', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationAuditLogsPage(
          iamModule: FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử quản trị'), findsOneWidget);
    expect(find.textContaining('hoạt động trong 30 ngày'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Thành viên'), findsOneWidget);
    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('Tổ chức'), findsOneWidget);
  });

  testWidgets('category chip taps update filtered query', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationAuditLogsPage(
          iamModule: recording,
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    final queries = recording.queriesOf<SearchTenantAuditLogsQuery>().toList();
    expect(queries.length, greaterThan(1));
    expect(queries.last.eventCategory?.code, 'member');
  });

  testWidgets('search text field triggers debounced search with query', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantAuditSearchOk),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationAuditLogsPage(
          iamModule: recording,
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(VSearchBar), 'Bác sĩ A');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final queries = recording.queriesOf<SearchTenantAuditLogsQuery>().toList();
    expect(queries.last.query, 'Bác sĩ A');
  });

  testWidgets('actor unavailable detail shows generic actor message', (tester) async {
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

  testWidgets('detail renders change diff rows correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-001',
          iamModule: FakeIamModule(scenario: FakeIamScenario.tenantAuditDetailOk),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tên hiển thị'), findsOneWidget);
    expect(find.text('Trước: Old'), findsOneWidget);
    expect(find.text('Sau: New'), findsOneWidget);
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
