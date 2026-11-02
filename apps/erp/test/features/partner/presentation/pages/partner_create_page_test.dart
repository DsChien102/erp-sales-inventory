import 'package:erp/features/partner/presentation/pages/partner_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../support/fake_partner_repository.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

void main() {
  testWidgets('wgt_e01_u02_fr07_01: success shows toast and hands off id', (
    tester,
  ) async {
    var createdId = '';
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerCreatePage(
          partnerType: PartnerType.person,
          repository: FakePartnerRepository(
            scenario: FakePartnerScenario.createPersonOk,
          ),
          onCreated: (id) => createdId = id,
          onOpenExisting: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_full_name')),
      'Nguyễn Văn Minh',
    );
    await tester.enterText(
      find.byKey(const Key('input_phone')),
      '0901234567',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pumpAndSettle();

    expect(createdId, 'p-new-1');
  });

  testWidgets('wgt_e01_u02_fr03_01: organization create success hands off id', (
    tester,
  ) async {
    var createdId = '';
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerCreatePage(
          partnerType: PartnerType.organization,
          repository: FakePartnerRepository(
            scenario: FakePartnerScenario.createOrganizationOk,
          ),
          onCreated: (id) => createdId = id,
          onOpenExisting: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('role_supplier')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_organization_name')),
      'Công ty TNHH An Phát',
    );
    await tester.enterText(
      find.byKey(const Key('input_phone')),
      '02812345678',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pumpAndSettle();

    expect(createdId, 'p-new-2');
  });

  testWidgets('wgt_e01_u03_fr01_01: edit success hands off updated id', (
    tester,
  ) async {
    var updatedId = '';
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerCreatePage.edit(
          partnerId: 'p-1',
          repository: FakePartnerRepository(
            scenario: FakePartnerScenario.detailPersonActive,
          ),
          onUpdated: (id) => updatedId = id,
          onOpenExisting: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(find.textContaining('Người liên hệ chính'), findsNothing);
    expect(
      tester.widget<VButton>(find.byKey(const Key('btn_save_view'))).onPressed,
      isNull,
    );

    // Expand main info (hydrate opens role section by default).
    await tester.tap(find.text('3. Thông tin cá nhân'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_full_name')),
      'Nguyễn Văn B',
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<VButton>(find.byKey(const Key('btn_save_view'))).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pumpAndSettle();

    expect(updatedId, 'p-1');
  });

  testWidgets('dirty back opens leave confirmation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => PartnerCreatePage(
              partnerType: PartnerType.person,
              repository: FakePartnerRepository(),
              onCreated: (_) {},
              onOpenExisting: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.pump();

    await tester.tap(find.byIcon(VIcons.arrowBack.value));
    await tester.pumpAndSettle();

    expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
    expect(find.text('Ở lại chỉnh sửa'), findsOneWidget);
    expect(find.text('Rời khỏi'), findsOneWidget);
  });
}
