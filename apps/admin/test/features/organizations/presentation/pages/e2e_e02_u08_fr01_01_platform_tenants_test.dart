import 'package:admin/features/audit/presentation/pages/audit_logs_page.dart';
import 'package:admin/features/organizations/presentation/pages/organizations_page.dart';
import 'package:admin/features/organizations/presentation/pages/platform_tenant_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// e2e_e02_u08_fr01_01 — Admin platform tenants / audit via FakeIamModule.
///
/// Covers:
///  US-08: list → detail
///  US-06: suspend + restore
///  US-09: transfer ownership
///  US-10: audit list → detail
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('US-08 — list → detail', () {
    testWidgets('e2e_e02_u08_fr01_01: list shows tenants from module', (
      tester,
    ) async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);
      getIt
        ..registerSingleton<IExecutionContext>(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OrganizationsPage(iamModule: module)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mậu Hiên'), findsOneWidget);
      expect(find.text('VietVet Trading'), findsOneWidget);
    });

    testWidgets('e2e_e02_u08_fr01_02: list → detail loads tenant', (
      tester,
    ) async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);
      getIt
        ..registerSingleton<IExecutionContext>(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OrganizationsPage(iamModule: module)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mậu Hiên'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết tổ chức'), findsOneWidget);
      expect(find.text('TEN-000142'), findsOneWidget);
      expect(find.text('Thành viên tổ chức'), findsOneWidget);
    });
  });

  group('US-06 — suspend / restore', () {
    testWidgets('e2e_e02_u06_fr01_01: suspend then restore tenant', (
      tester,
    ) async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantSuspendOk);
      getIt
        ..registerSingleton<IExecutionContext>(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        MaterialApp(
          home: PlatformTenantDetailPage(
            tenantId: 'org-001',
            iamModule: module,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang hoạt động'), findsWidgets);
      expect(find.text('Hoạt động gần nhất'), findsOneWidget);
      expect(find.text('13/07/2026 · 09:18'), findsOneWidget);

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạm ngừng tổ chức'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'risk review');
      await tester.tap(find.text('Tạm ngừng').last);
      await tester.pumpAndSettle();

      expect(find.text('Đã tạm ngừng'), findsWidgets);

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khôi phục tổ chức'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khôi phục').last);
      await tester.pumpAndSettle();

      expect(find.text('Đang hoạt động'), findsWidgets);
    });
  });

  group('US-09 — transfer ownership', () {
    testWidgets('e2e_e02_u09_fr01_01: transfer owner to member', (
      tester,
    ) async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.ownershipTransferOk,
      );
      getIt
        ..registerSingleton<IExecutionContext>(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        MaterialApp(
          home: PlatformTenantDetailPage(
            tenantId: 'org-001',
            iamModule: module,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thay đổi chủ sở hữu'));
      await tester.pumpAndSettle();

      expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
      await tester.tap(find.text('Trần Thị Hoa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển quyền'));
      await tester.pumpAndSettle();

      final detail = await module.executeQueryAsync(
        GetPlatformTenantQuery(tenantId: 'org-001'),
      );
      expect(detail.ownerUserId, 'hoa-tran');
      expect(detail.members.where((m) => m.isOwner), hasLength(1));
    });
  });

  group('US-10 — audit list / detail', () {
    testWidgets('e2e_e02_u10_fr01_01: audit list → detail redacted', (
      tester,
    ) async {
      final module = FakeIamModule(scenario: FakeIamScenario.auditSearchOk);
      getIt
        ..registerSingleton<IExecutionContext>(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AuditLogsPage(iamModule: module)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã tạm ngừng tổ chức'), findsOneWidget);
      await tester.tap(find.text('Đã tạm ngừng tổ chức'));
      await tester.pumpAndSettle();

      expect(find.text('COR-7F29A1'), findsOneWidget);
      expect(find.text('Sau: Đã tạm ngừng'), findsOneWidget);
    });
  });
}
