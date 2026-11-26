import 'dart:ui' show CheckedState;

import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/core/validation/tax_code.dart';
import 'package:erp/features/iam/data/models/tenant_profile.dart';
import 'package:erp/features/iam/data/models/upsert_legal_profile_result.dart';
import 'package:erp/features/iam/data/organization_repository.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:supabase/supabase.dart';

import '../../support/scripted_iam_repositories.dart';

final class _DelayedDuplicateRepo extends OrganizationRepository {
  _DelayedDuplicateRepo()
    : _inner = ScriptedOrganizationRepository(
        mode: OrganizationScript.duplicateWarning,
      ),
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

  @override
  Future<TenantProfile> getTenant() => _inner.getTenant();

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
  }) async {
    if (allowDuplicateTaxCode) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return _inner.upsertLegalProfile(
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
}

TenantProfile _emptyLegalTenant() {
  final base = sampleTenantProfile();
  return TenantProfile(
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
  );
}

void main() {
  testWidgets('wgt_e02_u03_fr01_01: legal form does not use endsWith 999 simulation', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ScriptedOrganizationRepository();
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh hồ sơ pháp lý'), findsOneWidget);
    expect(find.text('Lưu hồ sơ'), findsOneWidget);

    // Tax code ending with 999 must not auto-open mock duplicate sheet.
    final taxFields = find.byType(TextField);
    expect(taxFields, findsWidgets);
    await tester.enterText(taxFields.at(1), '0123456999');
    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Mã số thuế đã được ghi nhận'), findsNothing);
    expect(repository.upserts, hasLength(1));
    await cubit.close();
  });

  testWidgets('tax code field has number keyboard, formats 13-digit, and displays helper text', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ScriptedOrganizationRepository();
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    final taxFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
    );
    expect(taxFieldFinder, findsOneWidget);
    final taxField = tester.widget<TextField>(taxFieldFinder);
    expect(taxField.keyboardType, TextInputType.number);

    expect(
      find.text('10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.'),
      findsOneWidget,
    );

    await tester.enterText(taxFieldFinder, '0123456789001');
    await tester.pumpAndSettle();

    expect(find.text('0123456789-001'), findsOneWidget);
    await cubit.close();
  });

  group('PopScope discard confirmation in legal profile form', () {
    Future<void> pumpForm(WidgetTester tester, OrganizationProfileCubit cubit) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrganizationLegalProfileFormPage(cubit: cubit),
                  ),
                ),
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();
    }

    testWidgets('unmodified form pops directly on back without dialog', (tester) async {
      final repository = ScriptedOrganizationRepository();
      final cubit = OrganizationProfileCubit(organizationRepository: repository);
      await cubit.load();

      await pumpForm(tester, cubit);
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsNothing);
      await cubit.close();
    });

    testWidgets('modified form asks confirmation on back, can keep editing or discard', (tester) async {
      final repository = ScriptedOrganizationRepository();
      final cubit = OrganizationProfileCubit(organizationRepository: repository);
      await cubit.load();

      await pumpForm(tester, cubit);

      final taxFieldFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
      );
      await tester.enterText(taxFieldFinder, '0123456789001');
      await tester.pumpAndSettle();

      // Tap back -> dialog appears
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      // Tap 'Tiếp tục sửa' -> dialog closes, page remains, value kept
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsOneWidget);
      expect(find.text('0123456789-001'), findsOneWidget);

      // Tap back again -> discard
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsNothing);
      await cubit.close();
    });

    testWidgets('modified form asks confirmation on cancel button', (tester) async {
      final repository = ScriptedOrganizationRepository();
      final cubit = OrganizationProfileCubit(organizationRepository: repository);
      await cubit.load();

      await pumpForm(tester, cubit);

      final taxFieldFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
      );
      await tester.enterText(taxFieldFinder, '0123456789001');
      await tester.pumpAndSettle();

      // Tap 'Hủy' button
      await tester.tap(find.widgetWithText(VButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsNothing);
      await cubit.close();
    });
  });

  testWidgets('malformed tax code shows the field error without a toast', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    final taxFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
    );
    await tester.enterText(taxFieldFinder, '031234567');
    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text(taxCodeFormatMessage), findsOneWidget);
    expect(
      find.text('Vui lòng điền đầy đủ các thông tin bắt buộc'),
      findsNothing,
    );
    await cubit.close();
  });

  testWidgets('missing fields still show the toast', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(
        tenant: _emptyLegalTenant(),
      ),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    expect(
      find.text('Vui lòng điền đầy đủ các thông tin bắt buộc'),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets('typing clears the legal name and tax code errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(
        tenant: _emptyLegalTenant(),
      ),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên pháp lý'), findsOneWidget);
    expect(find.text('Vui lòng nhập mã số thuế'), findsOneWidget);

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập tên pháp lý',
      ),
      'Công ty A',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
      ),
      '0123456789',
    );
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên pháp lý'), findsNothing);
    expect(find.text('Vui lòng nhập mã số thuế'), findsNothing);
    await cubit.close();
  });

  testWidgets('malformed tax code is reported even without an entity type', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(
        tenant: _emptyLegalTenant(),
      ),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập tên pháp lý',
      ),
      'Công ty A',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
      ),
      '031234567',
    );
    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng chọn loại chủ thể'), findsOneWidget);
    expect(find.text(taxCodeFormatMessage), findsOneWidget);
    expect(
      find.text('Vui lòng điền đầy đủ các thông tin bắt buộc'),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets(
    'save anyway with a 500ms response closes the form without asking',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _DelayedDuplicateRepo();
      final cubit = OrganizationProfileCubit(organizationRepository: repo);
      await cubit.load();

      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          OrganizationLegalProfileFormPage(cubit: cubit),
                    ),
                  );
                },
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
      await tester.pumpAndSettle();
      expect(find.text('Mã số thuế đã được ghi nhận'), findsOneWidget);

      await tester.tap(find.widgetWithText(VButton, 'Vẫn lưu'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Mở form'), findsOneWidget);
      expect(result, isTrue);
      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(tester.takeException(), isNull);
      await cubit.close();
    },
  );

  testWidgets('390: entity type is a two-part radio', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final handle = tester.ensureSemantics();
    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(
        tenant: _emptyLegalTenant(),
      ),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Hộ kinh doanh')).flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    await tester.tap(find.text('Hộ kinh doanh'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Hộ kinh doanh')).flagsCollection.isChecked,
      CheckedState.isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Doanh nghiệp')).flagsCollection.isChecked,
      CheckedState.isTrue,
    );

    handle.dispose();
    await cubit.close();
  });

  testWidgets('390: invalid entity type turns both halves danger', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(
        tenant: _emptyLegalTenant(),
      ),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    final lightColors = VTheme.lightTheme.extension<VColorScheme>()!;
    final segment = find.byType(EntityTypeSegment);
    expect(segment, findsOneWidget);
    final decorations = tester
        .widgetList<Container>(
          find.descendant(of: segment, matching: find.byType(Container)),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border != null)
        .toList();
    expect(decorations.length, greaterThanOrEqualTo(2));
    for (final d in decorations) {
      expect(d.border!.top.color, lightColors.danger);
    }
    await cubit.close();
  });

  testWidgets('1280: entity type is required and tax code has a hint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(
        tenant: _emptyLegalTenant(),
      ),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    final requiredAsterisks = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(' *'),
    );
    expect(requiredAsterisks, findsNWidgets(3));
    expect(
      find.text('10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.'),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets('resizing keeps entity type, tax code and units', (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
      ),
      '0123456789-001',
    );
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();

    expect(find.text('0123456789-001'), findsOneWidget);
    expect(find.text('Doanh nghiệp'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('320 at text scale 2.0 and 840x900 do not overflow', (
    tester,
  ) async {
    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(),
    );
    await cubit.load();

    for (final size in const [Size(320, 568), Size(840, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(2.0),
            ),
            child: OrganizationLegalProfileFormPage(cubit: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
    await cubit.close();
  });
}
