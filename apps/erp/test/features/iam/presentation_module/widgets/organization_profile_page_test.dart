import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/core/widgets/address/vn_administrative_units_loader.dart';
import 'package:erp/features/iam/data/models/tenant_profile.dart';
import 'package:erp/features/iam/data/models/upsert_legal_profile_result.dart';
import 'package:erp/features/iam/data/organization_repository.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase/supabase.dart';

import '../../support/scripted_iam_repositories.dart';

final class _CountingOrgRepo extends OrganizationRepository {
  _CountingOrgRepo({
    OrganizationScript mode = OrganizationScript.ok,
    TenantProfile? tenant,
  }) : _inner = ScriptedOrganizationRepository(mode: mode, tenant: tenant),
       super(
         rpc: SupabaseRpc(
           SupabaseClient(
             'http://127.0.0.1',
             'anon',
             authOptions: const AuthClientOptions(autoRefreshToken: false),
           ),
         ),
         tenantId: () async => 'org-001',
       );

  final ScriptedOrganizationRepository _inner;
  int getTenantCalls = 0;
  bool failNextGet = false;

  @override
  Future<TenantProfile> getTenant() async {
    getTenantCalls++;
    if (failNextGet) {
      failNextGet = false;
      throw Exception('network error');
    }
    return _inner.getTenant();
  }

  @override
  Future<TenantProfile> updateProfile({
    required String displayName,
    required String? contactEmail,
    required String? contactPhone,
    required String? contactAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
  }) => _inner.updateProfile(
    displayName: displayName,
    contactEmail: contactEmail,
    contactPhone: contactPhone,
    contactAddressText: contactAddressText,
    provinceCode: provinceCode,
    communeCode: communeCode,
    expectedVersion: expectedVersion,
  );

  @override
  Future<UpsertLegalProfileResult> upsertLegalProfile({
    required String legalEntityType,
    required String legalName,
    required String taxCode,
    required String? registeredAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
    bool allowDuplicateTaxCode = false,
  }) => _inner.upsertLegalProfile(
    legalEntityType: legalEntityType,
    legalName: legalName,
    taxCode: taxCode,
    registeredAddressText: registeredAddressText,
    provinceCode: provinceCode,
    communeCode: communeCode,
    expectedVersion: expectedVersion,
    allowDuplicateTaxCode: allowDuplicateTaxCode,
  );
}

