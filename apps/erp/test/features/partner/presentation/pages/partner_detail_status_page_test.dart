import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _FakePrincipalSnapshot implements IPrincipalSnapshot {
  @override
  String? get userId => 'user-1';

  @override
  String? get tenantId => 'tenant-1';

  @override
  String? get role => 'member';

  @override
  bool hasPermission(String code) => true;
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

  Future<void> openDetailPage(
    WidgetTester tester, {
    required FakePartnerModule partnerModule,
    required PartnerItemModel initialPartner,
  }) async {
    getIt
      ..registerSingleton<IPartnerModule>(partnerModule)
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'tenant-1', userId: 'user-1'),
      )
      ..registerSingleton<IPrincipalSnapshot>(_FakePrincipalSnapshot());

    await tester.pumpWidget(
      MaterialApp(
        home: PartnerDetailPage(
          partnerId: 'partner-1',
          initialPartner: initialPartner,
          canManageStatus: true,
          canDelete: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapMenuAction(WidgetTester tester, String label) async {
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('e2e_e02_u01_fr03_01 deactivate flow updates status via fake module', (tester) async {
    final partnerModule = FakePartnerModule(scenario: FakePartnerScenario.deactivateOk);
    await openDetailPage(
      tester,
      partnerModule: partnerModule,
      initialPartner: _activePartner,
    );

    await tapMenuAction(tester, 'Ngừng hoạt động');
    await tester.tap(find.widgetWithText(TextButton, 'Ngừng hoạt động'));
    await tester.pumpAndSettle();

    expect(partnerModule.detailLoadCount, greaterThanOrEqualTo(2));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Kích hoạt lại'), findsOneWidget);
  });

  testWidgets('e2e_e02_u01_fr04_01 reactivate flow updates status via fake module', (tester) async {
    final partnerModule = FakePartnerModule(scenario: FakePartnerScenario.reactivateOk);
    await openDetailPage(
      tester,
      partnerModule: partnerModule,
      initialPartner: _inactivePartner,
    );

    await tapMenuAction(tester, 'Kích hoạt lại');
    await tester.tap(find.widgetWithText(TextButton, 'Kích hoạt lại'));
    await tester.pumpAndSettle();

    expect(partnerModule.detailLoadCount, greaterThanOrEqualTo(2));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Ngừng hoạt động'), findsOneWidget);
  });
}
