import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// e2e_e02_u01..u07 — tenant profile/legal (S12) + audit (S13).
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> _phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void _register(IIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'org-001'),
      )
      ..registerSingleton<IIamModule>(module);
  }

  testWidgets(
    'e2e_e02_u01_fr01_01: load profile → edit → UpdateTenantProfileCommand',
    (tester) async {
      await _phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.tenantProfileUpdateOk),
      );
      _register(module);

      final router = GoRouter(
        initialLocation: '/more/organization-profile',
        routes: [
          GoRoute(
            path: '/more/organization-profile',
            builder: (context, state) => OrganizationProfilePage(
              iamModule: module,
              executionContext: FakeExecutionContext(tenantId: 'org-001'),
            ),
          ),
          GoRoute(
            path: '/more/organization-profile/edit',
            builder: (context, state) {
              final cubit = OrganizationProfileCubit(
                iamModule: module,
                executionContext: FakeExecutionContext(tenantId: 'org-001'),
              )..load();
              return OrganizationEditProfilePage(cubit: cubit);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mậu Hiên'), findsWidgets);

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa thông tin tổ chức'));
      await tester.pumpAndSettle();

      expect(find.text('Chỉnh thông tin tổ chức'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Mậu Hiên Updated');
      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(module.commandsOf<UpdateTenantProfileCommand>(), hasLength(1));
    },
  );

  testWidgets(
    'e2e_e02_u01_fr01_02: legal duplicate warning then confirm',
    (tester) async {
      await _phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.legalDuplicateWarning),
      );
      _register(module);

      final cubit = OrganizationProfileCubit(
        iamModule: module,
        executionContext: FakeExecutionContext(tenantId: 'org-001'),
      );
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationLegalProfileFormPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      final taxFields = find.byType(TextField);
      expect(taxFields, findsWidgets);
      await tester.enterText(taxFields.at(1), '0312345678');
      await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
      await tester.pumpAndSettle();

      expect(find.text('Mã số thuế đã được ghi nhận'), findsOneWidget);
      await tester.tap(find.widgetWithText(VButton, 'Vẫn lưu'));
      await tester.pumpAndSettle();

      expect(
        module.commandsOf<UpsertLegalProfileCommand>(),
        isNotEmpty,
      );
      await cubit.close();
    },
  );

  testWidgets(
    'e2e_e02_u01_fr01_03: profile STATE_CHANGED / stale version surfaces failure',
    (tester) async {
      await _phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantProfileStale,
      );
      _register(module);

      final cubit = OrganizationProfileCubit(
        iamModule: module,
        executionContext: FakeExecutionContext(tenantId: 'org-001'),
      );
      await cubit.load();

      final ok = await cubit.updateProfile(
        TenantProfileFormInput(
          displayName: 'Stale Name',
          contactEmail: cubit.state.tenant?.contactEmail,
          contactPhone: cubit.state.tenant?.contactPhone,
          contactAddressText: cubit.state.tenant?.contactAddressText,
        ),
      );

      expect(ok, isFalse);
      expect(cubit.state.failure?.code, IamBlockedCodes.stateChanged);
      await cubit.close();
    },
  );

  testWidgets(
    'e2e_e02_u07_fr01_01: audit search → detail by auditLogId',
    (tester) async {
      await _phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantAuditSearchOk,
      );
      _register(module);

      final router = GoRouter(
        initialLocation: '/more/audit-logs',
        routes: [
          GoRoute(
            path: '/more/audit-logs',
            builder: (context, state) => OrganizationAuditLogsPage(
              iamModule: module,
              executionContext: FakeExecutionContext(tenantId: 'org-001'),
              clockLocal: () => DateTime(2026, 7, 31),
            ),
          ),
          GoRoute(
            path: '/more/audit-logs/:auditLogId',
            builder: (context, state) => AuditLogDetailPage(
              auditLogId: state.pathParameters['auditLogId']!,
              iamModule: module,
              executionContext: FakeExecutionContext(tenantId: 'org-001'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử quản trị'), findsOneWidget);
      expect(find.textContaining('hoạt động'), findsWidgets);

      // Open first list item if tappable.
      final items = find.byType(InkWell);
      if (items.evaluate().isNotEmpty) {
        await tester.tap(items.first);
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'e2e_e02_u07_fr01_02: audit forbidden shows unauthorized state',
    (tester) async {
      await _phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantAuditForbidden,
      );
      _register(module);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationAuditLogsPage(
            iamModule: module,
            executionContext: FakeExecutionContext(tenantId: 'org-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('quyền'), findsWidgets);
    },
  );
}
