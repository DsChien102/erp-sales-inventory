import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _AuditAcceptanceIamModule implements IIamModule {
  static const activationAuditId = 'AUD-T-ACTIVATE-042';
  final auditQueries = <SearchTenantAuditLogsQuery>[];

  static final _activationSummary = TenantAuditLogSummaryDto(
    auditLogId: activationAuditId,
    eventCode: IamAuditEvents.tenantActivated,
    eventCategory: TenantAuditEventCategory.organization,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime(2026, 8, 20, 9, 30),
    source: 'tenant-app',
    trackingId: 'TRK-ACTIVATE-042',
    actor: const TenantAuditActorDto(
      userId: 'user-owner-042',
      displayName: 'Lê Thị Lan',
      actorType: 'user',
      roleCode: 'store_owner',
      roleLabel: 'Chủ sở hữu',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
    subject: const TenantAuditSubjectDto(
      type: 'tenant',
      id: 'org-001',
      displayName: 'Phòng khám Vet 45',
      code: 'VET45-HCM',
      secondaryLabel: null,
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
  );

  static final _profileUpdateSummary = TenantAuditLogSummaryDto(
    auditLogId: 'AUD-T-PROFILE-043',
    eventCode: IamAuditEvents.tenantProfileUpdated,
    eventCategory: TenantAuditEventCategory.organization,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime(2026, 8, 20, 9),
    source: 'tenant-app',
    trackingId: 'TRK-PROFILE-043',
    actor: const TenantAuditActorDto(
      userId: 'user-manager-043',
      displayName: 'Nguyễn Văn An',
      actorType: 'user',
      roleCode: 'store_manager',
      roleLabel: 'Quản lý chi nhánh',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
    subject: const TenantAuditSubjectDto(
      type: 'tenant',
      id: 'org-001',
      displayName: 'Phòng khám Vet 45',
      code: 'VET45-HCM',
      secondaryLabel: null,
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
  );

  static final _activationDetail = TenantAuditLogDetailDto(
    auditLogId: activationAuditId,
    tenantId: 'org-001',
    eventCode: IamAuditEvents.tenantActivated,
    eventCategory: TenantAuditEventCategory.organization,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime(2026, 8, 20, 9, 30),
    source: 'tenant-app',
    trackingId: 'TRK-ACTIVATE-042',
    actorUnavailable: false,
    beforeRedacted: false,
    afterRedacted: false,
    actor: _activationSummary.actor,
    subject: _activationSummary.subject,
    beforeState: const {
      'status': 'provisioning',
      'updated_at': '2026-08-20T02:29:00Z',
      'business_timezone': 'Asia/Ho_Chi_Minh',
    },
    afterState: const {
      'status': 'active',
      'updated_at': '2026-08-20T02:30:00Z',
      'business_timezone': 'Asia/Ho_Chi_Minh',
    },
  );

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('No command is expected in the audit acceptance flow.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchTenantAuditLogsQuery) {
      final auditQuery = query as SearchTenantAuditLogsQuery;
      auditQueries.add(auditQuery);
      var items = [_activationSummary, _profileUpdateSummary];
      if (auditQuery.tenantId != 'org-001') {
        items = const [];
      }
      items = items
          .where(
            (item) =>
                !item.occurredAt.isBefore(auditQuery.fromUtc) &&
                item.occurredAt.isBefore(auditQuery.toUtc),
          )
          .toList();
      if (auditQuery.result != null) {
        items = items.where((item) => item.result.code == auditQuery.result).toList();
      }
      if (auditQuery.eventCategory != null) {
        items = items.where((item) => item.eventCategory == auditQuery.eventCategory).toList();
      }
      if (auditQuery.subjectType != null) {
        items = items.where((item) => item.subject.type == auditQuery.subjectType).toList();
      }
      final eventCodes = auditQuery.eventCodes;
      if (eventCodes != null && eventCodes.isNotEmpty) {
        items = items.where((item) => eventCodes.contains(item.eventCode)).toList();
      }
      final freeText = auditQuery.query?.trim().toLowerCase();
      if (freeText != null && freeText.isNotEmpty) {
        items = items
            .where(
              (item) => [
                item.auditLogId,
                item.eventCode,
                item.trackingId,
                item.actor.displayName,
                item.subject.displayName,
                item.subject.code,
              ].whereType<String>().any((value) => value.toLowerCase().contains(freeText)),
            )
            .toList();
      }
      return TenantAuditLogSearchPageDto(
            items: items,
            totalCount: items.length,
          )
          as TResult;
    }
    if (query is GetTenantAuditLogQuery) {
      final detailQuery = query as GetTenantAuditLogQuery;
      if (detailQuery.tenantId == 'org-001' && detailQuery.auditLogId == activationAuditId) {
        return _activationDetail as TResult;
      }
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    throw UnsupportedError('Unexpected query ${query.runtimeType}.');
  }
}

/// e2e_e02_u01..u07 — tenant profile/legal (S12) + audit (S13).
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void register(IIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'org-001'),
      )
      ..registerSingleton<IIamModule>(module);
  }

  testWidgets(
    'e2e_e02_u01_fr01_01: load profile → edit → UpdateTenantProfileCommand',
    (tester) async {
      await phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.tenantProfileUpdateOk),
      );
      register(module);

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
      await phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.legalDuplicateWarning),
      );
      register(module);

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
      await phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantProfileStale,
      );
      register(module);

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
    'e2e_e02_u07_fr01_01: audit list/search → activation forensic detail',
    (tester) async {
      await phone(tester);
      final module = _AuditAcceptanceIamModule();
      register(module);

      final router = GoRouter(
        initialLocation: '/more/audit-logs',
        routes: [
          GoRoute(
            path: '/more/audit-logs',
            builder: (context, state) => OrganizationAuditLogsPage(
              iamModule: module,
              executionContext: FakeExecutionContext(tenantId: 'org-001'),
              clockLocal: () => DateTime(2026, 8, 20),
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
      expect(module.auditQueries, hasLength(1));
      final initialAuditQuery = module.auditQueries.single;
      expect(initialAuditQuery.tenantId, 'org-001');
      expect(initialAuditQuery.fromUtc, DateTime.utc(2026, 7, 21, 17));
      expect(initialAuditQuery.toUtc, DateTime.utc(2026, 8, 20, 17));
      expect(initialAuditQuery.query, isNull);
      expect(initialAuditQuery.result, isNull);
      expect(initialAuditQuery.eventCategory, isNull);
      expect(initialAuditQuery.subjectType, isNull);
      expect(initialAuditQuery.eventCodes, isNull);
      expect(initialAuditQuery.cursor, isNull);
      expect(find.text('2 hoạt động trong 30 ngày'), findsOneWidget);
      expect(find.text('Kích hoạt tổ chức'), findsOneWidget);
      expect(find.text('Cập nhật hồ sơ tổ chức'), findsOneWidget);
      expect(
        find.textContaining('Phòng khám Vet 45'),
        findsNWidgets(2),
      );

      await tester.enterText(find.byType(VSearchBar), 'Kích hoạt tổ chức');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(module.auditQueries, hasLength(2));
      final searchAuditQuery = module.auditQueries.last;
      expect(searchAuditQuery.tenantId, 'org-001');
      expect(searchAuditQuery.fromUtc, DateTime.utc(2026, 7, 21, 17));
      expect(searchAuditQuery.toUtc, DateTime.utc(2026, 8, 20, 17));
      expect(searchAuditQuery.query, isNull);
      expect(searchAuditQuery.result, isNull);
      expect(searchAuditQuery.eventCategory, isNull);
      expect(searchAuditQuery.subjectType, isNull);
      expect(searchAuditQuery.eventCodes, [IamAuditEvents.tenantActivated]);
      expect(searchAuditQuery.cursor, isNull);
      expect(find.text('1 hoạt động trong 30 ngày'), findsOneWidget);
      expect(find.text('Kích hoạt tổ chức'), findsNWidgets(2));
      expect(find.text('Cập nhật hồ sơ tổ chức'), findsNothing);

      final activationCard = find.byWidgetPredicate(
        (widget) =>
            widget is AuditLogItemCard &&
            widget.log.title == 'Kích hoạt tổ chức' &&
            widget.log.id == 'AUD-T-ACTIVATE-042',
        description: 'activation audit card with stable title and audit ID',
      );
      expect(activationCard, findsOneWidget);

      await tester.tap(activationCard);
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết hoạt động'), findsOneWidget);
      expect(find.text('Kích hoạt tổ chức'), findsOneWidget);
      expect(
        find.text('iam.tenant.activated · AUD-T-ACTIVATE-042'),
        findsOneWidget,
      );
      expect(find.text('Thành công'), findsOneWidget);

      expect(find.text('Lê Thị Lan'), findsOneWidget);
      expect(find.text('user-owner-042'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
      expect(find.text('Chủ sở hữu'), findsOneWidget);
      expect(find.text('store_owner'), findsOneWidget);

      expect(find.text('Loại đối tượng'), findsOneWidget);
      expect(find.text('Tổ chức'), findsOneWidget);
      expect(find.text('Phòng khám Vet 45'), findsOneWidget);
      expect(find.text('VET45-HCM'), findsOneWidget);
      expect(find.text('org-001'), findsOneWidget);
      expect(find.text('Thông tin hiện tại'), findsNothing);
      expect(find.text('Không còn dữ liệu'), findsNothing);

      expect(find.text('20/08/2026 · 09:30'), findsOneWidget);
      expect(find.text('tenant-app'), findsOneWidget);
      expect(find.text('TRK-ACTIVATE-042'), findsOneWidget);

      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Đang khởi tạo'), findsOneWidget);
      expect(find.text('Đang hoạt động'), findsOneWidget);
      expect(find.text('Thời gian cập nhật'), findsOneWidget);
      expect(find.text('2026-08-20T02:29:00Z'), findsOneWidget);
      expect(find.text('2026-08-20T02:30:00Z'), findsOneWidget);
      expect(find.text('Business Timezone'), findsNothing);
    },
  );

  testWidgets(
    'e2e_e02_u07_fr01_02: audit forbidden shows unauthorized state',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantAuditForbidden,
      );
      register(module);

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

      expect(find.text('Chưa được cấp quyền'), findsOneWidget);
      expect(
        find.text('Bạn không có quyền xem lịch sử quản trị'),
        findsOneWidget,
      );
      expect(find.text('Quay lại'), findsOneWidget);
      expect(find.text('Không thể tải lịch sử quản trị'), findsNothing);
      expect(find.text('Thử lại'), findsNothing);
    },
  );
}
