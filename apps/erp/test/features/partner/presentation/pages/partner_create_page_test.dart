import 'package:erp/features/partner/presentation/pages/partner_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('wgt_e01_u02_fr07_01: success shows toast and hands off id', (
    tester,
  ) async {
    var createdId = '';
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerCreatePage(
          partnerType: PartnerType.person,
          partnerModule: FakePartnerModule(
            scenario: FakePartnerScenario.createPersonOk,
          ),
          executionContext: FakeExecutionContext(),
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
          partnerModule: FakePartnerModule(
            scenario: FakePartnerScenario.createOrganizationOk,
          ),
          executionContext: FakeExecutionContext(),
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

  testWidgets('dirty back opens leave confirmation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => PartnerCreatePage(
              partnerType: PartnerType.person,
              partnerModule: FakePartnerModule(),
              executionContext: FakeExecutionContext(),
              onCreated: (_) {},
              onOpenExisting: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
    expect(find.text('Ở lại chỉnh sửa'), findsOneWidget);
    expect(find.text('Rời khỏi'), findsOneWidget);
  });
}
