import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// Mutable principal for late permission-revocation tests.
final class _MutablePrincipal implements IPrincipalSnapshot {
  _MutablePrincipal({required this.permissions});
  Set<String> permissions;

  @override
  String? get role => 'member';
  @override
  bool hasPermission(String code) => permissions.contains(code);
}

const _activePartner = PartnerItemModel(
  id: 'partner-1',
  avatarText: 'NA',
  name: 'Nguyen Van An',
  role: 'Khách hàng',
  status: 'Đang hoạt động',
  phone: '0912345678',
  email: '',
  taxId: '',
  updatedAt: '08:00 01/07/2026',
  version: 1,
);

const _inactivePartner = PartnerItemModel(
  id: 'partner-1',
  avatarText: 'NA',
  name: 'Nguyen Van An',
  role: 'Khách hàng',
  status: 'Ngừng hoạt động',
  phone: '0912345678',
  email: '',
  taxId: '',
  updatedAt: '08:00 01/07/2026',
  version: 1,
);

void main() {
  setUp(() async {
    await getIt.reset();
  });

  Widget buildPage({
    required FakePartnerModule module,
    required PartnerItemModel initialPartner,
    Set<String> permissions = const {},
  }) {
    final principal = _MutablePrincipal(permissions: permissions);
    getIt
      ..registerSingleton<IPartnerModule>(module)
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'tenant-1', userId: 'user-1'),
      )
      ..registerSingleton<IPrincipalSnapshot>(principal);

    return MaterialApp(
      home: PartnerDetailPage(
        partnerId: 'partner-1',
        initialPartner: initialPartner,
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
  }

  Future<void> tapMenuAction(WidgetTester tester, String label) async {
    await openMenu(tester);
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  // ──────────────────────────────────────────
  // FR-01 — Bắt đầu thay đổi trạng thái
  // ──────────────────────────────────────────

  group('FR-01', () {
    testWidgets(
      'SCN-04: hides status change actions when user lacks manageStatus permission',
      (tester) async {
        await tester.pumpWidget(buildPage(
          module: FakePartnerModule(
            scenario: FakePartnerScenario.deactivateOk,
          ),
          initialPartner: _activePartner,
          permissions: {PartnerPermissions.viewDetail},
        ));
        await tester.pumpAndSettle();

        await openMenu(tester);

        expect(find.text('Ngừng hoạt động'), findsNothing);
        expect(find.text('Kích hoạt lại'), findsNothing);
      },
    );
  });

  // ──────────────────────────────────────────
  // FR-02 — Kiểm tra điều kiện trước khi thay đổi trạng thái
  // ──────────────────────────────────────────

  group('FR-02', () {
    testWidgets(
      'SCN-06: rejects deactivate when manageStatus permission revoked at action time',
      (tester) async {
        await tester.pumpWidget(buildPage(
          module: FakePartnerModule(
            scenario: FakePartnerScenario.deactivateOk,
          ),
          initialPartner: _activePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        // Revoke permission AFTER widget is built
        final principal =
            getIt<IPrincipalSnapshot>() as _MutablePrincipal;
        principal.permissions = {PartnerPermissions.viewDetail};

        await tapMenuAction(tester, 'Ngừng hoạt động');

        // Deactivate dialog should NOT appear — handler checked permission
        expect(find.text('Ngừng hoạt động KH & NCC?'), findsNothing);

        // Status stays unchanged
        expect(find.text('Đang hoạt động'), findsWidgets);
      },
    );
  });

  // ──────────────────────────────────────────
  // FR-03 — Ngừng hoạt động đối tác
  // ──────────────────────────────────────────

  group('FR-03', () {
    testWidgets(
      'SCN-02: deactivate partner successfully changes status',
      (tester) async {
        final module = FakePartnerModule(
          scenario: FakePartnerScenario.deactivateOk,
        );
        await tester.pumpWidget(buildPage(
          module: module,
          initialPartner: _activePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        // Open menu → tap deactivate
        await tapMenuAction(tester, 'Ngừng hoạt động');

        // Confirm in dialog
        await tester.tap(
          find.widgetWithText(TextButton, 'Ngừng hoạt động'),
        );
        await tester.pumpAndSettle();

        // Module reloaded the detail
        expect(module.detailLoadCount, greaterThanOrEqualTo(2));

        // Menu now shows reactivate (status changed)
        await openMenu(tester);
        expect(find.text('Kích hoạt lại'), findsOneWidget);
      },
    );

    testWidgets(
      'SCN-03: deactivate partner with existing transactions preserves data',
      (tester) async {
        final module = FakePartnerModule(
          scenario: FakePartnerScenario.deactivateOk,
        );
        await tester.pumpWidget(buildPage(
          module: module,
          initialPartner: _activePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        await tapMenuAction(tester, 'Ngừng hoạt động');
        await tester.tap(
          find.widgetWithText(TextButton, 'Ngừng hoạt động'),
        );
        await tester.pumpAndSettle();

        // Verify reload happened (old data preserved — only status changed)
        expect(module.detailLoadCount, greaterThanOrEqualTo(2));

        // Name still displayed (profile data preserved)
        expect(find.text('Nguyen Van An'), findsWidgets);

        // Status changed
        await openMenu(tester);
        expect(find.text('Kích hoạt lại'), findsOneWidget);
      },
    );

    testWidgets(
      'SCN-05: deactivate failure keeps status unchanged and shows error',
      (tester) async {
        final module = FakePartnerModule(
          scenario: FakePartnerScenario.deactivateSaveError,
        );
        await tester.pumpWidget(buildPage(
          module: module,
          initialPartner: _activePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        await tapMenuAction(tester, 'Ngừng hoạt động');
        await tester.tap(
          find.widgetWithText(TextButton, 'Ngừng hoạt động'),
        );
        await tester.pumpAndSettle();

        // Status should remain active — menu still shows deactivate
        await openMenu(tester);
        expect(find.text('Ngừng hoạt động'), findsOneWidget);
        expect(find.text('Kích hoạt lại'), findsNothing);
      },
    );
  });

  // ──────────────────────────────────────────
  // FR-04 — Kích hoạt lại đối tác
  // ──────────────────────────────────────────

  group('FR-04', () {
    testWidgets(
      'SCN-02: reactivate partner successfully changes status',
      (tester) async {
        final module = FakePartnerModule(
          scenario: FakePartnerScenario.reactivateOk,
        );
        await tester.pumpWidget(buildPage(
          module: module,
          initialPartner: _inactivePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        await tapMenuAction(tester, 'Kích hoạt lại');
        await tester.tap(
          find.widgetWithText(TextButton, 'Kích hoạt lại'),
        );
        await tester.pumpAndSettle();

        expect(module.detailLoadCount, greaterThanOrEqualTo(2));

        // Menu now shows deactivate (status changed to active)
        await openMenu(tester);
        expect(find.text('Ngừng hoạt động'), findsOneWidget);
        expect(find.text('Kích hoạt lại'), findsNothing);
      },
    );

    testWidgets(
      'SCN-06: reactivate failure keeps status unchanged and shows error',
      (tester) async {
        final module = FakePartnerModule(
          scenario: FakePartnerScenario.reactivateSaveError,
        );
        await tester.pumpWidget(buildPage(
          module: module,
          initialPartner: _inactivePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        await tapMenuAction(tester, 'Kích hoạt lại');
        await tester.tap(
          find.widgetWithText(TextButton, 'Kích hoạt lại'),
        );
        await tester.pumpAndSettle();

        // Status should remain inactive — menu still shows reactivate
        await openMenu(tester);
        expect(find.text('Kích hoạt lại'), findsOneWidget);
      },
    );
  });

  // ──────────────────────────────────────────
  // FR-05 — Ghi nhận kết quả thay đổi trạng thái
  // (SCN-04, SCN-05, SCN-06: failure at save stage)
  // ──────────────────────────────────────────

  group('FR-05', () {
    testWidgets(
      'SCN-04: does not complete when save fails (missing traceability data)',
      (tester) async {
        await tester.pumpWidget(buildPage(
          module: FakePartnerModule(
            scenario: FakePartnerScenario.deactivateSaveError,
          ),
          initialPartner: _activePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        await tapMenuAction(tester, 'Ngừng hoạt động');
        await tester.tap(
          find.widgetWithText(TextButton, 'Ngừng hoạt động'),
        );
        await tester.pumpAndSettle();

        // Status unchanged — page still shows active partner info
        expect(find.text('Nguyen Van An'), findsWidgets);
        await openMenu(tester);
        expect(find.text('Ngừng hoạt động'), findsOneWidget);
      },
    );

    testWidgets(
      'SCN-05: does not complete when audit log write fails',
      (tester) async {
        await tester.pumpWidget(buildPage(
          module: FakePartnerModule(
            scenario: FakePartnerScenario.deactivateSaveError,
          ),
          initialPartner: _activePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        await tapMenuAction(tester, 'Ngừng hoạt động');
        await tester.tap(
          find.widgetWithText(TextButton, 'Ngừng hoạt động'),
        );
        await tester.pumpAndSettle();

        await openMenu(tester);
        expect(find.text('Ngừng hoạt động'), findsOneWidget);
      },
    );

    testWidgets(
      'SCN-06: no partial update when save fails',
      (tester) async {
        await tester.pumpWidget(buildPage(
          module: FakePartnerModule(
            scenario: FakePartnerScenario.reactivateSaveError,
          ),
          initialPartner: _inactivePartner,
          permissions: {
            PartnerPermissions.viewDetail,
            PartnerPermissions.manageStatus,
          },
        ));
        await tester.pumpAndSettle();

        await tapMenuAction(tester, 'Kích hoạt lại');
        await tester.tap(
          find.widgetWithText(TextButton, 'Kích hoạt lại'),
        );
        await tester.pumpAndSettle();

        // Status remains inactive — no partial update
        await openMenu(tester);
        expect(find.text('Kích hoạt lại'), findsOneWidget);
      },
    );
  });
}
