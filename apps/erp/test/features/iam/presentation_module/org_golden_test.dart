import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/address/vn_administrative_units_loader.dart';
import 'package:erp/features/iam/data/models/tenant_profile.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../receivable/presentation/receivable_test_harness.dart';
import '../support/scripted_iam_repositories.dart';

TenantProfile _goldenTenant({bool withLegal = false}) {
  return TenantProfile(
    tenantId: 'org-001',
    displayName: 'Thú y An Phát',
    version: 1,
    businessTimezone: 'Asia/Ho_Chi_Minh',
    baseCurrencyCode: 'VND',
    createdAt: DateTime(2026, 7, 10),
    updatedAt: DateTime(2026, 7, 12),
    contactEmail: 'lan@anphat.vn',
    contactPhone: '0912 345 678',
    contactAddressText: 'Số 12 Nguyễn Trãi',
    provinceCode: '79',
    communeCode: '27139',
    legalProfile: withLegal
        ? TenantLegalProfile(
            tenantId: 'org-001',
            legalEntityType: LegalEntityType.enterprise,
            legalName: 'Công ty TNHH Thú y An Phát',
            taxCode: '0312345678',
            version: 1,
            createdAt: DateTime(2026, 7, 11),
            updatedAt: DateTime(2026, 7, 11),
            registeredAddressText: 'Số 12 Nguyễn Trãi',
            provinceCode: '79',
            communeCode: '27139',
          )
        : null,
  );
}

/// Seed danh mục trong thân `testWidgets`: `Future.value` tạo ở `setUp` nằm
/// ngoài vùng thời gian giả nên `FutureBuilder` của form không nhận kết quả.
void _seedUnits() {
  VnAdministrativeUnitsLoader.seedCacheForTest(const [
    VnAdministrativeUnit(
      code: '79',
      fullName: 'Thành phố Hồ Chí Minh',
      wards: [
        VnWard(
          code: '27139',
          fullName: 'Phường Bàn Cờ',
          provinceCode: '79',
        ),
      ],
    ),
  ]);
}

Future<void> _captureOrg(
  WidgetTester tester, {
  required int width,
  required String name,
  required Widget page,
  Future<void> Function()? act,
}) async {
  _seedUnits();
  final phone = width == 390;
  final view = tester.view;
  view.physicalSize = phone ? const Size(390, 844) : const Size(1280, 800);
  view.devicePixelRatio = 1;
  if (phone) {
    view.padding = const FakeViewPadding(top: 30, bottom: 34);
    view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      home: RepaintBoundary(key: key, child: page),
    ),
  );
  await tester.pumpAndSettle();
  if (act != null) {
    await act();
    await tester.pumpAndSettle();
  }
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(
      '${repoRoot()}/docs/refactor/plans/P10/img/10-8g/flutter-$name-$width.png',
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadInterFont();
  });

  tearDown(VnAdministrativeUnitsLoader.resetCache);

  for (final width in const [390, 1280]) {
    testWidgets('org-profile__no-legal $width', (tester) async {
      await _captureOrg(
        tester,
        width: width,
        name: 'org-profile__no-legal',
        page: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(
            tenant: _goldenTenant(withLegal: false),
          ),
        ),
      );
    });

    testWidgets('org-profile__with-legal $width', (tester) async {
      await _captureOrg(
        tester,
        width: width,
        name: 'org-profile__with-legal',
        page: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(
            tenant: _goldenTenant(withLegal: true),
          ),
        ),
      );
    });

    testWidgets('org-profile__forbidden $width', (tester) async {
      await _captureOrg(
        tester,
        width: width,
        name: 'org-profile__forbidden',
        page: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(
            mode: OrganizationScript.forbidden,
          ),
        ),
      );
    });
  }

  testWidgets('org-profile__actions 390', (tester) async {
    await _captureOrg(
      tester,
      width: 390,
      name: 'org-profile__actions',
      page: OrganizationProfilePage(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: false),
        ),
      ),
      act: () => tester.tap(find.text('Thao tác')),
    );
  });

  for (final width in const [390, 1280]) {
    testWidgets('org-edit__filled $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: false),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-edit__filled',
        page: OrganizationEditProfilePage(cubit: cubit),
      );
      await cubit.close();
    });

    testWidgets('org-edit__errors $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: false),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-edit__errors',
        page: OrganizationEditProfilePage(cubit: cubit),
        act: () async {
          final fields = find.byType(TextField);
          await tester.enterText(fields.at(0), '');
          await tester.enterText(fields.at(1), '');
          await tester.enterText(fields.at(2), 'lan@anphat');
          await tester.enterText(fields.at(3), '');
          await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
        },
      );
      await cubit.close();
    });

    testWidgets('org-edit__discard $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: false),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-edit__discard',
        page: OrganizationEditProfilePage(cubit: cubit),
        act: () async {
          await tester.enterText(
            find.byType(TextField).first,
            'Thú y An Phát Quận 3',
          );
          await tester.tap(find.widgetWithText(VButton, 'Hủy'));
        },
      );
      await cubit.close();
    });

    testWidgets('org-legal__add-empty $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: false),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-legal__add-empty',
        page: OrganizationLegalProfileFormPage(cubit: cubit),
      );
      await cubit.close();
    });

    testWidgets('org-legal__add-errors $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: false),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-legal__add-errors',
        page: OrganizationLegalProfileFormPage(cubit: cubit),
        act: () => tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ')),
      );
      await cubit.close();
    });

    testWidgets('org-legal__add-tax-format $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: false),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-legal__add-tax-format',
        page: OrganizationLegalProfileFormPage(cubit: cubit),
        act: () async {
          if (width == 390) {
            await tester.tap(find.text('Hộ kinh doanh'));
          } else {
            await tester.tap(find.text('Chọn loại chủ thể'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Hộ kinh doanh').last);
          }
          await tester.enterText(
            find.byWidgetPredicate(
              (w) =>
                  w is TextField &&
                  w.decoration?.hintText == 'Nhập tên pháp lý',
            ),
            'Hộ kinh doanh Thú y An Phát',
          );
          await tester.enterText(
            find.byWidgetPredicate(
              (w) =>
                  w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
            ),
            '031234567',
          );
          await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
        },
      );
      await cubit.close();
    });

    testWidgets('org-legal__edit-filled $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          tenant: _goldenTenant(withLegal: true),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-legal__edit-filled',
        page: OrganizationLegalProfileFormPage(cubit: cubit),
      );
      await cubit.close();
    });

    testWidgets('org-legal__duplicate $width', (tester) async {
      final cubit = OrganizationProfileCubit(
        organizationRepository: ScriptedOrganizationRepository(
          mode: OrganizationScript.duplicateWarning,
          tenant: _goldenTenant(withLegal: true),
        ),
      );
      await cubit.load();
      await _captureOrg(
        tester,
        width: width,
        name: 'org-legal__duplicate',
        page: OrganizationLegalProfileFormPage(cubit: cubit),
        act: () => tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ')),
      );
      await cubit.close();
    });
  }
}