Future<GoRouter> pumpOrgProfile(
  WidgetTester tester, {
  required Size size,
  required OrganizationRepository repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/more/organization-profile',
    routes: [
      GoRoute(
        path: '/more/organization-profile',
        builder: (context, state) =>
            OrganizationProfilePage(organizationRepository: repository),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  const Text('EDIT_PAGE'),
                  TextButton(
                    onPressed: () => context.pop(true),
                    child: const Text('DONE_EDIT'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: 'legal',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  const Text('LEGAL_PAGE'),
                  TextButton(
                    onPressed: () => context.pop(true),
                    child: const Text('DONE_LEGAL'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('wgt_e02_u01_fr01_01: loads tenant profile without mock defaults', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ tổ chức'), findsWidgets);
    expect(find.text('Mậu Hiên'), findsWidgets);
    expect(find.text('contact@mauhien.vn'), findsOneWidget);
    expect(find.text('Thao tác'), findsOneWidget);

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác hồ sơ'), findsOneWidget);
    expect(find.text('Chỉnh sửa thông tin tổ chức'), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ pháp lý'), findsOneWidget);
  });

  testWidgets('forbidden shows unauthorized empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(
            mode: OrganizationScript.forbidden,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thao tác'), findsNothing);
  });

  testWidgets('section headings expose header semantics', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.text('Thông tin tổ chức'));
    expect(node.flagsCollection.isHeader, isTrue);

    handle.dispose();
  });

  testWidgets('load error retries', (tester) async {
    final repo = _CountingOrgRepo()..failNextGet = true;
    await pumpOrgProfile(
      tester,
      size: const Size(390, 844),
      repository: repo,
    );

    expect(find.text('Không tải được hồ sơ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Mậu Hiên'), findsWidgets);
    expect(repo.getTenantCalls, 2);
  });

  testWidgets('add legal opens the form', (tester) async {
    final base = sampleTenantProfile();
    final repo = _CountingOrgRepo(
      tenant: TenantProfile(
        tenantId: base.tenantId,
        displayName: base.displayName,
        version: base.version,
        businessTimezone: base.businessTimezone,
        baseCurrencyCode: base.baseCurrencyCode,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        contactEmail: base.contactEmail,
        contactPhone: base.contactPhone,
        contactAddressText: base.contactAddressText,
        provinceCode: base.provinceCode,
        communeCode: base.communeCode,
        legalProfile: null,
      ),
    );
    await pumpOrgProfile(
      tester,
      size: const Size(390, 844),
      repository: repo,
    );

    await tester.tap(find.byKey(const Key('legal_profile_org_banner_add')));
    await tester.pumpAndSettle();

    expect(find.text('LEGAL_PAGE'), findsOneWidget);
  });

  testWidgets('returning true reloads', (tester) async {
    final repo = _CountingOrgRepo();
    await pumpOrgProfile(
      tester,
      size: const Size(390, 844),
      repository: repo,
    );
    final before = repo.getTenantCalls;

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa thông tin tổ chức'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT_PAGE'), findsOneWidget);
    await tester.tap(find.text('DONE_EDIT'));
    await tester.pumpAndSettle();

    expect(repo.getTenantCalls, before + 1);
  });

  testWidgets('390: address shows ward and province', (tester) async {
    VnAdministrativeUnitsLoader.seedCacheForTest(const [
      VnAdministrativeUnit(
        code: '79',
        fullName: 'Thành phố Hồ Chí Minh',
        wards: [
          VnWard(
            code: '27139',
            fullName: 'Phường Xuân Hoà',
            provinceCode: '79',
          ),
        ],
      ),
    ]);
    addTearDown(VnAdministrativeUnitsLoader.resetCache);
    final base = sampleTenantProfile();
    final repo = _CountingOrgRepo(
      tenant: TenantProfile(
        tenantId: base.tenantId,
        displayName: base.displayName,
        version: base.version,
        businessTimezone: base.businessTimezone,
        baseCurrencyCode: base.baseCurrencyCode,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        contactEmail: base.contactEmail,
        contactPhone: base.contactPhone,
        contactAddressText: 'Số 12 Nguyễn Trãi',
        provinceCode: '79',
        communeCode: '27139',
        legalProfile: base.legalProfile,
      ),
    );
    await pumpOrgProfile(
      tester,
      size: const Size(390, 844),
      repository: repo,
    );

    expect(
      find.text('Số 12 Nguyễn Trãi, Phường Xuân Hoà, Thành phố Hồ Chí Minh'),
      findsOneWidget,
    );
  });

  testWidgets(
    '390: no legal profile shows notice, reminder and Bổ sung; no banner',
    (tester) async {
      final base = sampleTenantProfile();
      final repo = _CountingOrgRepo(
        tenant: TenantProfile(
          tenantId: base.tenantId,
          displayName: base.displayName,
          version: base.version,
          businessTimezone: base.businessTimezone,
          baseCurrencyCode: base.baseCurrencyCode,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
          contactEmail: base.contactEmail,
          contactPhone: base.contactPhone,
          contactAddressText: base.contactAddressText,
          legalProfile: null,
        ),
      );
      await pumpOrgProfile(
        tester,
        size: const Size(390, 844),
        repository: repo,
      );

      expect(find.byType(VBanner), findsNothing);
      expect(find.text('Chưa có hồ sơ pháp lý'), findsOneWidget);
      expect(
        find.text('Bổ sung hồ sơ pháp lý để xuất hoá đơn điện tử.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('legal_profile_org_banner_add')),
        findsOneWidget,
      );
    },
  );

  testWidgets('1280: no Thao tác; edit icons open edit and legal', (
    tester,
  ) async {
    final repo = _CountingOrgRepo();
    final router = await pumpOrgProfile(
      tester,
      size: const Size(1280, 800),
      repository: repo,
    );

    expect(find.text('Thao tác'), findsNothing);

    await tester.tap(find.byTooltip('Chỉnh sửa thông tin tổ chức'));
    await tester.pumpAndSettle();
    expect(find.text('EDIT_PAGE'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Chỉnh sửa hồ sơ pháp lý'));
    await tester.pumpAndSettle();
    expect(find.text('LEGAL_PAGE'), findsOneWidget);
  });

  testWidgets('1280: no legal profile shows Thêm hồ sơ pháp lý', (tester) async {
    final base = sampleTenantProfile();
    final repo = _CountingOrgRepo(
      tenant: TenantProfile(
        tenantId: base.tenantId,
        displayName: base.displayName,
        version: base.version,
        businessTimezone: base.businessTimezone,
        baseCurrencyCode: base.baseCurrencyCode,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        contactEmail: base.contactEmail,
        contactPhone: base.contactPhone,
        contactAddressText: base.contactAddressText,
        legalProfile: null,
      ),
    );
    await pumpOrgProfile(
      tester,
      size: const Size(1280, 800),
      repository: repo,
    );

    expect(find.text('Thêm hồ sơ pháp lý'), findsOneWidget);
    await tester.tap(find.text('Thêm hồ sơ pháp lý'));
    await tester.pumpAndSettle();
    expect(find.text('LEGAL_PAGE'), findsOneWidget);
  });

  testWidgets('1280: header omits empty contact parts', (tester) async {
    final base = sampleTenantProfile();
    final repo = _CountingOrgRepo(
      tenant: TenantProfile(
        tenantId: base.tenantId,
        displayName: base.displayName,
        version: base.version,
        businessTimezone: base.businessTimezone,
        baseCurrencyCode: base.baseCurrencyCode,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        contactEmail: null,
        contactPhone: null,
        contactAddressText: null,
        legalProfile: null,
      ),
    );
    await pumpOrgProfile(
      tester,
      size: const Size(1280, 800),
      repository: repo,
    );

    expect(find.textContaining('·'), findsNothing);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('320 at text scale 2.0 and 840x900 do not overflow', (
    tester,
  ) async {
    for (final size in const [Size(320, 568), Size(840, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(2.0),
            ),
            child: OrganizationProfilePage(
              organizationRepository: _CountingOrgRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
  });
}
